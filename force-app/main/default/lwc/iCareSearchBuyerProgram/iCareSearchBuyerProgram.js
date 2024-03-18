import { LightningElement,api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import apexGetBuyers  from "@salesforce/apex/iCare_BuyerController.getBuyers"

import BACK from '@salesforce/label/c.iCare_Go_Back';
import SEARCH from '@salesforce/label/c.iCare_Search';
import SEARCH_OR_SELECT_BUYER from '@salesforce/label/c.iCare_Search_or_Select_Frequently_Buyer';
import SEARCH_BUYER from '@salesforce/label/c.iCare_Search_Buyer';
import BUYER_PROGRAM_TITLE from '@salesforce/label/c.iCare_Buyer_Program_Title';

export default class ICareSearchBuyerProgram extends NavigationMixin(LightningElement) {
    @api accountId;

    @track buyersList = [];
    @track filteredBuyers = [];
    @track inputValue;
    @track showSuggestions = true;

    @track searchedBuyerName;

    label = {
        BACK,
        SEARCH,
        SEARCH_BUYER,
        SEARCH_OR_SELECT_BUYER,
        BUYER_PROGRAM_TITLE
    }
    handleBuyerSearchInputChange(event) {
        this.filteredBuyers = [];
        this.searchedBuyerName = event.detail.value;
    
        if( this.buyersList == undefined || this.buyersList.length === 0){
            this.searchBuyers(this.accountId);
        }
    
        if(this.buyersList.length !== 0 && this.searchedBuyerName.length !== 0){
            this.filterBuyersBySearchText(this.searchedBuyerName);
        }
        this.showSuggestions = true;
    
    }
 
    handleGoBackClick(event){
        const selectedEvent = new CustomEvent("gobackclick");

        this.dispatchEvent(selectedEvent);
    }

    handlePreselect(event){
        this.searchedBuyerName = event.currentTarget.dataset.name;
    this.showSuggestions = false;
    this.handleSearchClick(event);
    }

    handleSearchClick(event){
        let selectedBuyer = this.buyersList.find(buyer => {
                                        return buyer.buyerName.toLowerCase() === this.searchedBuyerName.toLowerCase();
                                    });

        const selectedEvent = new CustomEvent("searchclick", {
            detail: JSON.stringify(selectedBuyer)
            });
        this.dispatchEvent(selectedEvent);
    }

    filterBuyersBySearchText(searchTextValue){
      this.filteredBuyers = this.buyersList.filter(buyer => {
            const lowerCaseName = buyer.buyerName.toLowerCase();
            const lowerCaseSearch = searchTextValue.toLowerCase();
            return lowerCaseName.includes(lowerCaseSearch);
        });

    }

    async searchBuyers(accountId){
            await apexGetBuyers({accountId : accountId})
            .then((result) => {
                this.buyersList = JSON.parse(result);
            }).catch(error => {
                console.log('Fail to get Buyers. Error: '+ error);
                console.log(JSON.stringify(error));
            })
    }

}