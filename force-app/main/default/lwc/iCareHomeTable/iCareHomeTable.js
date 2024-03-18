import { LightningElement, wire, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";

import RECENT_REPORTS_LABEL from "@salesforce/label/c.iCare_Recent_Reports_Title";
import TRACK_JOBS_LABEL from "@salesforce/label/c.iCare_Portal_Track_Jobs";

import RECENT_UPDATED_JOBS from "@salesforce/label/c.GTS_RecentUpdatedJobs_Label";
import RECENT_COMPLETED_JOBS from "@salesforce/label/c.GTS_RecentCompletedJobs_Label";

export default class ICareHomeTable extends NavigationMixin(LightningElement) {
  @api isReportToBeShown;
  @api numberOfRecords;
  @api pagination = false;
  @api tableName = "Track Jobs";

  @track v_Offset = 0;
  @track v_TotalRecords;
  @track page_size = 5;

  tableHeaderLabel;
  availableJobs;
  error;
  //columns = colsTrackJobs;

  sortFieldName;
  sortDirection;
  connectedCallback() {
    this.generateHeader();
  }

  generateHeader() {
    if (this.tableName === "View Reports") {
      this.tableHeaderLabel = RECENT_REPORTS_LABEL;
    } else if (this.tableName === "GTS Updated Jobs") {
      this.tableHeaderLabel = RECENT_UPDATED_JOBS;
    } else if (this.tableName === "GTS Completed Jobs") {
      this.tableHeaderLabel = RECENT_COMPLETED_JOBS;
    } else {
      this.tableHeaderLabel = TRACK_JOBS_LABEL;
    }
  }
}