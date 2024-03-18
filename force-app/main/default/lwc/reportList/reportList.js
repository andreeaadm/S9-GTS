import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from "lightning/navigation";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { label } from "c/labelService";
import getUserWithProfile from "@salesforce/apex/ManageUserController.getUserDetails";
import getTableData from "@salesforce/apex/ReportListController.getTableData";
import ASSET_OBJECT from "@salesforce/schema/Asset";
import TYPE_FIELD from "@salesforce/schema/Asset.Type__c";
import hideReports from "@salesforce/apex/ReportListController.hideReports";
import csvExport from "@salesforce/apex/ReportListController.exportAsCSV";
import isAdminUser from "@salesforce/apex/ReportListController.isAdminUser";

export default class ReportList extends LightningElement {
  /*** Vars common to all list pages ***/
  @track labels = label;
  @api scrollAfterXPixels;
  @track tableData = { columns: [], rows: [] };
  @track tableDataCache = { columns: [], rows: [] };
  @track tableHeaderActionsVisible = false;
  @track rowLimit = 6;
  @track selectedRowIds = [];
  @track orderBy = "Last_Activity_Date__c DESC";
  @track isLoading = true;
  @track loadMoreMessage;
  @track allShown;
  @track isWorking = false;
  totalRows = 0;
  @track selectedRowId;
  @track isCellClicked = false;

  @api showExportButton;
  get conditionalExport() {
    return this.showExportButton ? this.labels.EXPORT : null;
  }
  // The list of actions is a list of objects, each with a label attribute
  // The list of actions might be different if one table row is selected vs. many table rows selected
  get actions() {
    let actionList = [];
    if(this.isAdmin.data){
      if(this.selectedRowIds.length > 1){
        actionList.push({label: "Assign reports"});
        actionList.push({label: "Retract reports"});
      }else{
        actionList.push({label: "Manage access"});
      }
    }
    actionList.push({label: this.filterHiddenOnly ? "Unhide" : "Hide"});
    return actionList;
  }
  filterTimeout;
  error;
  selectedRowCount = 0;

  /*** Vars specific to this implementation of objectHome ***/
  @track filterStatus = "";
  @track filterReportType = "";
  @track filterSearch = "";
  @track filterDateFrom = "";
  @track filterDateTo = "";
  @track filterHiddenOnly = false;
  @track filterWithdrawnOnly = false;
  @track filterUnassignedOnly = false;
  @track showManageModal = false;
  @track showHideModal = false;
  @track assetRecordTypeId;
  @track manageMode = "manage";
  adminOrCGA;

  @track hiddenReports = new Set();

  filterStatusOptions = [
    {
      label: "Official",
      value: "Official"
    },
    {
      label: "Withdrawn",
      value: "Withdrawn"
    }
  ];

