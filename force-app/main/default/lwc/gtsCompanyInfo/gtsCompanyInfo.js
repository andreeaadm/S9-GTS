import { LightningElement, api, wire, track } from "lwc";
import APPLICANT_TYPE from "@salesforce/label/c.GTS_Applicant_Type";
import BUTTON_LABEL from "@salesforce/label/c.GTS_Same_As_Exporter_Information_Above";
import CITY from "@salesforce/label/c.GTS_City";
import COMMERCIAL_NR from "@salesforce/label/c.GTS_Commercial_Registration_No";
import COMPANY_ADDRESS from "@salesforce/label/c.GTS_Company_Address";
import COMPANY_NAME from "@salesforce/label/c.GTS_Company_Name";
import COMPANY_NUMBER from "@salesforce/label/c.GTS_Commercial_Registration_No";
import CONTACT_NUMBER from "@salesforce/label/c.GTS_Contact_Number";
import CONTACT_PERSON from "@salesforce/label/c.GTS_Contact_Person";
import COUNTRY from "@salesforce/label/c.GTS_Country";
import EMAIL from "@salesforce/label/c.GTS_Email";
import PAYMENT_TYPE from "@salesforce/label/c.GTS_Payment_Type";
import PO_NUMBER from "@salesforce/label/c.GTS_Purchase_Order_No";
import POSTAL_CODE from "@salesforce/label/c.GTS_PostalCode";
import SEARCH_COMPANY from "@salesforce/label/c.GTS_Search_Company";
import SEARCH_PERSON from "@salesforce/label/c.GTS_Search_Person";
import STATE from "@salesforce/label/c.GTS_State";
import STREET from "@salesforce/label/c.GTS_Street";

import { getRecord } from "lightning/uiRecordApi";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import apexGetContactInfo from "@salesforce/apex/GTSJobRequestContactInfo.getContactInfo";

import BILLING_CITY from "@salesforce/schema/Account.BillingCity";
import COUNTRY_CODE from "@salesforce/schema/Account.BillingCountryCode";
import BILLING_STREET from "@salesforce/schema/Account.BillingStreet";
import STATE_CODE from "@salesforce/schema/Account.BillingStateCode";
import BILLING_POSTAL_CODE from "@salesforce/schema/Account.BillingPostalCode";
import COMMERCIAL_REG_NO from "@salesforce/schema/Account.GTS_Commercial_Registration_No_TIN__c";
import NAME from "@salesforce/schema/Account.Name";
import APPLICANT_TYPE_FIELD from "@salesforce/schema/Account.GTS_Applicant_Type__c";

import PICKLIST_APPLICANT_TYPE from "@salesforce/schema/icare_Job_Request__c.GTS_Applicant_Type__c";

import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import COUNTRY_FIELD from "@salesforce/schema/Account.BillingCountryCode";
import STATE_FIELD from "@salesforce/schema/Account.BillingStateCode";

export default class GtsCompanyInfo extends LightningElement {
  @api accountRecordType;
  @api sectionName;
  @api showCommercialRegistrationNr = false;
  @api showPONr = false;
  @api showCopyButton = false;
  @api isAccountReadOnly;
  @api isReadOnly = false;
  @api showTradeablePayer = false;

  @api accountName;
  @api accountId;
  @api contactId;
  @api contactName;
  contactRecord;
  @api contactPhone;
  @api contactEmail;
  @api contactCommercialNr;
  @api contactPONr;
  @api contactPO;
  @api applicantType;
  @api paymentType;
  @api accountFilters;
  @api showApplicantType;
  @api showPaymentType;
  @api recordTypeId;
  @api addressStreet;
  @api addressCity;
  @api addressCountry;
  @api addressPostalCode;
  @api addressProvince;
  @api jobRequestRecord;
  @api isRequired = false;

  @api payOrdOptions;

  @track isApplicantTypeReadOnly;
  @track contactInfo;
  @track isContactInfoEmailRO;
  @track isContactInfoPhoneRO;

  @track selectedCountry = "";
  @track selectedState = "";
  @track stateValues = [];
  @track countryOptions = [];
  @track stateOptions = [];

  labels = {
    APPLICANT_TYPE,
    BUTTON_LABEL,
    CITY,
    COMMERCIAL_NR,
    COMPANY_ADDRESS,
    COMPANY_NAME,
    COMPANY_NUMBER,
    CONTACT_NUMBER,
    CONTACT_PERSON,
    COUNTRY,
    EMAIL,
    PAYMENT_TYPE,
    PO_NUMBER,
    SEARCH_COMPANY,
    SEARCH_PERSON,
    POSTAL_CODE,
    STATE,
    STREET
  };

