import { LightningElement, wire, api, track } from "lwc";
import SAVE_DRAFT from "@salesforce/label/c.GTS_Save_as_Draft";
import CANCEL from "@salesforce/label/c.GTS_Cancel";
import BACK from "@salesforce/label/c.GTS_Back";
import CONTINUE from "@salesforce/label/c.GTS_Continue";
import DECLARATION from "@salesforce/label/c.GTS_Declaration";
import APPLICANT_PAYER from "@salesforce/label/c.GTS_Applicant_Payer";
import INSPECTION_DETAILS from "@salesforce/label/c.GTS_Inspection_Details";
import DOCUMENTS_SOW from "@salesforce/label/c.GTS_Document_Label";
import GENERAL_INFO from "@salesforce/label/c.GTS_GeneralInformation_SOW";
import BACK_TO_EDIT from "@salesforce/label/c.GTS_Back_To_Edit";
import SUBMIT from "@salesforce/label/c.GTS_Confirm_Submit";
import REQUIRED_FIELDS from "@salesforce/label/c.GTS_CoC_Required_Fields";
import COMMERCIAL_SERVICES_TRADEABLE from "@salesforce/label/c.GTS_Commercial_Services_Tradeable";
import EXPORTER from '@salesforce/label/c.GTS_Exporter';
import COMPANY_NAME from "@salesforce/label/c.GTS_Company_Name";
import CITY from "@salesforce/label/c.GTS_City";
import COUNTRY from "@salesforce/label/c.GTS_Country";
import POSTAL_CODE from "@salesforce/label/c.GTS_PostalCode";
import STREET from "@salesforce/label/c.GTS_Street";
import CONTACT_PERSON from "@salesforce/label/c.GTS_Contact_Person";
import EMAIL from "@salesforce/label/c.GTS_Email";
import COMMERCIAL_SERVICE_REQUIRED from '@salesforce/label/c.GTS_Commercial_Service_Required';
import STATEMENT_OF_WORK from "@salesforce/label/c.GTS_Statement_Of_Work";
import COMMERCIAL_NR from "@salesforce/label/c.GTS_Commercial_Registration_No";
import CONTACT_NUMBER from "@salesforce/label/c.GTS_Contact_Number";
import UPDATE_PROGRESS_BAR from "@salesforce/messageChannel/GTLPortalMessageChannel__c";
import STEP_CLICK from "@salesforce/messageChannel/GTLPortalMessageChannelProgressBar__c";

import { ShowToastEvent } from "lightning/platformShowToastEvent";

import { publish, subscribe, MessageContext } from "lightning/messageService";

import JOB_REQUEST_OBJECT from "@salesforce/schema/icare_Job_Request__c";
import { getJobRequestSimpleDescription } from "c/gtsJobRequestUtility";
import { validatePageRequiredFields } from "c/gtsJobRequestUtility";

import createContentLink from "@salesforce/apex/ICareFileUploadController.createContentLink";
import apexSaveJobRequest from "@salesforce/apex/GTSJobRequestSave.saveJobRequest";

import { getObjectInfo } from "lightning/uiObjectInfoApi";

export default class GtsTradeableController extends LightningElement {
  @api isReadOnly = false;

  @api accountRecord;
  @api contactRecord;
  @api recordTypeId;
  isRequiredFieldsBlank = false;
  missingFields = [];

  @track jobRequestRecordId;

  showGeneralInformation = true;
  showApplicantPayer;
  showInspectionDetails;
  showDocuments;
  showDeclaration;
  showSummary;
  showThankYouPage;

  validationStatus = false;
  isOtherComServ = false;

  @track currentStepNumber = 0;
  subscription = null;
  showSpinner = false;
  contentVersionIds = [];
  newContentVersionIds = [];
  @api inputContentVersionIds;

  @track isDeclarationChecked = false;

  @track isGeneralInfoVisited = false;
  @track isApplicantVisited = false;
  @track isInspectionVisited = false;
  @track isDocVisited = false;
  @track isDeclarationVisited = false;

  labels = {
    CANCEL,
    CONTINUE,
    SAVE_DRAFT,
    GENERAL_INFO,
    APPLICANT_PAYER,
    INSPECTION_DETAILS,
    DOCUMENTS_SOW,
    DECLARATION,
    BACK_TO_EDIT,
    SUBMIT,
    BACK,
    REQUIRED_FIELDS
  };

