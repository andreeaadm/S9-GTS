import { LightningElement, api, track } from 'lwc';
import { utilFunctions } from "c/gmaelAccessPassportUtils";
import { utilLabels } from "c/gmaelPortalCustomLabels";
import getCountriesListView from '@salesforce/apex/GMAEL_AccessPassportPortalController.getCountriesListView';

export default class GmaelPortalAccessPassport extends LightningElement {

    @api recordId;    
    @api accountId;
    @api ginNumber;
    @api selectedContact;
    labels = utilFunctions.labels;  
    clabels = utilLabels.labels;  
    countryListView = false;
    showResult = false;
    data = null;
    reportData;
    countriesListView = [];
    selectedCountries = [];
    resetButtonLabel = this.clabels.GMAEL_Portal_Reset_Map;
    

    loadCountriesByContinent() {
        
        try {
            getCountriesListView().then(result =>{

                if (result) {

                    for(var key in result){
                        this.countriesListView.push({value:result[key], key:key});
                    }
                }
            }).catch(error =>{
    
                utilFunctions.toast(this, 'Error', error.body.message || error.message, 'error');
            })
        } catch (error) {
        
            console.error('Error loading countries:', error);
        }
    }
    
    connectedCallback() {
        
        this.loadCountriesByContinent();
        this.retrieveData();

    }

    renderedCallback() {
        const buttonMapViewDefault = this.template.querySelector('.mapViewBtn');
        buttonMapViewDefault.classList.add('background-click');
    }

    handleAccordionClick(event) {
        const accordionSection = event.currentTarget.closest('.slds-accordion__list-item');
        const allAccordionSections = this.template.querySelectorAll('.slds-accordion__list-item');

        allAccordionSections.forEach(section => {
            if (section !== accordionSection) {
                section.classList.remove('slds-is-open');
            }
        });

        const allAccordionButtons = this.template.querySelectorAll('.slds-accordion__summary-action');
        
        allAccordionButtons.forEach(button => {
            if (button !== event.currentTarget) {
                button.classList.remove('slds-is-clicked');
            }

            const span = button.querySelector('.slds-accordion__summary-content');
            if (span) {
                span.classList.remove('slds-is-clicked');
                span.style.color = '';
            }
        });

        accordionSection.classList.toggle('slds-is-open');

        const accordionButton = event.currentTarget;
        const isClicked = accordionButton.classList.contains('slds-is-clicked');
        accordionButton.classList.toggle('slds-is-clicked', !isClicked);
        
        const span = accordionButton.querySelector('.slds-accordion__summary-content');
        const color = 'var(--Dark-Blue)'
        if (span) {
            span.classList.toggle('slds-is-clicked', !isClicked);
            span.style.color = span.classList.contains('slds-is-clicked') ? color : 'white';
        }
    }

    retrieveData() {
        
        utilFunctions.retrieveData({recordId: null}).then(result =>{

            console.log('data: ', result);
            this.data = result;
        }).catch(error =>{

            utilFunctions.toast(this, 'Error', error.body.message || error.message, 'error');
        })
    }

    handleCountryListViewToggle(event) {

        this.selectedCountries = [];
        this.countryListView = event.target.dataset.action === 'listView' ? true : false;
        this.resetButtonLabel = this.countryListView ? this.clabels.GMAEL_Portal_Reset_List : this.clabels.GMAEL_Portal_Reset_Map;
        const buttonMapView = this.template.querySelector('.mapViewBtn');
        const buttonListView = this.template.querySelector('.listViewBtn');

        if(event.target.dataset.action === 'listView'){
            buttonListView.classList.add('background-click');
            buttonMapView.classList.remove('background-click');
            buttonMapView.style.backgroundColor = ("transparent");

        }

        if(event.target.dataset.action === 'mapView'){
            buttonMapView.classList.add('background-click')
            buttonListView.classList.remove('background-click');
            buttonMapView.style.backgroundColor = ("var(--Intertek-Cerello)");
        }
    }
    
    handleResetCountries(event) {
        
        if (this.countryListView) {
            
            this.selectedCountries = [];
            let selectedItems = this.template.querySelectorAll('.li-padding');

            selectedItems.forEach(function (li) {
                li.classList.remove('selected');
            });
        } else {

            this.reportData = null;
            this.template.querySelector('c-gmael-portal-a-p-dynamic-map')?.resetCountriesOnMap();
        }
    }

    handleNext(event) {

        if (!this.countryListView) {
            
            this.selectedCountries = this.template.querySelector('c-gmael-portal-a-p-dynamic-map').getSelectedCountries();
        }
        
        localStorage.setItem('selectedCountries', this.selectedCountries);
        this.showResult = true;
       }

    handleCountryClick(event) {

        event.target.classList.toggle('selected');

        const elements = this.template.querySelectorAll('.selected');
        this.selectedCountries = [];
        elements.forEach(element => {
            console.log('pais',element.dataset.countryid);
            this.selectedCountries.push(element.dataset.countryid);
        });
    }

    setSelectedCountries(event) {

        this.selectedCountries = event.detail;
    }

    setPreviewData(event) {

        this.reportData = event.detail;
    }

    get isCountrySelected() {

        return !(this.selectedCountries && this.selectedCountries?.length > 0);
    }
    get buttonClass() {

        return !(this.selectedCountries && this.selectedCountries?.length > 0) ? 'disable-button' : 'nextBtn';
    }


    get countryListViewClass() {

        return this.countryListView ? 'display: none;' : 'display: "";';
    }
}