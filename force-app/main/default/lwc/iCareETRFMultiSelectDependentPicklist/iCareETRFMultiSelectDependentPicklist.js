/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, track } from "lwc";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";
import getDependentPicklistValues from "@salesforce/apex/PicklistController.getDependentPicklistValues";
import HELP_TEXT from "@salesforce/label/c.iCare_Picklist_Help_Text";

export default class ICareETRFMultiSelectDependentPicklist extends LightningElement {
  selectedValues = [];
  preSelectedLabelList = [];
  @api preSelectedValues;
  @api objectName;
  @api dependentFieldName;
  @api returnedValues;
  @api returnedValuesText;
  @api controllingFieldValue;

  customLabel = {
    HELP_TEXT
  };

  isPicklistOptions;

  @track picklistOptions = [];

  error;
  @api fieldLabel;
  size = 10;

  connectedCallback() {
    this.getPicklistValues();
  }

  getPicklistValues() {
    getDependentPicklistValues({
      objectName: this.objectName,
      dependentField: this.dependentFieldName,
      controllingFieldValue: this.controllingFieldValue
    })
      .then((result) => {
        this.picklistOptions = result.map((option) => ({
          label: option.picklistLabel,
          value: option.picklistValue,
          selected: false
        }));
        this.getPreSelectedValues();
        if (this.picklistOptions.length < 5) {
          this.size = this.picklistOptions.length;
        } else {
          this.size = Math.min(Math.max(this.picklistOptions.length, 5), 10);
        }
        this.isPicklistOptions = this.picklistOptions.length > 0;
      })
      .catch((error) => {
        console.log("error:" + error);
        this.error = error;
      });
  }

  // iterate over preselected values and highlight
  getPreSelectedValues() {
    if (this.preSelectedValues !== undefined) {
      let preSelectedValuesList = this.preSelectedValues[0].split(";");
      for (let i = 0; i < this.picklistOptions.length; i++) {
        if (preSelectedValuesList.includes(this.picklistOptions[i].value)) {
          this.picklistOptions[i].selected = true;
          this.selectedValues.push(this.picklistOptions[i].value);
          this.preSelectedLabelList.push(this.picklistOptions[i].label);
        }
      }
      this.returnedValuesText = this.preSelectedLabelList.join(", ");
      this.returnedValues = this.preSelectedValues;
    }
  }

  // Event handler for selection change
  handleSelection(event) {
    // Get the selected values
    this.selectedValues = Array.from(event.target.selectedOptions).map(
      (option) => option.value
    );
    this.returnedValuesText = Array.from(event.target.selectedOptions)
      .map((option) => option.label)
      .join(", ");

    this.returnedValues = this.selectedValues.join(";");
    this.dispatchEvent(
      new FlowAttributeChangeEvent("returnedValues", this.returnedValues)
    );
  }
}