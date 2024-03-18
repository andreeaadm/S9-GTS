import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import USER_ID from "@salesforce/user/Id";
import USER_OBJECT from "@salesforce/schema/User";
import NAME_FIELD from "@salesforce/schema/User.Name";
import FIRSTNAME_FIELD from "@salesforce/schema/User.FirstName";
import LASTNAME_FIELD from "@salesforce/schema/User.LastName";
import EMAIL_FIELD from "@salesforce/schema/User.Email";
import EMAIL_OPT_OUT_FIELD from "@salesforce/schema/User.Email_Opt_Out__c";
import ISACTIVE_FIELD from "@salesforce/schema/User.IsActive";
import CREATEDDATE_FIELD from "@salesforce/schema/User.CreatedDate";
import updateUser from "@salesforce/apex/UserDetailController.updateUser";

export default class UserDetail extends LightningElement {
  @api recordId;
  @track isWorking = false;
  @track editMode = false;
  firstNameField = FIRSTNAME_FIELD;
  lastNameField = LASTNAME_FIELD;
  emailField = EMAIL_FIELD;
  isActiveField = ISACTIVE_FIELD;
  emailOptOutField= EMAIL_OPT_OUT_FIELD;
  createdDateField = CREATEDDATE_FIELD;

  get currentUser() {
    return this.recordId &&
      !(this.recordId === "") &&
      !(this.recordId === "home")
      ? this.recordId
      : USER_ID;
  }

  connectedCallback() {
    document.title = "User Detail";
  }

  @wire(getObjectInfo, { objectApiName: USER_OBJECT })
  userObject;

  @wire(getRecord, {
    recordId: "$currentUser",
    fields: [
      NAME_FIELD,
      FIRSTNAME_FIELD,
      LASTNAME_FIELD,
      EMAIL_FIELD,
      ISACTIVE_FIELD,
      EMAIL_OPT_OUT_FIELD,
      CREATEDDATE_FIELD
    ]
  })
  user;

  get isUpdateable() {
    return this.userObject?.data?.updateable;
  }

  get name() {
    return getFieldValue(this.user.data, NAME_FIELD);
  }

  get firstName() {
    return getFieldValue(this.user.data, FIRSTNAME_FIELD);
  }

  get lastName() {
    return getFieldValue(this.user.data, LASTNAME_FIELD);
  }

  get email() {
    return getFieldValue(this.user.data, EMAIL_FIELD);
  }

  get status() {
    return getFieldValue(this.user.data, ISACTIVE_FIELD)
      ? "Enabled"
      : "Disabled";
  }

  get emailOptOut() {
    return getFieldValue(this.user.data, EMAIL_OPT_OUT_FIELD)
  }


  get createdDate() {
    return getFieldValue(this.user.data, CREATEDDATE_FIELD);
  }

  toggleIsWorking() {
    this.isWorking = !this.isWorking;
  }

  toggleEdit() {
    this.editMode = !this.editMode;
  }

  handleUpdateUser() {
    if (this.validateInputs()) {
      this.toggleIsWorking();
      let editedUser = {
        sobjectType: "User",
        Id: this.currentUser
      };
      for (let input of this.template.querySelectorAll("c-modal c-input")) {
        if (input.fieldId) {
          editedUser[input.fieldId] = input.value;
        }
      }
      updateUser({ record: editedUser })
        .then((result) => {
          if (result && result.statusCode === 200) {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "The changes have been saved",
                variant: "success"
              })
            );
            refreshApex(this.user);
            this.toggleEdit();
          } else if (result && result.messages) {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error",
                message: result.messages[0],
                variant: "error"
              })
            );
          }
          this.toggleIsWorking();
        })
        .catch((error) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: "Please contact an administrator",
              variant: "error"
            })
          );
          this.toggleIsWorking();
        });
    }
  }

  validateInputs() {
    let isValid = true;
    this.template.querySelectorAll(".form c-input").forEach((input) => {
      if (!input.validate().isValid) {
        isValid = false;
      }
    });
    return isValid;
  }
}