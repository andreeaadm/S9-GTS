import { LightningElement, wire, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Id from "@salesforce/user/Id";
import FORMULATOR_OBJECT from "@salesforce/schema/Formulator__c";
import FORMULATOR_NAME_FIELD from "@salesforce/schema/Formulator__c.Name";
import PHONE_FIELD from "@salesforce/schema/Formulator__c.Phone__c";
import ADDRESS_FIELD from "@salesforce/schema/Formulator__c.Address__c";
import CITY_TOWN_FIELD from "@salesforce/schema/Formulator__c.City_Town__c";
import STATE_PROVINCE_FIELD from "@salesforce/schema/Formulator__c.State_Province__c";
import ZIP_POSTAL_CODE_FIELD from "@salesforce/schema/Formulator__c.Zip_Postal_Code__c";
import COUNTRY_FIELD from "@salesforce/schema/Formulator__c.Country__c";
import CONTACT_NAME_FIELD from "@salesforce/schema/Formulator__c.Contact_Name__c";
import CONTACT_EMAIL_FIELD from "@salesforce/schema/Formulator__c.Contact_Email__c";
import getUserAccessKey from "@salesforce/apex/ZDHCGatewayService.getUserAccessKey";
import createZDHCFormulator from "@salesforce/apex/TC_SearchFormulatorsController.createZDHCFormulator";
import { label, format } from "c/labelService";

export default class TcCreateFormulator extends LightningElement {
  //PUBLIC PROPERTIES
  @api showNoResultsContent;
  @api showCancelButton;

  //TEMPLATE PROPERTIES
  showLoader;
  labels = label;

  //INTERNAL PROPERTIES
  _userId = Id;

  //LIGHTNING DATA SERVICE
  /**
   * retrieve the UserAccessKey for the current user
   */
  @wire(getUserAccessKey, {
    recordId: "$_userId"
  })
  _userAccessKey;

  //GETTERS & SETTERS
  /**
   * @returns the object api name for the c-form cmp
   */
  get objectApiName() {
    return FORMULATOR_OBJECT.objectApiName;
  }

  /**
   * @returns an array of field api names for fhe c-form cmp
   */
  get fieldApiNames() {
    return [
      FORMULATOR_NAME_FIELD.fieldApiName,
      PHONE_FIELD.fieldApiName,
      ADDRESS_FIELD.fieldApiName,
      CITY_TOWN_FIELD.fieldApiName,
      STATE_PROVINCE_FIELD.fieldApiName,
      ZIP_POSTAL_CODE_FIELD.fieldApiName,
      COUNTRY_FIELD.fieldApiName,
      CONTACT_NAME_FIELD.fieldApiName,
      CONTACT_EMAIL_FIELD.fieldApiName
    ];
  }

  /**
   * @returns an array of labels for the c-form cmp inputs
   */
  get fieldLabels() {
    return [
      this.labels.TC_FORMULATOR_NAME,
      this.labels.PHONE,
      this.labels.ADDRESS,
      this.labels.CITY_TOWN,
      this.labels.STATE_PROVINCE,
      this.labels.POSTAL_CODE,
      this.labels.COUNTRY_GENERIC,
      this.labels.CONTACT_NAME,
      this.labels.CONTACT_EMAIL
    ];
  }

  /**
   * @returns array of required field api names for the c-form cmp
   */
  get requiredFieldApiNames() {
    return [FORMULATOR_NAME_FIELD.fieldApiName, COUNTRY_FIELD.fieldApiName];
  }

  //EVENT HANDLERS
  /**
   * handles the user submitting the formulator for creation in SF and ZDHC
   */
  handleCreateFormulator() {
    this.template.querySelector("c-form").save();
  }

  /**
   * handles the c-form cmp successfully inserting the Formulator__c record
   * @param {object} event - success custom event
   */
  handleSuccess(event) {
    this.showLoader = false;
    this._createZDHCFormulator(event.detail.recordId);
  }

  /**
   * handles the c-form cmp catching an error when inserting the Formulator__c record
   * @param {object} event - error custom event
   */
  handleError(event) {
    this._showToastNotification(
      this.labels.ERROR,
      this.labels.TC_OBJECT_NAMED_UPDATE_ERROR_WITH_MESSAGE.replace(
        "{0} {1} ",
        "The Formulator"
      ).replace("{2}", event.detail.message),
      "error"
    );
  }

  /**
   * handles the user choosing to cancel the create process
   */
  handleCancel() {
    this.dispatchEvent(new CustomEvent("cancelcreateformulator"));
  }

  //INTERNAL FUNCTIONS

  async _createZDHCFormulator(formulatorId) {
    try {
      const formulator = await createZDHCFormulator({
        userAccessKey: this._userAccessKey.data,
        formulatorId: formulatorId
      });
      this.dispatchEvent(
        new CustomEvent("createdformulator", {
          detail: formulator,
          bubbles: true,
          composed: true
        })
      );
    } catch (error) {
      this._showToastNotification(
        label.ERROR,
        format(label.ZDHC_FORMULATOR_NOT_CREATED, error.body.message),
        "error"
      );
    }
  }

  /**
   * handles a caught exception and notifies the user
   * @param {object} error - exception caught when communicating with the server
   */
  _handleError(error) {
    let errorMessage;
    if (Array.isArray(error.body)) {
      errorMessage = error.body.map((e) => e.message).join(", ");
    } else if (typeof error.body.message === "string") {
      errorMessage = error.body.message;
    }
    this._showToastNotification(
      this.labels.ERROR,
      this.labels.TC_OBJECT_NAMED_UPDATE_ERROR_WITH_MESSAGE.replace(
        "{0} {1} ",
        "Formulator"
      ).replace("{2}", errorMessage),
      "error"
    );
    this.showLoader = false;
  }

  /**
   * displays a toast notification to the user
   * @param {string} title - title for the notification
   * @param {string} message - core message of the notification
   * @param {string} variant - type of message shown (success / info / warning / error)
   */
  _showToastNotification(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }
}