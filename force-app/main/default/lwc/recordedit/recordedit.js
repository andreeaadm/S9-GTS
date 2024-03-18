import { LightningElement, api } from 'lwc';

export default class Recordedit extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api layoutType;
    @api recordDetailTitle;
    @api relatedListTitle;
    @api relatedObjectApiName;
    @api parentFieldApiName;
}