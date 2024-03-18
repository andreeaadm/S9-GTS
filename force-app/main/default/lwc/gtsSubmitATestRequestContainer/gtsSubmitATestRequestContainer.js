import { LightningElement, wire, api, track } from "lwc";
import getJobRequests from "@salesforce/apex/GTSJobRequestController.getJobRequests";
import getJobRequest from "@salesforce/apex/GTSJobRequestController.getJobRequest";
import getRecordTypeId from "@salesforce/apex/GTSJobRequestController.getRecordTypeByApiName";
import getAllDraftJobRequests  from "@salesforce/apex/GTSJobRequestController.getAllDraftJobRequests";
import getAllFavJobRequests from "@salesforce/apex/GTSJobRequestController.getAllFavJobRequests";
import apexGetContentDocumentVersion from "@salesforce/apex/GTSJobRequestController.getContentDocumentVersion";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import deleteJobRequest from "@salesforce/apex/Icare_SubmitTestRequestController.deleteJobRequest";
import LightningConfirm from "lightning/confirm";
import { NavigationMixin } from "lightning/navigation";

import TITLE from "@salesforce/label/c.iCare_Submit_Test_Homepage";
import TIP1 from "@salesforce/label/c.iCare_Submit_a_Test_Request_P1";
import TIP2 from "@salesforce/label/c.iCare_Submit_a_Test_Request_P2";
import SHIPMENT_CERTIFICATE from '@salesforce/label/c.GTS_Shipment_Certificate';
import REGISTRATION_LICENSE from '@salesforce/label/c.GTS_Registration_Licence';
import COMMERCIAL_SERVICES_TRADEABLE from '@salesforce/label/c.GTS_Commercial_Services_Tradeable';
import SELF_REFERENCE_TEST from "@salesforce/label/c.iCare_Self_Reference_Test_Button";
import VIEW_ALL from "@salesforce/label/c.iCare_Portal_View_all";
import FAVOURITES from "@salesforce/label/c.iCare_Favourites";
import SAVED_DRAFTS from "@salesforce/label/c.iCare_Saved_Drafts";
import SAVED from "@salesforce/label/c.iCare_Saved";
import SAMPLE_DESCRIPTION from "@salesforce/label/c.GTS_Draft_Name";
import DELETE from "@salesforce/label/c.iCare_Portal_Delete";
import NAME from "@salesforce/label/c.iCare_Portal_Name";
import BUYER_PROGRAM from "@salesforce/label/c.iCare_Buyer_Program_Button";

import CONFIRM_DELETE_HEADER from "@salesforce/label/c.iCare_Confirm_Delete_Header";
import CONFIRM_DELETE_MESSAGE from "@salesforce/label/c.iCare_Confirm_Delete_Message";
import RECORD_DELETED_HEADER from "@salesforce/label/c.iCare_Record_Deleted_Header";
import RECORD_DELETED_MESSAGE from "@salesforce/label/c.iCare_Record_Deleted_Message";

import TIMEZONE from "@salesforce/i18n/timeZone";

import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import ID_FIELD from "@salesforce/schema/Account.Id";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import ADDRESS_CITY_FIELD from "@salesforce/schema/Account.BillingCity";
import ADDRESS_STATE_CODE from "@salesforce/schema/Account.BillingStateCode";
import ADDRESS_COUNTRY_CODE from "@salesforce/schema/Account.BillingCountryCode";
import ADDRESS_POSTAL_CODE from "@salesforce/schema/Account.BillingPostalCode";
import ADDRESS_STREET from "@salesforce/schema/Account.BillingStreet";
import APPLICANT_TYPE from "@salesforce/schema/Account.GTS_Applicant_Type__c";
import COMMERCIAL_REG_NO from "@salesforce/schema/Account.GTS_Commercial_Registration_No_TIN__c";

import USER_OBJECT from "@salesforce/schema/User";
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import CONTACT_NAME from "@salesforce/schema/User.Contact.Name";
import CONTACT_EMAIL from "@salesforce/schema/User.Contact.Email";
import CONTACT_PHONE from "@salesforce/schema/User.Contact.Phone";

import { getObjectInfo } from "lightning/uiObjectInfoApi";

import JOB_REQUEST_OBJECT from "@salesforce/schema/icare_Job_Request__c";

import Id from "@salesforce/user/Id";

