import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
//Labels and fields
import ANALYST_TITLE_LABEL from "@salesforce/label/c.GTS_Intertek_Analyst_Title";
import SUPPORTING_DOCUMENTS_TITLE_LABEL from "@salesforce/label/c.GTS_Supporting_Documents_Title";
import FILE_UPLOAD_SUCCESS_LABEL from "@salesforce/label/c.GTS_File_Upload_Success";
import FILE_UPLOAD_ERROR_LABEL from "@salesforce/label/c.GTS_File_Upload_Error";
import FIRST_NAME_FIELD from "@salesforce/schema/iCare_Job__c.GTS_Analyst_First_Name__c";
import LAST_NAME_FIELD from "@salesforce/schema/iCare_Job__c.GTS_Analyst_Last_Name__c";
import EMAIL_FIELD from "@salesforce/schema/iCare_Job__c.GTS_Analyst_Username__c";
//apex methods
import getFormVersion from "@salesforce/apex/ICareFileUploadController.getFormVersionName";
import createContentDocumentLink from "@salesforce/apex/ICareFileUploadController.createContentLink";
//LMS
import { publish, MessageContext } from "lightning/messageService";
import GTS_PORTAL_CHANNEL from "@salesforce/messageChannel/GTSPortalMessageChannel__c";

const fields = [FIRST_NAME_FIELD, LAST_NAME_FIELD, EMAIL_FIELD];

export default class GtsJobProgressionFileUpload extends LightningElement {
  @api recordId;
  @api formName;
  analystInformation;
  jobProgressionPage = true;
  pageTitle = ANALYST_TITLE_LABEL;
  fileUploadTitle = SUPPORTING_DOCUMENTS_TITLE_LABEL;

  //Get analyst information (from Job record)
  @wire(getRecord, { recordId: "$recordId", fields })
  job({ error, data }) {
    if (data) {
      let firstName = data.fields.GTS_Analyst_First_Name__c.value;
      let lastName = data.fields.GTS_Analyst_Last_Name__c.value;
      let email = data.fields.GTS_Analyst_Username__c.value;
      //display analyst information only if first or last name or email are populated
      this.analystInformation =
        (firstName && lastName) || email ? data : undefined;
    } else if (error) {
      console.log("error " + JSON.stringify(error));
    }
  }

  //Get form version to be used by child component to determine the available document types
  @wire(getFormVersion, { jobRecordId: "$recordId" })
  formVersion({ error, data }) {
    if (data) {
      this.formName = data;
    } else if (error) {
      console.log("error " + JSON.stringify(error));
    }
  }

  //Get methods to retrieve field values
  get firstName() {
    return this.analystInformation
      ? getFieldValue(this.analystInformation, FIRST_NAME_FIELD)
      : "";
  }

  get lastName() {
    return this.analystInformation
      ? getFieldValue(this.analystInformation, LAST_NAME_FIELD)
      : "";
  }

  get email() {
    return this.analystInformation
      ? getFieldValue(this.analystInformation, EMAIL_FIELD)
      : "";
  }

  @wire(MessageContext)
  messageContext;

  //Once a file is uploaded, create a CDL to link the file and the job record. If this is successful, send a LMS message to other components
  handleDocumentUpload(event) {
    let conVersionIds = [];
    conVersionIds.push(event.detail);

    createContentDocumentLink({
      contentVersionIds: conVersionIds,
      recordId: this.recordId
    })
      .then((result) => {
        const event = new ShowToastEvent({
          title: FILE_UPLOAD_SUCCESS_LABEL,
          message: "",
          variant: "success"
        });
        this.dispatchEvent(event);

        //publish new content document link Id to the messaging service channel for other components to handle
        const payload = { contentDocumentLinkId: result[0].Id };
        publish(this.messageContext, GTS_PORTAL_CHANNEL, payload);
      })
      .catch((error) => {
        console.log("error saving ContentDocumentLink " + error);
        const event = new ShowToastEvent({
          title: FILE_UPLOAD_ERROR_LABEL,
          message: "",
          variant: "error"
        });
        this.dispatchEvent(event);
      });
  }
}