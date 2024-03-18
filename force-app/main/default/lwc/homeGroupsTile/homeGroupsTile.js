import { LightningElement, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getTableData from "@salesforce/apex/GroupListController.getTableData";

export default class HomeGroupsTile extends NavigationMixin(LightningElement) {
  @track isEmpty = true;
  @track showModal = false;
  @track tableData = { columns: [], rows: [] };
  @track isLoading = true;
  @track hasLoaded = false;

  connectedCallback() {
    this.getData();
  }

  getData() {
    getTableData({
      rowLimit: 6,
      orderBy: "CreatedDate DESC",
      selectedRowIds: [],
      context: "home"
    })
      .then((response) => {
        if (response.table) {
          this.tableData = response.table;
          this.isEmpty =
            response.table.rows.length && response.table.rows.length > 0
              ? false
              : true;
          this.error = undefined;
          this.isLoading = false;
          this.hasLoaded = true;
        } else if (error) {
          this.error = error;
          this.tableData = { columns: [], rows: [] };
          this.isEmpty = true;
          this.isLoading = false;
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

  navToGroupList() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: "Groups__c"
      }
    });
  }
}