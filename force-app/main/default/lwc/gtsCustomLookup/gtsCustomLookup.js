import { LightningElement, api, wire, track } from 'lwc';
// import apex method from salesforce module 
import fetchLookupData from '@salesforce/apex/GTSCustomLookupController.fetchLookupData';
import fetchDefaultRecord from '@salesforce/apex/GTSCustomLookupController.fetchDefaultRecord';

const DELAY = 300; // delay apex callout timing in milliseconds  

export default class GtsCustomLookup extends LightningElement {

    // public properties with initial default values 
    @api label = 'custom lookup label'; //Default value
    @api placeholder = 'search...'; //Default value
    @api iconName = 'standard:account'; //Default value
    @api sObjectApiName = 'Account'; //Default value
    @api defaultRecordId = '';
    @api fieldsApiNameWithValueMap = '{}';
    @api value;
    @api labelApiName = 'Name';
    @api valueApiName = 'Id';
    @api isReadOnly = false;
    @api isRequired = false;
    @track correctParameter = 'Name';

    // private properties 
    lstResult = []; // to store list of returned records   
    hasRecords = true;
    searchKey = ''; // to store input field value
    isSearchLoading = false; // to control loading spinner  
    delayTimeout;
    selectedRecord = {}; // to store selected lookup record in object formate 

    fieldsValueJson;
    // initial function to populate default selected lookup record if defaultRecordId provided  
    connectedCallback() {
        this.searchKey = this.value;

        if (this.defaultRecordId != '') {

            fetchDefaultRecord({ 
                recordId: this.defaultRecordId, 
                'sObjectApiName': this.sObjectApiName,
                fieldsApiNameWithValueMap: this.fieldsApiNameWithValueMap,
                 labelApiName : this.labelApiName,
                 valueApiName : this.valueApiName
                 })
            .then((result) => {

                if (result != null) {

                    this.selectedRecord = result;
                    this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
                }
            })
            .catch((error) => {
                this.error = error;
                this.selectedRecord = {};
            });
        }
    }
    renderedCallback(){
        this.searchKey = this.value;
    }

    // wire function property to fetch search record based on user input
    @wire(fetchLookupData, { searchKey: '$searchKey', sObjectApiName: '$sObjectApiName', fieldsApiNameWithValueMap : '$fieldsApiNameWithValueMap', labelApiName : '$labelApiName', valueApiName : '$valueApiName' })
    searchResult(value) {
        const { data, error } = value; // destructure the provisioned value
        this.isSearchLoading = false;
        if (data) {
            this.hasRecords = data.length == 0 ? false : true;
            this.lstResult = JSON.parse(JSON.stringify(data));
        }
        else if (error) {
            console.log('(error: ' + JSON.stringify(error));
        }
    };

    // update searchKey property on input field change  
    handleKeyChange(event) {
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        this.isSearchLoading = true;
        this.value = event.target.value;
        this.searchKey = event.target.value;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.lookupUpdateHandler(undefined, searchKey);
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
        }, DELAY);
    }


    // method to toggle lookup result section on UI 
    toggleResult(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch (whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }

    // method to clear selected lookup record  
    handleRemove() {
        this.searchKey = '';
        this.value = '';
        this.selectedRecord = {};
        this.lookupUpdateHandler(undefined, undefined); // update value on parent component as well from helper function

        // remove selected pill and display input field again 
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-hide');
        searchBoxWrapper.classList.add('slds-show');

        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-show');
        pillDiv.classList.add('slds-hide');
    }

    // method to update selected record from search result 
    handelSelectedRecord(event) {
        var objId = event.target.getAttribute('data-recid'); // get selected record Id 
        this.selectedRecord = this.lstResult.find(data => data.Id === objId); // find selected record from list
        this.value = this.selectedRecord.Name;
        //MODIFICAT this.lookupUpdateHandler(this.selectedRecord, this.selectedRecord[thie.labelApiName]); // update value on parent component as well from helper function
        this.lookupUpdateHandler(this.selectedRecord, this.selectedRecord.Name); // update value on parent component as well from helper function
        this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
    }

    /*Common helper method started*/

    handelSelectRecordHelper() {
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');

        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-show');
        searchBoxWrapper.classList.add('slds-hide');

        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-hide');
        pillDiv.classList.add('slds-show');
    }

    // send selected lookup record to parent component using custom event
    lookupUpdateHandler(value, label) {
        value = (value != undefined) ? value : '';
        const oEvent = new CustomEvent('lookupupdate',
            {
                'detail': {
                selectedRecord: value,
                selectedName: label
                 }
            }
        );

        this.dispatchEvent(oEvent);
    }

        displayParameter(item) {
            return item[this.labelApiName];
        }
}