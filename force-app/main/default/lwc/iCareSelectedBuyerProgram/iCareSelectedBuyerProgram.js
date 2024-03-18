import { LightningElement,api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import AS_THE_BUYER from '@salesforce/label/c.iCare_As_The_Buyer';
import BUYER_NOT_FOUND from '@salesforce/label/c.iCare_Buyer_Not_Found';
import CHANGE_BUYER from '@salesforce/label/c.iCare_Change_Buyer';
import CONTACT_CUSTOMER_SUPPORT from '@salesforce/label/c.iCare_Contact_Us_Intertek_Assistant';
import CONTINUE_TO_INTERLINK from '@salesforce/label/c.iCare_Continue_To_Interlink';
import CONTINUE_WITH_BUYER from '@salesforce/label/c.iCare_Continue_With_Buyer';
import SUBMIT_A_TEST_REQUEST from '@salesforce/label/c.iCare_Submit_A_Test_Request';
import YOU_HAVE_SELECTED from '@salesforce/label/c.iCare_You_Have_Selected';

export default class ICareSelectedBuyerProgram extends NavigationMixin(LightningElement) {
    @api selectedBuyer;

    get displayInterlinkBuyer(){
        return (this.displayFoundBuyer && this.selectedBuyer.interlinkCode !== undefined && this.selectedBuyer.interlinkCode !== '');
    };

    get displayFoundBuyer(){
        return (this.selectedBuyer && this.selectedBuyer.buyerName !== undefined && this.selectedBuyer.buyerName !== '');
    };

    label = {
        AS_THE_BUYER,
        BUYER_NOT_FOUND,
        CHANGE_BUYER,
        CONTACT_CUSTOMER_SUPPORT,
        CONTINUE_TO_INTERLINK,
        CONTINUE_WITH_BUYER,
        SUBMIT_A_TEST_REQUEST,
        YOU_HAVE_SELECTED
    }

    handleChangeBuyer(event){
        const selectedEvent = new CustomEvent("changebuyer");

        this.dispatchEvent(selectedEvent);
    }

    handleContinueToInterlink(event){
        window.location.href = 'https://interlink.intertek.com';
    }

    handleSubmitATestRequest(event){
        const selectedEvent = new CustomEvent("submittestrequest");

        this.dispatchEvent(selectedEvent);
    }
}