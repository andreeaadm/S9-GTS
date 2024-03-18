import { LightningElement, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getCases from "@salesforce/apex/CaseListController.getCases";
import { label } from "c/labelService";

export default class CaseList extends NavigationMixin(LightningElement) {
  @track isEmpty = true;
  @track tableData = { columns: [], rows: [] };
  @track rowLimit = 6;
  @track orderBy = "CaseNumber DESC";
  @track loadMoreMessage = "";
  @track allShown = true;
  @track isLoading = true;
  @track hasLoaded = false;
  labels = label;

  @wire(getCases, {
    rowLimit: "$rowLimit",
    orderBy: "$orderBy"
  })
  wiredCases(response) {
    if (response && response.data) {
      this.tableData = response.data.table;
      this.isEmpty =
        response.data.table.rows.length && response.data.table.rows.length > 0
          ? false
          : true;
      this.allShown =
        response.data.table.rows.length == response.data.totalRows;
      this.loadMoreMessage =
        this.labels.DATA_TABLE_RESULTS_COUNT_INFO_PREFIX +
        " " +
        response.data.table.rows.length +
        " " +
        this.labels.OF +
        " " +
        response.data.totalRows +
        " " +
        this.labels.DATA_TABLE_RESULTS_COUNT_INFO_SUFFIX;
      this.error = undefined;
      this.isLoading = false;
      this.hasLoaded = true;
    } else if (response && response.error) {
      this.error = response.error;
      this.tableData = { columns: [], rows: [] };
      this.isLoading = false;
      this.hasLoaded = true;
    }
  }

  handleViewMore() {
    this.rowLimit = this.rowLimit + 6;
    this.isLoading = true;
  }

  handleOrderBy(evt) {
    // make sure we pass in orderBy AND tableData.columns. orderBy will contain the newly requested sort and tableData.tableCols will contain any previous sorts, allowing us to overlay the two
    this.orderBy = evt.detail;
    this.isLoading = true;
  }

  navToCreateCase() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: "RaiseTicket__c"
      }
    });
  }
}