import { LightningElement, api } from 'lwc';
import { utilFunctions } from "c/gmaelAccessPassportUtils";
import { utilLabels } from "c/gmaelPortalCustomLabels";
import getReportData from '@salesforce/apex/GMAEL_AccessPassportPortalController.getReportData';

export default class GmaelPortalAPTableContainer extends LightningElement {

    @api countries;
    reportData;
    reportCountryData;
    clabels = utilLabels.labels;

    connectedCallback() {

        if (this.countries) {
            
            this.loadSelectedCountriesData();
        }
    }
    
    loadSelectedCountriesData() {
        
        try {

            getReportData({countries: this.countries}).then(result =>{

                if (result) {

                    this.reportData = result;
                    this.reportCountryData = result.reportCountries[0];
                }
            }).catch(error =>{
    
                utilFunctions.toast(this, 'Error', error.body.message || error.message, 'error');
            })
        } catch (error) {

            console.error('Error loading countries:', error);
        }
    }

    countrySelectHandler(event) {

        this.reportCountryData = (this.reportData.reportCountries).filter(
            country => country.reportCountry.GMAEL_Country_Name__c === event.target.value
        )[0];
    }
}