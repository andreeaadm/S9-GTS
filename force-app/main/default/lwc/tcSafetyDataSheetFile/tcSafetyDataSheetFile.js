import { LightningElement, api, track, wire } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class TcSafetyDataSheetFile extends LightningElement {
    @api recordId;
    get acceptedFormats() {
        return ['.pdf'];
    }
    @track isSdsUploaded = true;

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        if(uploadedFiles){
            //custom event
            const passSdsEvent = new CustomEvent('sdsupload', {
            detail:{isUploaded:this.isSdsUploaded} 
            });
            this.dispatchEvent(passSdsEvent);
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