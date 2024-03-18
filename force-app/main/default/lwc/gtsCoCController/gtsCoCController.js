import { LightningElement, track, wire, api} from 'lwc';

import { publish,subscribe, MessageContext } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import UPDATE_PROGRESS_BAR from '@salesforce/messageChannel/GTLPortalMessageChannel__c';
import STEP_CLICK from '@salesforce/messageChannel/GTLPortalMessageChannelProgressBar__c';

import BACK from '@salesforce/label/c.GTS_Back';
import BACK_TO_EDIT from '@salesforce/label/c.GTS_Back_To_Edit';
import CANCEL from '@salesforce/label/c.GTS_Cancel';
import CONTINUE from '@salesforce/label/c.GTS_Continue';
import DECLARATION from '@salesforce/label/c.GTS_Declaration';
import GENERAL_INFO from '@salesforce/label/c.GTS_General_Information';
import JOB_INFO from '@salesforce/label/c.GTS_Job_Information';
import DOCUMENTS from '@salesforce/label/c.GTS_Documents';
import REQUIRED_FIELDS from '@salesforce/label/c.GTS_CoC_Required_Fields';
import SAVE_DRAFT from '@salesforce/label/c.GTS_Save_as_Draft';
import SHIPMENT_DOC from '@salesforce/label/c.GTS_Shipment_Document';
import SUBMIT from '@salesforce/label/c.GTS_Confirm_Submit';
import APPLICANT_TYPE from "@salesforce/label/c.GTS_Applicant_Type";
import EXPORTER from '@salesforce/label/c.GTS_Exporter';
import COMPANY_NAME from "@salesforce/label/c.GTS_Company_Name";
import CITY from "@salesforce/label/c.GTS_City";
import COUNTRY from "@salesforce/label/c.GTS_Country";
import POSTAL_CODE from "@salesforce/label/c.GTS_PostalCode";
import STREET from "@salesforce/label/c.GTS_Street";
import CONTACT_PERSON from "@salesforce/label/c.GTS_Contact_Person";
import EMAIL from "@salesforce/label/c.GTS_Email";
import CONTACT_NUMBER from "@salesforce/label/c.GTS_Contact_Number";
import SHIPMENT_CERTIFICATE from '@salesforce/label/c.GTS_Shipment_Certificate';
import IMPORTER from '@salesforce/label/c.GTS_Importer';
import COMMERCIAL_NR from "@salesforce/label/c.GTS_Commercial_Registration_No";

import { createRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

import { getJobRequestSimpleDescription } from "c/gtsJobRequestUtility";
import { validatePageRequiredFields } from "c/gtsJobRequestUtility";

import JOB_REQUEST_OBJECT from "@salesforce/schema/icare_Job_Request__c";

import createContentLink from "@salesforce/apex/ICareFileUploadController.createContentLink";
import apexSaveJobRequest from "@salesforce/apex/GTSJobRequestSave.saveJobRequest";

export default class GtsCoCController extends LightningElement {
    @api jobRequestInput;
    @api accountRecord;
    @api contactRecord;
    @api recordTypeId;

    @track jobRequestRecordId;

    labels = {
        BACK,
        BACK_TO_EDIT,
        CANCEL,
        CONTINUE,
        DECLARATION,
        GENERAL_INFO,
        JOB_INFO,
        DOCUMENTS,
        REQUIRED_FIELDS,
        SAVE_DRAFT,
        SHIPMENT_DOC,
        SUBMIT
    }

    jobRequestRecord;

    @track isWetIssuingOffice = false;
    @track currentStepNumber = 0;
    subscription = null;
    contentVersionIds = [];
    newContentVersionIds = [];
    @api inputContentVersionIds;

    @track progressBarStepsLabels = [
        GENERAL_INFO,
        JOB_INFO,
        SHIPMENT_DOC,
        DOCUMENTS,
        DECLARATION
    ];

    @track isGeneralInfoVisited = false;
    @track isJobInfoVisited = false;
    @track isShipmentDocVisited = false;
    @track isDocVisited = false;
    @track isDeclarationVisited = false;

    get showCancelButton(){
        return (this.currentStepNumber < 5);
    }
    get showBackButton(){
        return (this.currentStepNumber > 0 && this.currentStepNumber < 5);
    }

    checkDeclaration(){
        return (this.jobRequestRecord.GTS_CoC_Declaration_1__c == true && this.jobRequestRecord.GTS_CoC_Declaration_2__c == true && (this.jobRequestRecord.GTS_CoC_Declaration_3__c == true || !this.isWetIssuingOffice)) ;
    }

    get showContinueButton(){
        return (this.showGeneralInformation || this.showJobInformation || this.showShipmentDocument || this.showDocuments || this.showDeclaration);
    }


    get disableContinueButton(){
        return (this.showDeclaration && !this.showContinueButtonVal);
    }

    get continueButtonClass(){
        return (this.showDeclaration && !this.showContinueButtonVal) ? 'disable-button' : 'blue-button';
    }

    @track showContinueButtonVal;


  get isAccountApplicantTypePopulated() {
    return ((this.accountRecord.data.fields.GTS_Applicant_Type__c.value != undefined && this.accountRecord.data.fields.GTS_Applicant_Type__c.value.length > 0))
  }

    get showGeneralInformation(){
        return (this.currentStepNumber == 0);
    }
    get showJobInformation(){
        return (this.currentStepNumber == 1);
    }
    get showShipmentDocument(){
        return (this.currentStepNumber == 2);
    }
    get showDocuments(){
        return (this.currentStepNumber == 3);
    }
    get showDeclaration(){
        return (this.currentStepNumber == 4);
    }
    get showSummary(){
        return (this.currentStepNumber == 5);
    }
    get showThankYouPage(){
        return (this.currentStepNumber == 6);
    }

    showSpinner = false;

    @wire(MessageContext) messageContext;
    @wire(MessageContext) messageContextPB;

    handleClickContinue(event) {
        this.currentStepNumber += 1;
        if(this.currentStepNumber == 5){
            this.missingFields = [];
        }
        this.handleProgressBarUpdate();
    }
    handleClickBack(event){
        this.currentStepNumber -= 1;
        this.handleProgressBarUpdate();
    }

    handleDocumentUpload(event){
        this.newContentVersionIds.push(event.detail);
        this.contentVersionIds.push(event.detail);
      }

    checkVisitedPages(){
        if(this.showGeneralInformation){
            this.isGeneralInfoVisited = true;
        }else if(this.showJobInformation){
            this.isJobInfoVisited = true;
        }else if(this.showShipmentDocument){
            this.isShipmentDocVisited = true;
        }else if(this.showDocuments){
            this.isDocVisited = true;
        }else if(this.showDeclaration){
            this.isDeclarationVisited = true;
        }
    }

    get stepsArray(){
        this.checkVisitedPages();
        return (this.currentStepNumber > 5) ? [] : [
                           {
                               stepName: this.labels.GENERAL_INFO,
                               isCurrent : this.showGeneralInformation,
                               isCompleted : validatePageRequiredFields(['GTS_Program__c','GTS_Applicant_Type__c'], this.jobRequestRecord),
                               isVisited : this.isGeneralInfoVisited,
                               hasRequiredFields : true
                           },
                           {
                               stepName: this.labels.JOB_INFO,
                               isCurrent : this.showJobInformation,
                               isCompleted : validatePageRequiredFields(['GTS_Applicant_Company_Name__c', 'iCare_Applicant_Address__City__s', 'iCare_Applicant_Address__CountryCode__s', 'iCare_Applicant_Address__PostalCode__s', 'iCare_Applicant_Address__Street__s', 'iCare_Applicant_Contact_Person_Name__c', 'iCare_Applicant_Email__c', 'GTS_Applicant_Contact_Number__c', 'GTS_Commercial_Registration_No_TIN__c',
                               'GTS_Importer_Company_Name_Text__c', 'GTS_Importer_Company_Address__City__s', 'GTS_Importer_Company_Address__CountryCode__s', 'GTS_Importer_Company_Address__PostalCode__s', 'GTS_Importer_Company_Address__Street__s', 'GTS_Importer_Contact_Person_Name_Text__c', 'GTS_Importer_Email__c', 'GTS_Importer_Contact_Number__c', 'GTS_Importer_Commercial_Reg_No_TIN__c'],
                               this.jobRequestRecord
                               ),
                               isVisited : this.isJobInfoVisited,
                               hasRequiredFields : true
                           },
                           {
                               stepName: this.labels.SHIPMENT_DOC,
                               isCurrent : this.showShipmentDocument,
                               isVisited : this.isShipmentDocVisited
                           },
                           {
                               stepName: this.labels.DOCUMENTS,
                               isCurrent : this.showDocuments,
                               isVisited : this.isDocVisited
                           },
                           {
                               stepName: this.labels.DECLARATION,
                               isCurrent : this.showDeclaration,
                               isCompleted : this.checkDeclaration(),
                               isLastStep : true,
                               isVisited : this.isDeclarationVisited,
                               hasRequiredFields : true
                           }
                       ];
    }

    handleProgressBarUpdate() {
        const payload = {
            stepsArray: this.stepsArray
        };
        publish(this.messageContext, UPDATE_PROGRESS_BAR, payload);
    }

    connectedCallback() {
        this.jobRequestRecord = {...this.jobRequestInput};
        if(this.inputContentVersionIds.length > 0){
           this.contentVersionIds = [...this.inputContentVersionIds];
        }
        this.handleProgressBarUpdate();
        this.subscribeToProgressBarClickMessageChannel();

        this.jobRequestRecord.iCare_Applicant_Company__c = this.accountRecord.data.fields.Id.value;
        this.jobRequestRecord.GTS_Applicant_Company_Name__c = this.accountRecord.data.fields.Name.value;
        if(this.jobRequestRecord.GTS_Applicant_Contact_Person__c == undefined || this.jobRequestRecord.GTS_Applicant_Contact_Person__c.length == 0){
            this.jobRequestRecord.GTS_Applicant_Contact_Person__c = this.contactRecord.data.fields.ContactId.value;
        }
        if(this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c == undefined || this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c.length == 0){
            this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c = this.contactRecord.data.fields.Contact.displayValue;
        }
        if(this.accountRecord.data.fields.GTS_Applicant_Type__c.value != undefined && this.accountRecord.data.fields.GTS_Applicant_Type__c.value.length >0){
            this.jobRequestRecord.GTS_Applicant_Type__c = this.accountRecord.data.fields.GTS_Applicant_Type__c.value;
        }
        if(this.accountRecord.data.fields.GTS_Commercial_Registration_No_TIN__c.value != undefined && this.accountRecord.data.fields.GTS_Commercial_Registration_No_TIN__c.value.length >0){
            this.jobRequestRecord.GTS_Commercial_Registration_No_TIN__c = this.accountRecord.data.fields.GTS_Commercial_Registration_No_TIN__c.value;
        }
        this.jobRequestRecord.RecordTypeId = this.recordTypeId;
    }

    subscribeToProgressBarClickMessageChannel() {
        this.subscription = subscribe(
            this.messageContextPB,
            STEP_CLICK,
            (message) => this.handleProgressBarMessage(message)
        );
    }

      handleProgressBarMessage(message) {

        switch (message.step) {
            case GENERAL_INFO:
                this.currentStepNumber = 0;
                break;
            case JOB_INFO:
                this.currentStepNumber = 1;
                break;
            case SHIPMENT_DOC:
                this.currentStepNumber = 2;
                break;
            case DOCUMENTS:
                this.currentStepNumber = 3;
                break;
            case DECLARATION:
                this.currentStepNumber = 4;
                break;
            default:
                break;
        }

        this.handleProgressBarUpdate();
      }

      handleClickSaveDraft(){
          this.jobRequestRecord.iCare_Draft_ETRF__c = true;
          this.jobRequestRecord.iCare_Sample_Description__c = getJobRequestSimpleDescription(this.jobRequestRecord,SHIPMENT_CERTIFICATE);
          this.saveJobRequest();
      }

      saveJobRequest() {

          let newObject;
          if(this.jobRequestRecord.RecordTypeId != undefined){
              newObject = {...this.jobRequestRecord}
          }else{
              newObject = {...this.jobRequestRecord, RecordTypeId: ''};
          }
          let fields;
          if(this.jobRequestRecord.iCare_Active_Favourite__c){
                        fields = delete newObject.Id;
          }
          if(this.jobRequestRecord.RecordType!= undefined){
                      newObject.RecordTypeId = this.jobRequestRecord.RecordType.Id;
                      fields = delete newObject.RecordType;
          }
          fields = delete newObject.ProgramName;
          fields = delete newObject.GTS_Program__r;

          this.showSpinner = true;
          let recordInput = {...newObject, sobjectType: JOB_REQUEST_OBJECT.objectApiName}

          if(newObject.hasOwnProperty('Id')){
              apexSaveJobRequest({jobRequest : recordInput})
              .then((record) => {
                this.linkContentDocumentToJobRequest(record.Id, this.newContentVersionIds);
                this.showSpinner = false;
                if(this.jobRequestRecord.iCare_Draft_ETRF__c == true){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "Job Request saved",
                            variant: "success",
                        }),
                    );
                    this.backToSubmitARequest();
                }else{
                    this.handleProgressBarUpdate();
                    this.jobRequestRecordId = record.Id;
                    this.currentStepNumber = 6;
                }
              })
              .catch((error) => {
                  this.showSpinner = false;
                  this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error creating record",
                        message: error.body.message,
                        variant: "error",
                    }),
                  );
              });
          }else{
              apexSaveJobRequest({jobRequest : recordInput})
              .then((record) => {
                  this.linkContentDocumentToJobRequest(record.Id,  this.contentVersionIds);
                  this.showSpinner = false;
                  if(this.jobRequestRecord.iCare_Draft_ETRF__c == true){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Job Request created',
                            variant: 'success',
                        }),
                    );
                    this.backToSubmitARequest();
                  } else{
                          this.handleProgressBarUpdate();
                          this.jobRequestRecordId = record.Id;
                          this.currentStepNumber = 6;
                          if(this.jobRequestRecord.iCare_Active_Favourite__c == true){
                              this.backToSubmitARequest();
                          }
                  }
              })
              .catch(error => {
                      this.showSpinner = false;
                      this.error = error;
                      this.dispatchEvent(
                          new ShowToastEvent({
                              title: 'Error creating record',
                              message: error.body.message,
                              variant: 'error',
                          }),
                      );
                      console.log("error", JSON.stringify(this.error));
                  });
          }
      }


  linkContentDocumentToJobRequest(recordId, contentVersionIds){
    if(contentVersionIds && contentVersionIds.length > 0){
      createContentLink({contentVersionIds: contentVersionIds, recordId: recordId})
      .then((result1) => {
        console.log('result1 : ',JSON.stringify(result1));
      }).catch(error1 => {
        console.log(error1);
      })
    }
  }

    handleDeclarationCheckboxChange(event){
        this.jobRequestRecord.GTS_CoC_Declaration_1__c = event.detail.declaration6;
        this.jobRequestRecord.GTS_CoC_Declaration_2__c = event.detail.declaration4;
        this.jobRequestRecord.GTS_CoC_Declaration_3__c = event.detail.declaration5;
        this.isWetIssuingOffice = event.detail.isWetIssuingOffice;
        this.showContinueButtonVal = this.checkDeclaration();
    }

    handleGeneralInfoChange(event){
        this.jobRequestRecord.GTS_Program__c = event.detail.certificate;
        this.jobRequestRecord.ProgramName = event.detail.certificateLabel;
        this.jobRequestRecord.GTS_Applicant_Type__c = event.detail.applicantType;
        this.jobRequestRecord.GTS_Client_Reference__c = event.detail.clientReference;
    }

    handleClickCancel(event){
        this.backToSubmitARequest();
    }

    backToSubmitARequest(event){
        const generalInfoChanged = new CustomEvent("displaysubmitatestrequestpage");
        this.dispatchEvent(generalInfoChanged);

        this.currentStepNumber = 7;
        this.handleProgressBarUpdate();
    }

    showError = false;

    handleClickConfirm(){
        this.jobRequestRecord.iCare_Draft_ETRF__c = false;
        this.jobRequestRecord.GTS_Create_RFC_PDF__c = true;
        this.jobRequestRecord.iCare_Form_Completion_Date__c = new Date();
        this.showError = !this.validateRequiredFields();
        if(this.showError == false){
          this.saveJobRequest();
        }
    }

      get showErrorBox(){
          return this.missingFields != undefined && this.missingFields.length > 0;
      }

    requiredFields = {
        'GTS_Program__c' : SHIPMENT_CERTIFICATE,
        'GTS_Applicant_Type__c' : APPLICANT_TYPE,
        'GTS_Applicant_Company_Name__c' : EXPORTER + ' ' + COMPANY_NAME,
        'iCare_Applicant_Address__City__s' : EXPORTER + ' ' + CITY,
        'iCare_Applicant_Address__CountryCode__s' : EXPORTER + ' ' + COUNTRY,
        'iCare_Applicant_Address__PostalCode__s' : EXPORTER + ' ' + POSTAL_CODE,
        'iCare_Applicant_Address__Street__s': EXPORTER + ' ' + STREET,
        'iCare_Applicant_Contact_Person_Name__c': EXPORTER + ' ' + CONTACT_PERSON,
        'iCare_Applicant_Email__c' :EXPORTER + ' ' + EMAIL,
        'GTS_Applicant_Contact_Number__c' :EXPORTER + ' ' + CONTACT_NUMBER,
        'GTS_Commercial_Registration_No_TIN__c' : EXPORTER + ' ' + COMMERCIAL_NR,
        'GTS_Importer_Company_Name_Text__c' : IMPORTER + ' ' + COMPANY_NAME,
        'GTS_Importer_Company_Address__City__s': IMPORTER + ' ' + CITY,
        'GTS_Importer_Company_Address__CountryCode__s':  IMPORTER + ' ' + COUNTRY,
        'GTS_Importer_Company_Address__PostalCode__s':  IMPORTER + ' ' + POSTAL_CODE,
        'GTS_Importer_Company_Address__Street__s':  IMPORTER + ' ' + STREET,
        'GTS_Importer_Contact_Person_Name_Text__c': IMPORTER + ' ' + CONTACT_PERSON,
        'GTS_Importer_Email__c' : IMPORTER + ' ' + EMAIL,
        'GTS_Importer_Contact_Number__c' : IMPORTER + ' ' + CONTACT_NUMBER,
        'GTS_Importer_Commercial_Reg_No_TIN__c' : IMPORTER + ' ' + COMMERCIAL_NR,
        'GTS_CoC_Declaration_1__c' : DECLARATION,
        'GTS_CoC_Declaration_2__c' : DECLARATION,
        'GTS_CoC_Declaration_3__c' : DECLARATION
    };
    missingFields = [];

    validateRequiredFields() {
      let isValid = true;
      for (const key of Object.keys(this.requiredFields)) {
        if (!this.jobRequestRecord.hasOwnProperty(key) || this.jobRequestRecord[key] === null || this.jobRequestRecord[key] === undefined || this.jobRequestRecord[key] === ''
            || (typeof this.jobRequestRecord[key] === 'boolean' && this.jobRequestRecord[key] === false)
        ) {
            if (!this.missingFields.includes(this.requiredFields[key])) {
                this.missingFields = [...this.missingFields, this.requiredFields[key]];
            }
            isValid = false;
        }
      }
      return isValid;
    }

    handleApplicantPageUpdate(event){

        if(event.detail.exporterDetails != undefined){
            this.jobRequestRecord.iCare_Applicant_Company__c = event.detail.exporterDetails.applicantId;
            this.jobRequestRecord.GTS_Applicant_Company_Name__c = event.detail.exporterDetails.applicantName;
            this.jobRequestRecord.iCare_Applicant_Address__City__s = event.detail.exporterDetails.city;
            this.jobRequestRecord.iCare_Applicant_Address__CountryCode__s = event.detail.exporterDetails.country;
            this.jobRequestRecord.iCare_Applicant_Address__PostalCode__s = event.detail.exporterDetails.postalCode;
            this.jobRequestRecord.iCare_Applicant_Address__Street__s = event.detail.exporterDetails.street;
            this.jobRequestRecord.iCare_Applicant_Address__StateCode__s = event.detail.exporterDetails.state;
            this.jobRequestRecord.GTS_Applicant_Contact_Person__c = event.detail.exporterDetails.contactId;
            this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c = event.detail.exporterDetails.contactName;
            this.jobRequestRecord.GTS_Applicant_Contact_Number__c = event.detail.exporterDetails.contactPhone;
            this.jobRequestRecord.iCare_Applicant_Email__c = event.detail.exporterDetails.contactEmail;
            this.jobRequestRecord.GTS_Commercial_Registration_No_TIN__c = event.detail.exporterDetails.contactCommercialNr;
        }

        if(event.detail.importerDetails != undefined){
            this.jobRequestRecord.GTS_Importer_Company_Name__c = event.detail.importerDetails.applicantId;
            this.jobRequestRecord.GTS_Importer_Company_Name_Text__c = event.detail.importerDetails.applicantName;
            this.jobRequestRecord.GTS_Importer_Company_Address__City__s = event.detail.importerDetails.city;
            this.jobRequestRecord.GTS_Importer_Company_Address__CountryCode__s = event.detail.importerDetails.country;
            this.jobRequestRecord.GTS_Importer_Company_Address__PostalCode__s = event.detail.importerDetails.postalCode;
            this.jobRequestRecord.GTS_Importer_Company_Address__Street__s = event.detail.importerDetails.street;
            this.jobRequestRecord.GTS_Importer_Company_Address__StateCode__s = event.detail.importerDetails.state;
            this.jobRequestRecord.GTS_Importer_Contact_Person__c = event.detail.importerDetails.contactId;
            this.jobRequestRecord.GTS_Importer_Contact_Person_Name_Text__c = event.detail.importerDetails.contactName;
            this.jobRequestRecord.GTS_Importer_Contact_Number__c = event.detail.importerDetails.contactPhone;
            this.jobRequestRecord.GTS_Importer_Email__c = event.detail.importerDetails.contactEmail;
            this.jobRequestRecord.GTS_Importer_Commercial_Reg_No_TIN__c = event.detail.importerDetails.contactCommercialNr;
        }

        if(event.detail.inspectionLocationDetails != undefined){
            this.jobRequestRecord.GTS_Inspection_Location_Company_Name__c = event.detail.inspectionLocationDetails.applicantId;
            this.jobRequestRecord.GTS_Inspection_Location_Company_Text__c = event.detail.inspectionLocationDetails.applicantName;
            this.jobRequestRecord.GTS_Inspection_Location_Company_Address__City__s = event.detail.inspectionLocationDetails.city;
            this.jobRequestRecord.GTS_Inspection_Location_Company_Address__CountryCode__s = event.detail.inspectionLocationDetails.country;
            this.jobRequestRecord.GTS_Inspection_Location_Company_Address__PostalCode__s = event.detail.inspectionLocationDetails.postalCode;
            this.jobRequestRecord.GTS_Inspection_Location_Company_Address__Street__s = event.detail.inspectionLocationDetails.street;
            this.jobRequestRecord.GTS_Inspection_Location_Company_Address__StateCode__s = event.detail.inspectionLocationDetails.state;
            this.jobRequestRecord.GTS_Inspection_Location_Contact_Person__c = event.detail.inspectionLocationDetails.contactId;
            this.jobRequestRecord.GTS_Inspection_Loc_Contact_Name_Text__c = event.detail.inspectionLocationDetails.contactName;
            this.jobRequestRecord.GTS_Inspection_Location_Contact_Number__c = event.detail.inspectionLocationDetails.contactPhone;
            this.jobRequestRecord.GTS_Inspection_Location_Email__c = event.detail.inspectionLocationDetails.contactEmail;

        }

            if(event.detail.payerDetails != undefined){
                this.jobRequestRecord.GTS_Payer_Company_Name__c = event.detail.payerDetails.applicantId;
                this.jobRequestRecord.GTS_Payer_Company_Name_Text__c = event.detail.payerDetails.applicantName;
                this.jobRequestRecord.GTS_Payer_Company_Address__City__s = event.detail.payerDetails.city;
                this.jobRequestRecord.GTS_Payer_Company_Address__CountryCode__s = event.detail.payerDetails.country;
                this.jobRequestRecord.GTS_Payer_Company_Address__PostalCode__s = event.detail.payerDetails.postalCode;
                this.jobRequestRecord.GTS_Payer_Company_Address__Street__s = event.detail.payerDetails.street;
                this.jobRequestRecord.GTS_Payer_Company_Address__StateCode__s = event.detail.payerDetails.state;
                this.jobRequestRecord.GTS_Payer_Contact_Person__c = event.detail.payerDetails.contactId;
                this.jobRequestRecord.GTS_Payer_Contact_Person_Text__c = event.detail.payerDetails.contactName;
                this.jobRequestRecord.GTS_Payer_Contact_Number__c = event.detail.payerDetails.contactPhone;
                this.jobRequestRecord.GTS_Payer_Email__c = event.detail.payerDetails.contactEmail;
                this.jobRequestRecord.GTS_Payer_Company_Address__City__s = event.detail.payerDetails.city;
                this.jobRequestRecord.GTS_Purchase_Order_Number__c = event.detail.payerDetails.contactPONr;

            }
        this.jobRequestRecord.GTS_Inview_Requested__c = event.detail.inviewRequested;
    }

    handleShipmentDocumentChange(event){
        this.jobRequestRecord = { ...event.detail.jobRequestRecord};
    }

    handleSaveFavouriteJobRequest(event) {
        this.jobRequestRecord.iCare_Active_Favourite__c = true;
        this.jobRequestRecord.iCare_Favourite_Name__c = event.detail.favouriteName;
        this.jobRequestRecord.GTS_Create_RFC_PDF__c = false;
        this.saveJobRequest();
    }
}