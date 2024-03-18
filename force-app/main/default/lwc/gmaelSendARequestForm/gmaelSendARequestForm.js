import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { utilFunctions, reduceErrors } from "c/gmaelAccessPassportUtils";
import { utilLabels } from "c/gmaelPortalCustomLabels";
import createIConnectLead from '@salesforce/apex/GMAEL_SendARequestFormController.createIConnectLead';
import getData from '@salesforce/apex/GMAEL_SendARequestFormController.getData';

export default class GmaelSendARequestForm extends LightningElement {
    
    @api subject;
    firstStep = false;
    secondStep = false;
    thirdStep = false;
    countriesListView = [];
    selectedServices = [];
    selectedCountries = [];
    data;
    formCountries;
    formStates;
    disableNextButton = true;
    @track additionalInformation;
    stateRequired = false;
    clabels = utilLabels.labels;

    connectedCallback() {
        
        if (!this.data) {
            
            this.initData();
        }        
    }

    get enableLoader() {

        return !this.firstStep && !this.secondStep && !this.thirdStep;
    }

    initData() {
        
        try {

            getData().then(result =>{

                if (result) {

                    console.log(result);
                    this.data = result;
                    this.formCountries = result?.countries;//?.map(item => ({ key: item, value: item }));
                    for(var key in result.countriesByContinent){
                        this.countriesListView.push({value:result.countriesByContinent[key], key:key});
                    }
                    this.firstStep = true;
                }
            }).catch(error =>{
    
                this.toast('Error', error.body.message || error.message || error, 'error');
            })
        } catch (error) {
        
            console.error('Error loading countries:', error);
        }
    }

    handleNext() {
        
        const inputFields = this.template.querySelectorAll('lightning-input');
        
        let isValid = true;
        inputFields.forEach(field => {
            if (!field.reportValidity()) {
                
                isValid = false;
            }
        });
        
        this.refs.countryField.fireValidation();
        this.refs.industryField.fireValidation();

        if (this.formStates) {

            this.refs.stateField.fireValidation();
        }
        
        if (isValid) {
            
            this.handleBackButtonEvent(true);
            this.manageStepVisibility(false, true, false);
        }
    }

    handleInputChange(event) {

        if (event.currentTarget.dataset.field === 'INTK_Address__CountryCode__s') {
            
            this.data.iConnectLead[event.currentTarget.dataset.field] = event.detail.key;
            this.formStates = this.data.states[event.detail.key];
            this.refs.stateField.resetAutoComplete();
            this.data.iConnectLead['INTK_Address__StateCode__s'] = '';
            this.stateRequired = this.formStates ? true : false;
        } else {
        
            this.data.iConnectLead[event.currentTarget.dataset.field] = event.detail.value;
        }

        if (event.currentTarget.dataset.field === 'INTK_Address__StateCode__s') {
            
            this.data.iConnectLead[event.currentTarget.dataset.field] = event.detail.key;
        }

        this.disableNextButton = !(this.data.iConnectLead.INTK_First_Name__c && 
            this.data.iConnectLead.INTK_Last_Name__c && 
            this.data.iConnectLead.INTK_Job_Title__c &&
			this.data.iConnectLead.INTK_Company_Name__c && 
            this.data.iConnectLead.INTK_Address__City__s && 
            this.data.iConnectLead.INTK_Address__CountryCode__s && 
            (this.formStates ? this.data.iConnectLead.INTK_Address__StateCode__s : true) && 
            this.data.iConnectLead.INTK_Email__c && 
            this.data.iConnectLead.INTK_Industry__c && 
            this.data.iConnectLead.INTK_Business_Phone__c);
    }

    handleTextAreaChange(event) {

        this.additionalInformation = event.target.value;
    }

    handleSubmit() {
        
        this.data.iConnectLead['INTK_Subject__c'] = this.subject;
        this.data.iConnectLead["INTK_Description__c"] = 'Countries - ' + (this.refs.countriesListView.getSelectedCountries() ? this.refs.countriesListView.getSelectedCountries()?.join(', ') + '\n' : 'No Countries Selected') +
                                                        'Services - ' + (this.selectedServices ? this.selectedServices?.join(', ') + '\n' : '\n')+
                                                        'Additional Information - ' + (this.additionalInformation ? this.additionalInformation : '') + '\n' +
                                                        'State - ' + this.data.iConnectLead['INTK_Address__StateCode__s'] + '\n' +
                                                        'Industry - ' + this.data.iConnectLead['INTK_Industry__c'];
        
        try {

            createIConnectLead({lead:this.data.iConnectLead}).then(result =>{

                this.handleBackButtonEvent(false);
                this.manageStepVisibility(false, false, true);
                localStorage.removeItem('selectedCountries')
            }).catch(error =>{

                // parse to user friendly error message
                let errorMsg = error.body.message || error.message || error;
                let errorMsgs = errorMsg.split(',');
                errorMsg = errorMsg.replace(errorMsgs[0] + ',', '');
                this.toast('Error', errorMsg, 'error');
            })
        } catch (error) {
        
            console.error('Error:', error);
        }
    }

    handleBackButtonEvent(msg) {

        this.dispatchEvent(new CustomEvent('back', {
            detail: msg
        }));
    }

    @api
    handleBack() {
        
        this.manageStepVisibility(true, false, false);
    }

    handleClose() {
        
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
                message: true
            }
        }));
    }

    handleServiceClick(event){

        event.target.classList.toggle('selected');
        const clickedService = event.target.textContent;
        const greenCircle = this.template.querySelector('.green-circle[data-service="'+clickedService+'"]');
        greenCircle.classList.toggle('hide');
        const elements = this.template.querySelectorAll('.selected');
        this.selectedServices = [];
        elements.forEach(element => {
            console.log(element.dataset.service);
            this.selectedServices.push(element.dataset.service);
        });
    }

    handleCountryClick(event) {

        event.target.classList.toggle('selected-country');
        const elements = this.template.querySelectorAll('.selected-country');
        this.selectedCountries = [];
        elements.forEach(element => {
            console.log(element.dataset.countryid);
            this.selectedCountries.push(element.dataset.countryid);
        });
    }

    manageStepVisibility(firstStep, secondStep, thirdStep) {

        this.firstStep = firstStep;
        this.secondStep = secondStep;
        this.thirdStep = thirdStep;
    }

    toast(title, message, variant) {

        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }

    get enableSubmitButton() {
        
        return this.selectedServices.length === 0;
    }

    get enableStates() {

        return !this.formStates;
    }
}