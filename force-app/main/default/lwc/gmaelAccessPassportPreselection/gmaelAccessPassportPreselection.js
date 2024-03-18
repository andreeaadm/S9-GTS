import { LightningElement, api, track } from 'lwc';

import CONTACT from'@salesforce/label/c.GMAEL_Contact';
import CONTACT_GIN_WARNING from'@salesforce/label/c.GMAEL_Contact_GIN_Warning';
import CONTACT_SEARCH from'@salesforce/label/c.GMAEL_Search_Contacts';
import GIN_ERROR from'@salesforce/label/c.GMAEL_GIN_Number_Format_Validation';
import GIN_NUMBER from'@salesforce/label/c.GMAEL_GIN_Number';
import TITLE_LABEL from'@salesforce/label/c.GMAEL_New_Passport_Access_Report';

import apexGetContacts  from "@salesforce/apex/GMAEL_AccessPassportController.getContacts"


export default class GMAELAccessPassportPreselection extends LightningElement {
    @api recordId;
    @track searchedContact;
    @track selectedContact;
    @track filteredContacts = [];
    @track contactsList = [];
    @track displaySuggestions = false;

    ginNumber;

    labels = {
        CONTACT,
        CONTACT_GIN_WARNING,
        CONTACT_SEARCH,
        GIN_ERROR,
        GIN_NUMBER,
        TITLE_LABEL
    }

	get disableSubmitButton() {
		return (
		    (this.selectedContact === undefined) ||
		    (this.selectedContact.length === 0) ||
		    (this.ginNumber === undefined) ||
		    (this.ginNumber.length === 0)
		    );
	}

    handleContactSearchInputChange(event) {
        this.filteredContacts = [];
        this.selectedContact = undefined;
        this.searchedContact = event.detail.value;

        if( this.contactsList == undefined || this.contactsList.length === 0){
            this.searchContacts();
        }

        if(this.contactsList.length !== 0 && this.searchedContact.length !== 0){
            this.filterContactsBySearchText(this.searchedContact);
        }
        this.displaySuggestions = true;

    }

    handleGinNumberInputChange(event) {
        this.ginNumber = event.detail.value;
        this.handleDisplayGinError(false);
    }

    handleContactSearchInputClick(event){
        this.searchedContact = event.target.value;

        if( this.contactsList == undefined || this.contactsList.length === 0){
            this.searchContacts();
        }

        if(this.contactsList.length !== 0 && this.searchedContact.length === 0){
            this.filteredContacts = this.contactsList;

        }
        this.displaySuggestions = true;

    }

    filterContactsBySearchText(searchTextValue){
      this.filteredContacts = this.contactsList.filter(contact => {
            const lowerCaseContact = contact.Name.toLowerCase();
            const lowerCaseSearch = searchTextValue.toLowerCase();
            return lowerCaseContact.includes(lowerCaseSearch);
        });

    }

    async searchContacts(){
        await apexGetContacts({accountId : this.recordId})
        .then((result) => {
            this.contactsList = JSON.parse(result);
        }).catch(error => {
             console.log('Fail to get Contacts. Error: '+ error);
             console.log(JSON.stringify(error));
        })
    }

    handlePreselect(event){
        this.searchedContact = event.currentTarget.dataset.name;
        this.selectedContact = event.currentTarget.dataset;
        this.displaySuggestions = false;
    }

    handleSubmitClick(event) {
        if(this.validateGinNumber()){
            this.dispatchSubmitClick()
            //nextPage
            //event to parent
            //event.target.label;
        }else{
            this.handleDisplayGinError(true);
        }
    }

    dispatchSubmitClick(){
        const selectedEvent = new CustomEvent("submitclick", {
                    detail: {
                        contact : this.selectedContact,
                        ginNumber : this.ginNumber
                    }
                    });
        this.dispatchEvent(selectedEvent);
    }

    handleDisplayGinError(displayErrorMessage){
        var ginInputCmp = this.template.querySelector('.ginInputCmp');
        if (displayErrorMessage) {
            ginInputCmp.setCustomValidity(this.labels.GIN_ERROR);
        }else{
            ginInputCmp.setCustomValidity('');
        }
        ginInputCmp.reportValidity();
    }

    validateGinNumber(){
        const ginFormat = /^G\d{8}$/;
        return ginFormat.test(this.ginNumber);
    }
}