import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import CASE_OBJECT from "@salesforce/schema/Case";
import ID_FIELD from "@salesforce/schema/Case.Id";
import CASENUMBER_FIELD from "@salesforce/schema/Case.CaseNumber";
import SUBJECT_FIELD from "@salesforce/schema/Case.Subject";
import DESCRIPTION_FIELD from "@salesforce/schema/Case.Description";
import ISCLOSED_FIELD from "@salesforce/schema/Case.IsClosed";
import { label } from "c/labelService";

export default class CaseDetail extends LightningElement {
  @api recordId;
  @track isWorking = false;
  @track editMode = false;
  caseNumberField = CASENUMBER_FIELD;
  subjectField = SUBJECT_FIELD;
  descriptionField = DESCRIPTION_FIELD;
  isClosedField = ISCLOSED_FIELD;
  labels = label;

  @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
  caseObject;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [CASENUMBER_FIELD, SUBJECT_FIELD, DESCRIPTION_FIELD, ISCLOSED_FIELD]
  })
  case;

  get isUpdateable() {
    return (
      this.caseObject?.data?.updateable &&
      this.case.data &&
      !getFieldValue(this.case.data, ISCLOSED_FIELD)
    );
  }

  get caseNumber() {
    return getFieldValue(this.case.data, CASENUMBER_FIELD);
  }

  get subject() {
    return getFieldValue(this.case.data, SUBJECT_FIELD);
  }

  get description() {
    return getFieldValue(this.case.data, DESCRIPTION_FIELD);
  }

  toggleIsWorking() {
    this.isWorking = !this.isWorking;
  }

  toggleEdit() {
    this.editMode = !this.editMode;
  }

  handleUpdateCase() {
    if (this.validateInputs()) {
      this.toggleIsWorking();
      const fields = {};
      fields[ID_FIELD.fieldApiName] = this.recordId;
      for (let input of this.template.querySelectorAll("c-input")) {
        if (input.fieldId) {
          fields[input.fieldId] = input.value;
        }
      }
      const recordInput = { fields };
      updateRecord(recordInput)
        .then((result) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.SUCCESS,
              message: this.labels.CHANGES_SAVED,
              variant: "success"
            })
          );
          this.toggleEdit();
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
          this.toggleIsWorking();
        });
    }
  }

  validateInputs() {
    let isValid = true;
    this.template.querySelectorAll("c-input").forEach((input) => {
      if (!input.validate().isValid) {
        isValid = false;
      }
    });
    return isValid;
  }
}