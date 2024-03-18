import { LightningElement, api } from 'lwc';
import DETAIL_HEADER from '@salesforce/label/c.iCare_Expert_Title';

export default class ICareExpertDetailHeader extends LightningElement {
    
    customLabel = {
        DETAIL_HEADER
    }

    @api expertname;
    
    returnClick(){
        const event = new CustomEvent('returntoexperts');
        this.dispatchEvent(event);
    }
}