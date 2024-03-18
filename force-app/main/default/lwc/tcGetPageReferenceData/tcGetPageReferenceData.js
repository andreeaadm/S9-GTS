import { LightningElement, api, wire } from "lwc";
import { getRecord, getRecordUi } from "lightning/uiRecordApi";
import { CurrentPageReference } from "lightning/navigation";

export default class TcGetPageReferenceData extends LightningElement {
  //PUBLIC PROPERTIES
  /**
   * if true then the cmp will use LDS to retrieve additional sObject data
   */
  @api getRecordData;
  /**
   * string or an array of sObject field API names for the requested object or related fields accessible through sObject relationships
   */
  @api fields;

  //INTERNAL PROPERTIES
  _recordIdForRecordUi;
  _recordId;
  _fieldsToQuery = [];

  //LIGHTNING DATA SERVICE
  /**
   * retrieves the page state from the url
   */
  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      let pageState = currentPageReference.state;
      if (this.getRecordData && this.fields) {
        this._recordIdForRecordUi = pageState.recordId;
      }
      this.dispatchEvent(
        new CustomEvent("retrievedstate", { detail: pageState })
      );
    }
  }

  /**
   * gets the object metadata for the record Id retrieved from the state
   */
  @wire(getRecordUi, {
    recordIds: "$_recordIdForRecordUi",
    layoutTypes: "Compact",
    modes: "View"
  })
  wiredRecordUi({ error, data }) {
    if (data) {
      let objectName = data.records[this._recordIdForRecordUi].apiName;
      this._formatFieldsForDataService(objectName);
    } else if (error) {
      this._handleWireError(error);
    }
  }

  /**
   * gets sObject record if requested by the wrapping component
   */
  @wire(getRecord, {
    recordId: "$_recordId",
    fields: "$_fieldsToQuery"
  })
  wiredRecord({ error, data }) {
    if (data) {
      this.dispatchEvent(new CustomEvent("retrievedrecord", { detail: data }));
    } else if (error) {
      this._handleWireError(error);
    }
  }

  //INTERNAL FUNCTIONS
  /**
   * format the field names with the object
   * @param {string} sObjectName - API name of the sObject to be queried by LDS
   */
  _formatFieldsForDataService(sObjectName) {
    if (this.fields) {
      if (this.fields instanceof Array) {
        this.fields.forEach((field) => {
          this._fieldsToQuery.push(sObjectName + "." + field);
        });
      } else this._fieldsToQuery.push(sObjectName + "." + this.fields);
      this._recordId = this._recordIdForRecordUi;
    }
  }

  /**
   * processes an error and notifies the wrapper cmp
   * @param {string | array} error - exception returned from the LDS wire service
   */
  _handleWireError(error) {
    console.error(error);
    let errorMsg = "Unknown error";
    if (Array.isArray(error.body)) {
      errorMsg = error.body.map((e) => e.message).join(", ");
    } else if (typeof error.body.message === "string") {
      errorMsg = error.body.message;
    }
    this.dispatchEvent(new CustomEvent("error", { detail: errorMsg }));
  }
}