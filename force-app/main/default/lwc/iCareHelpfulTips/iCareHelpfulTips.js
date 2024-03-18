import { LightningElement } from 'lwc';
import HELP_HEADER from '@salesforce/label/c.iCare_Enquiry_Help_Header';
import HELP_TEXT_1 from '@salesforce/label/c.iCare_Enquiry_Help_Text_1';
import HELP_TEXT_2 from '@salesforce/label/c.iCare_Enquiry_Help_Text_2';


export default class ICareHelpfulTips extends LightningElement {

    customLabel = {
        HELP_HEADER,
        HELP_TEXT_1,
        HELP_TEXT_2
    }
}