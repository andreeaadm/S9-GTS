import { LightningElement, api } from 'lwc';
import { utilFunctions } from "c/gmaelAccessPassportUtils";

export default class GmaelAPTableContainer extends LightningElement {

    @api reportData;
    labels = utilFunctions.labels;  
}