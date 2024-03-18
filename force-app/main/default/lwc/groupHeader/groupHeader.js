import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";

import checkForDupeGroup from "@salesforce/apex/GroupListController.checkForDupeGroup";
import updateGroup from "@salesforce/apex/GroupListController.updateGroup";

import GROUPNAME_FIELD from "@salesforce/schema/Contact_Group__c.Group_Name__c";
import GROUPDESCRIPTION_FIELD from "@salesforce/schema/Contact_Group__c.Group_Description__c";
import ACCOUNT_FIELD from "@salesforce/schema/Contact_Group__c.Account__c";
import EXPIRY_FIELD from "@salesforce/schema/Contact_Group__c.Expiry__c";
import ISDEFAULTGROUP_FIELD from "@salesforce/schema/Contact_Group__c.Is_Default_Group__c";
export default class GroupHeader extends LightningElement {
  @api recordId;
  showModal = false;
  isWorking = false;
  validGroupName = true;
  editedGroupName;
  groupNameTimeout;
  editedGroup = {};

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      GROUPNAME_FIELD,
      GROUPDESCRIPTION_FIELD,
      ACCOUNT_FIELD,
      EXPIRY_FIELD,
      ISDEFAULTGROUP_FIELD
    ]
  })
  group;

  @wire(checkForDupeGroup, {
    groupName: "$editedGroupName"
  })
  wiredDupeData({ error, data }) {
    if (data) {
      if (data == "true") {
        this.template
          .querySelector("c-input[data-id='GroupName']")
          .toggleCustomError(true);
        this.validGroupName = false;
      } else {
        this.template
          .querySelector("c-input[data-id='GroupName']")
          .toggleCustomError(false);
        this.validGroupName = true;
      }
    } else if (error) {
      this.error = error;
    }
    this.isWorking = false;
  }

  get name() {
    return getFieldValue(this.group.data, GROUPNAME_FIELD);
  }

  get description() {
    return getFieldValue(this.group.data, GROUPDESCRIPTION_FIELD);
  }

  get account() {
    return getFieldValue(this.group.data, ACCOUNT_FIELD);
  }

  get expiry() {
    return getFieldValue(this.group.data, EXPIRY_FIELD);
  }

  get isDefaultGroup() {
    return getFieldValue(this.group.data, ISDEFAULTGROUP_FIELD);
  }

  handleBtnClick() {
    this.toggleModal();
  }

  toggleModal() {
    this.showModal = !this.showModal;
  }

  handleEditGroupInputChange(evt) {
    // update newGroup, plus also check for duplicate group names, live as the user types (after a short pause)
    let editedGroup = JSON.parse(JSON.stringify(this.editedGroup));
    editedGroup[evt.detail.fieldId] = evt.detail.value;
    this.editedGroup = editedGroup;
    if (evt.detail.fieldId == "Group_Name__c") {
      this.isWorking = true;
      window.clearTimeout(this.groupNameTimeout);
      this.groupNameTimeout = setTimeout(
        function () {
          this.editedGroupName = evt.detail.value;
        }.bind(this),
        500
      );
    }
  }

  async handleConfirmEditGroup() {
    this.isWorking = true;
    if (!this.validateEditGroupInputs() || !this.validGroupName) {
      // Do nothing, let inputs display their own inline error messages
    } else {
      // send the data off to Apex which tries to update the group
      // if a duplicate group name is found, display error toast
      this.editedGroup.Id = this.recordId;
      let response = await updateGroup({ editedGroup: this.editedGroup });
      if (response.status == "OK") {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Group updated",
            message: "Successfully updated the group",
            variant: "Success"
          })
        );
        //refreshApex(this.group);
        //this.toggleModal();
        window.location.href = window.location.href;
      } else {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: response.messages[0],
            variant: "Error"
          })
        );
      }
    }
    this.isWorking = false;
  }

  validateEditGroupInputs() {
    let isValid = true;
    this.template.querySelectorAll("c-modal c-input").forEach((input) => {
      if (!input.validate().isValid) {
        isValid = false;
      }
    });
    // Workaround: make sure we re-set the error state where group name is a duplicate
    if (!this.validGroupName) {
      this.template
        .querySelector("c-input[data-id='GroupName']")
        .toggleCustomError(true);
    }
    return isValid;
  }
}