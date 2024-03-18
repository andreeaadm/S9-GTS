import { LightningElement, wire, track, api } from "lwc";
import { label } from "c/labelService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import USER_ID from "@salesforce/user/Id";
import getCompanies from "@salesforce/apex/UserDetailController.getCompanyList";
import removeRelationship from "@salesforce/apex/UserDetailController.removeRelationship";
import updateAccounts from "@salesforce/apex/UserDetailController.updateRelationship";
import getAccountOptions from "@salesforce/apex/UserDetailController.getAccountOptions";
import addAccount from "@salesforce/apex/UserDetailController.addAccountRelationship";
import getUserWithContact from "@salesforce/apex/ManageUserController.getUserWithContact";

export default class ProfileCompaniesList extends LightningElement {
  @api readOnlyMode; // Do not use, to be retired
  @api accessOptions = [
    { label: "Read-Only", value: "Read-Only" },
    { label: "Client Admin", value: "Client Admin" }
  ];
  @track accountOptions = [];
  @api additionalClasses = "greytile";
  companyInfo;
  @track isLoading = true;
  @track hasLoaded = false;
  @track isEmpty = true;
  @track companies = [];
  @api inEditMode = false;
  @api recordId;
  @track showAddAccountModal = false;
  @track labels = label;
  wiredACRs;
  @api
  get userToManage() {
    return this.recordId &&
      !(this.recordId === "") &&
      !(this.recordId === "home")
      ? this.recordId
      : USER_ID;
  }

  get isMyUser() {
    return (
      this.recordId == "home" ||
      this.recordId.substring(0, 15) == USER_ID.substring(0, 15)
    );
  }
  // to hide buttons when isMyUser or approval requested/rejected (but not approved!)
  get isMyUserOrInApproval() {
    if (
      this.recordId == "home" ||
      this.recordId.substring(0, 15) == USER_ID.substring(0, 15)
    ) {
      return true;
    }
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
    }
  }

  get addAccountPlaceholder() {
    return this.accountOptions.length == 0
      ? "No accounts found"
      : "Select an account";
  }

  get disableAddAccount() {
    return (
      this.isLoading ||
      this.accountOptions.length == 0 ||
      !this.accountOptions[0].value
    );
  }

  @wire(getUserWithContact, { userId: "$userToManage" })
  userRecord;

  @wire(getAccountOptions, { userId: "$userToManage" })
  AccountContactOptions({ error, data }) {
    if (data) {
      data.forEach((acc) => {
        this.accountOptions.push({ label: acc.Name, value: acc.Id });
      });
    } else if (error) {
      console.error("Error fetching account options");
    }
  }

  @wire(getCompanies, { userId: "$userToManage" })
  AccountContactRelations(response) {
    this.wiredACRs = response;
    if (response.data) {
      let companies = JSON.parse(JSON.stringify(response.data));
      for (let c of companies) {
        c.class = c.acr.IsDirect ? "accounts primary" : "accounts";
      }
      this.companies = companies;
      this.hasLoaded = true;
      this.isLoading = false;
    } else if (response.error) {
      console.error("Error fetching user's accounts");
    }
  }

  handleOnCancel() {
    this.inEditMode = false;
  }

  handleCancelModal() {
    this.showAddAccountModal = false;
  }

  handleToast(evt) {
    const toast = new ShowToastEvent({
      title: evt.detail.title,
      message: evt.detail.message,
      variant: evt.detail.variant
    });
    this.dispatchEvent(toast);
  }

  handleSaveAccounts() {
    this.isLoading = true;
    let accountUpdateEvent;
    let changedAccounts = [];
    for (let input of this.template.querySelectorAll(".accessLevel c-input")) {
      if (input.value) {
        changedAccounts.push({
          sobjectType: "AccountContactRelation",
          Id: input.dataset.id,
          MTC_Role__c: input.value
        });
      }
    }
    if (changedAccounts.length >= 1) {
      updateAccounts({ acrList: changedAccounts })
        .then((result) => {
          accountUpdateEvent = new CustomEvent("saveaccounts", {
            detail: {
              title: "Accounts saved",
              message: "Successfully saved the accounts",
              variant: "Success"
            }
          });
          this.handleToast(accountUpdateEvent);
          refreshApex(this.wiredACRs);
          this.isLoading = false;
          this.inEditMode = false;
        })
        .catch((error) => {
          accountUpdateEvent = new CustomEvent("saveaccounts", {
            detail: {
              title: "Error",
              message: "There was an error saving the accounts",
              variant: "Error"
            }
          });
          this.handleToast(accountUpdateEvent);
          this.isLoading = false;
          this.inEditMode = false;
        });
    }
  }

  handleRemove(e) {
    this.isLoading = true;
    const idToRemove = e.target.dataset.id;
    let accountDeletionErrorEvent;
    removeRelationship({ acrId: idToRemove })
      .then((result) => {
        accountDeletionErrorEvent = new CustomEvent("removeaccount", {
          detail: {
            title: "Account removed",
            message: "Successfully removed the account",
            variant: "Success"
          }
        });
        this.handleToast(accountDeletionErrorEvent);
        refreshApex(this.wiredACRs);
        this.isLoading = false;
      })
      .catch((error) => {
        accountDeletionErrorEvent = new CustomEvent("removeaccount", {
          detail: {
            title: "Error",
            message: "There was an error removing the account",
            variant: "Error"
          }
        });
        this.handleToast(accountDeletionErrorEvent);
        this.isLoading = false;
      });
  }

  enableEditMode() {
    this.inEditMode = true;
  }

  showAddAccount() {
    this.showAddAccountModal = true;
  }

  handleAddAccount() {
    this.isLoading = true;
    let accessLevel = this.template.querySelector(
      "c-input[data-name='MTC_Role__c']"
    ); //needs null check

    let accountId = this.template.querySelector(
      "c-input[data-name='AccountId']"
    ); //needs null check
    let accountAddEvent;
    addAccount({
      userId: this.userToManage,
      accountId: accountId.value,
      mtcRole: accessLevel.value
    })
      .then((result) => {
        accountAddEvent = new CustomEvent("addaccount", {
          detail: {
            title: "Account added",
            message: "Successfully added the account",
            variant: "Success"
          }
        });
        this.showAddAccountModal = false;
        this.handleToast(accountAddEvent);
        refreshApex(this.wiredACRs);
        this.isLoading = false;
      })
      .catch((error) => {
        accountAddEvent = new CustomEvent("addaccount", {
          detail: {
            title: "Error",
            message: "There was an error adding the account",
            variant: "Error"
          }
        });
        this.showAddAccountModal = false;
        this.handleToast(accountAddEvent);
        this.isLoading = false;
      });
  }
}