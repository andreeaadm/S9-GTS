import { LightningElement, api, track, wire } from "lwc";
import { label } from "c/labelService";
import USER_ID from "@salesforce/user/Id";
import getGroupList from "@salesforce/apex/UserDetailController.getGroupList";
import getUserWithContact from "@salesforce/apex/ManageUserController.getUserWithContact";

export default class AssignedGroupsTile extends LightningElement {
  @track labels = label;
  @track hasLoaded = false;
  @track showManageModal = false;
  @track manageMode = "assign";
  @api recordId;
  @track selectedRowIds = [];
  @track groups = [];
  @api additionalClasses = "greytile headerbtns-must-wrap";

  @track theCurrentUser;

  @wire(getUserWithContact, { userId: "$theCurrentUser" })
  userRecord;
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

  get currentUser() {
    if (this.theCurrentUser == null) {
      var rec =
        this.recordId && this.recordId !== "" && this.recordId !== "home"
          ? this.recordId
          : USER_ID;

      this.theCurrentUser = rec;
      return rec;
    } else {
      return this.theCurrentUser;
    }
  }

  get hasGroups() {
    return this.groups.length && this.groups.length > 0;
  }

  get conditionalButtonAddGroup() {
    var label = this.labels.ADD;
    if (this.theCurrentUser.substring(0, 15) == USER_ID.substring(0, 15)) {
      label = null;
    }
    return label;
  }
  get conditionalButtonRemoveGroup() {
    var label = this.labels.REMOVE;
    if (this.theCurrentUser.substring(0, 15) == USER_ID.substring(0, 15)) {
      label = null;
    }
    return label;
  }
  renderedCallback() {
    this.hasLoaded = true;
  }

  connectedCallback() {
    this.selectedRowIds.push(this.currentUser);
    this.getGroupRecords();
  }

  getGroupRecords() {
    getGroupList({ userId: this.currentUser })
      .then((result) => {
        this.groups = result;
      })
      .catch((error) => {
        console.log("error", error);
      });
  }

  showAddToGroupModal() {
    this.showManageModal = true;
    this.manageMode = "assign";
  }

  showRemoveFromGroupModal() {
    this.showManageModal = true;
    this.manageMode = "retract";
  }

  handleCloseModal() {
    this.getGroupRecords(); //refresh group list after action from modal
    this.showManageModal = false;
  }
}