  connectedCallback() {
    this.getUserData();
    this.getData();
  }

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      if (currentPageReference.state.unassigned) {
        this.filterUnassignedOnly = true;
      }
    }
  }

  // Get the correct record type Id for our assets
  @wire(getObjectInfo, { objectApiName: ASSET_OBJECT })
  wiredAssetInfo({ data, error }) {
    if (data) {
      this.assetRecordTypeId = Object.values(data.recordTypeInfos).find(
        (item) => item.name === "MTC Report"
      ).recordTypeId;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.assetRecordTypeId = undefined;
    }
  }

  //Check if current user is admin.
  @wire(isAdminUser)
  isAdmin;

  /*** We cannot get picklist values for status as Intertek need to exclude certain pick list options. Leaving here for potential future use. ***/
  /*
  // Get picklist options for the Status filter
  @wire(getPicklistValues, {
    recordTypeId: "$assetRecordTypeId",
    fieldApiName: STATUS_FIELD
  })
  filterStatusOptions;
  */

  // Get picklist options for the Type filter
  @wire(getPicklistValues, {
    recordTypeId: "$assetRecordTypeId",
    fieldApiName: TYPE_FIELD
  })
  filterReportTypeOptions;

  // Use an imperative method to get report data and store in tableData variable
  // We cannot use @wire because we can't stop it watching selectedRowIds, which causes us problems
  getData() {
    this.tableData = { columns: [], rows: [] };
    this.tableData = { columns: [], rows: [] };
    getTableData({
      rowLimit: this.rowLimit,
      orderBy: this.orderBy,
      selectedRowIds: this.selectedRowIds,
      context: "",
      filterStatus: this.filterStatus,
      filterReportType: this.filterReportType,
      filterSearch: this.filterSearch,
      filterDateFrom: this.filterDateFrom,
      filterDateTo: this.filterDateTo,
      filterHiddenOnly: this.filterHiddenOnly,
      filterWithdrawnOnly: this.filterWithdrawnOnly,
      filterUnassignedOnly: this.filterUnassignedOnly
    })
      .then((response) => {
        if (response.table) {
          this.tableDataCache = response.table;
          this.allShown = response.table.rows.length == response.totalRows;
          this.totalRows = response.totalRows;

          this.redrawTable();

          if (response.table.rows.length > this.rowLimit) {
            this.rowLimit = response.table.rows.length;
          }
          this.error = undefined;
          this.isLoading = false;
        } else if (response && response.error) {
          this.error = response.error;
          this.tableData = { columns: [], rows: [] };
          this.isLoading = false;
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

  getUserData() {
    // Retrieving username via WireService requires User Management Settings changes.
    // Moved to Apex to retain preferred UM-Settings.
    getUserWithProfile({ userId: null })
      .then((response) => {
        this.adminOrCGA = response.Profile?.Name.includes("Admin");
        if (response.Hidden_Report_IDs_JSON__c != null) {
          let result = JSON.parse(response.Hidden_Report_IDs_JSON__c);
          this.hiddenReports = new Set([...result]);
        }
      })
      .catch((error) => {
        console.log("error", error);
      });
  }

  handleHiddenFilterChange(evt) {
    this[evt.detail.fieldId] = evt.detail.value;
    this.redrawTable();
  }

  handleFilterChange(evt) {
    // After a short delay, update the group name filter
    window.clearTimeout(this.filterTimeout);
    this.filterTimeout = setTimeout(
      function () {
        // make sure the filter input's fieldId attribute exactly matches the filter variable name up above ^^^
        this[evt.detail.fieldId] = evt.detail.value;
        this.isLoading = true;
        this.getData();
      }.bind(this),
      500
    );
  }

  handleViewMore() {
    this.rowLimit = this.rowLimit * 2;
    this.isLoading = true;
    this.getData();
  }

  handleOrderBy(evt) {
    // make sure we pass in orderBy AND tableData.data.columns. orderBy will contain the newly requested sort and tableData.data.tableCols will contain any previous sorts, allowing us to overlay the two
    this.orderBy = evt.detail;
    this.isLoading = true;
    this.getData();
  }

  handleSelectedRowsChange(evt) {
    this.selectedRowIds = evt.detail.selectedRowIds;
    this.selectedRowCount = this.selectedRowIds.length;
  }

  async handleConfirmHideUnhide() {
    this.isWorking = true;

    for (let r of this.selectedRowIds) {
      if (this.filterHiddenOnly) {
        this.hiddenReports.delete(r);
      } else {
        this.hiddenReports.add(r);
      }
    }

    this.redrawTable();

    let response = await hideReports({
      selectedReportIds: [...this.hiddenReports]
    });

    if ((response.status = "OK")) {
      this.handleCancelModal();
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: response.messages[0],
          variant: "Error"
        })
      );
    }
    this.isWorking = false;
  }

  redrawTable() {
    let tableData = { columns: this.tableDataCache.columns, rows: [] };
    for (let row of this.tableDataCache.rows) {
      if (this.hiddenReports.has(row.rowId)) {
        if (this.filterHiddenOnly) {
          tableData.rows.push(row);
        }
      } else if (!this.filterHiddenOnly) {
        tableData.rows.push(row);
      }
    }
    this.tableData = tableData;

    this.loadMoreMessage =
      "Showing " +
      tableData.rows.length +
      " of " +
      (this.filterHiddenOnly
        ? this.hiddenReports.size
        : this.totalRows - this.hiddenReports.size) +
      " results";
  }

  handleCancelModal() {
    this.showManageModal = this.showHideModal = false;
  }

  handleActionClick(evt) {
    // depending on the action, launch the appropriate modal
    switch (evt.detail.label) {
      case "Manage access":
        this.manageMode = "manage";
        this.showManageModal = true;
        break;
      case "Assign reports":
        this.manageMode = "assign";
        this.showManageModal = true;
        break;
      case "Retract reports":
        this.manageMode = "retract";
        this.showManageModal = true;
        break;
      case "Hide":
        this.showHideModal = true;
        break;
      case "Unhide":
        this.showHideModal = true;
        break;
    }
  }
  async handleBtnClick(evt) {
    let whatExport = "Reports";
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Downloading " + whatExport + "...",
        message: "",
        variant: "info"
      })
    );

    let response = await csvExport();

    var hiddenElement = document.createElement("a");
    hiddenElement.href =
      "data:text/csv;charset=utf-8," + encodeURIComponent(response);
    hiddenElement.target = "_blank";
    let time = new Date().getTime();
    hiddenElement.download = whatExport + "_" + time + ".csv";
    hiddenElement.click();
  }

  onCellClicked(event) {
    this.selectedRowId = event.detail.selectedRowId;
    this.isCellClicked = event.detail.isCellClicked;
  }

  onBackToReportList(event) {
    this.isCellClicked = event.detail.isBackToReportList;
  }

}