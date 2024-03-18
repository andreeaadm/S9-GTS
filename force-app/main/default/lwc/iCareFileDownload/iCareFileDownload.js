import { LightningElement, api, wire, track } from 'lwc';
import getRelatedFilesByRecordId from '@salesforce/apex/iCare_FileDownloadController.getRelatedFilesByRecordId';
import FILES_LABEL from '@salesforce/label/c.iCare_Portal_Files';
import DOWNLOAD_MY_LABEL from '@salesforce/label/c.iCare_Portal_Download_My';


export default class ICareFileDownload extends LightningElement {
    @api recordId;
    @track error;
    filesList =[];
    sfdcBaseURL;

    customLabels = {
        FILES_LABEL,
        DOWNLOAD_MY_LABEL
    }

    renderedCallback() {
        this.sfdcBaseURL = window.location.origin;
    }
    
    @wire(getRelatedFilesByRecordId, { recordId: '$recordId' })
    wiredResult({data, error}) {
        if(data){
            this.filesList = Object.keys(data).map(item=>({
                "label": item,
                "value": item,
                "url": this.sfdcBaseURL + data[item]
            }))
        }
        if(error){
            this.error = error;
        }
    }
}