import { getJobRequestStructure } from "c/gtsJobRequestUtility";

const favouriteColumns = [
  {
    label: SAVED,
    fieldName: "LastModifiedDate",
    type: "date",
    hideDefaultActions: false,
    typeAttributes: {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: TIMEZONE
    }
  },
  {
    label: NAME,
    type: "button",
    initialWidth: 300,
    typeAttributes: {
      label: { fieldName: "favNameButton" },
      name: "openFavourite",
      variant: "base"
    }
  },
  {
    label: DELETE,
    type: "button",
    typeAttributes: {
      label: DELETE,
      name: "delete",
      title: "Delete",
      variant: "destructive-text"
    }
  }
];

const draftColumns = [
  {
    label: SAVED,
    fieldName: "LastModifiedDate",
    type: "date",
    hideDefaultActions: false,
    typeAttributes: {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: TIMEZONE
    }
  },
  {
    label: SAMPLE_DESCRIPTION,
    type: "button",
    initialWidth: 300,
    typeAttributes: {
      label: { fieldName: "iCare_Sample_Description__c" },
      name: "openDraft",
      variant: "base"
    }
  },
  {
    label: DELETE,
    type: "button",
    typeAttributes: {
      label: DELETE,
      name: "delete",
      title: "Delete",
      variant: "destructive-text"
    }
  }
];

