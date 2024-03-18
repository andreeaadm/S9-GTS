import { LightningElement, api, wire } from "lwc";
import { label } from "c/labelService";
import { refreshApex } from "@salesforce/apex";
import getBulletins from "@salesforce/apex/BulletinListController.getBulletins";

export default class BulletinList extends LightningElement {
  @api bulletinType;
  isEmpty = true;

  tableData = {
    columns: [],
    rows: []
  };

  rowLimit = 50;
  allShown = true;
  isLoading = true;
  labels = label;
  wiredData;

  renderedCallback() {
    if (this.bulletinType === "Sent") {
      refreshApex(this.wiredData);
    }
  }

  get bulletinTitle() {
    switch (this.bulletinType) {
      case "Pinned":
        return this.labels.PINNED_BULLETINS;
      case "Unpinned":
        return this.labels.UNPINNED_BULLETINS;
      case "Sent":
        return this.labels.SENT_BULLETINS;
      default:
        return null;
    }
  }

  get emptyAndPinned() {
    return this.isEmpty && this.bulletinType === "Pinned";
  }

  @wire(getBulletins, {
    rowLimit: "$rowLimit",
    context: "$bulletinType"
  })
  wiredBulletins(response) {
    this.wiredData = response;
    if (response && response.data) {
      this.tableData = response.data.table;
      this.isEmpty = response.data.totalRows === 0;
      this.allShown =
        this.isEmpty || this.bulletinType === "Pinned"
          ? true
          : response.data.totalRows < this.rowLimit;
      this.isLoading = false;
    } else if (response && response.error) {
      this.tableData = { columns: [], rows: [] };
      this.isLoading = false;
    }
  }

  handleViewMore() {
    this.rowLimit = this.rowLimit + 50;
    this.isLoading = true;
  }
}