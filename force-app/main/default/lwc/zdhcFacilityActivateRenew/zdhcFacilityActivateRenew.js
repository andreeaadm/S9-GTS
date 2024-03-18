import { LightningElement, api, wire } from "lwc";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import getUserAccessKey from "@salesforce/apex/ZDHCGatewayService.getUserAccessKey";
import makeCallout from "@salesforce/apex/ZDHCGatewayService.makeCallout";
import updateInCheckSubscriptionDate from "@salesforce/apex/ZDHCGatewayService.updateInCheckSubscriptionDate";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label } from "c/labelService";
import toxLogo from "@salesforce/resourceUrl/toxLogo";

export default class ZdhcFacilityActivateRenew extends LightningElement {
  //PUBLIC PROPERTIES
  @api recordId;

  //TEMPLATE PROPERTIES
  labels = label;
  noFacilityManager;
  noUserAccessKey;
  noPrerequisites;
  noOrgGUID;
  noToxSubscription;
  canActivate;
  canRenew;

  //INTERNAL PROPERTIES
  _getRecordFields = [];
  _facilityManagerId;
  _orgGuid;
  _expirationDate;
  _userAccessKey;
  _subscriptionDate;

  //GETTERS & SETTERS
  /**
   * required by LWC - not used
   */
  get getRecordFields() {
    return this._getRecordFields;
  }

  /**
   * provides the record fields to be queried by getRecords Lightning Data Service
   */
  @api
  set getRecordFields(value) {
    this._getRecordFields.push(value);
  }