  @api jobRequestInput;
  jobRequestRecord;

  @wire(MessageContext) messageContext;
  @wire(MessageContext) messageContextPB;

  requiredFields = {
    GTS_Program__c: COMMERCIAL_SERVICE_REQUIRED,
    GTS_Applicant_Company_Name__c: EXPORTER + ' ' + COMPANY_NAME,
    iCare_Applicant_Address__City__s: EXPORTER + ' ' + CITY,
    iCare_Applicant_Address__CountryCode__s: EXPORTER + ' ' + COUNTRY,
    iCare_Applicant_Address__PostalCode__s: EXPORTER + ' ' + POSTAL_CODE,
    iCare_Applicant_Address__Street__s: EXPORTER + ' ' + STREET,
    iCare_Applicant_Contact_Person_Name__c: EXPORTER + ' ' + CONTACT_PERSON,
    iCare_Applicant_Email__c: EXPORTER + ' ' + EMAIL,
    GTS_Applicant_Contact_Number__c: EXPORTER + ' ' + CONTACT_NUMBER,
    GTS_Statement_of_Work__c: STATEMENT_OF_WORK
  };
  validateRequiredFields() {
    let isValid = true;
    for (const key of Object.keys(this.requiredFields)) {
      if (
        !this.jobRequestRecord.hasOwnProperty(key) ||
        this.jobRequestRecord[key] === null ||
        this.jobRequestRecord[key] === undefined ||
        this.jobRequestRecord[key] === "" ||
        (typeof this.jobRequestRecord[key] === "boolean" &&
          this.jobRequestRecord[key] === false)
      ) {
        if (!this.missingFields.includes(this.requiredFields[key])) {
          this.missingFields = [
            ...this.missingFields,
            this.requiredFields[key]
          ];
        }
        isValid = false;
      }
    }
    return isValid;
  }

  handleGeneralInfoChange(event) {
    console.log("event.detail.comServReq : ", event.detail.comServReq);
    this.jobRequestRecord.GTS_Program__c = event.detail.comServReq;
    this.jobRequestRecord.ProgramName = event.detail.programName;
    if (event.detail.otherValue) {
      this.jobRequestRecord.GTS_ComSer_Prog_Please_Specify__c =
        event.detail.otherValue;
      this.isOtherComServ = true;
    } else {
      this.isOtherComServ = false;
    }
  }

  handleDateValidation(event) {
    this.validationStatus = event.detail;
    console.log("event.detail : ", event.detail);
  }

  handleDeclarationCheckboxChange(event) {
    this.jobRequestRecord.GTS_ComSer_Declaration_1__c =
      event.detail.declaration1;
    this.jobRequestRecord.GTS_ComSer_Declaration_2__c =
      event.detail.declaration2;
    this.jobRequestRecord.GTS_ComServ_Declaration_3__c =
      event.detail.declaration3;
    this.jobRequestRecord.GTS_ComSer_Declaration_4__c =
      event.detail.declaration4;
    this.jobRequestRecord.GTS_CoC_Declaration_3__c = event.detail.declaration5;

    if (
      this.jobRequestRecord.GTS_ComSer_Declaration_1__c &&
      this.jobRequestRecord.GTS_ComSer_Declaration_2__c &&
      this.jobRequestRecord.GTS_ComServ_Declaration_3__c &&
      this.jobRequestRecord.GTS_ComSer_Declaration_4__c &&
      (this.jobRequestRecord.GTS_CoC_Declaration_3__c || !(event.detail.isWetIssuingOffice))
    ) {
      this.isDeclarationChecked = true;
      this.validationStatus = false;
    } else {
      this.isDeclarationChecked = false;
      this.validationStatus = true;
    }
  }

  handleDocumentUpload(event){
    console.log('tradeable controller documentUpload : ',event.detail);
    this.newContentVersionIds.push(event.detail);
    this.contentVersionIds.push(event.detail);
  }

  get showCancelButton() {
    return this.currentStepNumber < 6;
  }

  get showBackButton() {
    return this.currentStepNumber > 0 && this.currentStepNumber < 6;
  }

