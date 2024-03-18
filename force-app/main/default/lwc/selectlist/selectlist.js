import { LightningElement, api, track } from "lwc";

export default class Selectlist extends LightningElement {
  _value;
  _options;
  @api label;
  @api fieldId;
  @api needsEmptyOption = false;
  @api get value() {
    return this._value;
  }
  set value(value) {
    this._value = value;
    this.setLabelForValue();
  }
  @api get options() {
    return this._options;
  }
  set options(options) {
    this._options = options;
    this.setLabelForValue();
  }
  @api disabled;
  @api get placeholder() {
    return this._placeholder;
  }
  set placeholder(value) {
    this._placeholder = value;
    this.setLabelForValue();
  }
  _placeholder;
  @track mouseDownFlag;
  @api get styleClass() {
    return this._styleClass;
  }
  set styleClass(value) {
    if (value || value === "") {
      this._styleClass = value.includes("select-list")
        ? value
        : "select-list " + value;
    }
  }
  _styleClass = "select-list";

  get anchorClass() {
    return this.placeholder && !this.value ? "select placeholder" : "select";
  }

  connectedCallback() {
    this.setLabelForValue();
  }

  setLabelForValue() {
    if (this.value != null && this.value != "" && this.options) {
      let option;
      for (let thisOption of this.options) {
        if (thisOption.value === this.value) {
          option = thisOption;
        }
      }
      if (option) {
        this.label = option.label ? option.label : option.value;
      }
    } else {
      this.label = this.placeholder ? this.placeholder : "--";
    }
  }

  handleChange(evt) {
    evt.stopPropagation();
    this.toggleOptions(evt);
    this.value = evt.detail.value;
    this.dispatchEvent(
      new CustomEvent("change", {
        detail: { value: evt.detail.value, fieldId: this.fieldId }
      })
    );
  }

  toggleOptions(evt) {
    if (!this.disabled) {
      this.mouseDownFlag = false;
      let optionsContainer = this.template.querySelector(".select-options");
      optionsContainer.classList.toggle("visible");
      optionsContainer.classList.toggle("positioned");
      let trigger = this.template.querySelector(".trigger");
      trigger.classList.toggle("active");
    }
  }

  hideOptions(evt) {
    if (
      !this.mouseDownFlag ||
      evt.target.getAttribute("data-id") === "thelist"
    ) {
      this.mouseDownFlag = false;
      let optionsContainer = this.template.querySelector(".select-options");
      optionsContainer.classList.remove("visible");
      optionsContainer.classList.remove("positioned");
      let trigger = this.template.querySelector(".trigger");
      trigger.classList.remove("active");
    }
  }

  setMouseDownFlag() {
    this.mouseDownFlag = true;
  }
}