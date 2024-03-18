import { LightningElement, api } from "lwc";
import COMPANY_ADDRESS from "@salesforce/label/c.GTS_Company_Address";
import COMPANY_NAME from "@salesforce/label/c.GTS_Company_Name";
import CONTACT_NUMBER from "@salesforce/label/c.GTS_Contact_Number";
import CONTACT_PERSON from "@salesforce/label/c.GTS_Contact_Person";
import EMAIL from "@salesforce/label/c.GTS_Email";
import APPLICANT_DETAILS from "@salesforce/label/c.GTS_Applicant_Details";
import PAYER from "@salesforce/label/c.GTS_Payer";
import PURCHASE_ORDER from "@salesforce/label/c.GTS_Purchase_Order";
import SEARCH_PERSON from "@salesforce/label/c.GTS_Search_Person";

export default class GtsTradeableApplicantPayer extends LightningElement {
  @api isReadOnly = false;
  @api jobRequestRecord;
  @api recordTypeId;
  @api accountRecordType;

  labels = {
    COMPANY_ADDRESS,
    COMPANY_NAME,
    CONTACT_NUMBER,
    CONTACT_PERSON,
    EMAIL,
    APPLICANT_DETAILS,
    PAYER,
    PURCHASE_ORDER,
    SEARCH_PERSON
  };

  get payerFieldsFiltering() {
    return JSON.stringify({
      GTS_Account__c: this.jobRequestRecord.iCare_Applicant_Company__c,
      GTS_Role__c: "Payer"
    });
  }

  exporterDetails;
  payerDetails;

  handleUpdateExporterInfo(event) {
    this.exporterDetails = event.detail;
    this.dispatchChangeDataEvent();
  }

  handleUpdatePayerInfo(event) {
    this.payerDetails = event.detail;
    this.dispatchChangeDataEvent();
  }

  dispatchChangeDataEvent() {
    const oEvent = new CustomEvent("updateapplicantpage", {
      detail: {
        exporterDetails: this.exporterDetails,
        payerDetails: this.payerDetails
      }
    });

    this.dispatchEvent(oEvent);
  }
}