export default class gtsSubmitATestRequestContainer extends NavigationMixin(
  LightningElement
) {
  customLabel = {
    TITLE,
    TIP1,
    TIP2,
    SHIPMENT_CERTIFICATE,
    REGISTRATION_LICENSE,
    COMMERCIAL_SERVICES_TRADEABLE,
    SELF_REFERENCE_TEST,
    VIEW_ALL,
    FAVOURITES,
    SAVED_DRAFTS,
    SAVED,
    SAMPLE_DESCRIPTION,
    DELETE,
    NAME,
    BUYER_PROGRAM,
    CONFIRM_DELETE_HEADER,
    CONFIRM_DELETE_MESSAGE,
    RECORD_DELETED_HEADER,
    RECORD_DELETED_MESSAGE
  };

  @track draftData = [];
  @track favouritesData = [];
  favouriteColumns = favouriteColumns;
  draftColumns = draftColumns;
  allJobRequestData = [];
  viewAllJobRequests = false;
  selectedRecordTypeName = "";
  sumbitJobRequestPage = false;


  displaySubmitAJobByBuyerProgram = false; //to be deleted
  displaySearchedBuyer = false; //to be deleted
  selectedBuyer; //to be deleted
  selectedDraft;

  @api accountId;
  userId = Id;

  @api renewRevision;
  @api jobExistingNumber;
  @api jobId;

  @track jobRequestRecord = {};
  jobRequestFields = ['Name'];
  @track jobRequestId;
  @track showSpinner;
  @track recordTypeId;
  @api associatedJobRequestId;

  connectedCallback() {
      console.log('connedt');
      console.log('connedt',this.associatedJobRequestId);
      this.jobRequestRecord = { ...getJobRequestStructure()};
      if(this.renewRevision != undefined){
        this.handleOpenRenewalRevision();
      }else{
          this.loadJobRequests();
      }
  }

  handleOpenRenewalRevision(){
      if(this.associatedJobRequestId != undefined && this.associatedJobRequestId.length >0){
          this.jobRequestId = this.associatedJobRequestId;
          this.getJobRequestById(false);
      }else{
          this.jobRequestRecord.GTS_Renewal_Revision__c = this.renewRevision;
          if(this.jobExistingNumber != undefined){
            this.jobRequestRecord.GTS_Existing_Number__c = this.jobExistingNumber;
          }
          //this.showRenewReviewPage = true;
      }

  }
  showRenewReviewPage;

  get showRenewSpinner(){
     return this.account != undefined && this.account.data != undefined && this.contact != undefined && this.contact.data != undefined && this.recordTypeInfos != undefined;
  }

  loadJobRequests() {
    this.showSpinner = true;
    this.sumbitJobRequestPage = true;
    this.viewAllJobRequests = false;
    getJobRequests()
      .then((result) => {
        result = result.map((row) => {
          var favName =
            row.iCare_Favourite_Name__c != undefined
              ? row.iCare_Favourite_Name__c.slice(0, 50)
              : "";
          var draftName =
            row.iCare_Sample_Description__c != undefined
              ? row.iCare_Sample_Description__c.slice(0, 50)
              : "";
          return {
            ...row,
            favNameButton: favName,
            draftNameButton: draftName
          };
        });

        this.favouritesData = result.filter(
          (row) => row.iCare_Draft_ETRF__c == false
        );
        this.draftData = result.filter(
          (row) => row.iCare_Draft_ETRF__c == true
        );
        this.showSpinner = false;
      })
      .catch((error) => {
        this.showSpinner = false;
        console.log("error >>" + JSON.stringify(error));
      });
  }

  async handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    switch (actionName) {
      case "delete":
        const result = await LightningConfirm.open({
          message: CONFIRM_DELETE_MESSAGE,
          variant: "header",
          label: CONFIRM_DELETE_HEADER,
          theme: "success"
        }).then((result) => {
          if (result) {
            deleteJobRequest({ jobReqId: row.Id })
              .then((result) => {
                console.log("record deleted");
                this.showSuccessToast();
                this.loadJobRequests();
              })
              .catch((error) => {
                console.log("error in delete *** ", error);
              });
          }
        });
        break;
      case "openFavourite":
        this.jobRequestId = row.Id;
        this.viewAllJobRequests = false;
        this.sumbitJobRequestPage = false;
        this.getJobRequestById(true);
        break;
      case "openDraft":
        this.jobRequestId = row.Id;
        this.viewAllJobRequests = false;
        this.sumbitJobRequestPage = false;
        this.getJobRequestById(false);
        break;
      default:
        break;
    }
  }

  contentVersionIds =[];
  getContentDocumentVersion(){
          apexGetContentDocumentVersion({jobRequestId : this.jobRequestRecord.Id})
            .then((result) => {
              this.contentVersionIds = result;
                                switch(this.jobRequestRecord.RecordType.DeveloperName){
                                    case 'GTS_Certificate_of_Conformity_Request' :
                                      this.showCoCPage = true;
                                      break;
                                     case 'GTS_Registration_License_Product_Certificate_Request' :
                                         if(this.jobRequestRecord.GTS_Renewal_Revision__c != undefined && this.jobRequestRecord.GTS_Renewal_Revision__c.length > 0){
                                             this.renewRevision = this.jobRequestRecord.GTS_Renewal_Revision__c;
                                             this.showRenewReviewPage = true;
                                             this.sumbitJobRequestPage = false;
                                         }else{
                                             this.showLicensePage = true;
                                         }
                                         break;
                                     case 'GTS_Commercial_Service_Request' :
                                         this.showTradeablePage = true;
                                         break;
                                }

            })
            .catch((error) => {
              this.contentVersionIds = [];
              console.log("error loading ContentVersions" + JSON.stringify(error));
            });


  }

  getJobRequestById(isFavorite){
          getJobRequest({recordId : this.jobRequestId})
            .then((result) => {
              this.jobRequestRecord = result;
              if(result.GTS_Program__c && result.GTS_Program__r.Name){
                  this.jobRequestRecord.ProgramName = result.GTS_Program__r.Name;
                  delete this.jobRequestRecord.GTS_Program__r.Name;
              }else{
                  this.jobRequestRecord.ProgramName = '';
              }

              this.jobRequestRecord.iCare_Draft_ETRF__c = false;
              this.jobRequestRecord.iCare_Active_Favourite__c = false;
              this.jobRequestRecord.iCare_Favourite_Name__c = '';
              this.recordTypeId = this.jobRequestRecord.RecordTypeId;
              if(this.renewRevision != undefined && this.renewRevision.length >0){
                  this.jobRequestRecord.GTS_Renewal_Revision__c = this.renewRevision;
              }

              this.getContentDocumentVersion();

              if(isFavorite){
                  delete this.jobRequestRecord.Id;
              }
            })
            .catch((error) => {
              console.log("error >>" + JSON.stringify(error));
            });
  }

  showSuccessToast() {
    const evt = new ShowToastEvent({
      title: RECORD_DELETED_HEADER,
      message: RECORD_DELETED_MESSAGE,
      variant: "success",
      mode: "dismissable"
    });
    this.dispatchEvent(evt);
  }

  viewAllDraftRecords(event) {
    console.log("View All Records **");
    let selectedRecordType = event.target.name;
    this.selectedRecordTypeName = selectedRecordType;
    this.isFavorite = false;
    getAllDraftJobRequests ({v_Offset : 0,v_pagesize : 5})
      .then((result) => {
        this.allJobRequestData = result;
        this.viewAllJobRequests = true;
        this.sumbitJobRequestPage = false;
      })
      .catch((error) => {
        console.log("error --> " + JSON.stringify(error));
      });
  }
  @track isFavorite;
  viewAllFavRecords(event) {
    console.log("View All Records **");
    let selectedRecordType = event.target.name;
    this.selectedRecordTypeName = selectedRecordType;
    this.isFavorite = true;
    getAllFavJobRequests({v_Offset : 0,v_pagesize : 5})
      .then((result) => {
        this.allJobRequestData = result;
        this.viewAllJobRequests = true;
        this.sumbitJobRequestPage = false;
      })
      .catch((error) => {
        console.log("error --> " + JSON.stringify(error));
      });
  }

  refreshJobRequest(event) {
    console.log("View All Records **");
    getAllJobRequests({ recTypeName: this.selectedRecordTypeName })
      .then((result) => {
        this.allJobRequestData = result;
        this.viewAllJobRequests = true;
        this.sumbitJobRequestPage = false;
      })
      .catch((error) => {
        console.log("error --> " + JSON.stringify(error));
      });
  }

  handleSelectRow(event) {
        console.log("event --> ",event.detail);
        this.jobRequestId = event.detail;
        this.viewAllJobRequests = false;
        this.sumbitJobRequestPage = false;

        this.getJobRequestById();
  }

  @track showCoCPage = false;
  handleCoCClick(event) {
    this.recordTypeByName('GTS_Certificate_of_Conformity_Request');    
  }

  @track showLicensePage = false;
  handleLicenseOrRegistrationClick(event) {
    this.recordTypeByName(
      "GTS_Registration_License_Product_Certificate_Request"
    );
  }

  showTradeablePage = false;

  handleTradeableClick() {
    this.recordTypeId = this.recordTypeByName("GTS_Commercial_Service_Request");
  }

  handleBackToSubmitATestRequestPage(event) {
    this.showCoCPage = false;
    this.showLicensePage = false;
    this.showTradeablePage = false;
    this.showRenewReviewPage = false;
    this.showSpinner = true;
    this.jobRequestRecord = { ...getJobRequestStructure()};
    this.loadJobRequests();
    this.sumbitJobRequestPage = true;
  }

  @wire(getRecord, {
    recordId: "$accountId",
    fields: [
      ID_FIELD,
      NAME_FIELD,
      ADDRESS_CITY_FIELD,
      ADDRESS_STATE_CODE,
      ADDRESS_COUNTRY_CODE,
      ADDRESS_POSTAL_CODE,
      ADDRESS_STREET,
      APPLICANT_TYPE,
      COMMERCIAL_REG_NO
    ]
  })
  account;

  @wire(getRecord, {
    recordId: "$userId",
    fields: [
      CONTACT_ID,
      CONTACT_NAME,
      CONTACT_EMAIL,
      CONTACT_PHONE
    ]
  })
  contact;

  @track recordTypeInfos;

  @wire(getObjectInfo, { objectApiName: JOB_REQUEST_OBJECT })
  objectInfoWire({ error, data }) {
    if (data) {
      this.recordTypeInfos = data.recordTypeInfos;
      if(this.renewRevision != undefined){
         this.recordTypeId = this.recordTypeByName(
             "GTS_Registration_License_Product_Certificate_Request"
         );
      }
    } else if (error) {
      console.error("Error getting object info", error);
    }
  }

  async recordTypeByName(name) {
    let recordTypeId;
    await getRecordTypeId({recordTypeApiName: name})
    .then((result) => {
      console.log('result'+result);
      this.recordTypeId = result;
      this.sumbitJobRequestPage = false;
      switch(name) {
        case 'GTS_Certificate_of_Conformity_Request':
            this.showCoCPage = true;
            break;
        case 'GTS_Commercial_Service_Request':
            this.showTradeablePage = true;
            break;
        case 'GTS_Registration_License_Product_Certificate_Request':
            if (this.renewRevision != undefined){
              this.showRenewReviewPage = true;
            }else{
              this.showLicensePage = true;
            }
            break;
      }
    
    })
    .catch((error) => {
      console.log("error >>" + JSON.stringify(error));
    });
  }


}