import { LightningElement } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';
import ThankYou from '@salesforce/resourceUrl/iconsiCare'


import THANK_YOU_LABEL from '@salesforce/label/c.iCare_Portal_Thank_You';
import THANK_YOU_SUBMITTED_MESSAGE_LABEL from '@salesforce/label/c.iCare_Portal_Enquiry_Submitted_Message';

export default class ICareThankYouEnquiry extends NavigationMixin(LightningElement) {

  ThankYou= ThankYou + '/thank-you.svg';

    labels = {
        THANK_YOU_LABEL,
        THANK_YOU_SUBMITTED_MESSAGE_LABEL
    }

    handleRedirectToHome(event){
           this[NavigationMixin.Navigate]({
             type: 'comm__namedPage',
             attributes: {
               name:'Home'
             }
           });
    }
}