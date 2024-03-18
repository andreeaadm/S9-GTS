import { LightningElement, api, track } from 'lwc';
import BUYER_PROGRAM from '@salesforce/label/c.iCare_Buyer_Program';
import FREQUENTLY_USED_BUYERS from '@salesforce/label/c.iCare_Frequently_Used';
import NO_FREQUENTLY_USED_BUYERS from '@salesforce/label/c.iCare_No_Data';

import apexGetFrequentBuyers  from "@salesforce/apex/iCare_BuyerController.getFrequentBuyers"

const COLS_TO_DISPLAY = [
    {label: BUYER_PROGRAM, fieldName: 'buyerName', type: 'text', hideDefaultActions: true}
]

export default class ICareFrequentUsedBuyerProgram extends LightningElement {
    @api accountId;
    @track frequentlyBuyersList = [];
    @track isDataLoaded = false;

    columns = COLS_TO_DISPLAY;

    label = {
        BUYER_PROGRAM,
        FREQUENTLY_USED_BUYERS,
        NO_FREQUENTLY_USED_BUYERS
    }

     connectedCallback(){
         if(this.accountId != undefined){
             this.getFrequentBuyers(this.accountId);
         }
     }

     async getFrequentBuyers(accountId){
         if(this.frequentlyBuyersList == undefined || this.frequentlyBuyersList.length == 0){
             await apexGetFrequentBuyers({accountId: accountId})
                .then((result) => {
                     this.frequentlyBuyersList = JSON.parse(result);
                })
                .catch(error => {
                    console.log('Fail to get Frequent Buyers. Error: '+ error)
                });
            }
            this.isDataLoaded = true;
     }

     handleListClick(event){
        let selectedBuyer = this.frequentlyBuyersList.find(buyer => {
                                        return buyer.id === event.currentTarget.dataset.id;
                                    });

        const selectedEvent = new CustomEvent("frequentlybuyerclick", {
            detail: JSON.stringify(selectedBuyer)
            });
        this.dispatchEvent(selectedEvent);
     }
}