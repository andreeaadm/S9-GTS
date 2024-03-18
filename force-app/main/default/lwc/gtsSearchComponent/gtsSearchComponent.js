import { LightningElement,api, track } from 'lwc';

import apexGetBuyers  from "@salesforce/apex/iCare_BuyerController.getBuyers"

export default class gtsSearchComponent extends LightningElement {
    @api searchInputLabel;
    @api searchInputPlaceholder;
    @api recordsOptions;

    @api accountId;

    @track buyersList = [];
    @track filteredBuyers = [];
    @track inputValue;
//    @track showSuggestions = true;

    @track searchItemValue;
    @track filteredRecords;

    get showSuggestions() {
        return (this.filteredRecords != undefined && this.filteredRecords.length !== 0);
    }

    handleSearchInputChange(event) {
        this.filteredRecords = this.recordsOptions;

        this.searchItemValue = event.detail.value;

        if(this.recordsOptions.length !== 0 && this.recordsOptions.length !== 0){
            this.filterRecordsBySearchText(this.searchItemValue);
        }

    }

    handlePreselect(event){
        this.searchItemValue = event.currentTarget.dataset.name;
    this.handleSearchClick(event);
    }

    handleSearchClick(event){
        let selectedBuyer = this.buyersList.find(buyer => {
                                        return buyer.buyerName.toLowerCase() === this.searchItemValue.toLowerCase();
                                    });

        const selectedEvent = new CustomEvent("searchclick", {
            detail: JSON.stringify(selectedBuyer)
            });
        this.dispatchEvent(selectedEvent);
    }

    filterRecordsBySearchText(searchTextValue){
      this.filteredRecords = this.recordsOptions.filter(recordOption => {
            const lowerCaseName = recordOption.Name.toLowerCase();
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