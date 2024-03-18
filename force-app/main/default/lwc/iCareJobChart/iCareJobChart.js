import { LightningElement, wire, api, track } from "lwc";
import iCarePortalJobsCharMC from "@salesforce/messageChannel/iCarePortalJobsChart__c";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";

import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext
} from "lightning/messageService";

export default class ICareJobChart extends LightningElement {
  @api objectName = "iCare_Job__c";
  @api fieldName = "iCare_Job_Status_Portal__c";
  @api recordTypeId;
  @api value;
  @track picklistOptions;
  apiFieldName;

  chartLabels;
  chartPercentages;
  chartJobsData;
  totalRecsLabel;
  chartColors;
  chartLabelsIni;
  chartPercentagesIni;

  error;
  isGtsPage = false;

  @wire(getObjectInfo, { objectApiName: "$objectName" })
  getObjectData({ error, data }) {
    if (data) {
      if (this.recordTypeId == null)
        this.recordTypeId = data.defaultRecordTypeId;
      this.apiFieldName = this.objectName + "." + this.fieldName;
    } else if (error) {
      console.log("Error: " + error);
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: "$apiFieldName"
  })
  getPicklistValues({ error, data }) {
    if (data) {
      console.log("getPicklistValues : ", data);
      // Map picklist values
      this.picklistOptions = data.values.map((plValue) => {
        return {
          label: plValue.label,
          value: plValue.value
        };
      });
      this.translateLabels(this.chartLabelsIni, this.chartPercentagesIni);
    } else if (error) {
      console.log("getPicklistValues Error : " + error);
    }
  }

  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    this.subscribeToMessageChannel();
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }

  subscribeToMessageChannel() {
    this.chartLabels = undefined;
    this.chartJobsData = undefined;
    this.totalRecsLabel = undefined;

    this.subscription = subscribe(
      this.messageContext,
      iCarePortalJobsCharMC,
      (message) => this.handleMessage(message),
      { scope: APPLICATION_SCOPE }
    );
  }

  handleMessage(message) {
    console.log("message : " + message);
    this.chartJobsData = message.chartJobsData;
    this.totalRecsLabel = message.chartTotalRecs;
    this.chartLabelsIni = message.chartLabels;
    this.chartPercentagesIni = message.chartPercentages;
    this.isGtsPage = message.gtsPage;
    this.translateLabels(message.chartLabels, message.chartPercentages);
    this.assignColors(message.chartLabels);

    console.log("message.gtsPage :" + message.gtsPage);
    if (message.gtsPage) {
      this.apiFieldName = this.objectName + ".iCare_Job_Status__c";
    }
  }

  translateLabels(labelsToTranslate, percentages) {
    let mapPicklist = new Map();
    let chartLabelsTranslated = [];

    if (this.isGtsPage) {
      for (let record of this.picklistOptions) {
        if (labelsToTranslate.includes(record.value)) {
          chartLabelsTranslated.push(
            record.label +
              " " +
              percentages[labelsToTranslate.indexOf(record.value)]
          );
        }
      }
    } else {
      if (this.picklistOptions != undefined) {
        //Get map from picklist for translations
        for (let record of this.picklistOptions) {
          mapPicklist.set(record.value, record.label);
        }
        if (labelsToTranslate != undefined) {
          //Translate the message labels
          for (let record of labelsToTranslate) {
            let labelTranslated = mapPicklist.get(record);
            if (labelTranslated != null) {
              chartLabelsTranslated.push(
                labelTranslated +
                  " " +
                  percentages[labelsToTranslate.indexOf(record)]
              ); //Get index of the translated label to get the %
            } else {
              chartLabelsTranslated.push(
                record + " " + percentages[labelsToTranslate.indexOf(record)]
              ); //Get index of the translated label to get the %
            }
          }
        }
      }
    }
    this.chartLabels = chartLabelsTranslated;
  }

  assignColors(chartLabels) {
    //Assign colors by status
    let chartColorsMod = [];
    this.resetColors();
    if (chartLabels != undefined) {
      chartLabels.forEach((record) => {
        switch (record) {
          case "Job Submitted":
            chartColorsMod.push("rgba(33, 182, 215)"); //Blue
            break;
          case "Sample Received":
            chartColorsMod.push("rgba(71, 78, 84)"); //Grey
            break;
          case "Test in Progress":
            chartColorsMod.push("rgba(33, 182, 215, 0.1)"); //"White"
            break;
          case "Test Report Issued":
            chartColorsMod.push("rgba(255, 199, 0)"); //Cerello (Yellow)
            break;
          case "Cancelled":
            chartColorsMod.push("rgba(0, 0, 0)"); //Black
            break;
          case "Submitted":
            chartColorsMod.push("rgba(255, 199, 0)"); //Cerello (Yellow)
            break;
          case "Accepted":
            chartColorsMod.push("rgba(255, 255, 255)"); //white
            break;
          case "OrderAccepted":
            chartColorsMod.push("rgba(255, 255, 255)"); //white
            break;
          case "Complete":
            chartColorsMod.push("rgba(33, 182, 215)"); //Blue
            break;
          case "InspectionScheduled":
            chartColorsMod.push("rgba(71, 78, 84)"); //Grey
            break;
          case "InspectionRequested":
            chartColorsMod.push("rgba(71, 78, 84)"); //Grey
            break;
          case "In Progress":
            chartColorsMod.push("rgba(71, 78, 84)"); //Grey
            break;
          case "InProgress":
            chartColorsMod.push("rgba(71, 78, 84)"); //Grey
            break;
          case "AwaitingFinalDocs":
            chartColorsMod.push("rgba(93, 164, 182)");
            break;
          case "InspectionComplete":
            chartColorsMod.push("rgba(129, 129, 129)");
            break;
          case "Drafting":
            chartColorsMod.push("rgba(93, 164, 182)");
            break;
          default:
            chartColorsMod.push("rgba(33, 182, 215)"); //Blue
            break;
        }
      });
    }

    if (chartColorsMod.length) {
      this.chartColors = chartColorsMod;
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  resetColors() {
    //5 initial colors defined by Client
    //For the "All" option, the status colors are assigned specifically on "assignColors"
    this.chartColors = [
      "rgba(33, 182, 215)",
      "rgba(71, 78, 84)",
      "rgba(255, 199, 0)",
      "rgba(33, 182, 215, 0.1)",
      "rgba(0, 0, 0)",
      //100 "Random" fixed Colors
      "rgba(65, 3, 126)",
      "rgba(170, 188, 201)",
      "rgba(202, 61, 133)",
      "rgba(120, 65, 56)",
      "rgba(58, 82, 87)",
      "rgba(91, 174, 97)",
      "rgba(29, 119, 248)",
      "rgba(128, 29, 151)",
      "rgba(232, 173, 56)",
      "rgba(123, 21, 82)",
      "rgba(163, 255, 154)",
      "rgba(24, 45, 59)",
      "rgba(120, 200, 161)",
      "rgba(155, 47, 62)",
      "rgba(24, 220, 12)",
      "rgba(159, 241, 249)",
      "rgba(174, 131, 45)",
      "rgba(102, 146, 168)",
      "rgba(75, 237, 125)",
      "rgba(55, 59, 6)",
      "rgba(139, 194, 155)",
      "rgba(127, 31, 128)",
      "rgba(118, 216, 63)",
      "rgba(175, 188, 91)",
      "rgba(219, 174, 91)",
      "rgba(224, 222, 92)",
      "rgba(51, 153, 34)",
      "rgba(69, 83, 201)",
      "rgba(201, 21, 65)",
      "rgba(82, 237, 185)",
      "rgba(167, 68, 46)",
      "rgba(249, 250, 9)",
      "rgba(82, 182, 182)",
      "rgba(125, 14, 2)",
      "rgba(66, 143, 138)",
      "rgba(178, 145, 21)",
      "rgba(39, 143, 42)",
      "rgba(73, 12, 203)",
      "rgba(166, 50, 209)",
      "rgba(144, 110, 30)",
      "rgba(232, 91, 212)",
      "rgba(83, 232, 222)",
      "rgba(175, 246, 199)",
      "rgba(227, 210, 79)",
      "rgba(92, 188, 92)",
      "rgba(75, 177, 174)",
      "rgba(81, 250, 196)",
      "rgba(136, 200, 169)",
      "rgba(105, 18, 163)",
      "rgba(222, 117, 192)",
      "rgba(203, 77, 64)",
      "rgba(237, 92, 84)",
      "rgba(12, 118, 34)",
      "rgba(17, 233, 90)",
      "rgba(37, 35, 160)",
      "rgba(217, 124, 99)",
      "rgba(10, 71, 76)",
      "rgba(136, 116, 52)",
      "rgba(124, 192, 228)",
      "rgba(206, 132, 26)",
      "rgba(36, 144, 175)",
      "rgba(3, 246, 188)",
      "rgba(144, 132, 55)",
      "rgba(136, 193, 192)",
      "rgba(32, 203, 96)",
      "rgba(243, 81, 20)",
      "rgba(31, 133, 184)",
      "rgba(78, 222, 43)",
      "rgba(226, 81, 68)",
      "rgba(204, 246, 200)",
      "rgba(207, 170, 13)",
      "rgba(136, 4, 133)",
      "rgba(199, 5, 164)",
      "rgba(204, 126, 20)",
      "rgba(242, 116, 73)",
      "rgba(129, 180, 87)",
      "rgba(101, 188, 214)",
      "rgba(26, 7, 32)",
      "rgba(31, 159, 75)",
      "rgba(157, 172, 19)",
      "rgba(29, 99, 175)",
      "rgba(177, 27, 33)",
      "rgba(153, 83, 205)",
      "rgba(150, 224, 43)",
      "rgba(90, 156, 166)",
      "rgba(44, 193, 244)",
      "rgba(37, 112, 29)",
      "rgba(20, 166, 232)",
      "rgba(137, 62, 10)",
      "rgba(3, 210, 188)",
      "rgba(226, 61, 26)",
      "rgba(235, 154, 229)",
      "rgba(108, 196, 62)",
      "rgba(233, 114, 176)",
      "rgba(167, 66, 138)",
      "rgba(177, 174, 11)",
      "rgba(180, 167, 163)",
      "rgba(139, 39, 37)",
      "rgba(236, 181, 14)",
      "rgba(15, 62, 32)"
    ];
  }
}