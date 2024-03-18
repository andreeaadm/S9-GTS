import { LightningElement, wire, api } from "lwc";
// import { NavigationMixin } from "lightning/navigation";
import buildTable from "@salesforce/apex/TC_SupplierFacilitiesController.buildTable";
import { label } from "c/labelService";

export default class TcSupplierFacilities extends LightningElement {
  @api recordId;

  tableData = { columns: [], rows: [] };
  rowLimit = 50;
  allShown = false;
  labels = label;
  noData;

  @wire(buildTable, { connectionId: "$recordId" })
  wiredFacilities(response) {
    if (response && response.data) {
      this.tableData = response.data.table;
      this.noData = response.data.totalRows === 0 ? true : false;
    } else {
      this.tableData = { columns: [], rows: [] };
      this.noData = true;
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