import { LightningElement, api, wire, track } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";

import USER_ID from "@salesforce/user/Id";
import USER_OBJECT from "@salesforce/schema/User";
import enableDisableUser from "@salesforce/apex/ManageUserController.enableDisableUser";
import approveDeclineAccessForUser from "@salesforce/apex/ManageUserController.approveDeclineAccessForUser";
import getUserWithContact from "@salesforce/apex/ManageUserController.getUserWithContact";

import { label } from "c/labelService";
export default class EnableDisableUser extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @track disableBtn = false;
  @track showModal = false;
  @track action;
  @track approvalAction;

  get approvalRequested() {
    let apprStatus = this.userRecord?.data?.approvalStatus;
    if (apprStatus && typeof apprStatus === "string") {
      return (
        apprStatus.localeCompare("requested", undefined, {
          sensitivity: "base"
        }) === 0
      );
    } else {
      return false;
    }
  }

  get approvalRequestedOrRejected() {
    let apprStatus = this.userRecord?.data?.approvalStatus;
    if (apprStatus && typeof apprStatus === "string") {
      return (
        apprStatus.localeCompare("requested", undefined, {
          sensitivity: "base"
        }) === 0 ||
        apprStatus.localeCompare("rejected", undefined, {
          sensitivity: "base"
        }) === 0
      );
    } else {
      return false;
    }
  }

  get isUpdateable() {
    return this.userObject?.data?.updateable && !this.isMyUser;
  }
  get isActive() {
    return this.userRecord?.data?.isActive;
  }
  get isMyUser() {
    return (
      this.recordId == "home" ||
      this.recordId.substring(0, 15) == USER_ID.substring(0, 15)
    );
  }

  labels = label;

  @wire(getObjectInfo, { objectApiName: USER_OBJECT })
  userObject;

  @wire(getUserWithContact, { userId: "$recordId" })
  userRecord;

  toggleModal(evt) {
    if (evt && evt.detail) {
      this.action = evt.detail.indexOne;
      this.approvalAction = evt.detail.indexTwo;
    }
    this.showModal = !this.showModal;
  }

  async handleConfirmApproveDecline(evt) {
    let decision = this.approvalAction;
    if (decision === "approve" || decision === "decline") {
      this.disableBtn = true;

      let response;
      response = await approveDeclineAccessForUser({
        userId: this.recordId,
        decision: decision
      });
      // Display toast
      if (response.status == "OK") {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.SUCCESS,
            message: this.labels.CHANGES_SAVED,
            variant: "success"
          })
        );
      } else {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR,
            message: response.messages[0],
            variant: "error",
            mode: "sticky"
          })
        );
      }

      refreshApex(this.userRecord);
      this.toggleModal();
      this.disableBtn = false;
      this[NavigationMixin.Navigate]({
        type: "comm__namedPage",
        attributes: {
          name: "Users__c"
        },
        state: {
          unassigned: "true"
        }
      });
    } else {
      this.toggleModal();
    }
  }

  async handleConfirm(evt) {
    let active = this.action === "enable";
    // disable the selected users and refresh
    this.disableBtn = true;

    let response;
    response = await enableDisableUser({
      selectedUserIds: [this.recordId],
      activateYN: active
    });
    // Display toast
    if (response.status == "OK") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.SUCCESS,
          message: this.labels.CHANGES_SAVED,
          variant: "success"
        })
      );
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: response.messages[0],
          variant: "error",
          mode: "sticky"
        })
      );
    }
    refreshApex(this.userRecord);
    this.toggleModal();
    this.disableBtn = false;
  }
}