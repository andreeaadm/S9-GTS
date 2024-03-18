import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import styles from '@salesforce/resourceUrl/gmaelStyles';
import { utilFunctions } from "c/gmaelAccessPassportUtils";
import { NavigationMixin } from "lightning/navigation";

const INTERVAL = 3000; // Check for PDF every 3 seconds
const MAX_WAIT_TIME = 80 *1000; // Maximum number of Seconds to check for the PDF
const CONGA_WAIT_TIME = 20000; // Time to wait for document to be created

export default class GmaelAPSearchOptions extends NavigationMixin(LightningElement){

    @api reportData;
    @api recordId;    
    @api accountId;
    @api reportId;
    @api ginNumber;
    @api selectedContact;
    labels = utilFunctions.labels; 
    showLoader = false;
    resetMapVisible = true;
    reportStatus;
    approvedProductCategories = [];
    approvedProductDescriptions = [];
    selectedApprovedProductCategory = '';
    selectedApprovedProductDescriptionId = '';
    defaultProductDescriptionId = '';
    selectedCountries = [];
    isReportDataExists = true;

    connectedCallback(){

        loadStyle(this, styles);
        this.loadProductCategories();

        if (this.reportData?.isReportObject && this.reportData?.reportId) {
            
            this.initiatePrePopulate();
            this.reportStatus = this.reportData?.reportRecordData?.GMAEL_Report_Status__c;
        } else {

            this.accountId = this.recordId;
        }
    }

    handleCountryListViewToggle(event){
        
        this.showLoader = true;
        utilFunctions.resetCountries();
        utilFunctions.fireCustomEvent(this, 'countrylistviewtoggle', event.target.checked);
        this.resetMapVisible = !event.target.checked;
        this.selectedCountries = [];
        setTimeout(() => { this.showLoader = false; }, 1000);
    }

    loadProductCategories() {

        this.approvedProductCategories = utilFunctions.preparePicklist(
            this.reportData?.approvedProductCategories, 
            false
        );
    }

    initiatePrePopulate() {

        if (this.reportData?.reportRecordData?.GAMEL_Filter_JSON__c) {
            
            let reportFilter = JSON.parse(this.reportData?.reportRecordData?.GAMEL_Filter_JSON__c);
            this.selectedApprovedProductCategory = reportFilter.productCategoryId;
            this.defaultProductDescriptionId = reportFilter.productDescriptionId;
            
            this.loadProductDescription(true);
            this.selectedCountries = reportFilter.countries;
            this.accountId = reportFilter.accId;
            this.contactId = reportFilter.contactId;
            this.selectedContact = reportFilter.contactId;
            this.ginNumber = reportFilter.ginNumber;
            this.reportId = this.reportData?.reportId;
            this.selectedApprovedProductDescriptionId = reportFilter.productDescriptionId;
            this.handlePreview(false);
        }
    }

    reportDataExist(reportData) {
        
        this.isReportDataExists = false;

        if (!reportData || !reportData?.reportCountries) {
        
            return;
        } else {
            
            reportData?.reportCountries?.forEach(rc => {
                if (rc?.legislationFound) {
                    this.isReportDataExists = rc?.legislationFound; 
                    return;        
                }
            });
        }
    }

    get enableApprovalButton() {

        return  (this.isReportDataExists
            && (this.reportStatus === 'Draft' || this.reportStatus === 'Rejected'));
    }

    get enableDownloadButton() {

        return (this.reportId && this.isReportDataExists); 
    }

    get disableProductDescription() {

        return (
		    (!this.selectedApprovedProductCategory) ||
		    (this.selectedApprovedProductCategory?.trim() === '') ||
            (this.selectedApprovedProductCategory === undefined)
        );
	}

    get disablePreviewButton() {

		return ((this.selectedCountries === undefined ||
                this.selectedCountries === null ||
                this.selectedCountries.length === 0) ||
                ((!this.selectedApprovedProductDescriptionId) ||
                (this.selectedApprovedProductDescriptionId?.trim() === '') ||
                (this.selectedApprovedProductDescriptionId === undefined)) ||
                ((!this.selectedApprovedProductCategory) ||
                (this.selectedApprovedProductCategory?.trim() === '') ||
                (this.selectedApprovedProductCategory === undefined))
        );
	}

    handleChange(event) {

        let keyId = event.detail.key;

        if (event.target.dataset.name === 'pd') {
            
            this.selectedApprovedProductDescriptionId = keyId;
        } else {

            this.resetProductDescription();
            this.selectedApprovedProductCategory = keyId;

            if (this.selectedApprovedProductCategory !== null 
                && this.selectedApprovedProductCategory !== undefined) {
                
                this.loadProductDescription(false);
            }
        }
    }

    resetProductDescription() {

        this.selectedApprovedProductDescriptionId = '';
        this.template.querySelector('c-gmael-autocomplete[data-name="pd"]').resetAutoComplete();
    }

