import { LightningElement, wire, track, api } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

import REGULATION_PRODUCT_FIELD from '@salesforce/schema/Regulation__c.Product__c';
import REGULATION_ADDITIONAL_PRODUCT_FIELD from '@salesforce/schema/Regulation__c.Additional_Product__c';
import REGULATION_AUXILIARY_PRODUCT_FIELD from '@salesforce/schema/Regulation__c.Auxiliary_Product__c';
import REGULATION_ANCILLARY_PRODUCT_FIELD from '@salesforce/schema/Regulation__c.Ancillary_Product__c';
import REGULATION_EXTRA_PRODUCT_FIELD from '@salesforce/schema/Regulation__c.Extra_Product__c';
import REGULATION_ID_FIELD from '@salesforce/schema/Regulation__c.Id';

import TESTITEM_PRODUCT_FIELD from '@salesforce/schema/Test_Item__c.Product__c';
import TESTITEM_ADDITIONAL_PRODUCT_FIELD from '@salesforce/schema/Test_Item__c.Additional_Product__c';
import TESTITEM_AUXILIARY_PRODUCT_FIELD from '@salesforce/schema/Test_Item__c.Auxiliary_Product__c';
import TESTITEM_ANCILLARY_PRODUCT_FIELD from '@salesforce/schema/Test_Item__c.Ancillary_Product__c';
import TESTITEM_EXTRA_PRODUCT_FIELD from '@salesforce/schema/Test_Item__c.Extra_Product__c';
import TESTITEM_ID_FIELD from '@salesforce/schema/Test_Item__c.Id';

