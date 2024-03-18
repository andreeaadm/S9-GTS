import { LightningElement, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import USER_ID from "@salesforce/user/Id";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import insertCase from "@salesforce/apex/CompanyAddressesController.insertCase";
import { label } from "c/labelService";

export default class CompanyProfiles extends LightningElement {
  @track labels = label;
  // Temporary stubbed data only - replace with API response when we have API plumbed in
  @track companies = [
    {
      Id: "xxxxxxxxxxxxxxxx",
      Name: "Company A",
      Street: "1 Main Street",
      City: "London",
      Country: "UK",
      Province: "Greater London",
      PostalCode: "N1 1GN"
    },
    {
      Id: "xxxxxxxxxxxxxxxy",
      Name: "Company B",
      Street: "2 Main Street",
      City: "London",
      Country: "UK",
      Province: "Greater London",
      PostalCode: "N1 1GN"
    },
    {
      Id: "xxxxxxxxxxxxxxxz",
      Name: "Company C",
      Street: "3 Main Street",
      City: "London",
      Country: "UK",
      Province: "Greater London",
      PostalCode: "N1 1GN"
    }
  ];
  @track showEditModal = false;
  @track selectedCompany;
  @track isWorking = true;

  @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
  user;

  get contactId() {
    return getFieldValue(this.user.data, CONTACT_ID);
  }

  connectedCallback() {
    // This is temporary until we have the API hooked up.
    // Once that's in place isWorking should be set to false after callback from API
    this.isWorking = false;
  }

  handleEdit(evt) {
    let selectedCompanyId = evt.detail.indexOne;
    this.selectedCompany = JSON.parse(JSON.stringify(this.companies)).filter(
      (company) => {
        return company.Id === selectedCompanyId;
      }
    )[0];
    this.toggleModal();
  }

  toggleModal() {
    this.showEditModal = !this.showEditModal;
  }

  toggleIsWorking() {
    this.isWorking = !this.isWorking;
  }

  handleCancel() {
    this.toggleModal();
  }

  handleSubmit() {
    if (this.validateInputs()) {
      this.toggleIsWorking();
      let newCase = {
        sobjectType: "Case",
        Description: "",
        ContactId: this.contactId,
        Origin: "MTC"
      };
      if (this.template.querySelector(".footer c-input").getChecked()) {
        newCase.Subject = "Address DELETION request";
      } else {
        newCase.Subject = "Address UPDATE request";
      }
      for (let input of this.template.querySelectorAll(".form c-input")) {
        newCase.Description += "\n" + input.value;
      }
      insertCase({ newCase: newCase })
        .then((result) => {
          if (result) {
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.SUCCESS,
                message: this.labels.CHANGES_REQUESTED,
                variant: "success"
              })
            );
          } else {
            this.dispatchEvent(
              new ShowToastEvent({
                title: this.labels.ERROR,
                message: this.labels.CONTACT_AN_ADMIN,
                variant: "error"
              })
            );
          }
          this.toggleModal();
          this.toggleIsWorking();
        })
        .catch((error) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.ERROR,
              message: this.labels.CONTACT_AN_ADMIN,
              variant: "error"
            })
          );
          this.toggleModal();
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