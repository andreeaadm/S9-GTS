import { LightningElement, track, wire, api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { publish,subscribe, MessageContext } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import UPDATE_PROGRESS_BAR from '@salesforce/messageChannel/GTLPortalMessageChannel__c';
import STEP_CLICK from '@salesforce/messageChannel/GTLPortalMessageChannelProgressBar__c';

import APPLICANT from '@salesforce/label/c.GTS_Job_Information';
import BACK from '@salesforce/label/c.GTS_Back';
import CANCEL from '@salesforce/label/c.GTS_Cancel';
import CONFIRM from '@salesforce/label/c.GTS_Confirm_Submit';
import CONTINUE from '@salesforce/label/c.GTS_Continue';
import DECLARATION from '@salesforce/label/c.GTS_Declaration';
import DOCUMENTS from '@salesforce/label/c.GTS_Documents';
import PURPOSE_APPLICATION from '@salesforce/label/c.GTS_Purpose_of_Application';
import REQUIRED_FIELDS from '@salesforce/label/c.GTS_CoC_Required_Fields';
import SAVE_DRAFT from '@salesforce/label/c.GTS_Save_as_Draft';
import REGISTRATION_LICENSE from '@salesforce/label/c.GTS_Registration_Licence_Renewal_Revision';

import DRAFT_ETRF from '@salesforce/schema/icare_Job_Request__c.iCare_Draft_ETRF__c';

import JOB_REQUEST_OBJECT from "@salesforce/schema/icare_Job_Request__c";

import { getJobRequestSimpleDescription } from "c/gtsJobRequestUtility";
import { validatePageRequiredFields } from "c/gtsJobRequestUtility";

import createContentLink from "@salesforce/apex/ICareFileUploadController.createContentLink";
import apexSaveJobRequest from "@salesforce/apex/GTSJobRequestSave.saveJobRequestAndAssociatedJobRequest";

export default class GtsLicenseRenewRevisionContainer extends NavigationMixin(LightningElement) {
    @api jobId;
    @api recordTypeId;
    @api jobRequestInput;
    @api accountRecord;
    @api contactRecord;
    contentVersionIds = [];
    newContentVersionIds = [];
    @api inputContentVersionIds;

    @track jobRequestRecordId;
    @track isWetIssuingOffice;

    @track isPurposeOfApplicantVisited = false;
    @track isApplicantVisited = false;
    @track isDocVisited = false;
    @track isDeclarationVisited = false;

    labels = {
        APPLICANT,
        BACK,
        CANCEL,
        CONFIRM,
        CONTINUE,
        DECLARATION,
        DOCUMENTS,
        PURPOSE_APPLICATION,
        REQUIRED_FIELDS,
        SAVE_DRAFT
    }

    get showCancelButton(){
        return (this.currentStepNumber < 4);
    }

    get showBackButton(){
        return (this.currentStepNumber > 0 && this.currentStepNumber <= 4 );
    }

    get showPurposeOfApplicant(){
        return (this.currentStepNumber == 0);
    }
    get showApplicant(){
        return (this.currentStepNumber == 1);
    }
    get showDocuments(){
        return (this.currentStepNumber == 2);
    }
    get showDeclaration(){
        return (this.currentStepNumber == 3);
    }
    get showSummary(){

        return (this.currentStepNumber == 4);
    }
    get showThankYouPage(){

        return (this.currentStepNumber == 5);
    }
    showSpinner = false;

    @track showContinueButtonVal = false;
    get showContinueButton(){
        return (this.showPurposeOfApplicant || this.showApplicant || this.showDocuments || this.showDeclaration);
    }

    get continueButtonClass(){
        return (this.showDeclaration && !this.showContinueButtonVal) ? 'disable-button' : 'blue-button';
    }

    get disableContinueButton(){
        return (this.showDeclaration && !this.showContinueButtonVal);
    }

    checkDeclaration(){
        return (this.jobRequestRecord.GTS_LRF_Declaration_1__c == true && this.jobRequestRecord.GTS_LRF_Declaration_2__c == true && (this.jobRequestRecord.GTS_LRF_Declaration_3__c == true || !this.isWetIssuingOffice)) ;
    }

    handleDocumentUpload(event){
        console.log('Reg-Lic controller documentUpload : ',event.detail);
        this.newContentVersionIds.push(event.detail);
        this.contentVersionIds.push(event.detail);
    }

    jobRequestRecord;

    getCurrentStepBaseOnLabel(label){
        switch (label) {
            case PURPOSE_APPLICATION:
                this.currentStepNumber = 0;
                break;
            case APPLICANT:
                this.currentStepNumber = 1;
                break;
            case DOCUMENTS:
                this.currentStepNumber = 2;
                break;
            case DECLARATION:
                this.currentStepNumber = 3;
                break;
            default:
                break;
        }
    }

    getLabelBasedOnCurrentStep(){
        switch (this.currentStepNumber) {
            case 0:
                this.progressBarStepsLabels = PURPOSE_APPLICATION;
                break;
            case 1:
                this.progressBarStepsLabels = APPLICANT;
                break;
            case 2:
                this.progressBarStepsLabels = DOCUMENTS;
                break;
            case 3:
                this.progressBarStepsLabels = DECLARATION;
                break;
            default:
                break;
        }
    }


    @track currentStepNumber = 0;
    @track currentStepLabel = PURPOSE_APPLICATION;

    subscription = null;
    @wire(MessageContext) messageContext;
    @wire(MessageContext) messageContextPB;
    @track progressBarStepsLabels = [
        PURPOSE_APPLICATION,
        APPLICANT,
        DOCUMENTS,
        DECLARATION
    ];


    connectedCallback() {
        this.currentStepNumber = 0;
        console.log('this.jobRequestRecord.currentStepNumber',this.currentStepNumber);
        console.log('this.jobRequestRecord.GTS_Renewal_Revision__c',this.jobRequestInput.GTS_Renewal_Revision__c);

        this.jobRequestRecord = {...this.jobRequestInput};
        if(this.inputContentVersionIds.length > 0){
            this.contentVersionIds = [...this.inputContentVersionIds];
        }
        this.jobRequestRecord.RecordTypeId = this.recordTypeId;
        console.log('0');
        this.jobRequestRecord.iCare_Applicant_Company__c = this.accountRecord.data.fields.Id.value;
        console.log('1');

        this.jobRequestRecord.GTS_Applicant_Company_Name__c = this.accountRecord.data.fields.Name.value;
        if(this.jobRequestRecord.GTS_Applicant_Contact_Person__c == undefined || this.jobRequestRecord.GTS_Applicant_Contact_Person__c.length == 0){
            this.jobRequestRecord.GTS_Applicant_Contact_Person__c = this.contactRecord.data.fields.ContactId.value;
        }
        console.log('2');
        if(this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c == undefined || this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c.length == 0){
            this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c = this.contactRecord.data.fields.Contact.displayValue;
        }
        console.log('3');
        if(this.accountRecord.data.fields.GTS_Applicant_Type__c.value != undefined && this.accountRecord.data.fields.GTS_Applicant_Type__c.value.length >0){
            this.jobRequestRecord.GTS_Applicant_Type__c = this.accountRecord.data.fields.GTS_Applicant_Type__c.value;
        }
        console.log('4');
        console.log('this.jobRequestRecord.GTS_Renewal_Revision__c',this.jobRequestRecord.GTS_Renewal_Revision__c);


        this.handleProgressBarUpdate();
        this.subscribeToProgressBarClickMessageChannel();
        sessionStorage.removeItem('uploadedDocuments');
    }

    checkVisitedPages(){
        if(this.showPurposeOfApplicant){
            this.isPurposeOfApplicantVisited = true;
        }else if(this.showApplicant){
            this.isApplicantVisited = true;
        }else if(this.showDocuments){
            this.isDocVisited = true;
        }else if(this.showDeclaration){
            this.isDeclarationVisited = true;
        }
    }

    get stepsArray(){
        this.checkVisitedPages();
        return (this.currentStepNumber > 4) ? [] : [
                           {
                               stepName: this.labels.PURPOSE_APPLICATION,
                               isCurrent : this.showPurposeOfApplicant,
                               isVisited : this.isPurposeOfApplicantVisited
                           },
                           {
                               stepName: this.labels.APPLICANT,
                               isCurrent : this.showApplicant,
                               isCompleted : validatePageRequiredFields(['GTS_Applicant_Company_Name__c', 'iCare_Applicant_Address__City__s', 'iCare_Applicant_Address__CountryCode__s', 'iCare_Applicant_Address__PostalCode__s', 'iCare_Applicant_Address__Street__s', 'iCare_Applicant_Contact_Person_Name__c', 'iCare_Applicant_Email__c', 'GTS_Applicant_Contact_Number__c',  'GTS_Applicant_Type__c'],
                               this.jobRequestRecord
                               ),
                               isVisited : this.isApplicantVisited,
                               hasRequiredFields : true
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

    subscribeToProgressBarClickMessageChannel() {
        this.subscription = subscribe(
            this.messageContextPB,
            STEP_CLICK,
            (message) => this.handleProgressBarMessage(message)
        );
    }

    handleProgressBarMessage(message){
        this.getCurrentStepBaseOnLabel(message.step);
        this.handleProgressBarUpdate();
    }

    handleClickCancel(event){
        this.backToSubmitARequest();
    }

    handleClickBack(event){
        this.currentStepNumber -= 1;
        this.handleProgressBarUpdate();
    }

    handleClickContinue(event) {
        this.currentStepNumber += 1;
        if(this.currentStepNumber == 4){
            this.missingFields = [];
        }
        this.handleProgressBarUpdate();
    }

    backToSubmitARequest(event){
        if(this.jobId){
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name:'Home'
                }
            });
        }else{
            const generalInfoChanged = new CustomEvent("displaysubmitatestrequestpage");
            this.dispatchEvent(generalInfoChanged);

            this.currentStepNumber = 6
        }

        this.handleProgressBarUpdate();
    }

    handleClickSaveDraft(){
        this.jobRequestRecord.iCare_Draft_ETRF__c = true;
        this.jobRequestRecord.iCare_Sample_Description__c = getJobRequestSimpleDescription(this.jobRequestRecord,REGISTRATION_LICENSE);
        this.saveJobRequest();
    }

    showError = false;
    handleClickConfirm(){
        this.jobRequestRecord.iCare_Draft_ETRF__c = false;
        this.showError = !this.validateRequiredFields();
        if(this.showError == false){
          this.saveJobRequest();
        }
    }

        requiredFields = {
            'GTS_Applicant_Type__c' : 'Applicant Type ',
            'GTS_Applicant_Company_Name__c' : 'Exporter Company Name ',
            'iCare_Applicant_Address__City__s' : 'Exporter Company Address ',
            'iCare_Applicant_Address__CountryCode__s' : 'Exporter Company Address ',
            'iCare_Applicant_Address__PostalCode__s' : 'Exporter Company Address ',
            'iCare_Applicant_Address__Street__s': 'Exporter Company Address ',
            'iCare_Applicant_Contact_Person_Name__c': 'Exporter Contact Person ',
            'iCare_Applicant_Email__c' :'Exporter Contact E-Mail ',
            'GTS_Applicant_Contact_Number__c' :'Exporter Contact Number '
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

      
        handleSaveFavouriteJobRequest(event) {
            
            this.jobRequestRecord.iCare_Active_Favourite__c = true;
            this.jobRequestRecord.iCare_Favourite_Name__c = event.detail.favouriteName;
            console.log(this.jobRequestRecord.iCare_Active_Favourite__c, this.jobRequestRecord.iCare_Favourite_Name__c);
    
            this.saveJobRequest();

        }
        get showErrorBox(){
              return this.missingFields != undefined && this.missingFields.length > 0;
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
               apexSaveJobRequest({jobRequest : recordInput, jobId : this.jobId})
              .then((record) => {
                this.linkContentDocumentToJobRequest(record.Id,  this.newContentVersionIds);
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
                     this.jobRequestRecordId = record.Id;
                     this.currentStepNumber = 5;
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
              apexSaveJobRequest({jobRequest : recordInput, jobId : this.jobId})
              .then((record) => {
                  this.linkContentDocumentToJobRequest(record.Id,  this.contentVersionIds);
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
                          this.showSpinner = false;
                          this.jobRequestRecordId = record.Id;
                          this.currentStepNumber = 5;
                          if(this.jobRequestRecord.iCare_Active_Favourite__c == true){
                              this.backToSubmitARequest();
                          }
                  }
              })
              .catch(error => {
                      this.message = undefined;
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

    handlePurposeOfApplication(event){
        this.jobRequestRecord.GTS_Renewal_Revision__c = event.detail.renewRevision;
      
//        this.jobRequestRecord.GTS_Program__c = event.detail.certificate;
//        this.jobRequestRecord.ProgramName = event.detail.certificateLabel;
//        this.jobRequestRecord.GTS_Type_of_Application__c = event.detail.typeOfApplication;
//        this.jobRequestRecord.GTS_Other_No_please_specify__c = event.detail.otherText;

    }


    handleDeclarationCheckboxChange(event){
        this.jobRequestRecord.GTS_LRF_Declaration_1__c = event.detail.declaration6;
        this.jobRequestRecord.GTS_LRF_Declaration_2__c = event.detail.declaration4;
        this.jobRequestRecord.GTS_LRF_Declaration_3__c = event.detail.declaration5;
        this.isWetIssuingOffice = event.detail.isWetIssuingOffice;
        this.showContinueButtonVal = this.checkDeclaration();
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
                this.jobRequestRecord.GTS_Applicant_Type__c = event.detail.exporterDetails.applicantType;
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
            }
        }
}