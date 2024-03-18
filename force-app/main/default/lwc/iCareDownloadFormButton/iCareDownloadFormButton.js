import { LightningElement, api } from 'lwc';
import getSingleDownloadLink from '@salesforce/apex/iCare_FileDownloadController.getSingleDownloadLink';
import BUTTON_LABEL from '@salesforce/label/c.iCare_Print_ETRF';    

const INTERVAL = 3000; // Check for PDF every 3 seconds
const MAX_WAIT_TIME = 80 *1000; // Maximum number of Seconds to check for the PDF
const CONGA_WAIT_TIME = 20000; // Time to wait for document to be created

export default class ICareDownloadFormButton extends LightningElement {   
    @api recordId; // Pass the record Id to the LWC from the parent component
    @api siteURL; //pass the site URL for redirection
    showSpinner = true;
    disableButton = true;
    customLabel = {
        BUTTON_LABEL,
    }
        
    connectedCallback(){
        // delay button activation to give time for conga to create file
        setTimeout(() => {
            this.activateButton();
        }, CONGA_WAIT_TIME);
    }
     
    activateButton(){
        this.showSpinner = false;
        this.disableButton = false;
    }

    handleDownloadClick() {
        this.showSpinner = true; // Show the spinner when the button is clicked
        this.checkForPDF();
    }

    checkForPDF(count = 0) {
        if (count <= MAX_WAIT_TIME) {            
            getSingleDownloadLink({ recordId: this.recordId })
                .then(result => {
                    if (result != null) {
                        this.showSpinner = false; // Hide the spinner once the result is received
                        this.disableButton = false; //Enable Button once the result is received
                        const link = document.createElement('a');
                        link.href = this.siteURL + result.slice(6); //remove duplicate /icare from url
                        link.target = '_blank';
                        link.click();
                    } else {
                        // Retry after INTERVAL
                        setTimeout(() => {
                            this.checkForPDF(count + INTERVAL);
                        }, INTERVAL);
                    }
                })
                .catch(error => {
                    this.showSpinner = false; // Hide the spinner in case of an error
                    // Handle any errors that occur during the Apex call
                    console.error('Error retrieving PDF download link:', error);
                });
        } else {
            // Maximum count reached, hide the spinner and display an error message
            this.showSpinner = false;
            console.log('PDF file not found after maximum count.');
        }
    }
}