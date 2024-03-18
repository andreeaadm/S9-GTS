import { LightningElement, track, wire, api } from "lwc";
import ICare_FileUpload_Format_Validation from "@salesforce/label/c.ICare_FileUpload_Format_Validation";
import getFileFormats from "@salesforce/apex/ICareFileUploadController.getFileFormats";
import getDocumentTypes from "@salesforce/apex/ICareFileUploadController.getDocumentTypes";
import OTHER_VALUE from "@salesforce/label/c.GTS_Other_Value";
import DOCUMENT_TYPE_VALIDATION from "@salesforce/label/c.GTS_DocumentTypeValidation";
import DOCUMENT_SIZE_VALIDATION from "@salesforce/label/c.GTS_DocumentSizeValidation";
import UPLOAD_DOCUMENTS_LABEL from "@salesforce/label/c.GTS_UploadDocuments_Label";

import createContentVersion from "@salesforce/apex/ICareFileUploadController.createContentVersion";
import getContentVersions from "@salesforce/apex/ICareFileUploadController.getContentVersions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ICareFileUpload extends LightningElement {
  @api isReadOnly = false;
  @api pageTitle = "Documents";
  @track uploadedDocuments = [];
  @api isFileUploaded = false;
  documentType = "";
  currentUploadedDocument = "";
  isUploadDisabled = true;
  acceptedFormats;
  options;
  @api gtsFormName = "REGISTRATION";
  uploadedDocumentList = [];
  otherValue;
  isOtherValue = false;
  fileData;
  @api contentVersionIds = [];
  contentVersionIds1 = [];
  @api isGtsJobProgressionPage = false;

  labels = { ICare_FileUpload_Format_Validation, OTHER_VALUE, DOCUMENT_TYPE_VALIDATION, DOCUMENT_SIZE_VALIDATION, UPLOAD_DOCUMENTS_LABEL };


  @wire(getFileFormats)
  getAcceptedFormats({ data, error }) {
    if (data) {
      this.acceptedFormats = data;
      console.log("accpetedFormats : ", data);
      console.log('isFileUploaded: ' + this.isFileUploaded);      
    } else {
      console.log(error);
    }
  }

  @wire(getDocumentTypes, { formName: "$gtsFormName" })
  getDocTypes({ data, error }) {
    if (data) {
      console.log("options : ", data);
      let options1 = [];
      data.forEach((docType) => {
        let opt = { label: docType, value: docType };
        options1.push(opt);
      });
      this.options = options1;
    } else {
      console.log(error);
    }
  }
  connectedCallback(){
    if(this.isReadOnly){
      this.isFileUploaded = true;
    }

    /*if(sessionStorage.getItem('uploadedDocuments')){
      this.uploadedDocuments = JSON.parse(sessionStorage.getItem('uploadedDocuments'));
    }*/

    if(this.contentVersionIds && this.contentVersionIds.length > 0){
      this.isFileUploaded = true;
      getContentVersions({contentVersionIds: this.contentVersionIds})
        .then(result => {
            for(let conVer of result){
              this.uploadedDocuments.push({
                docName: conVer.Title,
                docType: conVer.GTS_Document_Type__c
              });
            }

        }).catch(error =>{
          console.log(error);
        })
    }
  }

  handleOtherValueChange(event) {
    this.documentType = event.detail.value;
  }

  handleDocumentTypeSelect(event) {
    console.log("handleDocumentTypeSelect : " + event.detail.value);
    this.documentType = event.detail.value;

    if (this.documentType.includes("Other")) {
      this.isOtherValue = true;
    } else {
      this.isOtherValue = false;
    }

    if (this.uploadedDocumentList.includes(this.documentType)) {
      event.target.setCustomValidity(
        this.labels.DOCUMENT_TYPE_VALIDATION
      );
    } else {
      this.isUploadDisabled = false;
      event.target.setCustomValidity("");
    }
    event.target.reportValidity();
  }

  handleUploadFinished(event) {
    console.log('event.target : ',event.target.files);
    const file = event.target.files[0];
    let reader = new FileReader();
    reader.onload = () => {
        const maxSizeInBytes = 10 * 1024 * 1024; // 10 MB example limit
        console.log('file size : ', file.size);
        if (file.size > maxSizeInBytes) {
          this.dispatchEvent(
            new ShowToastEvent({
                title: '',
                message: this.labels.DOCUMENT_SIZE_VALIDATION,
                variant: 'error',
            }),
          );
        }else{
          let base64 = reader.result.split(',')[1];
          this.fileData = {fileName: file.name, base64: base64};
          createContentVersion({base64: this.fileData.base64, filename: this.fileData.fileName, documentType: this.documentType})
            .then(result => {
              console.log('Result : ', result.Id);
              console.log('Result : ', result.GTS_Document_Type__c);
              this.contentVersionIds1.push(result.Id);

              let conVerId = result.Id;

              this.currentUploadedDocument = this.fileData.fileName;
              this.uploadedDocuments.push({
                docName: this.currentUploadedDocument,
                docType: this.documentType
              });
              if (!this.documentType.includes("Other")) {
                this.uploadedDocumentList.push(this.documentType);
              }
              this.documentType = "";
              this.isUploadDisabled = true;
              this.isFileUploaded = true;
              this.isOtherValue = false;

              this.dispatchEvent(new CustomEvent('documentupload', {detail : conVerId}));

             // sessionStorage.setItem('uploadedDocuments', JSON.stringify(this.uploadedDocuments));
              
              //this.dispatchDataEvent();
            }).catch(error => {
              console.log('error : ',error);
            })
        }
    }
    reader.readAsDataURL(file)

    /*const uploadFiles = event.target.files;

    const maxSizeInBytes = 10 * 1024 * 1024; // 10 MB example limit
    const invalidFiles = uploadFiles.filter(file1 => file1.size > maxSizeInBytes);

    if (invalidFiles.length > 0) {
      event.target.setCustomValidity(this.labels.DOCUMENT_SIZE_VALIDATION);

    }else{

      this.currentUploadedDocument = uploadFiles[0].name;
      this.uploadedDocuments.push({
        docName: uploadFiles[0].name,
        docType: this.documentType
      });
      if (!this.documentType.includes("Other")) {
        this.uploadedDocumentList.push(this.documentType);
      }
      this.documentType = "";
      this.isUploadDisabled = true;
      this.isFileUploaded = true;
      this.isOtherValue = false;

      sessionStorage.setItem('uploadedDocuments', JSON.stringify(this.uploadedDocuments));
    }*/
  }

  dispatchDataEvent(){
    console.log('uploadedDocuments : ', this.uploadedDocuments.docName);
    console.log('this.contentVersionIds : ',this.contentVersionIds1);
    this.dispatchEvent(new CustomEvent('documentupload', {detail : this.contentVersionIds1}));
  }
}