import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProductMultiPicklistHandler extends LightningElement {    
    buttonsDisabled = false;
    renderingCompleted = false;
    initLoadComplete = false;
    @api recordId;
    @api objectApiName;
    @track fields;

    @track listOptions = [];

    @track selectedOptions = [];
    ID_FIELD;
    PRODUCT_FIELD;
    ADDITIONAL_PRODUCT_FIELD;
    AUXILIARY_PRODUCT_FIELD;
    ANCILLARY_PRODUCT_FIELD;
    EXTRA_PRODUCT_FIELD;

    @wire(getRecord, { recordId: '$recordId', fields: '$fields'})
    parseSelectedValues(data, error) {
        if(data && data.data && !this.initLoadComplete){
            this.initLoadComplete = true;
            let selectedValuesAsString = getFieldValue(data.data, this.PRODUCT_FIELD);
            let additionalSelectedValuesAsString = getFieldValue(data.data, this.ADDITIONAL_PRODUCT_FIELD);
            let auxSelectedValuesAsString = getFieldValue(data.data, this.AUXILIARY_PRODUCT_FIELD);
            let ancSelectedValuesAsString = getFieldValue(data.data, this.ANCILLARY_PRODUCT_FIELD);
            let extraSelectedValuesAsString = getFieldValue(data.data, this.EXTRA_PRODUCT_FIELD);
            this.selectedOptions = selectedValuesAsString.split(';');

            if (additionalSelectedValuesAsString !=null && additionalSelectedValuesAsString.length>0) {
                this.selectedOptions = this.selectedOptions.concat(additionalSelectedValuesAsString.split(';'));
            }
            if (auxSelectedValuesAsString !=null && auxSelectedValuesAsString.length>0) {
                this.selectedOptions = this.selectedOptions.concat(auxSelectedValuesAsString.split(';'));
            }
            if (ancSelectedValuesAsString !=null && ancSelectedValuesAsString.length>0) {
                this.selectedOptions = this.selectedOptions.concat(ancSelectedValuesAsString.split(';'));
            }
            if (extraSelectedValuesAsString !=null && extraSelectedValuesAsString.length>0) {
                this.selectedOptions = this.selectedOptions.concat(extraSelectedValuesAsString.split(';'));
            }
            
        } else if (error) {
            console.log('Error parsing record info', error);
        }
    }

    @wire (getObjectInfo, {objectApiName: '$objectApiName'})
    objInfo;

    @wire(getPicklistValues, {recordTypeId: '$objInfo.data.defaultRecordTypeId', fieldApiName: '$PRODUCT_FIELD' })
    products(data, error){
        if(data && data.data && data.data.values){
            data.data.values.forEach( objPicklist => {
                this.listOptions.push({
                    label: objPicklist.label,
                    value: objPicklist.value
                });
            });
            this.renderingCompleted = true;
        } else if(error){
            console.log('Error getting picklist values', error);
        }
    };

    connectedCallback() {
        setTimeout(() => {
            if (this.objectApiName === 'Regulation__c') {
                this.ID_FIELD = REGULATION_ID_FIELD;
                this.PRODUCT_FIELD = REGULATION_PRODUCT_FIELD;
                this.ADDITIONAL_PRODUCT_FIELD = REGULATION_ADDITIONAL_PRODUCT_FIELD;
                this.AUXILIARY_PRODUCT_FIELD = REGULATION_AUXILIARY_PRODUCT_FIELD;
                this.ANCILLARY_PRODUCT_FIELD = REGULATION_ANCILLARY_PRODUCT_FIELD;
                this.EXTRA_PRODUCT_FIELD = REGULATION_EXTRA_PRODUCT_FIELD;
                this.fields = [REGULATION_PRODUCT_FIELD, REGULATION_ADDITIONAL_PRODUCT_FIELD, REGULATION_AUXILIARY_PRODUCT_FIELD, REGULATION_ANCILLARY_PRODUCT_FIELD, REGULATION_EXTRA_PRODUCT_FIELD];
            } else if (this.objectApiName === 'Test_Item__c') {
                this.ID_FIELD = TESTITEM_ID_FIELD;
                this.PRODUCT_FIELD = TESTITEM_PRODUCT_FIELD;
                this.ADDITIONAL_PRODUCT_FIELD = TESTITEM_ADDITIONAL_PRODUCT_FIELD;
                this.AUXILIARY_PRODUCT_FIELD = TESTITEM_AUXILIARY_PRODUCT_FIELD;
                this.ANCILLARY_PRODUCT_FIELD = TESTITEM_ANCILLARY_PRODUCT_FIELD;
                this.EXTRA_PRODUCT_FIELD = TESTITEM_EXTRA_PRODUCT_FIELD;
                this.fields = [TESTITEM_PRODUCT_FIELD, TESTITEM_ADDITIONAL_PRODUCT_FIELD, TESTITEM_AUXILIARY_PRODUCT_FIELD, TESTITEM_ANCILLARY_PRODUCT_FIELD, TESTITEM_EXTRA_PRODUCT_FIELD];
            }
        }, 5);
    }

    handleChange(event) {
        this.selectedOptions = event.detail.value;
        this.selectedOptions.sort();
    }

    handleCancel(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit(e) {
        this.buttonsDisabled = true;
        const chunkSize = 100;
        let allChunks = [];
        for (let i = 0; i < this.selectedOptions.length; i += chunkSize) {
            let chunk = this.selectedOptions.slice(i, i + chunkSize);
            allChunks.push(chunk);
        }

        const updateFields = {};
        updateFields[this.ID_FIELD.fieldApiName] = this.recordId;
        updateFields[this.PRODUCT_FIELD.fieldApiName] = (allChunks.length>0 ? allChunks[0].join(';') : '');
        updateFields[this.ADDITIONAL_PRODUCT_FIELD.fieldApiName] = (allChunks.length>1 ? allChunks[1].join(';') : '');
        updateFields[this.AUXILIARY_PRODUCT_FIELD.fieldApiName] = (allChunks.length>2 ? allChunks[2].join(';') : '');
        updateFields[this.ANCILLARY_PRODUCT_FIELD.fieldApiName] = (allChunks.length>3 ? allChunks[3].join(';') : '');
        updateFields[this.EXTRA_PRODUCT_FIELD.fieldApiName] = (allChunks.length>4 ? allChunks[4].join(';') : '');

        const recordInput = { 
            fields: updateFields
        };

        updateRecord(recordInput)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Products updated',
                    variant: 'success'
                })
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            console.log('Error during update', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while updating record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }
}