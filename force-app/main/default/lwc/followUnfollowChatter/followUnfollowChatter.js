import { LightningElement, api, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label } from "c/labelService";
import { refreshApex } from "@salesforce/apex";
import { getRecord } from "lightning/uiRecordApi";
import isUserSubscribed from "@salesforce/apex/ChatterButtonController.isUserSubscribed";
import subscribeUserToRecord from "@salesforce/apex/ChatterButtonController.subscribeUserToRecord";
import unsubscribeUserFromRecord from "@salesforce/apex/ChatterButtonController.unsubscribeUserFromRecord";
import STATUS_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Status__c";
import ACTIVE_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Active__c";
import Id from "@salesforce/user/Id";
import networkId from "@salesforce/community/Id";

export default class FollowUnfollowChatter extends LightningElement {
  @api recordId;

  userId = Id;
  networkId = networkId;
  labels = label;

  @wire(getObjectInfo, { objectApiName: "Brand_Supplier_Connection__c" })
  objectData;

  get feedEnabled() {
    return this.objectData?.data?.feedEnabled;
  }

  @wire(isUserSubscribed, { recordId: "$recordId", userId: "$userId" })
  wiredResponse;

  get isFollowing() {
    return this.wiredResponse.data;
  }

  get showButton() {
    if (typeof this.isFollowing !== "undefined" && this.feedEnabled === true) {
      return true;
    }
    return false;
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [STATUS_FIELD, ACTIVE_FIELD]
  })
  handleRecordChange(response) {
    refreshApex(this.wiredResponse);
  }

  handleFollow() {
    subscribeUserToRecord({
      recordId: this.recordId,
      userId: this.userId,
      networkId: this.networkId
    })
      .then((result) => {
        refreshApex(this.wiredResponse);
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.SUCCESS,
            message: this.labels.FEED_FOLLOWED,
            variant: "success"
          })
        );
      })
      .catch((error) => {
        refreshApex(this.wiredResponse);
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR,
            message: "Action failed: " + error.body.message,
            variant: "error"
          })
        );
      });
  }

  handleUnfollow() {
    unsubscribeUserFromRecord({ recordId: this.recordId, userId: this.userId })
      .then((result) => {
        refreshApex(this.wiredResponse);
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.SUCCESS,
            message: this.labels.FEED_UNFOLLOWED,
            variant: "success"
          })
        );
      })
      .catch((error) => {
        refreshApex(this.wiredResponse);
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR,
            message: "Action failed: " + error.body.message,
            variant: "error"
          })
        );
      });
  }
}