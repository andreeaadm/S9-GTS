import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
//import { label } from 'c/labelService';

import STANDARDS_FIELD from "@salesforce/schema/Asset.Standards__c";
import assetExpiryBanner from "@salesforce/apex/AssetExpiryBannerController.assetExpirystatus"; /*Prateek*/

const fields = [STANDARDS_FIELD];

export default class ReportStandardsTile extends LightningElement {
  @api recordId;
  @api additionalClasses = "greytile";
  @track hasLoaded = false;
  @track isEmpty = true;
  @track standardRows = [];
  @api booleanExpiry; //Prateek
  @wire(assetExpiryBanner, { recordId: "$recordId"})
  wiredExpiryStatus({ error, data }) {
    if (data) {
      console.log('Report debug',data);
      this.booleanExpiry = data;
    }
  }
  @wire(getRecord, { recordId: "$recordId", fields })
  wiredAsset({ error, data }) {
    if (data) {
      var standards = getFieldValue(data, STANDARDS_FIELD);
      if (standards && !/^\s*$/.test(standards)) {
        var standardRows = standards.split(/\r?\n/);

        this.isEmpty = !(standardRows.length && standardRows.length > 0);
        this.standardRows = standardRows;
        this.hasLoaded = true;
        this.error = undefined;
      }
    } else if (error) {
      this.error = error;
      this.standardRows = [];
      this.isEmpty = true;
      this.hasLoaded = true;
    }
  }
}