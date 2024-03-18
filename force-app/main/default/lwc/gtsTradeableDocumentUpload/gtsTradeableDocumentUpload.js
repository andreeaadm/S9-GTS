import { LightningElement, api } from "lwc";
import DOCUMENTS_SOW from "@salesforce/label/c.GTS_Document_Label";
//import STATEMENT_OF_WORK from "@salesforce/label/c.GTS_Statement_Of_Work";
import DATE_LABEL from "@salesforce/label/c.GTS_Start_And_Completion_Date_Label";
import START_DATE from "@salesforce/label/c.GTS_Start_Date";
import COMPLETION_DATE from "@salesforce/label/c.GTS_Completion_Date";
//import FINAL_REPORT_LABEL from "@salesforce/label/c.GTS_Final_Report_Label";

export default class GtsTradeableDocumentUpload extends LightningElement {
  @api isReadOnly = false;
  @api jobRequestRecord;
  @api contentVersionIds;

  labels = {
    DOCUMENTS_SOW,
    //STATEMENT_OF_WORK,
    DATE_LABEL,
    START_DATE,
    COMPLETION_DATE
    //FINAL_REPORT_LABEL
  };

  /*handleSOWChange(event) {
    this.dispatchEvent(
      new CustomEvent("sowchange", { detail: event.detail.value })
    );
  }

  handleFinalReportChange(event) {
    this.dispatchEvent(
      new CustomEvent("finalreportchange", { detail: event.detail.value })
    );
  }*/

  handleDocumentUpload(event){
    console.log('documentUpload : ',event.detail);
    this.dispatchEvent(new CustomEvent('documentupload', {detail : event.detail}));
  }
}