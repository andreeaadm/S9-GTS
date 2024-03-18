import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import getTableData from "@salesforce/apex/UserListController.getTableData";
import countUnassigned from "@salesforce/apex/UserListController.countOfUnassigned";

export default class HomeUsersTile extends NavigationMixin(LightningElement) {
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
      orderBy: "LastLoginDate DESC",
      selectedRowIds: [],
      context: "home",
      groupId: this.recordId
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

  navToUnassignedList() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: "Users__c"
      },
      state: {
        unassigned: "true"
      }
    });
  }
  navToUsersList() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: "Users__c"
      }
    });
  }
}