  handleCopyExporterInfoClick(event) {
    this.accountId = this.jobRequestRecord.iCare_Applicant_Company__c;
    this.accountName = this.jobRequestRecord.GTS_Applicant_Company_Name__c;
    this.contactId = this.jobRequestRecord.GTS_Applicant_Contact_Person__c;
    this.contactName =
      this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c;
    this.contactPhone = this.jobRequestRecord.GTS_Applicant_Contact_Number__c;
    this.contactEmail = this.jobRequestRecord.iCare_Applicant_Email__c;
    this.contactCommercialNr =
      this.jobRequestRecord.GTS_Commercial_Registration_No_TIN__c;
    this.addressCity = this.jobRequestRecord.iCare_Applicant_Address__City__s;
    this.addressCountry =
      this.jobRequestRecord.iCare_Applicant_Address__CountryCode__s;
    this.addressPostalCode =
      this.jobRequestRecord.iCare_Applicant_Address__PostalCode__s;
    this.addressProvince =
      this.jobRequestRecord.iCare_Applicant_Address__StateCode__s;
    this.addressStreet =
      this.jobRequestRecord.iCare_Applicant_Address__Street__s;
    this.getContactInfo();
    this.dispatchChangeDataEvent();
  }

  connectedCallback() {
    if (this.contactId !== undefined) {
      this.getContactInfo();
    }
  }

  get isReadOnlyValue() {
    return this.isReadOnly === "true" ? true : false;
  }

  get contactFieldsFiltering() {
    return this.accountId !== undefined && this.accountId.length > 0
      ? JSON.stringify({ AccountId: this.accountId })
      : "null";
  }

  get isContactEmailReadOnly() {
    return this.isReadOnlyValue || this.isContactInfoEmailRO;
  }
  get checkApplicantTypeReadOnly() {
    return this.isApplicantTypeReadOnly || this.isReadOnlyValue;
  }

  get isContactPhoneReadOnly() {
    return this.isReadOnlyValue || this.isContactInfoPhoneRO;
  }

  get editAddress() {
    return (this.contactId !== undefined && this.contactId.length > 0) ||
      this.isReadOnlyValue === true
      ? true
      : false;
  }

  handleContactSelection(event) {
    this.contactId =
      event.detail.selectedRecord.Id !== undefined
        ? event.detail.selectedRecord.Id
        : "";
    this.contactName =
      event.detail.selectedName !== undefined ? event.detail.selectedName : "";
    this.contactEmail = "";
    this.contactPhone = "";
    this.contactInfo = undefined;
    this.addressCity = "";
    this.addressCountry = "";
    this.addressPostalCode = "";
    this.addressProvince = "";
    this.addressStreet = "";

    if (this.contactId !== undefined) {
      this.getContactInfo();
    }

    this.dispatchChangeDataEvent();
  }

  handleAccountSelection(event) {
    this.accountId =
      event.detail.selectedRecord.Id !== undefined
        ? event.detail.selectedRecord.Id
        : "";
    this.accountName =
      event.detail.selectedName !== undefined ? event.detail.selectedName : "";
    this.addressCity = "";
    this.addressCountry = "";
    this.addressPostalCode = "";
    this.addressProvince = "";
    this.addressStreet = "";
    this.contactName = "";
    this.contactId = "";
    this.contactPhone = "";
    this.contactEmail = "";
    this.dispatchChangeDataEvent();
  }

  getContactInfo() {
    apexGetContactInfo({ accountId: this.accountId, contactId: this.contactId })
      .then((result) => {
        this.contactInfo = result;
        if (
          this.contactInfo.Email !== undefined &&
          this.contactInfo.Email.length > 0
        ) {
          this.contactEmail = this.contactInfo.Email;
          this.isContactInfoEmailRO = true;
        } else {
          this.isContactInfoEmailRO = false;
        }
        if (
          this.contactInfo.Phone !== undefined &&
          this.contactInfo.Phone.length > 0
        ) {
          this.contactPhone = this.contactInfo.Phone;
          this.isContactInfoPhoneRO = true;
        } else {
          this.isContactInfoPhoneRO = false;
        }
        if (
          this.contactInfo.MailingCity != undefined &&
          this.contactInfo.MailingCity.length > 0
        ) {
          this.addressCity = this.contactInfo.MailingCity;
        }
        if (
          this.contactInfo.MailingCountryCode != undefined &&
          this.contactInfo.MailingCountryCode.length > 0
        ) {
          this.addressCountry = this.contactInfo.MailingCountryCode;
        }
        if (
          this.contactInfo.MailingPostalCode != undefined &&
          this.contactInfo.MailingPostalCode.length > 0
        ) {
          this.addressPostalCode = this.contactInfo.MailingPostalCode;
        }
        if (
          this.contactInfo.MailingStreet != undefined &&
          this.contactInfo.MailingStreet.length > 0
        ) {
          this.addressStreet = this.contactInfo.MailingStreet;
        }
        if (
          this.contactInfo.MailingStateCode != undefined &&
          this.contactInfo.MailingStateCode.length > 0
        ) {
          this.addressProvince = this.contactInfo.MailingStateCode;
        }

        this.dispatchChangeDataEvent();
      })
      .catch((error) => {
        console.log("error >>" + JSON.stringify(error));
      });
  }

