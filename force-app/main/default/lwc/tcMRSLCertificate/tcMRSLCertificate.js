import { LightningElement, api, track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class TcMrslCertificate extends LightningElement {
    @api recordId;
    get acceptedFormats() {
        return ['.pdf'];
    }
    @track isMrslUploaded = true;

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        if(uploadedFiles){
            //custom event
            const passMrslEvent = new CustomEvent('mrslupload', {
            detail:{isUploaded:this.isMrslUploaded} 
            });
            this.dispatchEvent(passMrslEvent);
        }
        let uploadedFileNames = '';
        for(let i = 0; i < uploadedFiles.length; i++) {
            uploadedFileNames += uploadedFiles[i].name;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: uploadedFiles.length + ' Files uploaded Successfully: ' + uploadedFileNames,
                variant: 'success',
            }),
        );
    }
}