import { LightningElement, api, wire, track } from "lwc";
import getAccountOptions from "@salesforce/apex/UserDetailController.getPrimaryAccountOptions";
import createNewUser from "@salesforce/apex/UserDetailController.createNewUser";
import { label } from "c/labelService";
import USER_ID from "@salesforce/user/Id";

export default class UserDetailRecord extends LightningElement {
  @track labels = label;
  @track roles = [];
  @track accountOptions;
  @track selectedAccount;
  @track selectedRole;
  roleOptions = new Map();
  emailRegex =
    /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

  //consider async connecetd callback
  @wire(getAccountOptions, { userId: USER_ID })
  AccountContactRelations({ error, data }) {
    let accountRelationOptions;

    if (data && !this.accountOptions) {
      try {
        let dataToTransform = data;
        accountRelationOptions = dataToTransform.map((acr) => {
          return {
            ...accountRelationOptions,
            label: acr.Account_Name_FF__c,
            value: acr.AccountId
          };
        });

        this.accountOptions = accountRelationOptions;

        Object.keys(dataToTransform).forEach((acr) => {
          this.roleOptions.set(
            dataToTransform[acr].AccountId,
            dataToTransform[acr].MTC_Role__c
          );
        });
      } catch {
        console.log(
          "error with pushing data to options",
          JSON.stringify(this.accountOptions)
        );
      }
    }

    //        console.log('acr options', JSON.stringify(accountRelationOptions));
    //        this.accountOptions = accountRelationOptions;
  }

  get showForm() {
    return this.accountOptions;
  }

  get AccountOptions() {}

  handleSelectAccount(event) {
    let mtcRole = this.roleOptions.get(event.detail.value);
    //look at original wire of accounts
    //get the mtc role
    // match the role if CGA then read-only
    this.roles = this.getUIFriendlyRoles(mtcRole);
  }

  getUIFriendlyRoles(mtcRole) {
    let dependentRoleOptions = [];
    switch (mtcRole) {
      case "CGA":
        dependentRoleOptions = [
          { label: "Read-Only", value: "Read-Only" },
          { label: "Administrator", value: "Admin" }
        ];
        break;
      case "Admin":
        dependentRoleOptions = [
          { label: "Read-Only", value: "Read-Only" },
          { label: "Administrator", value: "Admin" }
        ];
    }
    return dependentRoleOptions;
  }

  @api
  handleSubmit() {
    let isValid = true;

    let inputsArray = Array.from(this.template.querySelectorAll("c-input"));
    inputsArray.forEach((input) => {
      if (!input.validate().isValid) {
        isValid = false;
      }
    });
    let button = this.template.querySelector(".hidden");
    if (button && isValid) {
      button.click();
    }
  }

  handleSuccess(event) {
    //throw by below modal child
    this.showAddUserModal = false;
  }

  handleError(event) {}

  //on save button
  handleCreateUser(event) {
    // This must also suppress default submit processing
    event.preventDefault();
    event.stopPropagation();
    this.dispatchEvent(new CustomEvent("toggleisworking"));

    let fields = {}; //fields from the default form

    //select only fields in the record edit form
    let inputsArray = Array.from(
      this.template.querySelectorAll("lightning-record-edit-form c-input")
    );
    inputsArray.forEach((input) => {
      fields[input.fieldId] = input.value;
    });

    let userRec = { attributes: { type: "Contact" }, ...fields };

    let accessLevelValue = this.template.querySelector(
      "c-input[data-id='accessLevel']"
    ); //needs null check
    this.doCreateNewUser(accessLevelValue.value, userRec);
  }

  doCreateNewUser(accessLevelValue, userRec) {
    let userRecString = JSON.stringify(userRec);
    if (accessLevelValue && userRec) {
      createNewUser({ mtcRole: accessLevelValue, userParam: userRecString })
        .then((result) => {
          let userCreationEvent;
          if (result.statusCode === 200) {
            userCreationEvent = new CustomEvent("saveuser", {
              detail: {
                title: "User created",
                message: "Success! The new user will be visibile shortly.",
                variant: "Success"
              }
            });
          } else {
            userCreationEvent = new CustomEvent("saveuser", {
              detail: {
                title: "Error",
                message: result.messages[0],
                variant: "Error"
              }
            });
          }
          this.dispatchEvent(userCreationEvent);
        })
        .catch((error) => {
          const userCreationEvent = new CustomEvent("saveuser", {
            detail: {
              title: "Error",
              message: "There was an error creating the user",
              variant: "Error"
            }
          });
          this.dispatchEvent(userCreationEvent);
        });
    } else {
      return;
    }
    return;
  }
}