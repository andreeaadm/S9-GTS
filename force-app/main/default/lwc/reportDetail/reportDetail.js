import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import ASSET_OBJECT from "@salesforce/schema/Asset";
import ID_FIELD from "@salesforce/schema/Asset.Id";
import NAME_FIELD from "@salesforce/schema/Asset.Name";
import HIDDEN_BY_ITK_FIELD from "@salesforce/schema/Asset.Is_Hidden_By_Intertek__c";
import REFERENCE_FIELD from "@salesforce/schema/Asset.Client_Reference__c";
import assetExpiryBanner from "@salesforce/apex/AssetExpiryBannerController.assetExpirystatus"; /*Prateek*/

export default class ReportDetail extends LightningElement {
  @api recordId;
  @track isWorking = false;
  @track editMode = false;
  nameField = NAME_FIELD;
  referenceField = REFERENCE_FIELD;
  @api booleanExpiry; //Prateek

  @wire(getObjectInfo, { objectApiName: ASSET_OBJECT })
  assetObject;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [NAME_FIELD, REFERENCE_FIELD, HIDDEN_BY_ITK_FIELD]
  })
  asset;

  /*Prateek*/
  
  @wire(assetExpiryBanner, { recordId: "$recordId"})
  wiredExpiryStatus({ error, data }) {
    if (data) {
      this.booleanExpiry = data;
    }
  }

  get isHiddenByITK() {
    return getFieldValue(this.asset.data, HIDDEN_BY_ITK_FIELD);
  }

  get isUpdateable() {
    return this.assetObject?.data?.updateable;
  }

  get name() {
    return getFieldValue(this.asset.data, NAME_FIELD);
  }

  get reference() {
    return getFieldValue(this.asset.data, REFERENCE_FIELD);
  }

  toggleIsWorking() {
    this.isWorking = !this.isWorking;
  }

  toggleEdit() {
    this.editMode = !this.editMode;
  }

  handleUpdateReport() {
    if (this.validateInputs()) {
      this.toggleIsWorking();
      const fields = {};
      fields[ID_FIELD.fieldApiName] = this.recordId;
      for (let input of this.template.querySelectorAll("c-input")) {
        if (input.fieldId) {
          fields[input.fieldId] = input.value;
        }
      }
      const recordInput = { fields };
      updateRecord(recordInput)
        .then((result) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: "Your changes have been saved",
              variant: "success"
            })
          );
          this.toggleEdit();
          this.toggleIsWorking();
        })
        .catch((error) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: "Please contact an administrator",
              variant: "error"
            })
          );
          this.toggleIsWorking();
        });
    }
  }

  validateInputs() {
    let isValid = true;
    this.template.querySelectorAll("c-input").forEach((input) => {
      if (!input.validate().isValid) {
        isValid = false;
      }
    });
    return isValid;
  }
}