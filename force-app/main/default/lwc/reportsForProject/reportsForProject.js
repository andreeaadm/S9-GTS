import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import NAME_FIELD from "@salesforce/schema/Asset.Name";
import ID_FIELD from "@salesforce/schema/Asset.Id";

import getTableData from "@salesforce/apex/ProjectListController.getRelatedReportsAsTableData";

const fields = [ID_FIELD, NAME_FIELD];

export default class ReportsForProject extends LightningElement {
  @api recordId;
  @api additionalClasses = "greytile";
  @track hasLoaded = false;
  @track isLoading = false;
  @track isEmpty = true;

  @track tableData = { columns: [], rows: [] };

  connectedCallback() {
    this.getData();
  }

  getData() {
    this.isLoading = true;
    getTableData({
      projectId: this.recordId
    })
      .then((response) => {
        if (response.table) {
          this.tableData = response.table;
          this.error = undefined;
          this.isLoading = false;
          this.hasLoaded = true;
          this.isEmpty = !(
            response.table.rows.length && response.table.rows.length > 0
          );
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

  handleActionClick(evt) {
    console.log("event");
  }
}