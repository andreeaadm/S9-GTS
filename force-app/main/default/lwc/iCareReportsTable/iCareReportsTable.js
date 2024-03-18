import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import ALL_LABEL from "@salesforce/label/c.iCare_Portal_All";
import PASS_LABEL from "@salesforce/label/c.iCare_Portal_Pass";
import FAIL_LABEL from "@salesforce/label/c.iCare_Portal_Fail";
import NAN_LABEL from "@salesforce/label/c.iCare_NaN";

import TOTAL_NUMBER_LABEL from "@salesforce/label/c.iCare_Portal_TotalNumber";
import iCarePortalTableMC from "@salesforce/messageChannel/iCarePortalTablesMessageChannel__c";
import iCarePortalJobsCharMC from "@salesforce/messageChannel/iCarePortalJobsChart__c";
import { publish, subscribe, MessageContext } from "lightning/messageService";

export default class ICareReportsTable extends LightningElement {
  totalRecsLabel;
  chartLabels;
  chartJobsData;

  buyerOptions;
  statusFilter;
  availableJobs;

  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    this.subscribeToMessageChannel();
  }

  /**
        Sync Chart component with reports data - via message
    */
  sendMessage() {
    this.resetChartData();
    const payload = {
      chartLabels: JSON.stringify(this.chartLabels),
      chartJobsData: JSON.stringify(this.chartJobsData),
      totalRecsLabel: this.totalRecsLabel
    };
    publish(this.messageContext, iCarePortalJobsCharMC, payload);
  }

  /**
        Method to recalculate Chart information
    */
  resetChartData() {
    this.chartLabels = [];
    if (this.statusFilter === "All") {
      this.resetChartDataAllTable();
    } else {
      this.resetChartDataByBuyer();
    }
    FAIL_LABEL;

    this.totalRecsLabel = TOTAL_NUMBER_LABEL + " " + this.availableJobs.length;
  }

  /**
        Method to recalculate Chart information for Pass/Fail grouping
    */
  resetChartDataAllTable() {
    let dataValues = "";
    let failJobs = 0;
    let passJobs = 0;
    let nanJobs = 0;

    this.availableJobs.forEach((job) => {
      if (job.iCare_Job_Outcome__c === "Fail") {
        failJobs = failJobs + 1;
      } else if (job.iCare_Job_Outcome__c === "Pass") {
        passJobs = passJobs + 1;
      }else {
          nanJobs++;
      }
    });

    if (this.availableJobs.length > 0) {
      this.chartLabels.push(
        PASS_LABEL +
          " " +
          Math.round((passJobs / this.availableJobs.length) * 100) +
          "%"
      );
      this.chartLabels.push(
        FAIL_LABEL +
          " " +
          Math.round((failJobs / this.availableJobs.length) * 100) +
          "%"
      );
      this.chartLabels.push(
        NAN_LABEL +
          " " +
          Math.round((nanJobs / this.availableJobs.length) * 100) +
          "%"
      );

      dataValues = dataValues + passJobs + ", ";
      dataValues = dataValues + failJobs + ", ";
      dataValues = dataValues + nanJobs + ", ";

      this.chartJobsData =
        "[" + dataValues.slice(0, dataValues.lastIndexOf(",")) + "]";
    } else {
      this.chartLabels = "";
      this.chartJobsData = "";
    }
  }

  /**
        Method to recalculate Chart information for Buyer grouping
    */
  resetChartDataByBuyer() {
    let dataValues = "";
    const groupedByBuyer = this.availableJobs.reduce((groups, job) => {
      const buyer = job.iCare_Buyer_Program_formula__c;
      if (!groups[buyer]) {
        groups[buyer] = 1;
      } else {
        groups[buyer] = groups[buyer] + 1;
      }
      return groups;
    }, {});

    for (let buyer in groupedByBuyer) {
      const value = groupedByBuyer[buyer];
      this.chartLabels.push(
        buyer +
          " " +
          Math.round(((value / this.availableJobs.length) * 10000) / 100) +
          "%"
      );
      dataValues = dataValues + value + ", ";
    }

    this.chartJobsData =
      "[" + dataValues.slice(0, dataValues.lastIndexOf(",")) + "]";
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  handleAvailableJobs() {
    this.sendMessage();
  }

  subscribeToMessageChannel() {
    this.subscription = subscribe(
      this.messageContext,
      iCarePortalTableMC,
      (message) => {
        //this.totalRecsLabel = message.totalRecsLabel;
        this.buyerOptions = JSON.parse(message.buyerFilterValues);
        this.availableJobs = JSON.parse(message.availableJobs);
        this.statusFilter = JSON.parse(message.statusFilter);
        this.handleAvailableJobs();
      }
    );
  }
}