    resetProductCategory() {

        this.selectedApprovedProductCategory = '';
        this.template.querySelector('c-gmael-autocomplete[data-name="pc"]').resetAutoComplete();
    }   

    loadProductDescription(flag) {

        utilFunctions.retrieveProductTypeByCategoryId({productCategoryId: this.selectedApprovedProductCategory}).then(result =>{

            this.approvedProductDescriptions = utilFunctions.preparePicklist(result, true);
            
            if (this.defaultProductDescriptionId && flag) {
                
                this.selectedApprovedProductDescriptionId = this.defaultProductDescriptionId;
                this.template.querySelector('c-gmael-autocomplete[data-name="pd"]').setDefaultValue(
                    this.approvedProductDescriptions,
                    this.selectedApprovedProductDescriptionId
                );
            }
        }).catch(error =>{

            utilFunctions.toast(this, 'Error', error?.body?.message || error?.message || error, 'error');
        })
    }
    
    handelReset() {

        this.isReportDataExists = false;
        this.resetProductDescription();
        this.resetProductCategory();
        utilFunctions.resetCountries();        
        utilFunctions.fireCustomEvent(this, 'resetcountries', true);
    }

    handelApproval() {

        this.showLoader = true;

        utilFunctions.submitForApproval({
            reportId: this.reportId
        }).then(result => {
                
            utilFunctions.toast(this, 'Successful', 'Report has been sent for approval.', 'success');
            this.reportStatus = 'Pending Approval';
            this.showLoader = false;
        }).catch(error =>{
            
            this.showLoader = false;
            utilFunctions.toast(this, 'Error', error.body.message || error.message, 'error');
        });        
    }

    handlePreview() {

        this.previewHelper(true);
    }

    handleDownload() {

        this.showLoader = true;
        utilFunctions.resetGenerateReportFileValue({ recordId: this.reportId });
        this.checkForPDF();
    }

    checkForPDF(count = 0) {

        if (count <= MAX_WAIT_TIME) {

            utilFunctions.getDownloadLink({ recordId: this.reportId })
                .then(result => {

                    if (result != null) {

                        this.showLoader = false; // Hide the spinner once the result is received
                        this[NavigationMixin.Navigate]({
                           type: 'standard__webPage',
                           attributes: {
                               url: '/sfc/servlet.shepherd/document/download/'+result+'?operationContext=S1'
                           }
                        })
                    } else {

                        this.showLoader = true;
                        // Retry after INTERVAL
                        setTimeout(() => {
                            this.checkForPDF(count + INTERVAL);
                        }, INTERVAL);
                    }
                })
                .catch(error => {
                    this.showLoader = false; // Hide the spinner in case of an error
                    // Handle any errors that occur during the Apex call
                    console.error('Error retrieving PDF download link:', error);
                });
        } else {
            // Maximum count reached, hide the spinner and display an error message
            this.showLoader = false;
            console.log('PDF file not found after maximum count.');
        }
    }

    previewHelper(isPreviewed) {

        this.showLoader = true;
        console.log('selectedContact>>', this.selectedContact);//this.selectedContact);
        console.log('ginNumber>>', this.ginNumber);//this.ginNumber);
        console.log('reportId>>', this.reportId);
        console.log('accountId>>', this.accountId);//this.accountId);
        console.log('recordId>>', this.recordId);
        console.log('selectedCountries>>', this.selectedCountries);
        console.log('selectedApprovedProductDescriptionId>>', this.selectedApprovedProductDescriptionId);
        console.log('selectedApprovedProductCategory>>', this.selectedApprovedProductCategory);
        
        utilFunctions.retrieveReportData({
            countries: this.selectedCountries, accountId: this.accountId,
            contactId: this.selectedContact, ginNumber: this.ginNumber, 
            productDescriptionId: this.selectedApprovedProductDescriptionId, 
            productCategoryId: this.selectedApprovedProductCategory, reportId: this.reportId,
            isPreviewed:isPreviewed
        }).then(result =>{

            console.log('Result before preview', result);

            if (result.reportCountries.length === 0) {
                
                utilFunctions.toast(this, 'Error', 'There is no data found', 'error');
            } else {

                this.reportDataExist(result);
                this.reportId = (this.reportId ? this.reportId : result?.reportObj?.Id);
                utilFunctions.fireCustomEvent(this, 'preview', result);
                console.log('Result after preview', result);

                if (this.reportId) {
                    
                    this.reportStatus = this.reportData?.reportRecordData?.GMAEL_Report_Status__c || 'Draft';
                }
            }

            this.showLoader = false;
        }).catch(error =>{
            
            this.showLoader = false;
            utilFunctions.toast(this, 'Error', error.body.message || error.message, 'error');
        });
    }

    @api setSelectedCountries(selectedCountries) {
        
        this.selectedCountries = selectedCountries;
    }
}