  @wire(getRecord, {
    recordId: "$accountId",
    fields: [
      NAME,
      BILLING_CITY,
      COUNTRY_CODE,
      BILLING_STREET,
      BILLING_POSTAL_CODE,
      STATE_CODE,
      COMMERCIAL_REG_NO,
      APPLICANT_TYPE_FIELD
    ]
  })
  wiredAccount({ error, data }) {
    if (error) {
      console.log("Error loading Account");
    } else if (data) {

      if (!this.isReadOnly) {

        const accountRecord = data;

        this.isApplicantTypeReadOnly =
          accountRecord.fields.GTS_Applicant_Type__c.value != undefined &&
          accountRecord.fields.GTS_Applicant_Type__c.value.length > 0;
        let coNr =
          accountRecord.fields.GTS_Commercial_Registration_No_TIN__c.value;
        if (coNr != undefined && coNr.length > 0) {
          this.contactCommercialNr = coNr;
        }
        let appType = accountRecord.fields.GTS_Applicant_Type__c.value;
        if (appType != undefined && appType.length > 0) {
          this.applicantType = appType;
        }
        this.dispatchChangeDataEvent();
      }
    }
  }

  options = [];
  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: PICKLIST_APPLICANT_TYPE
  })
  getPicklistValuesForField({ data, error }) {
    if (error) {
      // TODO: Error handling
      console.error("error");
    } else if (data) {
      this.options = [...data.values];
    }
  }

  dispatchChangeDataEvent() {
    const companyInfoChanged = new CustomEvent("companyinfochanged", {
      detail: {
        applicantId: this.accountId,
        applicantName: this.accountName,
        contactId: this.contactId,
        contactName: this.contactName,
        contactPhone: this.contactPhone,
        contactEmail: this.contactEmail,
        contactCommercialNr: this.contactCommercialNr,
        contactPONr: this.contactPONr,
        contactPO: this.contactPO,
        applicantType: this.applicantType,
        paymentType: this.paymentType,
        city: this.addressCity,
        country: this.addressCountry,
        postalCode: this.addressPostalCode,
        street: this.addressStreet,
        state: this.addressProvince
      }
    });
    this.dispatchEvent(companyInfoChanged);
  }

  handleContactPhoneChange(event) {
    this.contactPhone = event.target.value;
    this.dispatchChangeDataEvent();
  }

  handleContactEmailChange(event) {
    this.contactEmail = event.target.value;
    this.dispatchChangeDataEvent();
  }
  handleCommercialNrChange(event) {
    this.contactCommercialNr = event.target.value;
    this.dispatchChangeDataEvent();
  }
  handlePONrChange(event) {
    this.contactPONr = event.target.value;
    this.dispatchChangeDataEvent();
  }
  handleApplicantTypeChange(event) {
    this.applicantType = event.detail.value;
    this.dispatchChangeDataEvent();
  }

  handleAddressStreetChange(event) {
    this.addressStreet = event.target.value;
    this.dispatchChangeDataEvent();
  }
  handleAddressCityChange(event) {
    this.addressCity = event.target.value;
    this.dispatchChangeDataEvent();
  }
  handleAddressStateChange(event) {
    this.addressProvince = event.target.value;
    this.dispatchChangeDataEvent();
  }
  handleAddressPostalCodeChange(event) {
    this.addressPostalCode = event.target.value;
    this.dispatchChangeDataEvent();
  }
  handleAddressCountryChange(event) {
    this.addressCountry = event.target.value;
    this.dispatchChangeDataEvent();
  }
  @wire(getPicklistValuesByRecordType, {
    recordTypeId: "$accountRecordType", // Replace with your record type ID
    objectApiName: "Account"
  })
  wiredPicklistValues({ error, data }) {
    if (data) {
      // Extract country picklist values
      this.countryOptions =
        data.picklistFieldValues[COUNTRY_FIELD.fieldApiName].values;
      this.stateValues = data.picklistFieldValues[STATE_FIELD.fieldApiName];
      if (this.addressCountry !== null) {
        this.getStateValues(this.addressCountry);
      }
    } else if (error) {
      console.error("Error retrieving picklist values: ", error);
    }
  }

  handleCountryChange(event) {
    this.addressProvince = "";
    this.getStateValues(event.detail.value);
    this.addressCountry = event.target.value;
    this.dispatchChangeDataEvent();
  }

  getStateValues(countryValue) {
    console.log("countryValue", countryValue);
    console.log("this.stateValues", JSON.stringify(this.stateValues));

    let countryNumber = this.stateValues.controllerValues[countryValue];
    this.stateOptions = this.stateValues.values.filter((obj) =>
      obj.validFor.includes(countryNumber)
    );
  }
}