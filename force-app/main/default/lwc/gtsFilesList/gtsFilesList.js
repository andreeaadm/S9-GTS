import { LightningElement, api, wire, track } from 'lwc';
import getRelatedFilesByRecordId from '@salesforce/apex/GTSFileDownloadController.getRelatedFilesByRecordId';
import NO_DOCS from '@salesforce/label/c.GTS_No_Documents';

export default class gtsFilesList extends LightningElement {
    @api recordId;
    @track error;
    filesList =[];
    sfdcBaseURL;

    @track keys = [];
    @track mapData;

    getMappedData(key) {
        return this.mapData[key];
    }

    get documentsExists(){
        return (this.keys != undefined && this.keys.length > 0);
    }

    customLabels = {
        NO_DOCS
    }

    renderedCallback() {
        this.sfdcBaseURL = window.location.origin;
    }
    
    @wire(getRelatedFilesByRecordId, { recordId: '$recordId' })
    wiredResult({data, error}) {
        if(data){
            try{
                let documentRecords = JSON.parse(data);
                let typeMap = {};

               documentRecords.forEach(item => {
                    if (!typeMap[item.documentType]) {
                        typeMap[item.documentType] = [];
                    }
                    typeMap[item.documentType].push(item);
                });

                if (typeMap['Certificate']) {
                    this.mapData = {
                        'Certificate': typeMap['Certificate'] || [],
                        ...typeMap
                    };
                }else{
                    this.mapData = {...typeMap};
                }
                            // Check if mapData is an object
                            if (typeof this.mapData === 'object' && this.mapData !== null) {
                                for (let key in this.mapData) {
                                            if (this.mapData.hasOwnProperty(key)) {

                                                this.keys = [...this.keys, key];
                                            }
                                        }
                            } else {
                                console.error('Invalid mapData format:', mapData);
                            }

            }catch(error){
                console.error('Error parsing map string', error);
            }
        }
        if(error){
            this.error = error;
            console.log('error',error);
        }
    }
}