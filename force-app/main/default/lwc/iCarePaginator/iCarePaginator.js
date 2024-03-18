import { LightningElement, api, track } from "lwc";
/* eslint-disable no-console */
/* eslint-disable no-alert */

// Custom Labels
import FIRST_PAGE_LABEL from "@salesforce/label/c.iCare_First_Page_Button";
import LAST_PAGE_LABEL from "@salesforce/label/c.iCare_Last_Page_Button";
import NEXT_LABEL from "@salesforce/label/c.iCare_Next_Button";
import PREVIOUS_LABEL from "@salesforce/label/c.iCare_Previous_Button";

export default class Paginator extends LightningElement {
  @track isNextDisabled = false;
  @track isPreviousDisabled = false;
  @track isFirstPageDisabled = false;
  @track isLastPageDisabled = false;

  @api isGtsTrackJobTabel = false;

  label = {
    FIRST_PAGE_LABEL,
    LAST_PAGE_LABEL,
    NEXT_LABEL,
    PREVIOUS_LABEL
  };

  @api changeView(str) {
    if (str === "trueprevious") {
      // let btn = this.template.querySelector('lightning-button.Previous');
      // btn.disabled = true
      this.isPreviousDisabled = true;
    }
    if (str === "falsenext") {
      // let btn = this.template.querySelector('lightning-button.Next');
      // btn.disabled = false;
      this.isNextDisabled = false;
    }
    if (str === "truenext") {
      // let btn = this.template.querySelector('lightning-button.Next');
      // btn.disabled = true;
      this.isNextDisabled = true;
    }
    if (str === "falseprevious") {
      // btn = this.template.querySelector('lightning-button.Previous');
      // btn.disabled = false;
      this.isPreviousDisabled = false;
    }
    if (str === "falseFirstPage") {
      this.isFirstPageDisabled = false;
    }
    if (str === "trueFirstPage") {
      this.isFirstPageDisabled = true;
    }
    if (str === "falseLastPage") {
      this.isLastPageDisabled = false;
    }
    if (str === "trueLastPage") {
      this.isLastPageDisabled = true;
    }
  }
  connectedCallback() {
    // this.template.querySelector('lightning-button.Previous').disabled = true;
    this.isPreviousDisabled = true;
    this.isFirstPageDisabled = true;
  }
  previousHandler() {
    this.dispatchEvent(new CustomEvent("previous"));
  }

  nextHandler() {
    this.dispatchEvent(new CustomEvent("next"));
  }
  FirstPageHandler() {
    this.dispatchEvent(new CustomEvent("firstpage"));
  }
  LastPageHandler() {
    this.dispatchEvent(new CustomEvent("lastpage"));
  }
  changeHandler(event) {
    try {
      event.preventDefault();
      const s_value = event.target.value;
      const selectedEvent = new CustomEvent("selected", { detail: s_value });

      this.dispatchEvent(selectedEvent);
    } catch (error) {
      console.log("error in changeHandler ***", error);
    }
  }
}