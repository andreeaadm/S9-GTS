import { LightningElement, wire} from 'lwc';

import iCarePortalJobsCharMC from '@salesforce/messageChannel/iCarePortalJobsChart__c';
import {subscribe, MessageContext} from 'lightning/messageService'


export default class ICareReportChart extends LightningElement {
    difDays;
    startDate;
    endDate;
    status;
    totalRecsLabel;

    labels;
    jobsData;
    error;

    @wire(MessageContext)
    messageContext;

    connectedCallback(){
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            iCarePortalJobsCharMC,
            (message) => {
                this.jobsData = JSON.parse(message.chartJobsData);
                this.labels = JSON.parse(message.chartLabels);
                this.totalRecsLabel = message.totalRecsLabel;

            }
        );
    }
}