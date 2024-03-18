import { LightningElement, api, track, wire } from "lwc";
import { getRecord, createRecord, updateRecord } from "lightning/uiRecordApi";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label, format } from "c/labelService";

export default class Form extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api recordTypeLabel;
  @api titleFieldApiName;
  // selectOptionsOverride accepts a map from field API name to a list of select options in the usual { label: "label", value: "value" } format.
  // e.g. {Origin: [{ label: "labelA", value: "valueA" }, { label: "labelB", value: "valueB" }]}
  @api selectOptionsOverride;
  @api displayToasts = false;
  @api saveBtnLabel;
  @api cancelBtnLabel;
  @api get fieldApiNames() {
    return this._fieldApiNames?.length > 0 ? this._fieldApiNames : undefined;
  }
  set fieldApiNames(value) {
    this._fieldApiNames = Array.isArray(value)
      ? value
      : value?.includes(",")
      ? value.split(/\s*,\s*/)
      : value?.length > 0
      ? [value]
      : undefined;
  }
  @api get fieldLabels() {
    return this._fieldLabels?.length > 0 ? this._fieldLabels : undefined;
  }
  set fieldLabels(value) {
    this._fieldLabels = Array.isArray(value)
      ? value
      : value?.includes(",")
      ? value.split(/\s*,\s*/)
      : value?.length > 0
      ? [value]
      : undefined;
  }
  @api get requiredFieldApiNames() {
    return this._requiredFieldApiNames?.length > 0
      ? this._requiredFieldApiNames
      : undefined;
  }
  set requiredFieldApiNames(value) {
    this._requiredFieldApiNames = Array.isArray(value)
      ? value
      : value?.includes(",")
      ? value.split(/\s*,\s*/)
      : value?.length > 0
      ? [value]
      : undefined;
  }
  @track fields = [];
  @track allFieldApiNames = [];
  @track allOptionalFieldApiNames = [];
  @track recordObject;
  @track recordTypeId = "";
  @track record;
  @track isWorking;
  fieldsProcessed = false;
  allPickListValues;
  labels = label;
  _fieldApiNames = [];
  _fieldLabels = [];
  _requiredFieldApiNames = [];

  get displayBtns() {
    return this.cancelBtnLabel && this.saveBtnLabel;
  }

  connectedCallback() {
    this.allOptionalFieldApiNames = [this.objectApiName + ".RecordTypeId"];
  }

  @wire(getObjectInfo, { objectApiName: "$objectApiName" })
  wiredRecordObject(response) {
    if (response.data) {
      this.recordObject = response;
      this.prepareFields();
      this.setRecordTypeId();
      if (!this.recordId) {
        this.processFields();
      }
    }
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: "$allFieldApiNames",
    optionalFields: "$allOptionalFieldApiNames"
  })
  wiredRecord(response) {
    if (response.data) {
      this.record = response;
      this.dispatchEvent(
        new CustomEvent("gotrecord", {
          detail: { record: response }
        })
      );
      if (response.data.fields.RecordTypeId) {
        this.recordTypeId = response.data.fields.RecordTypeId.value;
      }
      this.processFields();
    }
  }

  @wire(getPicklistValuesByRecordType, {
    objectApiName: "$objectApiName",
    recordTypeId: "$recordTypeId"
  })
  wiredPicklistValues(response) {
    if (response.data) {
      this.allPickListValues = response;
      this.processFields();
    }
  }

  prepareFields() {
    let allFieldApiNames = [];
    if (this.fieldApiNames) {
      for (let fieldName of this.fieldApiNames) {
        if (this.recordObject?.data?.fields[fieldName]) {
          allFieldApiNames.push(this.objectApiName + "." + fieldName);
        }
      }
    }
    if (
      this.titleFieldApiName &&
      this.titleFieldApiName.length > 0 &&
      !this.fieldApiNames.includes(this.titleFieldApiName)
    ) {
      allFieldApiNames.push(this.objectApiName + "." + this.titleFieldApiName);
    }
    this.allFieldApiNames = allFieldApiNames;
  }

  setRecordTypeId() {
    if (!this.recordTypeLabel && !this.recordTypeId) {
      this.recordTypeId = this.recordObject.data.defaultRecordTypeId;
    } else {
      const recTypeInfos = this.recordObject.data.recordTypeInfos;
      const recTypeInfo = Object.keys(recTypeInfos).find(
        (rti) => recTypeInfos[rti].name === this.recordTypeLabel
      );
      this.recordTypeId = recTypeInfo ? recTypeInfo.recordTypeId : "";
    }
  }

  processFields() {
    let noPicklists =
      this.fieldApiNames.find(
        (field) => this.recordObject.data.fields[field]?.dataType === "Picklist"
      ) === undefined;

    if (
      ((this.recordId && this.record?.data?.fields) ||
        this.recordObject?.data?.fields) &&
      (noPicklists || this.allPickListValues?.data?.picklistFieldValues) &&
      this.fieldApiNames &&
      !this.fieldsProcessed
    ) {
      let fields = [];
      for (let [i, fieldName] of this.fieldApiNames.entries()) {
        let field = this.recordObject.data.fields[fieldName];
        if (field?.updateable) {
          let newField = {
            apiName: fieldName,
            label:
              this.fieldLabels && this.fieldLabels[i]
                ? this.fieldLabels[i]
                : field.label,
            value: this.record?.data?.fields[fieldName]?.value,
            required:
              //field.required || this.requiredFieldApiNames?.includes(fieldName),
              this.requiredFieldApiNames?.includes(fieldName) ? true : false,
            length: field.length ? field.length : undefined,
            type:
              field.extraTypeInfo && field.extraTypeInfo === "RichTextArea"
                ? this.getFieldType(field.extraTypeInfo)
                : this.getFieldType(field.dataType),
            errorOnRequired: label.REQUIRED_FIELD,
            errorOnPattern: this.getErrorOnPattern(field.dataType)
          };
          if (field.referenceToInfos[0]) {
            newField.sObjectName = field.referenceToInfos[0].apiName;
          }
          if (this.getFieldType(field.dataType) === "SelectList") {
            if (
              this.selectOptionsOverride &&
              this.selectOptionsOverride[fieldName]
            ) {
              newField.selectOptions = this.selectOptionsOverride[fieldName];
            } else if (this.allPickListValues?.data) {
              // First, if this select list depends on another, make sure this one has the appropriate select options
              if (field.controllerName) {
                // Get the parent field's value
                let parentValue =
                  this.record?.data?.fields[field.controllerName]?.value;
                // Get the index of the value
                let key =
                  this.allPickListValues.data.picklistFieldValues[fieldName]
                    .controllerValues[parentValue];
                newField.selectOptions =
                  this.allPickListValues.data.picklistFieldValues[
                    fieldName
                  ]?.values.filter((opt) => opt.validFor.includes(key));
              } else {
                newField.selectOptions =
                  this.allPickListValues.data.picklistFieldValues[
                    fieldName
                  ]?.values;
              }
              // If this selectList isn't required, add a default blank value
              if (!newField.required) {
                newField.value = "";
                newField.needsEmptyOption = true;
              }
            }
          }
          fields.push(newField);
        }
      }
      this.fields = fields;
      this.fieldsProcessed = true;
    }
  }

  getFieldType(dataType) {
    switch (dataType) {
      case "Boolean":
        return "Checkbox";
      case "Currency":
        return "Currency";
      case "Date":
        return "Date";
      case "DateTime":
        return "DateTime";
      case "Double":
        return "Number";
      case "Email":
        return "Email";
      case "Percent":
        return "Percent";
      case "Picklist":
        return "SelectList";
      case "Reference":
        return "Lookup";
      case "TextArea":
        return "Textarea";
      case "RichTextArea":
        return "RichText";
      default:
        return "Text";
    }
  }
  getErrorOnPattern(dataType) {
    switch (dataType) {
      case "Email":
        return label.INVALID_EMAILADDRESS_FIELD;
      default:
        return label.INVALID_FIELD;
    }
  }

  handleFieldChange(evt) {
    evt.stopPropagation();
    let fieldToUpdate = this.fields.find(
      ({ apiName }) => apiName === evt.detail.fieldId
    );
    fieldToUpdate.value = evt.detail.value;

    let changedFieldInfo = this.recordObject.data.fields[evt.detail.fieldId];
    if (this.getFieldType(changedFieldInfo.dataType) === "SelectList") {
      let fields = JSON.parse(JSON.stringify(this.fields));
      // Check each field in the form to see if the selectlist that was changed is a controlling one, and update the children's select options accordingly
      for (let field of fields) {
        if (
          !this.selectOptionsOverride ||
          !this.selectOptionsOverride[field.apiName]
        ) {
          let fieldInfo = this.recordObject.data.fields[field.apiName];
          if (fieldInfo.controllerName == evt.detail.fieldId) {
            // Get the index of the select option that was chosen
            let key =
              this.allPickListValues.data.picklistFieldValues[field.apiName]
                .controllerValues[evt.detail.value];

            // Filter the available select options using the index we just found
            const filteredSelectOptions =
              this.allPickListValues.data.picklistFieldValues[
                field.apiName
              ]?.values.filter((opt) => opt.validFor.includes(key));

            // Now update selectOptions to be filteredSelectOptions
            field.selectOptions = filteredSelectOptions;

            if (!field.required) {
              field.value = "";
              field.needsEmptyOption = true;
            }

            // If the current value isn't one of the new options, set field value to null
            if (
              !filteredSelectOptions.some(
                (option) => option["value"] === field.value
              )
            ) {
              field.value = undefined;
            }
          }
        }
      }
      this.fields = fields;
    }
    this.dispatchEvent(new CustomEvent("change", { detail: evt.detail }));
  }

  cancel() {
    this.dispatchEvent(new CustomEvent("cancel"));
  }

  toggleIsWorking() {
    this.isWorking = !this.isWorking;
  }

  @api
  save() {
    if (this.fieldApiNames) {
      this.toggleIsWorking();
      if (this.validate()) {
        const fields = {};
        for (let input of this.template.querySelectorAll("c-input")) {
          if (input.fieldId) {
            fields[input.fieldId] = input.value;
          }
        }
        const recordInput = { fields };
        if (this.recordId) {
          recordInput.fields.Id = this.recordId;
          this._updateRecord(recordInput);
        } else {
          recordInput.apiName = this.objectApiName;
          this._createRecord(recordInput);
        }
      } else {
        this.toggleIsWorking();
      }
    } else {
      if (this.displayToasts) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: "No fields found",
            variant: "error"
          })
        );
      }
      this.dispatchEvent(
        new CustomEvent("error", { detail: { message: "No fields found" } })
      );
    }
  }

  @api
  validate() {
    let isValid = true;
    this.template.querySelectorAll("c-input").forEach((input) => {
      if (!input.validate().isValid) {
        if (isValid) {
          input.scrollIntoView();
        }
        isValid = false;
      }
    });
    if (!isValid) {
      this.dispatchEvent(
        new CustomEvent("error", { detail: { message: "Validation failed" } })
      );
    }
    return isValid;
  }

  @api
  reset(field) {
    if (field) {
      this.template.querySelector("c-input[data-id='" + field + "']").reset();
    } else {
      this.template.querySelectorAll("c-input").forEach((el) => {
        el.reset();
      });
    }
  }

  _createRecord(recordInput) {
    createRecord(recordInput)
      .then((result) => {
        if (this.displayToasts) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.SUCCESS,
              message: format(
                label.OBJECT_NAMED_UPDATE_SUCCESS,
                this.recordObject?.data?.label,
                this.record?.data?.fields?.Name?.value
              ),
              variant: "success"
            })
          );
        }
        this.dispatchEvent(
          new CustomEvent("success", {
            detail: {
              recordId: result.id
            }
          })
        );
        this.toggleIsWorking();
      })
      .catch((error) => {
        this._handleError(error);
      });
  }

  _updateRecord(recordInput) {
    updateRecord(recordInput)
      .then((result) => {
        if (this.displayToasts) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.SUCCESS,
              message: format(
                label.OBJECT_NAMED_UPDATE_SUCCESS,
                this.recordObject?.data?.label,
                this.record?.data?.fields?.Name?.value
              ),
              variant: "success"
            })
          );
        }
        this.dispatchEvent(new CustomEvent("success"));
        this.toggleIsWorking();
      })
      .catch((error) => {
        this._handleError(error);
      });
  }

  _handleError(error) {
    let errorMessage;
    if (Array.isArray(error.body)) {
      errorMessage = error.body.map((e) => e.message).join(", ");
    } else if (typeof error.body.message === "string") {
      errorMessage = error.body.message;
    }
    if (this.displayToasts) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: errorMessage,
          variant: "error"
        })
      );
    }
    this.dispatchEvent(
      new CustomEvent("error", { detail: { message: errorMessage } })
    );
    this.toggleIsWorking();
  }
}