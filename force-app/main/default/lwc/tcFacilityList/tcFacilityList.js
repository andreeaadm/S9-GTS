import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getFacilities from "@salesforce/apex/FacilityListController.getFacilitiesListTableData";
import { label } from "c/labelService";

export default class TcFacilityList extends NavigationMixin(LightningElement) {
  isLoading;
  tableData = { columns: [], rows: [] };
  rowLimit = 50;
  allShown = false;
  labels = label;
  noData;

  @wire(getFacilities)
  wiredFacilities(response) {
    if (response && response.data) {
      this.tableData = response.data.table;
      this.isLoading = false;
      this.noData = response.data.totalRows === 0 ? true : false;
    } else {
      this.tableData = { columns: [], rows: [] };
      this.noData = true;
      this.isLoading = false;
    }
  }

  get currentRows() {
    this.allShown = this.tableData.rows.length <= this.rowLimit;
    return this.tableData.rows.slice(0, this.rowLimit);
  }

  handleViewMore() {
    this.rowLimit += 50;
  }
}