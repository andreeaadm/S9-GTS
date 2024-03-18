import { LightningElement, api, wire } from 'lwc';

import { subscribe, MessageContext } from 'lightning/messageService';
import UPDATE_PROGRESS_BAR from '@salesforce/messageChannel/GTLPortalMessageChannel__c';

export default class GtsProgressBarController extends LightningElement {
    steps;
    subscription = null;
    
    @wire(MessageContext)
    messageContext;
    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            UPDATE_PROGRESS_BAR,
            (message) => this.handleMessage(message)
        );
    }

    handleMessage(message){
        this.steps = [];
        if(message.stepsArray != undefined){
            for (const step of message.stepsArray) {
                let ringValue = 0;
                let ringVariant = "base-autocomplete";
                if(step.isCurrent){
                    ringValue = "50";
                }else if(step.isVisited){
                    ringValue = "100";
                    if(step.hasRequiredFields){
                        if(!step.isCompleted){
                            ringVariant = "expired"
                        }
                    }
                }
                let stepObj = {name : step.stepName, ringValue : ringValue, ringVariant : ringVariant, isLastStep : step.isLastStep};
                this.steps.push(stepObj);
            }
        }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    renderedCallback(){
        const element = this.template.querySelector('c-gts-phat-element');
        const background = this.template.querySelector('.background');
        if (element){
            background.classList.add('container-background')
     
        }else{
            background.classList.remove('container-background')
        }
}
    
}