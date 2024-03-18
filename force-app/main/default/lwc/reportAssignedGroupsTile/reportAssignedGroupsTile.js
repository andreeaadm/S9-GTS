import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import { label, format } from "c/labelService";

import getTableData from "@salesforce/apex/ReportAccessListController.getTableData";
import removeAccess from "@salesforce/apex/ReportAccessListController.deleteAccess";
import adminChecker from "@salesforce/apex/ReportAccessListController.isCurrentUserAdminForReport";

import NAME_FIELD from "@salesforce/schema/Asset.Name";
import HIDDEN_BY_ITK_FIELD from "@salesforce/schema/Asset.Is_Hidden_By_Intertek__c";
import assetExpiryBanner from "@salesforce/apex/AssetExpiryBannerController.assetExpirystatus"; /*Prateek*/

export default class ReportAssignedGroupsTile extends LightningElement {
  labels = label;
  @api recordId;
  @api additionalClasses = "greytile";
  @track hasLoaded = false;
  @track isEmpty = true;
  @track isLoading = true;
  @api booleanExpiry; //Prateek
  @track tableData = { columns: [], rows: [] }; 

  @track showRemoveModal = false;
  @track unlinkModal = { accessId: "", reportName: "", groupName: "" };
  @track isWorking = false;
  @track reportName = "";
  isHiddenByITK = true;
  @track reportIdInArray;

  @track showManageModal = false;
  @track showHideModal = false;
  @track assetRecordTypeId;
  @track manageMode = "manage";

  @track userCanManage = false;

  get unlinkModalText() {
    return format(
      label.CONFIRMATION_REMOVE_A_FROM_B,
      this.unlinkModal.reportName,
      this.unlinkModal.groupName
    );
  }

  connectedCallback() {
    this.getData();
    this.reportIdInArray = [this.recordId];
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [NAME_FIELD, HIDDEN_BY_ITK_FIELD]
  })
  wiredAsset({ error, data }) {
    if (data) {
      this.reportName = getFieldValue(data, NAME_FIELD);
      this.isHiddenByITK = getFieldValue(data, HIDDEN_BY_ITK_FIELD);
    }
  }

  @wire(adminChecker, { reportId: "$recordId" })
  wiredAdminChecker({ error, data }) {
    this.userCanManage = data;
  }

  /*Prateek*/
  
  @wire(assetExpiryBanner, { recordId: "$recordId"})
  wiredExpiryStatus({ error, data }) {
    if (data) {
      this.booleanExpiry = data;
    }
  }

  get conditionalButtonManageAccess() {
    if (this.userCanManage) {
      return "Manage Access";
    } else {
      return null;
    }
  }

  getData() {
    this.isLoading = true;
    getTableData({
      rowLimit: 40,
      orderBy: "Contact_Group_Name_FF__c DESC",
      selectedRowIds: [],
      reportId: this.recordId
    })
      .then((response) => {
        if (response.table) {
          this.tableData = response.table;
          this.isEmpty =
            response.table.rows.length && response.table.rows.length > 0
              ? false
              : true;
          this.error = undefined;
          this.hasLoaded = true;
          this.isLoading = false;
        } else if (error) {
          this.error = error;
          this.tableData = { columns: [], rows: [] };
          this.isEmpty = true;
          this.hasLoaded = true;
        }
      })
      .catch((error) => {
        if (error) {
          this.error = error;
          this.tableData = { columns: [], rows: [] };
          this.isLoading = false;
        }
      });
  }

  handleActionClick(evt) {
    // depending on the action, launch the appropriate modal
    switch (evt.detail.value) {
      case "Remove":
        this.unlinkModal = {
          accessId: evt.detail.rowId,
          reportName: this.reportName,
          groupName: evt.detail.rowLabel
        };
        this.showRemoveModal = true;
        break;
    }
  }

  handleConfirmDelete(evt) {
    this.isWorking = true;
    removeAccess({ accessId: this.unlinkModal.accessId })
      .then((response) => {
        if (response.status === "OK") {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: "",
              variant: "Success"
            })
          );
        } else {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: response.messages[0],
              variant: "Error"
            })
          );
        }
        this.showRemoveModal = false;
        this.isWorking = false;
      })
      .then(() => this.getData())
      .catch((error) => {
        if (error) {
          this.error = error;
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: response.messages[0],
              variant: "Error"
            })
          );
        }
      });
  }

  showManageAccessModal() {
    this.showManageModal = true;
  }
  handleCancelModal() {
    this.getData();
    this.showManageModal = this.showRemoveModal = false;
  }
}