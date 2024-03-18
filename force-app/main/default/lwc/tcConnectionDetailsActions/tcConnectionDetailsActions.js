import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Id from "@salesforce/user/Id";
import ACCOUNT_ID_FIELD from "@salesforce/schema/User.Contact.AccountId";
import CONTACT_ID_FIELD from "@salesforce/schema/User.ContactId";
import ID_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Id";
import STATUS_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Status__c";
import ACTIVE_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Active__c";
import REQUESTOR_ACCOUNT_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Requestor_Contact__r.AccountId";
import REJECTED_BY_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Rejected_By__c";
import DISCONNECTED_BY_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Disconnected_By__c";
import { label } from "c/labelService";
export default class TcConnectionDetailsActions extends LightningElement {
  @api recordId;
  @api context; // isSupplierAdminUser AND isBrandAdminUser both appear to be true
  @api disableBtn = false;
  userId = Id;
  labels = label;
  modalTitle;
  modalContent;
  modalConfirmBtnLabel = "";
  modalCancelBtnLabel = this.labels.CANCEL;
  showModal = false;

  @wire(getRecord, {
    recordId: "$userId",
    fields: [ACCOUNT_ID_FIELD, CONTACT_ID_FIELD]
  })
  wiredUser;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [STATUS_FIELD, ACTIVE_FIELD, REQUESTOR_ACCOUNT_FIELD]
  })
  wiredRecord;

  get showCancel() {
    let connectionStatus = getFieldValue(this.wiredRecord.data, STATUS_FIELD);
    return (
      (this.context.isSupplierAdminUser || this.context.isBrandAdminUser) &&
      connectionStatus === "Requested" &&
      this.isRequestorAccount
    );
  }

  get showApproveReject() {
    let connectionStatus = getFieldValue(this.wiredRecord.data, STATUS_FIELD);
    return (
      (this.context.isSupplierAdminUser || this.context.isBrandAdminUser) &&
      connectionStatus === "Requested" &&
      !this.isRequestorAccount
    );
  }

  get showDisconnect() {
    let connectionStatus = getFieldValue(this.wiredRecord.data, STATUS_FIELD);
    return (
      (this.context.isSupplierAdminUser || this.context.isBrandAdminUser) &&
      connectionStatus === "Approved"
    );
  }

  get showMakeInactiveUpdateTarget() {
    let connectionStatus = getFieldValue(this.wiredRecord.data, STATUS_FIELD);
    let active = getFieldValue(this.wiredRecord.data, ACTIVE_FIELD);
    return (
      this.context.isBrandAdminUser && connectionStatus === "Approved" && active
    );
  }

  get showMakeActive() {
    let connectionStatus = getFieldValue(this.wiredRecord.data, STATUS_FIELD);
    let active = getFieldValue(this.wiredRecord.data, ACTIVE_FIELD);
    return (
      this.context.isBrandAdminUser &&
      connectionStatus === "Approved" &&
      !active
    );
  }

  get isRequestorAccount() {
    let userAccId = getFieldValue(this.wiredUser.data, ACCOUNT_ID_FIELD);
    let requestorAccId = getFieldValue(
      this.wiredRecord.data,
      REQUESTOR_ACCOUNT_FIELD
    );
    return userAccId === requestorAccId;
  }

  openModal(evt) {
    switch (evt.detail.label) {
      case this.labels.APPROVE_CONNECTION_REQUEST:
        this.modalTitle = this.labels.APPROVE_CONNECTION_REQUEST;
        this.modalContent = this.labels.ARE_YOU_SURE_APPROVE_CONNECTION;
        this.modalConfirmBtnLabel = this.labels.YES_APPROVE;
        this.modelCancelBtnLabel = this.labels.CANCEL;

        break;
      case this.labels.REJECT:
        this.modalTitle = this.labels.REJECT;
        this.modalContent = this.labels.ARE_YOU_SURE_REJECT_CONNECTION;
        this.modalConfirmBtnLabel = this.labels.YES_REJECT;
        this.modelCancelBtnLabel = this.labels.CANCEL;
        break;
      case this.labels.DISCONNECT:
        this.modalTitle = this.labels.DISCONNECT;
        this.modalContent = this.labels.ARE_YOU_SURE_DISCONNECT_CONNECTION;
        this.modalConfirmBtnLabel = this.labels.YES_DISCONNECT;
        this.modelCancelBtnLabel = this.labels.CANCEL;
        break;
      case this.labels.CANCEL_CONNECTION_REQUEST:
        this.modalTitle = this.labels.CANCEL_CONNECTION_REQUEST;
        this.modalContent = this.labels.ARE_YOU_SURE_CANCEL_CONNECTION;
        this.modalConfirmBtnLabel = this.labels.YES_CANCEL;
        this.modelCancelBtnLabel = this.labels.NO_GO_BACK;
        break;
    }
    this.showModal = true;
  }

  modalConfirm(evt) {
    this.disableBtn = true;
    let fields = {};
    let recordInput = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;

    switch (evt.detail.label) {
      case this.labels.YES_APPROVE:
        fields[STATUS_FIELD.fieldApiName] = "Approved";
        fields[ACTIVE_FIELD.fieldApiName] = true;
        recordInput = { fields };
        updateRecord(recordInput)
          .then(() => {
            this.closeModal();
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.SUCCESS,
                message: this.labels.YOU_HAVE_APPROVED_CONNECTION,
                variant: "success"
              })
            );
          })
          .catch((error) => {
            this.disableBtn = false;
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.ERROR,
                message: error.body.message,
                variant: "error"
              })
            );
          });
        break;

      case this.labels.YES_REJECT:
        fields[STATUS_FIELD.fieldApiName] = "Rejected";
        fields[ACTIVE_FIELD.fieldApiName] = true;
        fields[REJECTED_BY_FIELD.fieldApiName] = getFieldValue(
          this.wiredUser.data,
          CONTACT_ID_FIELD
        );
        recordInput = { fields };
        updateRecord(recordInput)
          .then(() => {
            this.closeModal();
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.SUCCESS,
                message: this.labels.YOU_HAVE_REJECTED_CONNECTION,
                variant: "success"
              })
            );
          })
          .catch((error) => {
            this.disableBtn = false;
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.ERROR,
                message: error.body.message,
                variant: "error"
              })
            );
          });
        break;

      case this.labels.YES_DISCONNECT:
        fields[STATUS_FIELD.fieldApiName] = "Disconnected";
        fields[ACTIVE_FIELD.fieldApiName] = false;
        fields[DISCONNECTED_BY_FIELD.fieldApiName] = getFieldValue(
          this.wiredUser.data,
          CONTACT_ID_FIELD
        );
        recordInput = { fields };
        updateRecord(recordInput)
          .then(() => {
            this.closeModal();
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.SUCCESS,
                message: this.labels.YOU_HAVE_DISCONNECTED_CONNECTION,
                variant: "success"
              })
            );
          })
          .catch((error) => {
            this.disableBtn = false;
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.ERROR,
                message: error.body.message,
                variant: "error"
              })
            );
          });
        break;

      case this.labels.YES_CANCEL:
        fields[STATUS_FIELD.fieldApiName] = "Cancelled";
        recordInput = { fields };
        updateRecord(recordInput)
          .then(() => {
            this.closeModal();
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.SUCCESS,
                message: this.labels.YOU_HAVE_CANCELLED_CONNECTION,
                variant: "success"
              })
            );
          })
          .catch((error) => {
            this.disableBtn = false;
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.ERROR,
                message: error.body.message,
                variant: "error"
              })
            );
          });
        break;
    }
  }

  markInactive() {
    this.disableBtn = true;
    let fields = {};
    let recordInput = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields[ACTIVE_FIELD.fieldApiName] = false;
    recordInput = { fields };
    updateRecord(recordInput)
      .then(() => {
        this.closeModal();
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.SUCCESS,
            message: this.labels.YOU_HAVE_UPDATED_CONNECTION_INACTIVE,
            variant: "success"
          })
        );
      })
      .catch((error) => {
        this.disableBtn = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR,
            message: error.body.message,
            variant: "error"
          })
        );
      });
  }

  markActive() {
    this.disableBtn = true;
    let fields = {};
    let recordInput = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields[ACTIVE_FIELD.fieldApiName] = true;
    recordInput = { fields };
    updateRecord(recordInput)
      .then(() => {
        this.closeModal();
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.SUCCESS,
            message: this.labels.YOU_HAVE_UPDATED_CONNECTION_ACTIVE,
            variant: "success"
          })
        );
      })
      .catch((error) => {
        this.disableBtn = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR,
            message: error.body.message,
            variant: "error"
          })
        );
      });
  }

  updateConformanceTarget() {
    // fire event for parent component to handle, so that we can make the Conformance Target field editable
    this.dispatchEvent(new CustomEvent("updateconformance"));
  }

  closeModal() {
    this.disableBtn = false;
    this.showModal = false;
  }
}