import { LightningElement, api, track } from 'lwc';

export default class GmaelAccessPassportController extends LightningElement {
    @api recordId;
    @track displayMap = false;

    ginNumber;
    selectedContact;

    handleSubmitClick(event){
        
        this.selectedContact = event.detail.contact.id;
        this.ginNumber = event.detail.ginNumber;
        this.displayMap = true;
    }
}