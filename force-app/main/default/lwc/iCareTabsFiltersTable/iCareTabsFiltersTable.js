import { LightningElement, wire, api } from "lwc";

import iCarePortalJobsCharMC from "@salesforce/messageChannel/iCarePortalJobsChart__c";
import { publish, subscribe, MessageContext } from "lightning/messageService";

import BUYER_PROGRAM_FIELD from "@salesforce/schema/iCare_Job__c.iCare_Buyer_Program_formula__c";
import DATE_TIME_FIELD from "@salesforce/schema/iCare_Job__c.iCare_Date_Time__c";

import FORM_FACTOR from "@salesforce/client/formFactor";
import LOCALE from "@salesforce/i18n/locale";

import JOB_ID_LABEL from "@salesforce/label/c.iCare_Portal_Job_Id";
import BUYER_PROGRAM_LABEL from "@salesforce/label/c.iCare_Portal_Buyer_Program";
import STATUS_LABEL from "@salesforce/label/c.iCare_Portal_Status";

import ALL_LABEL from "@salesforce/label/c.iCare_Portal_All";
import SAMPLE_RECEIVED_LABEL from "@salesforce/label/c.iCare_Portal_Sample_Received";
import COMPLETED_LABEL from "@salesforce/label/c.iCare_Portal_Completed";
import IN_PROGRESS_LABEL from "@salesforce/label/c.iCare_Portal_In_Progress";
import PENDING_LABEL from "@salesforce/label/c.iCare_Portal_Pending";
import CANCELLED_LABEL from "@salesforce/label/c.iCare_Portal_Cancelled";
import TOTAL_NUMBER_LABEL from "@salesforce/label/c.iCare_Portal_TotalNumber";
import ENTER_LABEL from "@salesforce/label/c.iCare_Portal_Enter_JobId_or_Key";
import START_DATE_LABEL from "@salesforce/label/c.iCare_Portal_Start_Date";
import END_DATE_LABEL from "@salesforce/label/c.iCare_Portal_End_Date";

import iCarePortalTableMC from "@salesforce/messageChannel/iCarePortalTablesMessageChannel__c";

const today = new Date();

const columnsM = [
  {
    label: JOB_ID_LABEL,
    fieldName: "LinkUrl",
    type: "url",
    typeAttributes: { label: { fieldName: "LinkLabel" }, target: "_self" },
    hideDefaultActions: "false"
  },
  {
    label: BUYER_PROGRAM_LABEL,
    fieldName: BUYER_PROGRAM_FIELD.fieldApiName,
    hideDefaultActions: "false"
  },
  {
    label: STATUS_LABEL,
    fieldName: "jobStatusLabel",
    hideDefaultActions: "false"
  }
];

export default class ICareTabsFiltersTable extends LightningElement {
  label = {
    ALL_LABEL,
    SAMPLE_RECEIVED_LABEL,
    COMPLETED_LABEL,
    IN_PROGRESS_LABEL,
    PENDING_LABEL,
    CANCELLED_LABEL,
    ENTER_LABEL,
    START_DATE_LABEL,
    END_DATE_LABEL
  };

  //columns = columns;

  @api tableName = "Track Jobs";

  datesPicklistValue = "30";
  datesPicklistLabel = "";
  iniDate = new Date();
  statusFilter;

  difDays = 30;
  previousDateChoice = 30; //Should be same as difDays

  showDates = false;
  startDate;
  endDate;
  totalRecsLabel;

  initialApexJobs;
  availableJobs; //Records to show
  searchBoxRecords;
  goupJobs;
  chartLabels = [];
  chartPercentages = [];

  error;

  searchKey;

  sortFieldName = DATE_TIME_FIELD.fieldApiName;
  sortDirection = "desc";

  isReportToBeShown = false;
  gtsPage = false;

  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    if (FORM_FACTOR === "Small") {
      this.columns = columnsM;
    }

    if (this.tableName === "GTS Track Jobs") {
      this.gtsPage = true;
    } else {
      this.gtsPage = false;
    }

    this.subscribeToMessageChannel();
  }

  /**
        Sync Chart component with reports data - via message
    */
  sendMessage() {
    const payload = {
      chartLabels: this.chartLabels,
      chartPercentages: this.chartPercentages,
      chartJobsData: Array.from(this.goupJobs.values()),
      chartTotalRecs: this.totalRecsLabel,
      gtsPage: this.gtsPage
    };

    try {
      publish(this.messageContext, iCarePortalJobsCharMC, payload);
    } catch (error) {
      console.log("Error: " + error);
    }
  }

  /**
        Method to get dates labels
    */
  handleDatesLabels() {
    this.iniDate = new Date();
    this.iniDate.setDate(today.getDate() - this.difDays); //Set initial date to dates rank

    this.datesPicklistLabel =
      Intl.DateTimeFormat(LOCALE).format(this.iniDate) +
      " to " +
      Intl.DateTimeFormat(LOCALE).format(today);
  }

  calculateTotalRecords() {
    if (this.availableJobs) {
      this.totalRecsLabel =
        TOTAL_NUMBER_LABEL + " " + this.availableJobs.length;
    } else {
      this.totalRecsLabel = TOTAL_NUMBER_LABEL + " 0";
    }
  }

  /**
        Method to apply the Tab (Status) filter
    */
  calculateChartData() {
    this.handleResetChartData();
    let goupRecords = new Map();

    if (this.availableJobs !== undefined) {
      //Get records grouped
      for (let record of this.availableJobs) {
        let jobStatus;

        if (this.tableName === "GTS Track Jobs") {
          jobStatus =
            record.iCare_Job_Status__c === undefined
              ? "undefined"
              : record.iCare_Job_Status__c;
        } else {
          if (this.statusFilter === "All") {
            jobStatus =
              record.iCare_Job_Status_Portal__c === undefined
                ? "undefined"
                : record.iCare_Job_Status_Portal__c;
          } else {
            jobStatus =
              record.iCare_Buyer_Program_formula__c === undefined
                ? "undefined"
                : record.iCare_Buyer_Program_formula__c;
          }
        }

        if (!goupRecords.has(jobStatus)) {
          goupRecords.set(jobStatus, 1);
        } else {
          goupRecords.set(jobStatus, goupRecords.get(jobStatus) + 1);
        }
      }

      //Get % per each element
      for (let key of goupRecords.keys()) {
        let ratio =
          this.availableJobs.length > 0
            ? goupRecords.get(key) / this.availableJobs.length
            : 1;
        this.chartLabels.push(key);
        this.chartPercentages.push(Math.floor(ratio * 100) + "%");
      }
    }
    this.goupJobs = goupRecords;
  }

  handleResetChartData() {
    //Reset chart Data Values
    this.goupJobs = undefined;
    this.chartLabels = [];
    this.chartPercentages = [];
  }

  handleResetSort() {
    //Reset sorting values
    this.sortFieldName = DATE_TIME_FIELD.fieldApiName;
    this.sortDirection = "desc";
  }

  handleAvailableJobs() {
    this.calculateTotalRecords();
    this.calculateChartData();
    this.sendMessage();
  }

  subscribeToMessageChannel() {
    this.subscription = subscribe(
      this.messageContext,
      iCarePortalTableMC,
      (message) => {
        this.availableJobs = JSON.parse(message.availableJobs);
        this.statusFilter = JSON.parse(message.statusFilter);

        this.handleAvailableJobs();
      }
    );
  }
}