  get showContinueButton() {
    return (
      this.showGeneralInformation ||
      this.showApplicantPayer ||
      this.showInspectionDetails ||
      this.showDocuments ||
      this.showDeclaration
    );
  }

  get continueButtonClass() {
    return this.validationStatus ? "grey-button" : "blue-button";
  }

  checkVisitedPages(){
      if(this.showGeneralInformation){
          this.isGeneralInfoVisited = true;
      }else if(this.showApplicantPayer){
          this.isApplicantVisited = true;
      }else if(this.showInspectionDetails){
          this.isInspectionVisited = true;
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
                               isCompleted : validatePageRequiredFields(['GTS_Program__c'], this.jobRequestRecord),
                               isVisited : this.isGeneralInfoVisited,
                               hasRequiredFields : true
                           },
                           {
                               stepName: this.labels.APPLICANT_PAYER,
                               isCurrent : this.showApplicantPayer,
                               isCompleted : validatePageRequiredFields(['GTS_Applicant_Company_Name__c', 'iCare_Applicant_Address__City__s', 'iCare_Applicant_Address__CountryCode__s', 'iCare_Applicant_Address__PostalCode__s', 'iCare_Applicant_Address__Street__s', 'iCare_Applicant_Contact_Person_Name__c', 'iCare_Applicant_Email__c', 'GTS_Applicant_Contact_Number__c'],
                               this.jobRequestRecord
                               ),
                               isVisited : this.isApplicantVisited,
                               hasRequiredFields : true
                           },
                           {
                               stepName: this.labels.INSPECTION_DETAILS,
                               isCurrent : this.showInspectionDetails,
                               isVisited : this.isInspectionVisited
                           },
                           {
                               stepName: this.labels.DOCUMENTS_SOW,
                               isCompleted : validatePageRequiredFields(['GTS_Statement_of_Work__c'], this.jobRequestRecord),
                               isCurrent : this.showDocuments,
                               isVisited : this.isDocVisited,
                               hasRequiredFields : true
                           },
                           {
                               stepName: this.labels.DECLARATION,
                               isCurrent : this.showDeclaration,
                               isCompleted : this.isDeclarationChecked,
                               isLastStep : true,
                               isVisited : this.isDeclarationVisited,
                               hasRequiredFields : true
                           }
                       ];
                       console.log('end3');
    }

  handleProgressBarUpdate() {
        const payload = {
            stepsArray: this.stepsArray
        };
        publish(this.messageContext, UPDATE_PROGRESS_BAR, payload);
  }

  connectedCallback() {
    this.jobRequestRecord = { ...this.jobRequestInput };
    if(this.inputContentVersionIds.length > 0){
        this.contentVersionIds = [...this.inputContentVersionIds];
    }
    this.handleProgressBarUpdate();
    this.subscribeToProgressBarClickMessageChannel();

    this.jobRequestRecord.RecordTypeId = this.recordTypeId;
    this.jobRequestRecord.iCare_Applicant_Company__c =
      this.accountRecord.data.fields.Id.value;
    this.jobRequestRecord.GTS_Applicant_Company_Name__c =
      this.accountRecord.data.fields.Name.value;

    this.jobRequestRecord.iCare_Applicant_Address__City__s =
      this.accountRecord.data.fields.BillingCity.value;
    this.jobRequestRecord.iCare_Applicant_Address__Street__s =
      this.accountRecord.data.fields.BillingStreet.value;
    this.jobRequestRecord.iCare_Applicant_Address__PostalCode__s =
      this.accountRecord.data.fields.BillingPostalCode.value;
    this.jobRequestRecord.iCare_Applicant_Address__CountryCode__s =
      this.accountRecord.data.fields.BillingCountryCode.value;
    this.jobRequestRecord.iCare_Applicant_Address__StateCode__s =
      this.accountRecord.data.fields.BillingStateCode.value;

    if (
      this.jobRequestRecord.GTS_Applicant_Contact_Person__c == undefined ||
      this.jobRequestRecord.GTS_Applicant_Contact_Person__c.length == 0
    ) {
      this.jobRequestRecord.GTS_Applicant_Contact_Person__c =
        this.contactRecord.data.fields.ContactId.value;
    }
    if (
      this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c ==
        undefined ||
      this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c.length == 0
    ) {
      this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c =
        this.contactRecord.data.fields.Contact.displayValue;
    }
    sessionStorage.removeItem("uploadedDocuments");
  }

  subscribeToProgressBarClickMessageChannel() {
    this.subscription = subscribe(
      this.messageContextPB,
      STEP_CLICK,
      (message) => this.handleProgressBarMessage(message)
    );
  }

  handleProgressBarMessage(message) {
      this.showGeneralInformation = false;
      this.showApplicantPayer = false;
      this.showInspectionDetails = false;
      this.showDocuments = false;
      this.showDeclaration = false;
      this.showSummary = false;
      this.showThankYouPage = false;

      switch (message.step) {
        case GENERAL_INFO:
          this.showGeneralInformation = true;
          this.currentStepNumber = 0;
          break;
        case APPLICANT_PAYER:
          this.showApplicantPayer = true;
          this.currentStepNumber = 1;
          break;
        case INSPECTION_DETAILS:
          this.showInspectionDetails = true;
          this.currentStepNumber = 2;
          break;
        case DOCUMENTS_SOW:
          this.showDocuments = true;
          this.currentStepNumber = 3;
          break;
        case DECLARATION:
          this.showDeclaration = true;
          this.currentStepNumber = 4;
          this.validationStatus = true;
          break;
        default:
          break;
      }

      this.handleProgressBarUpdate();
  }

  handleClickCancel() {
    this.backToSubmitARequest();
  }

  backToSubmitARequest() {
    const generalInfoChanged = new CustomEvent("displaysubmitatestrequestpage");
    this.dispatchEvent(generalInfoChanged);

    this.currentStepNumber = 7;
    this.handleProgressBarUpdate();
  }

  handleClickContinue() {
    if (this.showGeneralInformation === true) {
      this.showGeneralInformation = false;
      this.showApplicantPayer = true;
      this.currentStepNumber = 1;
    } else if (this.showApplicantPayer === true) {
      this.showApplicantPayer = false;
      this.showInspectionDetails = true;
      this.currentStepNumber = 2;
    } else if (this.showInspectionDetails === true) {
      this.showInspectionDetails = false;
      this.showDocuments = true;
      this.currentStepNumber = 3;
    } else if (this.showDocuments === true) {
      this.showDocuments = false;
      this.showDeclaration = true;
      this.currentStepNumber = 4;
      this.validationStatus = true;
    } else if (this.showDeclaration === true) {
      this.showDeclaration = false;
      this.showSummary = true;
      this.currentStepNumber = 5;
    }
    this.handleProgressBarUpdate();
    this.currentStepNumber = this.currentStepNumber + 1;
  }

  handleClickBack() {
    this.validationStatus = false;
    if (this.showApplicantPayer === true) {
      this.showApplicantPayer = false;
      this.showGeneralInformation = true;
      this.currentStepNumber = 1;
    } else if (this.showInspectionDetails === true) {
      this.showInspectionDetails = false;
      this.showApplicantPayer = true;
      this.currentStepNumber = 2;
    } else if (this.showDocuments === true) {
      this.showDocuments = false;
      this.showInspectionDetails = true;
      this.currentStepNumber = 3;
    } else if (this.showDeclaration === true) {
      this.showDeclaration = false;
      this.showDocuments = true;
      this.currentStepNumber = 4;
    } else if (this.showSummary === true) {
      this.showSummary = false;
      this.showDeclaration = true;
      this.currentStepNumber = 5;
      this.isRequiredFieldsBlank = false;
    }
    this.handleProgressBarUpdate();
    this.currentStepNumber = this.currentStepNumber - 1;
  }

  saveJobRequest() {
    let newObject;
    if (this.jobRequestRecord.RecordTypeId != undefined) {
      newObject = { ...this.jobRequestRecord };
    } else {
      newObject = { ...this.jobRequestRecord, RecordTypeId: "" };
    }
    let fields;
    if(this.jobRequestRecord.iCare_Active_Favourite__c){
     fields = delete newObject.Id;
    }
    if (this.jobRequestRecord.RecordType != undefined) {
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
                                message: "Draft updated",
                                variant: "success",
                            }),
                        );
                        this.backToSubmitARequest();
                    }else{
                         this.handleProgressBarUpdate();
                         this.jobRequestRecordId = record.Id;
                         this.showThankYouPage = true;
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
          .then((result) => {
            this.message = result;
            this.error = undefined;
            this.linkContentDocumentToJobRequest(result.Id,  this.contentVersionIds);

            if (this.jobRequestRecord.iCare_Draft_ETRF__c === false) {
              this.showSpinner = false;
              this.showSummary = false;
              this.jobRequestRecordId = result.Id;
              this.showThankYouPage = true;
              if (this.jobRequestRecord.iCare_Active_Favourite__c == true) {
                this.backToSubmitARequest();
              }
            } else if (this.jobRequestRecord.iCare_Draft_ETRF__c === true) {
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Success",
                  message: "Job Request created",
                  variant: "success"
                })
              );
              this.backToSubmitARequest();
            }
          })
          .catch((error) => {
            this.showSpinner = false;
            this.message = undefined;
            this.error = error;
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error creating record",
                message: error.body.message,
                variant: "error"
              })
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

  handleSOWChange(event) {
    this.jobRequestRecord.GTS_Statement_of_Work__c = event.detail;
  }

  handleFinalReportChange(event){
    this.jobRequestRecord.GTS_Final_Report_Required__c = event.detail;
  }

  handleClickSaveDraft() {
    this.jobRequestRecord.iCare_Draft_ETRF__c = true;
    this.jobRequestRecord.iCare_Sample_Description__c =
      getJobRequestSimpleDescription(
        this.jobRequestRecord,
        COMMERCIAL_SERVICES_TRADEABLE
      );
    this.saveJobRequest();
  }

  handleClickConfirm() {
    this.jobRequestRecord.iCare_Draft_ETRF__c = false;
    this.jobRequestRecord.GTS_Create_RFC_PDF__c = true;
    this.jobRequestRecord.iCare_Form_Completion_Date__c = new Date();
    this.isRequiredFieldsBlank = !this.validateRequiredFields();
    if (this.isRequiredFieldsBlank === false) {
      this.saveJobRequest();
    }
  }

  handleSaveFavouriteJobRequest(event) {
    this.jobRequestRecord.iCare_Active_Favourite__c = true;
    this.jobRequestRecord.iCare_Favourite_Name__c = event.detail.favouriteName;
    this.jobRequestRecord.GTS_Create_RFC_PDF__c = false;
    this.saveJobRequest();
    this.backToSubmitARequest();
  }

  handleApplicantPageUpdate(event) {
    if (event.detail.exporterDetails != undefined) {
      this.jobRequestRecord.iCare_Applicant_Company__c =
        event.detail.exporterDetails.applicantId;
      this.jobRequestRecord.GTS_Applicant_Company_Name__c =
        event.detail.exporterDetails.applicantName;
      this.jobRequestRecord.GTS_Applicant_Contact_Person__c =
        event.detail.exporterDetails.contactId;
      this.jobRequestRecord.iCare_Applicant_Contact_Person_Name__c =
        event.detail.exporterDetails.contactName;
      this.jobRequestRecord.GTS_Applicant_Contact_Number__c =
        event.detail.exporterDetails.contactPhone;
      this.jobRequestRecord.iCare_Applicant_Email__c =
        event.detail.exporterDetails.contactEmail;

      this.jobRequestRecord.iCare_Applicant_Address__City__s =
        event.detail.exporterDetails.city;
      this.jobRequestRecord.iCare_Applicant_Address__Street__s =
        event.detail.exporterDetails.street;
      this.jobRequestRecord.iCare_Applicant_Address__PostalCode__s =
        event.detail.exporterDetails.postalCode;
      this.jobRequestRecord.iCare_Applicant_Address__CountryCode__s =
        event.detail.exporterDetails.country;
      this.jobRequestRecord.iCare_Applicant_Address__StateCode__s =
        event.detail.exporterDetails.state;
    }

    if (event.detail.payerDetails != undefined) {
      this.jobRequestRecord.GTS_Payer_Company_Name__c =
        event.detail.payerDetails.applicantId;
      this.jobRequestRecord.GTS_Payer_Company_Name_Text__c =
        event.detail.payerDetails.applicantName;
      this.jobRequestRecord.GTS_Payer_Contact_Person__c =
        event.detail.payerDetails.contactId;
      this.jobRequestRecord.GTS_Payer_Contact_Person_Text__c =
        event.detail.payerDetails.contactName;
      this.jobRequestRecord.GTS_Payer_Contact_Number__c =
        event.detail.payerDetails.contactPhone;
      this.jobRequestRecord.GTS_Payer_Email__c =
        event.detail.payerDetails.contactEmail;
      this.jobRequestRecord.GTS_Purchase_Order_Number__c =
        event.detail.payerDetails.contactPONr;
      this.jobRequestRecord.GTS_Purchase_Order__c =
        event.detail.payerDetails.contactPO;

      this.jobRequestRecord.GTS_Payer_Company_Address__City__s =
        event.detail.payerDetails.city;
      this.jobRequestRecord.GTS_Payer_Company_Address__Street__s =
        event.detail.payerDetails.street;
      this.jobRequestRecord.GTS_Payer_Company_Address__PostalCode__s =
        event.detail.payerDetails.postalCode;
      this.jobRequestRecord.GTS_Payer_Company_Address__CountryCode__s =
        event.detail.payerDetails.country;
      this.jobRequestRecord.GTS_Payer_Company_Address__StateCode__s =
        event.detail.payerDetails.state;
    }
  }

  handleInspectionPageUpdate(event) {
    if (event.detail.inspectionLocationDetails) {
      this.jobRequestRecord.GTS_Inspection_Location_Company_Name__c =
        event.detail.inspectionLocationDetails.applicantId;
      this.jobRequestRecord.GTS_Inspection_Location_Company_Text__c =
        event.detail.inspectionLocationDetails.applicantName;
      this.jobRequestRecord.GTS_Inspection_Location_Contact_Person__c =
        event.detail.inspectionLocationDetails.contactId;
      this.jobRequestRecord.GTS_Inspection_Loc_Contact_Name_Text__c =
        event.detail.inspectionLocationDetails.contactName;
      this.jobRequestRecord.GTS_Inspection_Location_Contact_Number__c =
        event.detail.inspectionLocationDetails.contactPhone;
      this.jobRequestRecord.GTS_Inspection_Location_Email__c =
        event.detail.inspectionLocationDetails.contactEmail;

      this.jobRequestRecord.GTS_Inspection_Location_Company_Address__City__s =
        event.detail.inspectionLocationDetails.city;
      this.jobRequestRecord.GTS_Inspection_Location_Company_Address__Street__s =
        event.detail.inspectionLocationDetails.street;
      this.jobRequestRecord.GTS_Inspection_Location_Company_Address__PostalCode__s =
        event.detail.inspectionLocationDetails.postalCode;
      this.jobRequestRecord.GTS_Inspection_Location_Company_Address__CountryCode__s =
        event.detail.inspectionLocationDetails.country;
      this.jobRequestRecord.GTS_Inspection_Location_Company_Address__StateCode__s =
        event.detail.inspectionLocationDetails.state;
    }

    this.jobRequestRecord.GTS_Goods_Available_Date__c =
      event.detail.goodsAvailableDate;
    this.jobRequestRecord.GTS_Proposed_Inspection_Date__c =
      event.detail.proposedInspectionDate;
    this.jobRequestRecord.GTS_Shipment_Mode__c = event.detail.shipmentMode;
    this.jobRequestRecord.GTS_Shipment_Mode_Please_Specify__c =
      event.detail.otherShipmentMode;
    this.jobRequestRecord.GTS_Shipment_Type__c = event.detail.shipmentType;
    this.jobRequestRecord.GTS_Specify_Number_of_FCLs__c =
      event.detail.fclNumber;
    this.jobRequestRecord.GTS_Goods_Condition__c = event.detail.goodsCondition;
    this.jobRequestRecord.GTS_Inview_Requested__c =
      event.detail.inviewRequested;
  }

      accountRecordType;
      @wire(getObjectInfo, { objectApiName: 'Account' })
      objectInfoWire({ error, data }) {
        if (data) {
          let recordTypeInfos = data.recordTypeInfos;
          this.accountRecordType = Object.keys(recordTypeInfos).find(
                    (rti) => recordTypeInfos[rti].name === 'GMA Customer'
                  );
          this.showSpinner = false;
        } else if (error) {
          console.error("Error getting object info", error);
        }
      }
}