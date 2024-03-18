import { LightningElement, api, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation'
import getContentDetails from "@salesforce/apex/TC_getUploadedFilesOfChemicalProduct.getContentDetails";
import deleteContentDocument from '@salesforce/apex/TC_getUploadedFilesOfChemicalProduct.deleteContentDocument';

const columns = [
    { label: 'Title',fieldName: 'Title', wrapText : true,
        cellAttributes: { 
            iconName: { fieldName: 'icon' }, iconPosition: 'left' 
        }
    },  
    { label: 'File Size',   fieldName: 'Size' },
    { label: 'Delete', type:  'button', fieldName: 'Delete', typeAttributes: { 
            label: 'Delete',   name: 'Delete',   variant: 'destructive',iconName: 'action:delete', 
            iconPosition: 'right'
        } 
    },
    { label: 'Download', type:  'button', fieldName: 'Download', typeAttributes: { 
        label: 'Download',   name: 'Download',   variant: 'brand',iconName: 'action:download', 
        iconPosition: 'right'
    } 
} 
];
export default class TcSupplierChemicalLibraryFileUpload extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isBrandUser;
    @track uploadFiles = 'Upload Files';
    @api title;
    @track dataList;
    @track columnsList = columns;
    isLoading = false;
    @track isSdsUploaded = false;
    @track isMrslUploaded = false;
    @track isSdsFileUploaded = false;
    @track isMrslFileUploaded = false;
    @track deleteMode = false;
    @track isWorking = false;
    @track selectedRow = '';
    @track selectedOption = '';
    @track actionName = '';
    @track orgBaseURL = '';

    wiredFilesResult;

    connectedCallback() {
        if(this.isBrandUser) {
            this.columnsList = [...columns].filter(col => col.fieldName != 'Delete');
        }
        this.handleSync();
        let url = window.location.origin;
        this.generateBaseURL(url);    
    }

    options = [
        { label: 'Safety Data Sheet', value: 'sds' },
        { label: 'MRSL Certificate', value: 'mrsl' },
    ];

   // value = 'sds';

    generateBaseURL(url) {
        if(url.includes("my.site.com")) {
            this.orgBaseURL = url.replace("my.site.com", "lightning.force.com"); 
        }
        else {
            this.orgBaseURL = "https://intertek.lightning.force.com";
        } 
    }

    handleRowAction(event) {
        this.actionName = event.detail.action.name;
        this.selectedRow = event.detail.row;
        if(this.actionName == 'Delete'){
            this.deleteMode = true;               
        }
        if(this.actionName == 'Download'){ 
            this.handleFileDownload();
        }
    }

    handleFileDownload() {
        const row = this.selectedRow;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.orgBaseURL + '/sfc/servlet.shepherd/document/download/' + row.ContentDocumentId
            }
        })
    }

    handleChange(event) {
        this.selectedOption = event.detail.value;
    }
    
    toggleDELETE() {
        this.deleteMode = !this.deleteMode;
    }

    handleDeleteSelectedFile(){
        if(this.selectedOption) {
        this.isWorking = true;
        this.toggleDELETE();
        this.isLoading = true;
        const row = this.selectedRow;
        if(this.selectedOption == 'sds'){
            this.updateSdsOnChemicalProductAfterDelete(); 
            this.handleDeleteFiles(row); 
         }
         else if(this.selectedOption == 'mrsl'){
             this.updateMrslOnChemicalProductAfterDelete();
             this.handleDeleteFiles(row); 
         }
         this.selectedOption = '';
         this.isWorking = false;
         this.isLoading = false; 
        }
        else {
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: "File type is mandatory",
                  variant: "error"
                })
              );
        }    
    }

    handleDeleteFiles(row){
        
        deleteContentDocument({
            recordId : row.ContentDocumentId
        })
        .then(result => {
            this.dataList  = this.dataList.filter(item => {
                return item.ContentDocumentId !== row.ContentDocumentId ;
            });
        })
        .catch(error => {
            console.error('**** error **** \n ',error)
        })
        .finally(()=>{
            this.isLoading = false;
        });
    }

    handleSync(){

        let supportedIconExtensions = ['pdf'];
        this.isLoading = true;
        getContentDetails({
            recordId : this.recordId
        })
        .then(result => {
            let parsedData = JSON.parse(result);
            let stringifiedData = JSON.stringify(parsedData);
            let finalData = JSON.parse(stringifiedData);
            finalData.forEach(file => {
                file.Size = this.formatBytes(file.ContentDocument.ContentSize, 2);
                let fileType = file.ContentDocument.FileType.toLowerCase();
                    if(supportedIconExtensions.includes(fileType)){
                        file.icon = 'doctype:' + fileType;
                    }
            });
            this.dataList = finalData;
        })
        .catch(error => {
            console.error('**** error **** \n ',error)
        })
        .finally(()=>{
            this.isLoading = false;
        });
    }

    formatBytes(bytes,decimals) {
        if(bytes == 0) return '0 Bytes';
        var k = 1024,
            dm = decimals || 2,
            sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    } 

    onSdsUpload(event) {
        this.isSdsUploaded = event.detail.isUploaded;
        if(this.isSdsUploaded){
            this.handleSync();
            this.updateSdsOnChemicalProduct();
        }
    }

    onMrslUpload(event) {
        this.isMrslUploaded = event.detail.isUploaded;
        if(this.isMrslUploaded){
            this.handleSync();
            this.updateMrslOnChemicalProduct();
        }
    }  
    
    updateSdsOnChemicalProduct() {

        const fields = {
            Id : this.recordId,
            Is_Safety_Data_Sheet__c	: true
        }
    
        const recordInput = { fields };
        updateRecord(recordInput)
                .then(() => {
                })
                .catch(error => {
                    console.log('Error is::'+ error);
                });
    }

    updateMrslOnChemicalProduct() {

        const fields = {
            Id : this.recordId,
            Is_MRSL_Certificate__c : true
        }
    
        const recordInput = { fields };
        updateRecord(recordInput)
                .then(() => {
                })
                .catch(error => {
                    console.log('Error is::'+ error);
                });
    }

    updateSdsOnChemicalProductAfterDelete() {

        const fields = {
            Id : this.recordId,
            Is_Safety_Data_Sheet__c	: false
        }
    
        const recordInput = { fields };
        updateRecord(recordInput)
                .then(() => {
                })
                .catch(error => {
                    console.log('Error is::'+ error);
                });
    }

    updateMrslOnChemicalProductAfterDelete() {

        const fields = {
            Id : this.recordId,
            Is_MRSL_Certificate__c : false
        }
    
        const recordInput = { fields };
        updateRecord(recordInput)
                .then(() => {
                })
                .catch(error => {
                    console.log('Error is::'+ error);
                });
    }
}