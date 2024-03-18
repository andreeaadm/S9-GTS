import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import TOXCLEAR_FIELD from "@salesforce/schema/Account.Is_ToxClear_Account__c";
import COUNTRY_FIELD from "@salesforce/schema/Account.Country__c";
import { label, format } from "c/labelService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import TcExperienceCloud from "c/tcExperienceCloud";

export default class TcMyCompanySettings extends LightningElement {
  @api recordId;
  labels = label;
  context;
  isSupplierAdmin;
  isBrandAdmin;
  isAdmin;
  hasLoaded = false;
  hasCountry;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [TOXCLEAR_FIELD, COUNTRY_FIELD]
  })
  wiredRecord({ error, data }) {
    if (data) {
      this.hasCountry =
        getFieldValue(data, TOXCLEAR_FIELD) &&
        !!getFieldValue(data, COUNTRY_FIELD);
    }
  }

  constructor() {
    super();
    this.context = new TcExperienceCloud();
  }

  handleLoad() {
    this.isSupplierAdmin = this.context.isSupplierAdminUser;
    this.isBrandAdmin = this.context.isBrandAdminUser;
    this.isAdmin = this.context.isAdminUser;
    this.hasLoaded = true;
  }

  handleSave() {
    if (this.hasCountry) {
      this.template.querySelector(".hidden").click();
    } else {
      dispatchEvent(
        new ShowToastEvent({
          title: label.ERROR,
          message: label.TC_ACCOUNT_MISSING_COUNTRY,
          variant: "error"
        })
      );
    }
  }

  handleCancel() {
    const inputFields = this.template.querySelectorAll("lightning-input-field");
    if (inputFields) {
      inputFields.forEach((field) => {
        field.reset();
      });
    }
  }

  handleSuccess() {
    dispatchEvent(
      new ShowToastEvent({
        title: label.SUCCESS,
        message: format(label.TC_OBJECT_UPDATE_SUCCESS, "Account"),
        variant: "success"
      })
    );
  }

  handleError() {
    dispatchEvent(
      new ShowToastEvent({
        title: label.ERROR,
        message: format(label.TC_OBJECT_UPDATE_ERROR, "Account"),
        variant: "error"
      })
    );
  }
}