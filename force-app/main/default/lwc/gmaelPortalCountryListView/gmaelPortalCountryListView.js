import { LightningElement, track, api } from 'lwc';

export default class GmaelPortalCountryListView extends LightningElement {
    
    @track selectedCountries = [];
    @api countriesListView;
    @api 
    getSelectedCountries() {

        return this.selectedCountries;
    }

    connectedCallback() {

        if (this.countriesListView) {
            setTimeout(() => {
                this.prePopulateCountry();
            }, 1000);
        }
    }

    handleCountryClick(event) {

        event.target.classList.toggle('selected');
        const elements = this.template.querySelectorAll('.selected');
        this.selectedCountries = [];
        elements.forEach(element => {
            console.log(element.dataset.countrynamed);
            this.selectedCountries.push(element.dataset.countrynamed);
        });
    }

    prePopulateCountry() {

        this.selectedCountries = [];
        let selectedCountriesLocalStorage = JSON.parse(localStorage.getItem('selectedCountries'));
        const countries = this.template.querySelectorAll('.li-padding');

        countries.forEach(country => {
           
            selectedCountriesLocalStorage.forEach(selectedCountry => {

                if (selectedCountry === country.dataset.countryid) {
                    console.log(selectedCountry);
                    console.log(country.dataset.countryid);
                    country.classList.add('selected');
                    this.selectedCountries.push(country.dataset.countrynamed);
                }
            });
        });
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
}