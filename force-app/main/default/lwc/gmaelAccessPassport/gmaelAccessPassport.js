import { LightningElement, api } from 'lwc';
import { utilFunctions } from "c/gmaelAccessPassportUtils";

export default class GmaelAccessPassport extends LightningElement {

    @api recordId;    
    @api accountId;
    @api ginNumber;
    @api selectedContact;
    labels = utilFunctions.labels;  
    countryListView = false;
    data = null;
    reportData;
    
    connectedCallback() {
        
        this.retrieveData();
    }

    retrieveData() {
        
        utilFunctions.resetCountries(); 

        utilFunctions.retrieveData({recordId:this.recordId}).then(result =>{

            console.log('data: ', result);
            this.data = result;
        }).catch(error =>{

            utilFunctions.toast(this, 'Error', error.body.message || error.message, 'error');
        })
    }

    handleCountryListViewToggle(event) {
        
        this.countryListView = event.detail;
    }
    
    handleResetCountries(event) {
        
        this.reportData = null;
        this.template.querySelector('c-gmael-a-p-multi-select-list')?.resetCountryListView();
        this.template.querySelector('c-gmael-a-p-dynamic-map')?.resetCountriesOnMap();
    }

    setSelectedCountries(event) {
        
        this.template.querySelector('c-gmael-a-p-search-options').setSelectedCountries(event.detail);
    }

    setPreviewData(event) {

        this.reportData = event.detail;
    }
}