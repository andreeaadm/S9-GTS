import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getTableData from "@salesforce/apex/ProjectListController.getTableData";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { label } from "c/labelService";
import PROJECT_OBJECT from "@salesforce/schema/MTC_Project__c";
import STATUS_FIELD from "@salesforce/schema/MTC_Project__c.Status__c";
import csvExport from "@salesforce/apex/ProjectListController.exportAsCSV";

export default class ProjectList extends LightningElement {
  /*** Vars common to all list pages ***/
  @track labels = label;
  @api scrollAfterXPixels;
  @track tableData = { columns: [], rows: [] };
  @track tableHeaderActionsVisible = false;
  @track rowLimit = 6;
  @track orderBy = "Name DESC";
  @track isLoading = true;
  @track loadMoreMessage;
  @track allShown;
  filterTimeout;
  error;

  /*** Vars specific to this implementation of objectHome ***/
  @track filterStatus = "";
  @track filterSearch = "";
  @track filterDateFrom = "";
  @track filterDateTo = "";
  @track projectRecordTypeId;

  @api showExportButton;
  get conditionalExport() {
    return this.showExportButton ? this.labels.EXPORT : null;
  }
  // Get the correct record type Id for our assets
  @wire(getObjectInfo, { objectApiName: PROJECT_OBJECT })
  wiredProjectInfo({ data, error }) {
    if (data) {
      this.projectRecordTypeId = Object.values(data.recordTypeInfos).find(
        (item) => item.name === "Master"
      ).recordTypeId;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.assetRecordTypeId = undefined;
    }
  }

  // Get picklist options for the Status filter
  @wire(getPicklistValues, {
    recordTypeId: "$projectRecordTypeId",
    fieldApiName: STATUS_FIELD
  })
  filterStatusOptions;

  /*** While we've moved to imperative apex calls in other list pages,
   * projectList can continue using a wire as the table doesn't feature selectedRowIds
   ***/
  // Use @wire to get project data and store in tableData variable
  // should contain columns and rows lists
  @wire(getTableData, {
    rowLimit: "$rowLimit",
    orderBy: "$orderBy",
    context: "",
    filterStatus: "$filterStatus",
    filterSearch: "$filterSearch",
    filterDateFrom: "$filterDateFrom",
    filterDateTo: "$filterDateTo"
  })
  wiredTableData(response) {
    if (response && response.data) {
      this.tableData = response.data.table;
      this.allShown =
        response.data.table.rows.length == response.data.totalRows;
      this.loadMoreMessage =
        "Showing " +
        response.data.table.rows.length +
        " of " +
        response.data.totalRows +
        " results";
      this.error = undefined;
      this.isLoading = false;
    } else if (response && response.error) {
      this.error = response.error;
      this.tableData = { columns: [], rows: [] };
      this.isLoading = false;
    }
  }

  handleFilterChange(evt) {
    // After a short delay, update the group name filter which should trigger the @wire to re-query for table data
    window.clearTimeout(this.filterTimeout);
    this.filterTimeout = setTimeout(
      function () {
        // make sure the filter input's fieldId attribute exactly matches the filter variable name up above ^^^
        this[evt.detail.fieldId] = evt.detail.value;
        this.isLoading = true;
      }.bind(this),
      500
    );
  }

  handleViewMore() {
    // update this.rowLimit, which should be watched by the @wire service and cause the table data to refresh
    this.rowLimit = this.rowLimit + 6;
    this.isLoading = true;
  }

  handleOrderBy(evt) {
    // update orderBy, which should trigger @wire to refresh table data
    // make sure we pass in orderBy AND tableData.data.columns. orderBy will contain the newly requested sort and tableData.data.tableCols will contain any previous sorts, allowing us to overlay the two
    this.orderBy = evt.detail;
    this.isLoading = true;
  }

  async handleBtnClick(evt) {
    let whatExport = "Projects";
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
}