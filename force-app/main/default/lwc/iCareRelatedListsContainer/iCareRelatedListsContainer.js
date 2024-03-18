import { LightningElement, api, wire, track } from "lwc";

import INSPECTION from '@salesforce/label/c.GTS_Inspection_Label';
import HISTORY from '@salesforce/label/c.GTS_History';
import SHIPMENT from '@salesforce/label/c.GTS_Shipment';
import SUPPORTING_DOC from '@salesforce/label/c.GTS_Supporting_Documents_Title';

import apexIsRegistrationJob from "@salesforce/apex/GTSJobHistoryController.isRegistrationJob";

export default class ICareRelatedListsContainer extends LightningElement {
  @api recordId;
  @api accountId;
  @api showInspection;
  @api showShipment;
  @api showSupportingDocs;
  @api showHistory;


    labels = {
        INSPECTION,
        HISTORY,
        SHIPMENT,
        SUPPORTING_DOC
    }

  @wire(apexIsRegistrationJob, { jobId: '$recordId' })
  isRegistration;

  get checkIsRegistration(){
      return this.isRegistration.data;
  }
}