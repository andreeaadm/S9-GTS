import { LightningElement, api, track, wire } from 'lwc';
import getRelatedRecords from '@salesforce/apex/RelatedListController.getRelatedRecords';

export default class Relatedlist extends LightningElement {
    @api recordId;
    @api relatedObjectApiName;
    @api parentFieldApiName;

    @wire(getRelatedRecords, {
        relatedObjectApiName: '$relatedObjectApiName',
        parentFieldApiName: '$parentFieldApiName',
        parentRecordId: '$recordId'
    })
    records;
}