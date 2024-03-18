import { LightningElement, api, wire } from 'lwc';

import JOB_INFO from '@salesforce/label/c.GTS_Job_Information';
import EXPORTER from '@salesforce/label/c.GTS_Exporter';
import PAYER from '@salesforce/label/c.GTS_Payer';
import { getObjectInfo } from "lightning/uiObjectInfoApi";

export default class GtsLicenseApplicant extends LightningElement {
    @api isReadOnly;
    @api jobRequestRecord;
    @api isRequired;
    exporterDetails;
    payerDetails;

    labels = {
        EXPORTER,
        JOB_INFO,
        PAYER
    }

    get payerFieldsFiltering(){
        return JSON.stringify({'GTS_Account__c' : this.jobRequestRecord.iCare_Applicant_Company__c, 'GTS_Role__c' : 'Payer' });
    };

    handleUpdateExporterInfo(event){
        this.exporterDetails = event.detail;
        this.dispatchChangeDataEvent();
    }

    handleUpdatePayerInfo(event){
        this.payerDetails = event.detail;
        this.dispatchChangeDataEvent();
    }

    dispatchChangeDataEvent() {
        const oEvent = new CustomEvent('updateapplicantpage',
            {
                detail: {
                    exporterDetails : this.exporterDetails,
                    payerDetails : this.payerDetails,
                 }
            }
        );

        this.dispatchEvent(oEvent);
    }

    accountRecordType;
    @wire(getObjectInfo, { objectApiName: 'Account' })
    objectInfoWire({ error, data }) {
      if (data) {
        let recordTypeInfos = data.recordTypeInfos;
        this.accountRecordType = Object.keys(recordTypeInfos).find(
                    (rti) => recordTypeInfos[rti].name === 'GMA Customer'
        );
        this.showSpinner = false;
      } else if (error) {
        console.error("Error getting object info", error);
      }
    }
}