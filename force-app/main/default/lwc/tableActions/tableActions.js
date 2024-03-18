import { LightningElement, api } from "lwc";

export default class TableActions extends LightningElement {
  @api checked = false;
  @api actions;
  @api selectedRowCount = 0;
  // selectedState can be "unselected", "indeterminate" or "selected"
  // this will be used to drive the checkbox selected state
  @api get selectedState() {
    return this._selectedState;
  }
  set selectedState(value) {
    this._selectedState = value;
    this.setCheckboxState();
  }
  _selectedState = "none";
  hasRendered = false;

  renderedCallback() {
    this.hasRendered = true;
    //this.setCheckboxState();
  }

  setCheckboxState() {
    if (this.hasRendered) {
      let checkbox = this.template.querySelector("c-checkbox");
      switch (this.selectedState) {
        case "indeterminate":
          if (checkbox.getChecked()) {
            checkbox.uncheck();
          }
          checkbox.setIndeterminate(true);
          break;
        case "selected":
          if (!checkbox.getChecked()) {
            checkbox.click();
          }
          checkbox.setIndeterminate(false);
          break;
        default:
          if (checkbox.getChecked()) {
            checkbox.uncheck();
          }
          checkbox.setIndeterminate(false);
          break;
      }
    }
  }

  handleCheckboxChange(evt) {
    this.dispatchEvent(
      new CustomEvent("checkboxchange", {
        detail: {
          checked: evt.currentTarget.checked
        }
      })
    );
  }

  handleClick(evt) {
    this.dispatchEvent(
      new CustomEvent("actionclick", {
        detail: {
          label: evt.currentTarget.dataset.id
        }
      })
    );
  }
}