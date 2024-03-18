import { LightningElement, wire, api } from "lwc";

import iCarePortalTableMC from "@salesforce/messageChannel/iCarePortalTablesMessageChannel__c";
import { subscribe, MessageContext } from "lightning/messageService";

import DATE_TIME_FIELD from "@salesforce/schema/iCare_Job__c.iCare_Date_Time__c";

//import FORM_FACTOR from '@salesforce/client/formFactor';
import LOCALE from "@salesforce/i18n/locale";

import CUSTOM_LABEL from "@salesforce/label/c.iCare_Portal_Custom";
import LAST_24_HOURS_LABEL from "@salesforce/label/c.iCare_Portal_Last_24_hours";
import LAST_7_DAYS_LABEL from "@salesforce/label/c.iCare_Portal_Last_7_days";
import LAST_15_DAYS_LABEL from "@salesforce/label/c.iCare_Portal_Last_15_days";
import LAST_30_DAYS_LABEL from "@salesforce/label/c.iCare_Portal_Last_30_days";
import VIEW_ALL_LABEL from "@salesforce/label/c.iCare_Portal_View_all";
import ALL_LABEL from "@salesforce/label/c.iCare_Portal_All";
import SAMPLE_RECEIVED_LABEL from "@salesforce/label/c.iCare_Portal_Sample_Received";
import COMPLETED_LABEL from "@salesforce/label/c.iCare_Portal_Completed";
import IN_PROGRESS_LABEL from "@salesforce/label/c.iCare_Portal_In_Progress";
import PENDING_LABEL from "@salesforce/label/c.iCare_Portal_Pending";
import CANCELLED_LABEL from "@salesforce/label/c.iCare_Portal_Cancelled";
import ENTER_LABEL from "@salesforce/label/c.iCare_Portal_Enter_JobId_or_Key";
import GTS_ENTER_LABEL from "@salesforce/label/c.GTS_Portal_Enter_RFINumber";
import START_DATE_LABEL from "@salesforce/label/c.iCare_Portal_Start_Date";
import END_DATE_LABEL from "@salesforce/label/c.iCare_Portal_End_Date";
import COC_LABEL from "@salesforce/label/c.GTS_COC_Label";
import TRADEABLE_LABEL from "@salesforce/label/c.GTS_Tradeable_Label";
import REG_LIC_LABEL from "@salesforce/label/c.GTS_RegLic_Label";
import CONTAINS_SHIPMENT_LABEL from "@salesforce/label/c.GTS_Contains_Shipment";
import STATUS_LABEL from "@salesforce/label/c.GTS_Status";

import getTabs from "@salesforce/apex/iCare_TrackJobsController.getTabData";

import { getObjectInfo } from "lightning/uiObjectInfoApi";

import JOB_OBJECT from "@salesforce/schema/iCare_Job__c";

import JOB_STATUS_FIELD from "@salesforce/schema/iCare_Job__c.iCare_Job_Status__c";
import { getPicklistValues } from "lightning/uiObjectInfoApi";

const today = new Date();

export default class ICareTrackJobsContainer extends LightningElement {
  label = {
    ALL_LABEL,
    SAMPLE_RECEIVED_LABEL,
    COMPLETED_LABEL,
    IN_PROGRESS_LABEL,
    PENDING_LABEL,
    CANCELLED_LABEL,
    ENTER_LABEL,
    START_DATE_LABEL,
    END_DATE_LABEL,
    COC_LABEL,
    TRADEABLE_LABEL,
    REG_LIC_LABEL,
    CONTAINS_SHIPMENT_LABEL,
    STATUS_LABEL,
    GTS_ENTER_LABEL
  };

  tabLabels;

  columns;
  @api tableName;
  @api showBuyerFilter;

  datesPicklistValue = "30";
  datesPicklistLabel = "";
  iniDate = new Date();
  statusFilter;

  difDays = 30;
  previousDateChoice = 30; //Should be same as difDays

  showDates = false;
  startDate;
  endDate;

  availableJobs; //Records to show
  //searchBoxRecords;
  goupJobs;
  chartLabels = [];
  chartPercentages = [];

  error;

  searchKey;

  sortFieldName = DATE_TIME_FIELD.fieldApiName;
  sortDirection = "desc";

  @api isReportToBeShown = false;
  buyerPicklistValue = "All";
  buyerOptions = [];

