import { LightningElement, api, track, wire } from 'lwc';

import { publish, MessageContext } from 'lightning/messageService';
import STEP_CLICK from '@salesforce/messageChannel/GTLPortalMessageChannelProgressBar__c';

export default class GTSPathElement extends LightningElement {
    @api step;

    @wire(MessageContext)
    messageContext;
    @track isRendered = false;


    handleStepClick(event){
        const clickedStep = event.currentTarget.getAttribute('data-div-name');
        const payload = {
                    step: clickedStep
        };
       publish(this.messageContext, STEP_CLICK, payload);

    }
}