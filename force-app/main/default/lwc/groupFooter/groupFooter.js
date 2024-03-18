import { LightningElement, api, track, wire } from "lwc";
//import { deleteRecord } from "lightning/uiRecordApi";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import NAME_FIELD from "@salesforce/schema/Contact_Group__c.Group_Name__c";
import ISDEFAULTGROUP_FIELD from "@salesforce/schema/Contact_Group__c.Is_Default_Group__c";
import HASEXPIRED_FIELD from "@salesforce/schema/Contact_Group__c.Has_Expired_FF__c";
import deleteGroup from "@salesforce/apex/GroupListController.deleteGroups";
import restoreGroups from "@salesforce/apex/GroupListController.restoreGroups";

export default class GroupFooter extends NavigationMixin(LightningElement) {
  @api recordId;
  @track showModal = false;
  @track showRestoreModal = false;
  @track isWorking = false;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [NAME_FIELD, ISDEFAULTGROUP_FIELD, HASEXPIRED_FIELD]
  })
  group;

  get name() {
    return getFieldValue(this.group.data, NAME_FIELD);
  }

  get isDefaultGroup() {
    return getFieldValue(this.group.data, ISDEFAULTGROUP_FIELD);
  }

  get hasExpired() {
    return getFieldValue(this.group.data, HASEXPIRED_FIELD);
  }

  get showButton() {
    if (this.hasExpired === false || this.hasExpired === true) {
      return true;
    }
    return false;
  }

  handleBtnClick() {
    this.toggleModal();
  }

  toggleRestoreModal() {
    this.showRestoreModal = !this.showRestoreModal;
  }

  toggleModal() {
    this.showModal = !this.showModal;
  }

  async handleConfirmDeactivate() {
    this.isWorking = true;
    /*deleteRecord(this.recordId)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Group deleted",
            variant: "success"
          })
        );
        this[NavigationMixin.Navigate]({
          type: "comm__namedPage",
          attributes: {
            name: "Groups__c"
          }
        });
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error deleting group",
            message: error.body.message,
            variant: "error"
          })
        );
        this.isWorking = false;
      });*/

    let response = {};
    if (this.hasExpired) {
      response.status = "Already Inactive";
    } else {
      response = await deleteGroup({ selectedRowIds: [this.recordId] });
    }
    if (response.status == "OK") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Groups Deactivated",
          message: "Successfully deactivated the selected group(s)",
          variant: "Success"
        })
      );
      this.navigateToGroupList();
    } else if (response.status == "Already Inactive") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Already Inactive",
          message: "This group is already Inactive!",
          variant: "warning"
        })
      );
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: response.messages[0],
          variant: "Error"
        })
      );
    }
    this.isWorking = false;
  }

  async handleConfirmRestore() {
    this.isWorking = true;
    let response = await restoreGroups({ selectedRowIds: [this.recordId] });

    if (response.status == "OK") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Groups Restored",
          message: "Successfully restored the selected group(s)",
          variant: "Success"
        })
      );
      this.navigateToGroupList();
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: response.messages[0],
          variant: "Error"
        })
      );
    }
    this.isWorking = false;
  }

  navigateToGroupList() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: "Groups__c"
      }
    });
  }
}