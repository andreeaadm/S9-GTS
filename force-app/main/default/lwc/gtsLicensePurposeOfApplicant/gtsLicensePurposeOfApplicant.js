import { LightningElement, api, wire } from 'lwc';

import APPLICATION_TYPE from '@salesforce/label/c.GTS_Type_of_Application';
import IF_OTHER_TEXT from '@salesforce/label/c.GTS_If_Other';
import PURPOSE_APPLICATION from '@salesforce/label/c.GTS_Purpose_of_Application';
import SHIPMENT_CERTIFICATE from '@salesforce/label/c.GTS_Shipment_Certificate_Request';

import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import PICKLIST_APPLICATION_TYPE from '@salesforce/schema/icare_Job_Request__c.GTS_Type_of_Application__c';

export default class GtsLicensePurposeOfApplicant extends LightningElement {
    @api isReadOnly = false;
    @api jobRequestRecord;
    @api applicationTypeValue;
    @api otherTextValue;
    @api isRequired;

    @api certificate;

    certificateValue;
    certificateLabel;

    labels = {
        APPLICATION_TYPE,
        IF_OTHER_TEXT,
        PURPOSE_APPLICATION,
        SHIPMENT_CERTIFICATE
    }

    get programFilters(){
        return JSON.stringify({'GTS_Active__c' : true, 'GTS_Associated_Form_Type__c' : 'RLC'});
    };

    get applicationTypeOption(){
        return this.applicationTypeValue;
    }

    get showOtherText(){
        return this.applicationTypeValue == 'Other (please specify)';
    }

    options = [];
    @wire(getPicklistValues, {
        recordTypeId: '$jobRequestRecord.RecordTypeId',
        fieldApiName: PICKLIST_APPLICATION_TYPE
    })
    getPicklistValuesForField({ data, error }) {
          if (error) {
            console.error(error);
          } else if (data) {
            this.options = [...data.values]
          }
    }

    connectedCallback(){
        this.certificateValue = this.jobRequestRecord.GTS_Program__c;
        this.certificateLabel = this.jobRequestRecord.ProgramName;
    }

    handleCertificateSelection(event){
        this.certificateValue = (event.detail.selectedRecord.Id != undefined) ? event.detail.selectedRecord.Id : '';
        this.certificateLabel = (event.detail.selectedName != undefined) ? event.detail.selectedName : '';
        this.handleDispatchEvent();
    }

    handleApplicantTypeChange(event){
        this.applicationTypeValue = event.detail.value;
        this.otherTextValue = '';
        this.handleDispatchEvent();
    }

    handleOtherTextChanged(event){
        this.otherTextValue = event.detail.value;
        this.handleDispatchEvent();
    }

    handleDispatchEvent(){
        const purposeOfApplicationChanged = new CustomEvent("purposeofapplicationchanged", {
            detail : {
                certificate : this.certificateValue,
                certificateLabel : this.certificateLabel,
                typeOfApplication : this.applicationTypeValue,
                otherText : this.otherTextValue
            }
        });
        this.dispatchEvent(purposeOfApplicationChanged);
    }

}