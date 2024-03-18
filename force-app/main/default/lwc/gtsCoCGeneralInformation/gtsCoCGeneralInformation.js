import { LightningElement,api, track, wire } from 'lwc';
import APPLICANT_TYPE from '@salesforce/label/c.GTS_Applicant_Type';
import AUTHORIZED from '@salesforce/label/c.GTS_Authorized_Dealer';
import CLIENT_REFERENCE from '@salesforce/label/c.GTS_Client_Reference';
import GENERAL_INFO from '@salesforce/label/c.GTS_General_Information';
import SEARCH_CERTIFICATE from '@salesforce/label/c.GTS_Search_Certificate';
import SHIPMENT_CERTIFICATE from '@salesforce/label/c.GTS_Shipment_Certificate_Request';


import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import PICKLIST_APPLICANT_TYPE from '@salesforce/schema/icare_Job_Request__c.GTS_Applicant_Type__c';


export default class GtsCoCGeneralInformation extends LightningElement {
    @api isReadOnly = false;
    @api jobRequestRecord;
    @api accountId;
    @api isApplicantTypePopulated;

    @api certificate;

    @api isRequired = false;

    certificateValue;
    certificateLabel;
    applicantTypeOption;
    clientReference;

    get programFilters(){
        return JSON.stringify({'GTS_Active__c' : true, 'GTS_Associated_Form_Type__c' : 'CoC'});
    };

    get isApplicantTypeReadOnly(){
        return (this.isApplicantTypePopulated || this.isReadOnly);
    };

    connectedCallback(){
        this.certificateValue = this.jobRequestRecord.GTS_Program__c;
        this.certificateLabel = this.jobRequestRecord.ProgramName;
        this.applicantTypeOption = this.jobRequestRecord.GTS_Applicant_Type__c;
        this.clientReference = this.jobRequestRecord.GTS_Client_Reference__c;
    }

    labels = {
        APPLICANT_TYPE,
        AUTHORIZED,
        CLIENT_REFERENCE,
        GENERAL_INFO,
        SEARCH_CERTIFICATE,
        SHIPMENT_CERTIFICATE
    }

    options = [];
    @wire(getPicklistValues, {
        recordTypeId: '$jobRequestRecord.RecordTypeId',
        fieldApiName: PICKLIST_APPLICANT_TYPE
    })
    getPicklistValuesForField({ data, error }) {
          if (error) {
            // TODO: Error handling
            console.error('error');
          } else if (data) {
            this.options = [...data.values]
          }
    }

    handleApplicantTypeChange(event){
        this.applicantTypeOption = event.detail.value;
        this.handleDispatchEvent();
    }

    handleClientReferenceChange(event){
        this.clientReference = event.target.value;
        this.handleDispatchEvent();
    }

    handleCertificateSelection(event){
        this.certificateValue = (event.detail.selectedRecord.Id != undefined) ? event.detail.selectedRecord.Id : '';
        this.certificateLabel = (event.detail.selectedName != undefined) ? event.detail.selectedName : '';
        this.handleDispatchEvent();
    }

    handleDispatchEvent(){
        const generalInfoChanged = new CustomEvent("generalinfochanged", {
            detail : {
                certificate : this.certificateValue,
                certificateLabel : this.certificateLabel,
                applicantType : this.applicantTypeOption,
                clientReference : this.clientReference
            }
        });
        this.dispatchEvent(generalInfoChanged);
    }
}