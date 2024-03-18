import { LightningElement, api} from "lwc";
import THANK_YOU from "@salesforce/label/c.GTS_Thank_You";
import JOB_SUBMITTED from "@salesforce/label/c.GTS_Job_Submitted";
import THANK_YOU_NOTE from "@salesforce/label/c.GTS_Thank_You_Note";
import FAVOURITE_FIELD_LABEL from "@salesforce/label/c.GTS_Favourite_Field_Label";
import FAVOURITE_NAME from "@salesforce/label/c.iCare_Favourite_Name";
import PRINT_ETRF from "@salesforce/label/c.iCare_Print_ETRF";
import SAVE from "@salesforce/label/c.iCare_Submit_Save";
import gtsNoCongaDocModal from 'c/gtsNoCongaDocModal';

const INTERVAL = 3000; // Check for PDF every 3 seconds
const MAX_WAIT_TIME = 80 *1000; // Maximum number of Seconds to check for the PDF
const CONGA_WAIT_TIME = 20000; // Time to wait for document to be created

import getSingleDownloadLink from '@salesforce/apex/GTSFileDownloadController.getCongaDocumentDownloadLink';

export default class GtsThankYouPage extends LightningElement {
    @api hideFavorite = false;
    disabled = true;
    showSpinner = true;

    labels = {
        THANK_YOU,
        JOB_SUBMITTED,
        PRINT_ETRF,
        THANK_YOU_NOTE,
        FAVOURITE_FIELD_LABEL,
        FAVOURITE_NAME,
        SAVE
    };

    @api jobRequestRecordId;
    @api jobRequestRecord;
    favouriteName = '';

    connectedCallback(){
        // delay button activation to give time for conga to create file
        setTimeout(() => {
            this.activateButton();
        }, CONGA_WAIT_TIME);
    }

    activateButton(){
        this.showSpinner = false;
    }

    handleFavouriteChange(event) {
        this.favouriteName = event.detail.value;
        if(this.favouriteName){
            this.disabled = false;
        }
        else if (this.favouriteName == ''){
            this.disabled = true;
        }
        // Enable/Disable Save button on input of favourite
        // this.template.querySelector('.blue-button').disabled=(this.favouriteName == '' || this.favouriteName == null);
    }
    get saveButtonClass(){
        return (this.disabled) ? 'grey-button' : 'blue-button';
    }
    handlePrint() {
        this.showSpinner = true;
        this.checkForPDF();
    }

    checkForPDF(count = 0) {
        if (count <= MAX_WAIT_TIME) {
            getSingleDownloadLink({ recordId: this.jobRequestRecordId })
                .then(result => {
                    if (result != null) {
                        this.showSpinner = false; // Hide the spinner once the result is received
                        const link = document.createElement('a');
                        link.href = window.location.origin + result; //remove duplicate /icare from url
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
            this.handleShowModal();
            console.log('PDF file not found after maximum count.');
        }
    }

    handleSave() {
       // Create a custom event
      const customEvent = new CustomEvent( "savefavouritejobrequestevent", { detail: { favouriteName: this.favouriteName } } );

      // Dispatch the custom event
      this.dispatchEvent(customEvent);
    }

    async handleShowModal() {
        const result = await gtsNoCongaDocModal.open({
            size: 'large',
            description: 'Accessible description of modal\'s purpose'
        });
    }
}