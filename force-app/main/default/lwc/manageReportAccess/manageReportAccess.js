import { LightningElement, track, api, wire } from "lwc";
import getTableData from "@salesforce/apex/ManageReportController.getTableData";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import NAME_FIELD from "@salesforce/schema/Asset.Name";
import TYPE_FIELD from "@salesforce/schema/Asset.Type__c";
import REFERENCE_FIELD from "@salesforce/schema/Asset.Client_Reference__c";
import STATUS_FIELD from "@salesforce/schema/Asset.MTC_Status__c";
import manage from "@salesforce/apex/ManageReportController.manage";
import assign from "@salesforce/apex/ManageReportController.assign";
import retract from "@salesforce/apex/ManageReportController.retract";
import { label } from "c/labelService";

export default class ManageReportAccess extends LightningElement {
  @api mode = "manage"; // manage || assign || retract
  @api selectedRowIds = [];
  @track tableData = { columns: [], rows: [] };
  @track loadMoreMessage = "";
  @track allShown = true;
  @track isLoading = true;
  @track rowLimit = 6;
  @track orderBy = "Group_Name_FF__c ASC";
  @track selectedGroupIds = [];
  @track reportDetailId;
  @track filterSearch = "";
  @track filterStatus = "";
  filterTimeout;
  labels = label;

  filterStatusOptions = [
    {
      value: "Active",
      label: this.labels.ACTIVE
    },
    {
      value: "Inactive",
      label: this.labels.INACTIVE
    }
  ];

  get title() {
    return this.mode == "manage"
      ? "Manage access"
      : this.mode == "assign"
      ? "Assign access"
      : "Retract access";
  }

  get suffix() {
    return this.mode == "manage"
      ? "for"
      : this.mode == "assign"
      ? "to"
      : "from";
  }

  get selectedRowCount() {
    return this.selectedRowIds ? this.selectedRowIds.length : 0;
  }

  get buttonLabel(){
    return this.mode === 'retract' ? 'RETRACT' : 'ASSIGN';
  }

  get showGroupAssignmentNotice(){
    return this.mode !== 'retract';
  }

  connectedCallback() {
    if (this.selectedRowIds && this.selectedRowIds.length == 1) {
      this.reportDetailId = this.selectedRowIds[0];
    } else {
      this.reportDetailId = undefined;
    }
    this.getData();
  }

  @wire(getRecord, {
    recordId: "$reportDetailId",
    fields: [NAME_FIELD, TYPE_FIELD, REFERENCE_FIELD, STATUS_FIELD]
  })
  wiredReport;

  get name() {
    return getFieldValue(this.wiredReport.data, NAME_FIELD);
  }
  get type() {
    return getFieldValue(this.wiredReport.data, TYPE_FIELD);
  }
  get ref() {
    return getFieldValue(this.wiredReport.data, REFERENCE_FIELD);
  }
  get status() {
    return getFieldValue(this.wiredReport.data, STATUS_FIELD);
  }

  getData() {
    let filterStatus = this.filterStatus;
    if(this.filterStatus == "" || this.filterStatus == "Active"){
      filterStatus = "False";
    }else if(this.filterStatus == "Inactive"){
      filterStatus = "True";
    }

    this.tableData = { columns: [], rows: [] };
    getTableData({
      rowLimit: this.rowLimit,
      filterSearch: this.filterSearch,
      filterStatus: filterStatus,
      orderBy: this.orderBy,
      selectedRowIds: this.selectedRowIds,
      mode: this.mode
    })
      .then((response) => {
        if (response.table) {
          this.tableData = response.table;
          this.allShown =
            response.table.rows &&
            response.table.rows.length &&
            response.table.rows.length == response.totalRows;
          this.loadMoreMessage =
            "Showing " +
            response.table.rows.length +
            " of " +
            response.totalRows +
            " results";
          let tempSelectedGroupIds = [];
          for (let row of response.table.rows) {
            if (row.rowCells[0].value == "true") {
              tempSelectedGroupIds.push(row.rowId);
            }
          }
          this.selectedGroupIds = tempSelectedGroupIds;
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

  handleFilterChange(evt) {
    if(evt.detail.value == 'Active' || evt.detail.value == 'Inactive'){
      this.filterStatus = evt.detail.value;
    }

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
    // update this.rowLimit, which should be watched by the @wire service and cause the table data to refresh
    this.rowLimit = this.rowLimit + 6;
    this.isLoading = true;
    this.getData();
  }

  handleCheckboxChange(evt) {
    let tempSelectedGroupIds = JSON.parse(
      JSON.stringify(this.selectedGroupIds)
    );
    if (evt.detail.checked) {
      tempSelectedGroupIds.push(evt.detail.rowId);
      this.selectedGroupIds = tempSelectedGroupIds;
    } else {
      tempSelectedGroupIds = tempSelectedGroupIds.filter(function (
        value,
        index,
        arr
      ) {
        return value !== evt.detail.rowId;
      });
      this.selectedGroupIds = tempSelectedGroupIds;
    }
  }

  handleCancel() {
    this.dispatchEvent(new CustomEvent("close"));
  }

  async handleConfirm() {
    this.isLoading = true;
    // Call apex to either manage, assign, or retract reports to/from groups
    let response;
    switch (this.mode) {
      case "manage":
        response = await manage({
          selectedReportIds: this.selectedRowIds,
          selectedGroupIds: this.selectedGroupIds
        });
        break;
      case "assign":
        response = await assign({
          selectedReportIds: this.selectedRowIds,
          selectedGroupIds: this.selectedGroupIds
        });
        break;
      case "retract":
        response = await retract({
          selectedReportIds: this.selectedRowIds,
          selectedGroupIds: this.selectedGroupIds
        });
        break;
    }
    // Display toast
    if (response.status == "OK") {
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
    this.isLoading = false;
    // We need to freshen up the data in the table so that when we next open it, the correct checkboxes are selected
    this.tableData = { columns: [], rows: [] };
    // Tell parent to hide me
    this.dispatchEvent(new CustomEvent("close"));
  }

  handleSortClick(evt) {
    // update orderBy and then getData
    this.orderBy =
      evt.detail.colId +
      " " +
      (evt.detail.currentSortOrder == "DESC" ? "ASC" : "DESC");
    this.getData();
  }
}