import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getJobTestReport from '@salesforce/apex/iCare_JobTestReport.getJobTestReport';
//import gerReportUrl from '@salesforce/apex/iCare_JobController.gerReportUrl';
import iCarePortalMessageChannel from '@salesforce/messageChannel/iCarePortalMessageChannel__c';
import {subscribe, MessageContext} from 'lightning/messageService'
import DOWNLOAD_TEST_REPORT from '@salesforce/label/c.iCare_Download_Test_Report';
import TITLE_REPORTS from '@salesforce/label/c.iCare_Title_Reports';



export default class ICareFileDownload extends LightningElement {
    @api recordId;
    @track error;
    urlReport;
    showButton = false;
    subscription = null;

    customLabel = {
        DOWNLOAD_TEST_REPORT,
        TITLE_REPORTS
    }

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.handleSubscribe();
    }
 
    handleSubscribe() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(this.messageContext, iCarePortalMessageChannel, (message) => {
            if (message.message == 'Test Report Issued'){
                this.showButton = true;
            }
        });
    }

    handleClick(event) {
        getJobTestReport({jobId: this.recordId })
            .then(result => {
                this.urlReport = result;
                window.open(result);
            }) 
            .catch( error => { 
                let errorData = JSON.parse(error.body.message);
                this.showToast(errorData.name, errorData.message, 'error');
            });         
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}