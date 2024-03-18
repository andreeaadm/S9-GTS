import { LightningElement } from 'lwc'; 
import ThankYou from '@salesforce/resourceUrl/iconsiCare'
import THANK_YOU_HEADER from '@salesforce/label/c.iCare_Thank_You_Header';
import THANK_YOU_BODY from '@salesforce/label/c.iCare_Thank_You_Text_1';
import THANK_YOU_BUTTON from '@salesforce/label/c.iCare_Thank_You_Return_Button'

export default class ICareEnquirySubmitted extends LightningElement {
    ThankYou= ThankYou + '/thank-you.svg';

    customLabel = {
        THANK_YOU_HEADER,
        THANK_YOU_BODY,
        THANK_YOU_BUTTON
    }


    findAnotherExpert(){
        const event = new CustomEvent('findanotherexpert',{
            detail: {recordid: this.recordid}
        });
        this.dispatchEvent(event);
    }
}