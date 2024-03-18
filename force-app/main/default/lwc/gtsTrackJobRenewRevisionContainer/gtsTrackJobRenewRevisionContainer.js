import { LightningElement, api, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import RENEW_BUTTON from "@salesforce/label/c.GTS_Renew";
import REVISION_BUTTON from "@salesforce/label/c.GTS_Revision";

import apexIsJobCompleted from "@salesforce/apex/GTSJobHistoryController.isJobCompleted";
import apexGetJobExistingNumber from "@salesforce/apex/GTSJobLifecycle.getJobInspectionNumber";
import apexGetAssociatedJobRequest from "@salesforce/apex/GTSJobHistoryController.getAssociatedJobRequest";


export default class GtsTrackJobRenewRevisionContainer extends NavigationMixin(LightningElement) {
    @api recordId;
    @api accountId;
    renewRevision;
    labels = {
        RENEW_BUTTON,
        REVISION_BUTTON
    }

    handleRevision(event){
        this.renewRevision = 'Revision';
        this.redirectToSubmitJob();
    }
    handleRenew(event){
        this.renewRevision = 'Renewal';
        this.redirectToSubmitJob();
    }

  @wire(apexIsJobCompleted, { jobId: '$recordId' })
  isJobCompleted;

  @wire(apexGetJobExistingNumber, { jobId: '$recordId' })
  jobExistingNumber;

  @wire(apexGetAssociatedJobRequest, { jobId: '$recordId' })
  jobRequestId;

  get disableButtons(){

    return (!this.isJobCompleted.data);
  }
  get disableButtonsStyles(){

    return (!this.isJobCompleted.data) ? 'disable-button' : 'blue-button';
  }

    redirectToSubmitJob(event){
        console.log('test redirect')
        console.log('test redirect', this.jobRequestId);
        console.log('test redirect', this.jobRequestId.data);
      
        let existingNumber = this.jobExistingNumber.data;
           this[NavigationMixin.Navigate]({
             type: 'comm__namedPage',
             attributes: {
               name:'Submit_a_Test_Request__c'
           },
           state: {
               jobId: this.recordId,
               accountId: this.accountId,
               renewRevision : this.renewRevision,
               jobExistingNumber : existingNumber,
               associatedJobRequestId : this.jobRequestId.data
           }
           });
    }
}