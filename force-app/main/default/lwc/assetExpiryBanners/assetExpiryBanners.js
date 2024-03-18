import { LightningElement, wire, track,api } from "lwc";
import { label } from "c/labelService";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getCurrentUser from "@salesforce/apex/ManageUserController.getUserDetailsWired";
import assetExpiryBanner from "@salesforce/apex/AssetExpiryBannerController.assetExpiryBanner";
import requestFullAccess from "@salesforce/apex/ManageUserController.userRequestsFullMTCAccess";
import assetExpiryBanners from "@salesforce/apex/AssetExpiryBannerController.assetExpirystatusCheckforBanner"; /*Prateek*/

export default class AssetExpiryBannerController extends LightningElement {
  @track disableBtn = false;
  @track showModal = false; 
  @api recordId; 
  @api Asset; 
  @api NumberOfDays;
  @api messageExpired;
  @api agoVariable;
  labels = label;
  @api booleanExpiry; //Prateek
  @api UserIds;
 
    /*Prateek*/

  
  @wire(assetExpiryBanners, { recordId: "$recordId"}) 
  
  wiredExpiryStatus({ error, data }) {
    if (data) {
      console.log('Report debug banner',data);
      this.booleanExpiry = data;
    }
  }

 
  get conditionalButtonLabel() {
    if (this.isApprovalEquals("not requested")) {
      return "REQUEST UPGRADE";
    } else {
      return null;
    }
  }
  get isTempUser() {
    return this.userData.data && this.userData.data.Date_Expires__c != null;
  }
  get isApprovalButtonShown() {
    return this.isApprovalEquals("not requested");
  }

  isApprovalEquals(status) {
    let apprStatus =
      this.userData.data && this.userData.data.Contact?.Approval_Status__c;

    if (apprStatus && typeof apprStatus === "string") {
      return (
        apprStatus.localeCompare(status, undefined, {
          sensitivity: "base"
        }) === 0
      );
    } else {
      return false;
    }
  }

  get daysUntilExpiry() {
    return this.userData.data && this.userData.data.Date_Expires__c
      ? Math.ceil(
          (new Date(this.userData.data.Date_Expires__c) - new Date()) /
            (1000 * 3600 * 24)
        )
      : null;
  }

  get messagePartOne() {
    assetExpiryBanner({ recordId: this.recordId })
            .then(result => {
              if(this.NumberOfDays!=result){
                this.NumberOfDays = result;
                if(this.NumberOfDays > 0){
                  this.messageExpired = "Your temporary access to this report will expire in ";
                  this.agoVariable = " days";
                }
                if(this.NumberOfDays < 0){
                  this.messageExpired = "Your temporary access to this report has expired ";
                  this.agoVariable = " days ago."
                }
              }
                
            })
          /*  .catch(error => {
                this.error = error;
            }); */
    return (
      this.messageExpired +
      Math.abs(this.NumberOfDays) +
      this.agoVariable
    );
  }

  get messagePartTwo() {
    if (this.isApprovalEquals("requested")) {
      return "You have already requested access.";
    } else if (this.isApprovalEquals("not requested")) {
      return "Upgrade your account to avoid losing access.";
    } else if (this.isApprovalEquals("approved")) {
      return "Full access to MTC was granted.";
    } else if (this.isApprovalEquals("declined")) {
      return "Your request for full access to MTC was declined.";
    } else if(this.messageExpired === undefined){
      return "Your temporary access to this report has expired";
    } else {
      return "default"; 
    }
  }

  @wire(getCurrentUser)
  userData;

  toggleModal(evt) {
    if (evt && evt.detail) {
    }
    this.showModal = !this.showModal;
  }
  async handleConfirm(evt) {
    if (evt && evt.detail) {
      this.disableBtn = true;

      let response;
      response = await requestFullAccess();
      // Display toast
      if (response.status == "OK") {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.SUCCESS,
            message: this.labels.CHANGES_SAVED,
            variant: "success"
          })
        );
        refreshApex(this.userData);
      } else {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR,
            message: response.messages[0],
            variant: "error",
            mode: "sticky"
          })
        );
        this.disableBtn = false;
      }
    }
    this.showModal = !this.showModal;
  }
}