  recordTypeId;
  recordTypeInfos;
  statusOptions = [];
  status;
  isChecked = false;
  isCOC = true;
  sectionTitle = this.label.COC_LABEL;
  gtsTableName = "GTS Track Jobs CoC";
  isGTSTrackJobs = false;

  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    /*
        if (FORM_FACTOR === 'Small') {
            this.columns = columnsM;
        }
        */
    if (this.tableName === "GTS Track Jobs") {
      this.isGTSTrackJobs = true;
    } else {
      this.isGTSTrackJobs = false;
    }
    this.subscribeToMessageChannel();
    this.loadTabs();
  }

  get enterLable(){
    return (this.isGTSTrackJobs) ? this.label.GTS_ENTER_LABEL : this.label.ENTER_LABEL;
  }

  get options() {
    return [
      { label: CUSTOM_LABEL, value: "custom" },
      { label: LAST_24_HOURS_LABEL, value: "1" },
      { label: LAST_7_DAYS_LABEL, value: "7" },
      { label: LAST_15_DAYS_LABEL, value: "15" },
      { label: LAST_30_DAYS_LABEL, value: "30" },
      { label: VIEW_ALL_LABEL, value: "0" }
    ];
  }

  @wire(getObjectInfo, { objectApiName: JOB_OBJECT })
  objectInfoWire({ error, data }) {
    if (data) {
      this.recordTypeInfos = data.recordTypeInfos;
    } else if (error) {
      console.error("Error getting object info", error);
    }
  }

  recordTypeByName(name) {
    return Object.keys(this.recordTypeInfos).find(
      (rti) => this.recordTypeInfos[rti].name === name
    );
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: JOB_STATUS_FIELD
  })
  getPicklistValuesForField({ data, error }) {
    if (error) {
      console.error(error);
    } else if (data) {
      console.log("data : ", data);
      this.statusOptions = data.values.map((item) => ({
        label: item.label,
        value: item.value
      }));
      this.statusOptions.push({ label: "All", value: "All" });
    }
  }

  loadTabs() {
    getTabs({ tableName: this.tableName }).then((result) => {
      this.tabLabels = result.lstContainerTabs;
    });
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

  /**
        Method to setup the Tab (Status) filter
    */
  handleTabChange(event) {
    console.log("Handling tab change");

    if (this.tableName === "GTS Track Jobs") {
      if (event.target.value === this.label.COC_LABEL) {
        this.recordTypeId = this.recordTypeByName("Certificate of Conformity");
        this.isCOC = true;
        this.sectionTitle = this.label.COC_LABEL;
        this.gtsTableName = "GTS Track Jobs CoC";
      } else if (event.target.value === this.label.TRADEABLE_LABEL) {
        this.recordTypeId = this.recordTypeByName("Commercial Service");
        this.isCOC = false;
        this.sectionTitle = this.label.TRADEABLE_LABEL;
        this.gtsTableName = "GTS Track Jobs Tradeable";
      } else if (event.target.value === this.label.REG_LIC_LABEL) {
        this.recordTypeId = this.recordTypeByName(
          "Registration / License / Product Certificate"
        );
        this.isCOC = false;
        this.sectionTitle = this.label.REG_LIC_LABEL;
        this.gtsTableName = "GTS Track Jobs Registration/Licence";
      }

      this.template
        .querySelector("c-i-care-track-jobs-table")
        .handleGtsTabChanges(this.gtsTableName, this.recordTypeId);
    } else {
      this.statusFilter = event.target.value;

      console.log("status value: " + event.target.value);
      console.log(this.statusFilter);

      this.template
        .querySelector("c-i-care-track-jobs-table")
        .handleTabChanges(this.statusFilter);
    }
  }

  handleStatusChange(event) {
    console.log("Handling tab change");

    this.status = event.target.value;

    console.log("status value: " + event.target.value);

    this.template
      .querySelector("c-i-care-track-jobs-table")
      .handleStatusChanges(this.status);

    if (this.isChecked) {
      this.isChecked = false;
    }
  }

  handleCheckboxChange(event) {
    this.isChecked = event.target.checked;
    this.template
      .querySelector("c-i-care-track-jobs-table")
      .handleShipmentCheckboxChange(this.isChecked);
  }

  /**
        Method to apply dates filter
    */
  handleDatesChange(event) {
    this.handleResetBuyer();
    //Dates filter
    this.datesPicklistValue = event.detail.value;
    this.previousDateChoice = this.datesPicklistValue; //To control is calls back

    if (event.detail.value === "custom") {
      //Show dates fields and hide dates labels
      this.difDays = 0;
      this.showDates = true;
    } else {
      this.showDates = false;
      this.startDate = undefined;
      this.endDate = undefined;
      this.difDays = event.detail.value;

      this.handleDatesLabels();
      this.template
        .querySelector("c-i-care-track-jobs-table")
        .handleDateChange(this.startDate, this.endDate, this.difDays);

      //this.loadJobs();
    }

    if (event.detail.value === "custom" || event.detail.value === "0") {
      this.datesPicklistLabel = "";
    }
  }

  handleStartDateChange(event) {
    if (event.target.value !== undefined) {
      this.startDate = event.target.value;
      if (this.endDate !== undefined) {
        //Only made the query when both dates are filled
        //this.loadJobs();
        this.template
          .querySelector("c-i-care-track-jobs-table")
          .handleDateChange(this.startDate, this.endDate, this.difDays);
      }
    }
  }

  handleResetBuyer() {
    //Reset search keyboard control
    this.buyerPicklistValue = "All";
  }

  handleBuyerChange(event) {
    this.buyerPicklistValue = event.detail.value;
    this.template
      .querySelector("c-i-care-track-jobs-table")
      .handleBuyerChange(this.buyerPicklistValue);
  }

  handleEndDateChange(event) {
    if (event.target.value !== undefined) {
      let tempEndDate = new Date(event.target.value);
      tempEndDate.setHours(23, 59, 59);
      this.endDate = tempEndDate;
      if (this.startDate !== undefined) {
        //this.loadJobs();
        this.template
          .querySelector("c-i-care-track-jobs-table")
          .handleDateChange(this.startDate, this.endDate, this.difDays);
      }
    }
  }

  /**
        Method to apply the Search keyword filter
    */
  handleSearchBoxChange(event) {
    //Search keyword,  apply search keyword filter
    this.searchKey = event.target.value;
    this.template
      .querySelector("c-i-care-track-jobs-table")
      .handleSearchBoxChange(this.searchKey);
  }

  handleResetDates() {
    //Reset dates picklist
    this.datesPicklistValue = "30";
    this.difDays = 30;
    this.startDate = undefined;
    this.endDate = undefined;
    this.showDates = false;
    this.handleDatesLabels();
  }

  handleResetSearchBox() {
    //Reset search keyboard control
    this.searchKey = undefined;
  }

  get buyerOptionsValues() {
    return this.buyerOptions;
  }

  subscribeToMessageChannel() {
    this.subscription = subscribe(
      this.messageContext,
      iCarePortalTableMC,
      (message) => {
        this.buyerOptions = JSON.parse(message.buyerFilterValues);
      }
    );
  }
}