import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import getUserAccessKey from "@salesforce/apex/ZDHCGatewayService.getUserAccessKey";
import { label } from "c/labelService";

export default class ZdhcFacilityManagerChecks extends LightningElement {
  //PUBLIC PROPERTIES
  @api recordId;
  @api noFacilityManagerLabel;
  @api noUserAccessKeyLabel;

  //TEMPLATE PROPERTIES
  labels = label;
  noFacilityManager;
  noUserAccessKey;
  noPrerequisites;

  //INTERNAL PROPERTIES
  _getRecordFields = [];
  _facilityManagerId;

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
    fields: "$_getRecordFields"
  })
  wiredRecord({ error, data }) {
    this._resetProps();
    if (data) {
      this._facilityManagerId = undefined;
      let fieldsProvided = this._getRecordFields[0].split(".");
      fieldsProvided.shift();
      let fields = data.fields;
      for (let i = 0; i < fieldsProvided.length; i++) {
        if (
          fields[fieldsProvided[i]] &&
          fields[fieldsProvided[i]].value &&
          fields[fieldsProvided[i]].value != null
        ) {
          let field = fields[fieldsProvided[i]];
          fields =
            field.value && field.value.fields
              ? field.value.fields
              : field.value;
        }
      }
      if (!(fields instanceof Object)) {
        this._facilityManagerId = fields;
      }
      if (this._facilityManagerId == null) {
        this.noFacilityManager = this.noPrerequisites = true;
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
      } else {
        this.dispatchEvent(
          new CustomEvent("error", {
            detail: this.labels.FACILITY_MANAGER_ERROR
          })
        );
      }
    } else if (data) {
      this.dispatchEvent(
        new CustomEvent("founduseraccesskey", { detail: data })
      );
    } else {
      this.noUserAccessKey = this.noPrerequisites = true;
    }
  }

  //INTERNAL FUNCTIONS
  /**
   * resets the cmp props after each time the wire service is called so the cmp displays correctly
   */
  _resetProps() {
    this.noFacilityManager =
      this.noUserAccessKey =
      this.noPrerequisites =
        false;
    this.dispatchEvent(new CustomEvent("resetcmp"));
  }
}