import { LightningElement, api, wire } from "lwc";
import getExpertsList from "@salesforce/apex/iCareExpertComponentController.getExpertsList";
import getGtsExpertQueryRecordtypeId from "@salesforce/apex/iCareExpertComponentController.getGtsExpertQueryRecordtypeId";
import getGtsExpertQueryQueueId from "@salesforce/apex/iCareExpertComponentController.getGtsExpertQueryQueueId";

import { createRecord, getRecord, getFieldValue } from "lightning/uiRecordApi";
import EXPERT_QUERY_EXPERT from "@salesforce/schema/iCare_Expert_Query__c.iCare_Expert__c";
import EXPERT_QUERY_SUBJECT from "@salesforce/schema/iCare_Expert_Query__c.iCare_Subject__c";
import EXPERT_QUERY_QUERY from "@salesforce/schema/iCare_Expert_Query__c.iCare_Your_Query__c";
import EXPERT_QUERY_OBJECT from "@salesforce/schema/iCare_Expert_Query__c";
import EXPERT_QUERY_USER from "@salesforce/schema/iCare_Expert_Query__c.iCare_User__c";
import EXPERT_QUERY_ACCOUNT from "@salesforce/schema/iCare_Expert_Query__c.iCare_Account__c";
import EXPERT_QUERY_OWNER from "@salesforce/schema/iCare_Expert_Query__c.OwnerId";
import EXPERT_QUERY_RECORDTYPE from "@salesforce/schema/iCare_Expert_Query__c.RecordTypeId";
import EXPERT_QUERY_APPLICATION_NAME from "@salesforce/schema/iCare_Expert_Query__c.iCare_Source_Application_Name__c";

import GTS_OUR_EXPERTS from "@salesforce/label/c.GTS_Our_Experts";

import Id from "@salesforce/user/Id";
import USER_CONTACT_ID from "@salesforce/schema/User.ContactId";
import CONTACT_ACCOUNT_ID from "@salesforce/schema/Contact.AccountId";
import USER_COUNTRY from "@salesforce/schema/User.Country";

export default class Expertlist extends LightningElement {
  @api isCountrySelectionEnabled;
  @api isRegulatoryUpdatesVisible;
  @api title;
  @api indexTitle;
  @api text;

  displayExpertListTemplate = true; // This will be used to display the components for the first view
  displayEnquiryTemplate = false; // This is used to display the components in the template for the second view
  displayExpertSubmittedTemplate = false; // This is used to display the components in the final view.
  userId = Id;
  contactId;
  currentUserCountry;
  currentUserAccount;
  @api selectedExpertId;
  @api selectedExpertName;
  @api recordid;
  selection;
  createdRecordId;
  gtsExpertQueryRecordtypeId;
  gtsExpertQueryQueueId;
  @api output;
  error;
  experts;

  get selectedOurExperts() {
    return GTS_OUR_EXPERTS;
  }
  // @wire(getExpertsList, {selection :  this.selection}) experts;

  @wire(getRecord, { recordId: Id, fields: [USER_CONTACT_ID, USER_COUNTRY] })
  currentUserInfo({ data, error }) {
    if (data) {
      this.contactId = getFieldValue(data, USER_CONTACT_ID);
      this.currentUserCountry = getFieldValue(data, USER_COUNTRY);
    } else if (error) {
      this.error = error;
    }
  }

  @wire(getRecord, { recordId: "$contactId", fields: [CONTACT_ACCOUNT_ID] })
  contactInfo({ data, error }) {
    if (data) {
      this.currentUserAccount = getFieldValue(data, CONTACT_ACCOUNT_ID);
    } else if (error) {
      this.error = error;
    }
  }

  connectedCallback() {
    this.handleGetExpertsList(this.output);
    this.addEventListener("selectedexpert", this.handleSelectedExpert);
    this.addEventListener("sendenquiry", this.handleSendEnquiry);
    this.addEventListener("findanotherexpert", this.handleReturnToExperts);
    this.addEventListener("returntoexperts", this.handleReturnToExperts);

    getGtsExpertQueryRecordtypeId()
      .then((result) => {
        this.gtsExpertQueryRecordtypeId = result;
        this.error = undefined;
      })
      .catch((error) => {
        console.log("error" + error);
        this.error = error;
      });
    getGtsExpertQueryQueueId()
      .then((result) => {
        this.gtsExpertQueryQueueId = result;
        this.error = undefined;
      })
      .catch((error) => {
        console.log("error" + error);
        this.error = error;
      });
  }

  get options() {
    return [
      { label: "Local", value: "Local" },
      { label: "Global", value: "Global" }
    ];
  }
  handleClickRadioButton(event) {
    this.experts = undefined;
    this.output = event.target.value;
    this.handleGetExpertsList(this.output);
  }
  handleGetExpertsList(selectionValue) {
    getExpertsList({ selection: selectionValue })
      .then((result) => {
        this.experts = result;
        this.error = undefined;
      })
      .catch((error) => {
        console.log("error" + error);
        this.error = error;
        this.experts = undefined;
      });
  }

  handleSelectedExpert(event) {
    this.displayExpertListTemplate = false; // Close the first view
    this.displayEnquiryTemplate = true; // Display the second view
    this.displayExpertSubmittedTemplate = false; // Close the third view
    this.selectedExpertId = event.detail.recordid;
    this.selectedExpertName = event.detail.expertname;
    window.scrollTo(0, 0);
  }

  handleReturnToExperts(event) {
    this.displayExpertListTemplate = true; // Display the first view
    this.displayEnquiryTemplate = false; // Close the second view
    this.displayExpertSubmittedTemplate = false; // Close the third view
    window.scrollTo(0, 0);
  }

  handleSendEnquiry(event) {
    this.displayExpertListTemplate = false; // Close the first view
    this.displayEnquiryTemplate = false; // Close the second view
    this.displayExpertSubmittedTemplate = true; // Display the third view
    this.subject = event.detail.subject;
    this.enquiry = event.detail.enquiry;
    console.log(this.gtsExpertQueryQueueId);
    console.log(this.gtsExpertQueryRecordtypeId);
    const recordValues = {
      apiName: EXPERT_QUERY_OBJECT.objectApiName,
      fields: {
        [EXPERT_QUERY_EXPERT.fieldApiName]: this.selectedExpertId,
        [EXPERT_QUERY_SUBJECT.fieldApiName]: this.subject,
        [EXPERT_QUERY_QUERY.fieldApiName]: this.enquiry,
        [EXPERT_QUERY_USER.fieldApiName]: this.userId,
        [EXPERT_QUERY_ACCOUNT.fieldApiName]: this.currentUserAccount,
        [EXPERT_QUERY_APPLICATION_NAME.fieldApiName]: "My GTS",
        [EXPERT_QUERY_OWNER.fieldApiName]: this.gtsExpertQueryQueueId,
        [EXPERT_QUERY_RECORDTYPE.fieldApiName]: this.gtsExpertQueryRecordtypeId
      }
    };
    createRecord(recordValues)
      .then((result) => {
        this.createdRecordId = result.id;
      })
      .catch((error) => {
        this.error = error;
        console.error(
          "Error has occurred whilst creating record ",
          error.body.message
        );
        console.error("Error has occurred whilst creating record ", error.body);
      });
    window.scrollTo(0, 0);
  }
}