  //LIGHTNING DATA SERVICE
  /**
   * gets the specified sObject data to check if there is a valid Faciliy Manager to use with ZDHC
   */
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "Account.ZDHC_Organisation_GUID__c",
      "Account.InCheck_Subscription_Expiration_Date__c",
      "Account.InCheck_Status__c",
      "Account.ToxClear_Subscription_Status__c",
      "Account.Facility_Manager__c"
    ]
  })
  wiredRecord({ error, data }) {
    this._resetProps();
    if (data) {
      if (data.fields.Facility_Manager__c.value != null) {
        this._facilityManagerId = data.fields.Facility_Manager__c.value;
      } else if (this.noPrerequisites == false) {
        this.noFacilityManager = this.noPrerequisites = true;
      }

      if (data.fields.ZDHC_Organisation_GUID__c.value != null) {
        this._orgGuid = data.fields.ZDHC_Organisation_GUID__c.value;
      } else if (this.noPrerequisites == false) {
        this.noOrgGUID = this.noPrerequisites = true;
      }

      if (data.fields.ToxClear_Subscription_Status__c.value == "Active") {
        this.noToxSubscription = false;
      } else if (this.noPrerequisites == false) {
        this.noToxSubscription = this.noPrerequisites = true;
      }

      if (
        data.fields.ToxClear_Subscription_Status__c.value == "Active" &&
        data.fields.ZDHC_Organisation_GUID__c.value != null &&
        !this.noFacilityManager
      ) {
        if (
          data.fields.InCheck_Subscription_Expiration_Date__c.value != null &&
          data.fields.InCheck_Subscription_Expiration_Date__c.value != ""
        ) {
          this._expirationDate = data.fields.InCheck_Subscription_Expiration_Date__c.value;
          this._subscriptionDate =
            data.fields.InCheck_Subscription_Expiration_Date__c.value;
                      
          if(new Date(this._subscriptionDate).getDate() == 1 &&
            new Date(this._subscriptionDate).getMonth() == 0 &&
            new Date(this._subscriptionDate).getFullYear() == 1901
          ) {
            this.canActivate = true;
          } else {
            this.canRenew = true;
          }
        } else {
          this.canActivate = true;
        }
      }
    } else if (error) {
      console.error(error);
      this.dispatchEvent(
        new CustomEvent("error", { detail: this.labels.FACILITY_ERROR })
      );
    }
  }

  /**
   * calls the server to retrieve the UserAccessKey for accessing ZDHC
   */
  @wire(getUserAccessKey, {
    recordId: "$_facilityManagerId"
  })
  wiredAccessKey({ error, data }) {
    if (error) {
      console.error(error);
      if (
        error.body &&
        error.body.message &&
        error.body.message === this.labels.NO_USER_FOUND
      ) {
        this.noUserAccessKey = this.noPrerequisites = true;
        this.noOrgGUID = this.noToxSubscription = false;
      } else {
        this.dispatchEvent(
          new CustomEvent("error", {
            detail: this.labels.FACILITY_MANAGER_ERROR
          })
        );
      }
    } else if (data) {
      this._userAccessKey = data;
    } else {
      this.noUserAccessKey = this.noPrerequisites = true;
      this.noOrgGUID = this.noToxSubscription = false;
    }
  }

  //INTERNAL FUNCTIONS
  /**
   * resets the cmp props after each time the wire service is called so the cmp displays correctly
   */
  _resetProps() {
    this.noFacilityManager =
      this.noUserAccessKey =
      this.noOrgGUID =
      this.canActivate =
      this.canRenew =
      this.noPrerequisites =
        false;
    this.dispatchEvent(new CustomEvent("resetcmp"));
  }

  /**
   * Sends the callout to Activate the InCheck subscription for this facility
   */
  activateFacility() {
    makeCallout({
      zdhcRequest: {
        apiName: "activateInCheckSubscription",
        method: "POST",
        userAccessKey: this._userAccessKey,
        queryParams: {
          organizationGUID: this._orgGuid
        }
      }
    })
      .then((response) => {
        if (response.isSuccess && response.response.result.success) {
          let messageStringSplit = response.response.Message.split(" ");
          let dateString =
            messageStringSplit[messageStringSplit.length - 1] == ""
              ? messageStringSplit[messageStringSplit.length - 2]
              : messageStringSplit[messageStringSplit.length - 1];
          this.updateSubscriptionDate(dateString);
        } else if (!response.isSuccess || !response.response.result.success) {
          this._showToastNotification(
            this.labels.ERROR,
            this.labels.ZDHC_ACTIVATE_ERROR,
            "error"
          );
        }
      })
      .catch((error) => {
        console.error(error);
        this._showToastNotification(
          this.labels.ERROR,
          this.labels.ZDHC_ACTIVATE_ERROR,
          "error"
        );
      });
  }

  /**
   * Sends the callout to Renew the InCheck subscription for this facility
   */
  renewFacility() {
    makeCallout({
      zdhcRequest: {
        apiName: "renewInCheckSubscription",
        method: "POST",
        userAccessKey: this._userAccessKey,
        queryParams: {
          OrgGUID: this._orgGuid,
          expirationDate: this._expirationDate
        }
      }
    })
      .then((response) => {
        if (response.isSuccess && response.response.result.success) {
          let messageStringSplit = response.response.result.Message.split(" ");
          let dateString =
            messageStringSplit[messageStringSplit.length - 1] == ""
              ? messageStringSplit[messageStringSplit.length - 2]
              : messageStringSplit[messageStringSplit.length - 1];
          this.updateSubscriptionDate(dateString);
        } else if (!response.isSuccess || !response.response.result.success) {
          this._showToastNotification(
            this.labels.ERROR,
            response.response.result.Message,
            "error"
          );
        }
      })
      .catch((error) => {
        console.error(error);
        this._showToastNotification(
          this.labels.ERROR,
          response.response.result.Message,
          "error"
        );
      });
  }

  updateSubscriptionDate(dateString) {
    updateInCheckSubscriptionDate({
      recordId: this.recordId,
      dateString: dateString
    })
      .then((result) => {
        if (result == "success") {
          this._showToastNotification(
            this.labels.SUCCESS,
            this.labels.ZDHC_UPDATE_SUB_DATE_SUCCESS,
            "success"
          );
        } else {
          console.error(result);
          this._showToastNotification(
            this.labels.ERROR,
            this.labels.ZDHC_UPDATE_SUB_DATE_ERROR,
            "error"
          );
        }
      })
      .catch((error) => {
        console.error(error);
        this._showToastNotification(
          this.labels.ERROR,
          this.labels.ZDHC_UPDATE_SUB_DATE_ERROR,
          "error"
        );
      });
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