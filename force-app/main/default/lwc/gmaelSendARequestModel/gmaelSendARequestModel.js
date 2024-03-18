import TC_Requestor from '@salesforce/label/c.TC_Requestor';
import { LightningElement, api } from 'lwc';
import { utilLabels } from "c/gmaelPortalCustomLabels";

export default class GmaelSendARequestModel extends LightningElement {

    clabels = utilLabels.labels;
    showModel = false;
    showBackButton = false;
    showCloseButton = true;
    subject = this.clabels.GMAEL_Portal_Request_Subject_Value;
    disableSubject = false;

    @api
    handleShowBackButton(event) { 

        this.disableSubject = true;
        this.showBackButton = event.detail;
        this.showCloseButton = event.detail;
    }

    @api
    handleBackClick() {

        this.disableSubject = false;
        this.showBackButton = false;
        this.refs.requestForm.handleBack();
    }    

    @api
    handleShowModel() {

        this.subject = 'Intertek Access Services';
        this.showBackButton = false;
        this.showCloseButton = true;
        this.showModel = true;
        this.disableSubject = false;
    }

    @api
    handleHideModel() {

        this.showModel = false;
    }

    handleInputChange(event) {

        this.subject = event.target.value;
    }
}