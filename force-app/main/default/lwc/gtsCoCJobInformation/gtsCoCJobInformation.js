import { LightningElement,api, wire } from 'lwc';
import EXPORTER from '@salesforce/label/c.GTS_Exporter';
import JOB_INFO from '@salesforce/label/c.GTS_Job_Information';
import IMPORTER from '@salesforce/label/c.GTS_Importer';
import INSPECTION from '@salesforce/label/c.GTS_Inspection_Location';
import PAYER from '@salesforce/label/c.GTS_Payer';

import { getObjectInfo } from "lightning/uiObjectInfoApi";

import INVIEW_REQUESTED_LABEL from "@salesforce/label/c.GTS_Inview_Requested_Label";
import INVIEW_REQUESTED_TITLE1 from "@salesforce/label/c.GTS_Inview_Requested_Title1";
import INVIEW_REQUESTED_TITLE2 from "@salesforce/label/c.GTS_Inview_Requested_Title2";
import INVIEW_TECHNOLOGY_LINK from "@salesforce/label/c.GTS_Inview_Technology_Link";

export default class GtsCoCJobInformation extends LightningElement {
       @api isReadOnly = false;
       @api isRequired = false;
       showSpinner = true;
        labels = {
            EXPORTER,
            JOB_INFO,
            IMPORTER,
            INSPECTION,
            PAYER,
            INVIEW_REQUESTED_LABEL,
            INVIEW_REQUESTED_TITLE1,
            INVIEW_REQUESTED_TITLE2,
            INVIEW_TECHNOLOGY_LINK
        }

    @api jobRequestRecord;
    inviewRequested = false;

    get importerFieldsFiltering(){
        return JSON.stringify({'GTS_Account__c' : this.jobRequestRecord.iCare_Applicant_Company__c, 'GTS_Role__c' : 'Importer' });
    };

    get inspectionLocationFieldsFiltering(){
        return JSON.stringify({'GTS_Account__c' : this.jobRequestRecord.iCare_Applicant_Company__c, 'GTS_Role__c' : 'InspectionLocation' });
    };

    get payerFieldsFiltering(){
        return JSON.stringify({'GTS_Account__c' : this.jobRequestRecord.iCare_Applicant_Company__c, 'GTS_Role__c' : 'Payer' });
    };


    exporterDetails;
    importerDetails;
    payerDetails;
    inspectionLocationDetails;

    handleUpdateExporterInfo(event){
        this.exporterDetails = event.detail;
        this.dispatchChangeDataEvent();
    }

    handleUpdateImporterInfo(event){
        this.importerDetails = event.detail;
        this.dispatchChangeDataEvent();
    }

    handleUpdateInspectionInfo(event){
        this.inspectionLocationDetails = event.detail;
        this.dispatchChangeDataEvent();
    }
    handleUpdatePayerInfo(event){
        this.payerDetails = event.detail;
        this.dispatchChangeDataEvent();
    }
    handleInviewRequestedChange(event) {
        this.inviewRequested = event.target.checked;
        this.dispatchChangeDataEvent();
    }

    dispatchChangeDataEvent() {
        const oEvent = new CustomEvent('updateapplicantpage',
            {
                detail: {
                    exporterDetails : this.exporterDetails,
                    importerDetails : this.importerDetails,
                    inspectionLocationDetails : this.inspectionLocationDetails,
                    payerDetails : this.payerDetails,
                    inviewRequested : this.inviewRequested
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