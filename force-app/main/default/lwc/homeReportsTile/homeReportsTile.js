import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import getTableData from "@salesforce/apex/ReportListController.getTableData";
import countUnassigned from "@salesforce/apex/ReportListController.countOfUnassigned";

export default class HomeReportsTile extends NavigationMixin(LightningElement) {
  @api recordId;
  @track isEmpty = true;
  @track showModal = false;
  @track tableData = { columns: [], rows: [] };
  @track isLoading = true;
  @track hasLoaded = false;
  get labelForUnassignedButton() {
    if (this.wiredCountOfUnassigned && this.wiredCountOfUnassigned.data > 0) {
      return this.wiredCountOfUnassigned.data + " Unassigned";
    }
    return null;
  }

  @wire(countUnassigned)
  wiredCountOfUnassigned;

  connectedCallback() {
    //force clear cache
    refreshApex(this.wiredCountOfUnassigned);
    this.getData();
  }

  getData() {
    getTableData({
      rowLimit: 6,
      orderBy: "Date_Issued__c DESC",
      selectedRowIds: [],
      context: "home",
      filterStatus: null,
      filterReportType: null,
      filterSearch: null,
      filterDateFrom: null,
      filterDateTo: null,
      filterHiddenOnly: null,
      filterWithdrawnOnly: null,
      filterUnassignedOnly: false,
      groupId: this.recordId
    })
      .then((response) => {
        if (response && response.table) {
          this.tableData = response.table;
          this.isEmpty =
            response.table.rows.length && response.table.rows.length > 0
              ? false
              : true;
          this.error = undefined;
        }
        this.isLoading = false;
        this.hasLoaded = true;
      })
      .catch((error) => {
        if (error) {
          this.error = error;
          this.tableData = { columns: [], rows: [] };
          this.isLoading = false;
          this.hasLoaded = true;
        }
      });
  }

  navToUnassignedList() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: "Reports__c"
      },
      state: {
        unassigned: "true"
      }
    });
  }
  navToReportList() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: "Reports__c"
      }
    });
  }
}