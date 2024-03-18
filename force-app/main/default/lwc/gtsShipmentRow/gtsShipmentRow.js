import { LightningElement, api, wire } from "lwc";

import DOWNLOAD from '@salesforce/label/c.GTS_Certificate_Download';
import TIMEZONE from "@salesforce/i18n/timeZone";
import CERTIFICATE_NUMBER from '@salesforce/label/c.GTS_Certificate_Number';
import COMMERCIAL_INVOICE from '@salesforce/label/c.GTS_Commercial_Invoice';
import DATE_ISSUED from '@salesforce/label/c.GTS_Date_Issued';
import LINK from '@salesforce/label/c.GTS_Link';
import NAME from '@salesforce/label/c.iCare_Name';
import RECEIVED_DATE from '@salesforce/label/c.GTS_Received_Date';
import SHIPMENT_DOC from '@salesforce/label/c.GTS_Shipment_Documents';
import STATUS from '@salesforce/label/c.GTS_Status';

import apexGetCertificate from "@salesforce/apex/GTSFileDownloadController.getCertificate";
import apexGetShipments from "@salesforce/apex/GTSShipmentTableController.getShipments";


const columns = [
  {
    label: NAME,
    fieldName: "Name",
    type: "text",
    hideDefaultActions: "false",
    wrapText: true
  },
  {
    label: COMMERCIAL_INVOICE,
    fieldName: "GTS_Commercial_Invoice__c",
    type: "text",
    hideDefaultActions: "false",
    wrapText: true
  },
  {
    label: STATUS,
    fieldName: "GTS_Status__c",
    type: "text",
    hideDefaultActions: "false",
    wrapText: true
  },
  {
    label: RECEIVED_DATE,
    fieldName: "GTS_Received_Date__c",
    type: "date",
    hideDefaultActions: "false",
    typeAttributes: {
      day: "numeric",
      month: "numeric",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: TIMEZONE
    }
  },
  {
    label: CERTIFICATE_NUMBER,
    fieldName: "GTS_Certificate_Reference__c",
    type: "text",
    hideDefaultActions: "false",
    wrapText: true
  },
  {
    label: DATE_ISSUED,
    fieldName: "GTS_Date_Issued__c",
    type: "date",
    hideDefaultActions: "false",
    typeAttributes: {
      day: "numeric",
      month: "numeric",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: TIMEZONE
    },
    sortable: true
  },
  { label: LINK, fieldName: 'certificateLink', type: 'url', typeAttributes: { label: DOWNLOAD}, hideDefaultActions: "false" },

];

export default class ICareInspectionRow extends LightningElement {
  columns = columns;
  defaultSortDirection = 'desc';
  @api sortDirection;
  @api record;
  records;
  sortedBy = 'GTS_Date_Issued__c';
  certificateLink;

  labels = {
      SHIPMENT_DOC
  }

  get checkRecords(){
      return this.records != undefined;
  }
  connectedCallback() {
    this.getCertificateLink();
  }

   async getCertificateLink(){
        await apexGetCertificate({recordId: this.record.Id})
            .then(result => {
                // Handle the result from Apex
                this.sfdcBaseURL = window.location.origin;
                if(result.length > 0){
                  let urlResult = result.substring(1, result.length - 1);
                  this.certificateLink = (this.sfdcBaseURL + urlResult);
                }else{
                    this.certificateLink =  '';
                }
            })
            .catch(error => {
                // Handle the error from Apex
                console.error('Error from Apex:', error);
            });

            if(this.certificateLink != undefined && this.certificateLink.length > 0){
                 this.records = [{
                     ...this.record,
                     certificateLink : this.certificateLink
                 }];
            }else{
                 this.records = [this.record];
            }
  }

  onHandleSort(event) {
   let sortDirection = event.detail.sortDirection;
   this.dispatchDataSort(sortDirection);
  }

 dispatchDataSort(sortDirection) {
  const oEvent = new CustomEvent('sortrecords',
    {
      detail: {
        sortDirection : sortDirection
      }
    }
  );
  this.dispatchEvent(oEvent);
 }

}