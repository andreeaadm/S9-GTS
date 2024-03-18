import { LightningElement } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import ENQUIRY_HEADER from '@salesforce/label/c.iCare_Enquiry_Header';
import ENQUIRY_SUBJECT from '@salesforce/label/c.iCare_Enquiry_Subject';
import ENQUIRY_BODY from '@salesforce/label/c.iCare_Enquiry_Body';
import ENQUIRY_BUTTON from '@salesforce/label/c.iCare_Enquiry_Send_Button';
import ERROR_HEADING from'@salesforce/label/c.iCare_Error_Heading_1';
import ERROR_BODY_1 from'@salesforce/label/c.iCare_Error_Body_1';
import ERROR_BODY_2 from'@salesforce/label/c.iCare_Error_Body_2';
import ERROR_BODY_3 from'@salesforce/label/c.iCare_Error_Body_3';

export default class ICareEnquiryForm extends LightningElement {

    customLabel = {
        ENQUIRY_HEADER,
        ENQUIRY_SUBJECT,
        ENQUIRY_BODY,
        ENQUIRY_BUTTON,
        ERROR_HEADING,
        ERROR_BODY_1,
        ERROR_BODY_2,
        ERROR_BODY_3
    }

    subjectInformation = '';
    enquiryInformation = '';


    handleSubjectChange(event){
        this.subjectInformation = event.target.value;
    }

    handleEnquiryChange(event){
        this.enquiryInformation = event.target.value;
    }

    sendEnquiry(){
    if(this.subjectInformation == '' && this.enquiryInformation == ''){
        const event = new ShowToastEvent({
            title: this.customLabel.ERROR_HEADER,
            message: this.customLabel.ERROR_BODY_1,
            variant: 'Error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    } else if (this.subjectInformation == '' && this.enquiryInformation != ''){
        const event = new ShowToastEvent({
            title: this.customLabel.ERROR_HEADER,
            message: this.customLabel.ERROR_BODY_2,
            variant: 'Error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    } else if (this.subjectInformation != '' && this.enquiryInformation == ''){
        const event = new ShowToastEvent({
            title: this.customLabel.ERROR_HEADER,
            message: this.customLabel.ERROR_BODY_3,
            variant: 'Error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    } else {
        const event = new CustomEvent('sendenquiry',{
            detail: {
                subject: this.subjectInformation,
                enquiry: this.enquiryInformation
            }
        });
        this.dispatchEvent(event);
    }
        
    }

}