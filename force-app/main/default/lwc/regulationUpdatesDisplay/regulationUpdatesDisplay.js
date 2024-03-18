import { LightningElement,api } from 'lwc';
import getRegulationUpdateData from '@salesforce/apex/RegulationUpdatesDisplayController.getRegulationUpdateData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";
import recentUpdates from '@salesforce/label/c.GMA_Recent_Regulation_Updates';
import regName from '@salesforce/label/c.GMA_Regulation_Name';
import helpText from '@salesforce/label/c.GMA_Regulation_Update_HelpText';
import generateSheet from '@salesforce/label/c.GMA_Generate_Reg_Sheet';

export default class RegulationUpdatesDisplay extends NavigationMixin(LightningElement) {
    selectedRecords = [];
    hasRecords = false;

    label = {
        recentUpdates,
        regName,
        helpText,
        generateSheet
    };

    connectedCallback() {
        getRegulationUpdateData()
        .then((result) => {
            if(result && result.length!=0){
                this.hasRecords = true;
                this.selectedRecords = result;
            }
        })
        .catch((error) => {
            this.fireToastEvent("Error!","Unable to fetch records.","error");
            console.error(error);
        });
    }

    fireToastEvent(title,message,variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }  
    
    navigateToRegulatorySheet(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Regulatory_Sheet__c'
            }
        }); 
    }
}