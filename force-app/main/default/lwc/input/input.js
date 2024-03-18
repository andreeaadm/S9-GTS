import oegenResources from "@salesforce/resourceUrl/oegenResources";
import { LightningElement, api, track } from "lwc";
import { loadStyle } from "lightning/platformResourceLoader";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";

// All the characters permitted by RFC 5322, the local part and the domain
// name can contain one or more dots, two dots can only appear right next to
// each other in the local part.
// https://help.salesforce.com/s/articleView?id=000321158&type=1
const EMAIL_ADDRESS_INPUT_REGEX = /^[A-Za-z0-9_!#$%&'*+/=?`{|}~^-]+(?:\.\.?[A-Za-z0-9_!#$%&'*+/=?`{|}~^-]+)*@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*$/;

export default class Input extends LightningElement {
	@api
	get value() {
		return this._value;
	}
	set value(val) {
		this._value = val == undefined ? "" : val;
	}
	@api
	get required() {
		return this._required;
	}
	set required(value) {
		this._required = value;
		this.errors = [];
		if (!value) {
			// If we're using a Salesforce base component, we need to execute reportValidity() to remove the error state
			if (this.isDate || this.isDateTime || this.isFile) {
				// TODO: doesn't seem to blank the error message despite required being false now
				// Could be that a re-render hasn't happened yet
				this.template.querySelector("lightning-input").reportValidity();
			} else if (this.isLookup) {
				this.template.querySelector("lightning-input-field").reportValidity();
			}
		}
	}
	@api
	get title() {
		return this._title ? this._title : this.label;
	}
	set title(value) {
		this._title = value;
	}
	@api
	get errors() {
		return this._errors;
	}
	set errors(value) {
		this._errors = value;
		// If we're not using a Salesforce base component...
		// either toggle error styles on or off based on number of errors
		if (!this.isFile && !this.isLookup) {
			this.toggleErrorStyles(value && value.length > 0);
		}
	}
	@api values; // slider only
	@api minRange; // slider only
	@api maxRange; // slider only
	@api step; // slider only
	@api sliderConfig; // slider only
	@api label;
	@api hideLabel;
	@api placeholder;
	@api type = "Text";
	@api minLength = 1;
	@api maxLength = 255;
	@api regexPattern;
	@api disabled = false;
	@api fieldId;
	@api selectOptions;
	@api selectNeedsEmptyOption = false;
	@api styleClass;
	@api fileAcceptList; // File config
	@api singleFile = false;
	@api sObjectName;
	@api errorOnRequired = "This field is required";
	@api errorOnLength = "";
	@api errorOnPattern = "Invalid value";
	@api errorOnType = "Invalid value";
	@api errorOnCustom = "";

	@track isCheckbox;
	@track isCurrency;
	@track isFormula;
	@track isNumber;
	@track isPercent;
	@track isText;
	@track isTextarea;
	@track isRadio;
	@track isSelect;
	@track isEmailAddress;
	@track isDate;
	@track isDateTime;
	@track isFile;
	@track isLookup;
	@track isSlider;
	@track isRichText;

	observe;
	hasRendered = false;
	_value = "";
	_required = false;
	_title;
	@track _errors = [];

	connectedCallback() {
		this.decideType();
		this.decideIfDisabled();

		// date, datetime, file, lookup, and richtext use lightning base components
		// to style these we have to import CSS from a static resource
		if (
			this.isDate ||
			this.isDateTime ||
			this.isFile ||
			this.isLookup ||
			this.isSlider ||
			this.isRichText
		) {
			this.loadStyles();
		}

		if (this.isEmailAddress && !this.regexPattern) {
			this.regexPattern = EMAIL_ADDRESS_INPUT_REGEX;
			this.maxLength = 80; // Salesforce limit.
		}

		// init date/datetime styleclass
		if (this.isDate) {
			this.styleClass = this.styleClass
				? (this.styleClass = this.styleClass + " date")
				: (this.styleClass = "date");
		}
		if (this.isDateTime) {
			this.styleClass = this.styleClass
				? (this.styleClass = this.styleClass + " datetime")
				: (this.styleClass = "datetime");
		}

		// initialise observe, which we use as a helper to add event listeners to things including textareas
		if (window.attachEvent) {
			this.observe = function(element, event, handler) {
				element.attachEvent("on" + event, handler);
			};
		} else {
			this.observe = function(element, event, handler) {
				element.addEventListener(event, handler, false);
			};
		}

		// init minLength error
		this.errorOnLength = this.minLength
			? "Please enter at least " + this.minLength.toString() + " characters"
			: "";

		this.dispatchEvent(new CustomEvent("inputloaded"));
	}

	renderedCallback() {
		if (!this.hasRendered) {
			this.hasRendered = true;
			if (this.isTextarea) {
				let textArea = this.template.querySelector("textarea");
				function resize() {
					textArea.style.height = "auto";
					textArea.style.height = textArea.scrollHeight + 2 + "px";
				}
				/* 0-timeout to get the already changed text */
				function delayedResize() {
					window.setTimeout(resize, 0);
				}
				this.observe(textArea, "change", resize);
				this.observe(textArea, "cut", delayedResize);
				this.observe(textArea, "paste", delayedResize);
				this.observe(textArea, "drop", delayedResize);
				this.observe(textArea, "keydown", delayedResize);

				resize();
			}
		}
	}

	loadStyles() {
		loadStyle(this, oegenResources + "/css/baseComponentOverrides/input.css");
	}

	get bypassValidation() {
		return (
			this.isCheckbox ||
			this.isRadio ||
			this.isSelect ||
			this.isDate ||
			this.isDateTime ||
			this.isFile ||
			this.isLookup
		);
	}

	decideType() {
		switch (this.type) {
			case "Checkbox":
				this.isCheckbox = true;
				break;
			case "Currency":
				this.isCurrency = true;
				break;
			case "Formula":
				this.isFormula = true;
				break;
			case "Number":
				this.isNumber = true;
				break;
			case "Percent":
				this.isPercent = true;
				break;
			case "Text":
				this.isText = true;
				break;
			case "Textarea":
				this.isTextarea = true;
				break;
			case "Radio":
				this.isRadio = true;
				break;
			case "SelectList":
				this.isSelect = true;
				break;
			case "Email":
				this.isEmailAddress = true;
				break;
			case "Date":
				this.isDate = true;
				break;
			case "DateTime":
				this.isDateTime = true;
				break;
			case "File":
				this.isFile = true;
				break;
			case "Lookup":
				this.isLookup = true;
				break;
			case "Slider":
				this.isSlider = true;
				break;
			case "RichText":
				this.isRichText = true;
				break;
			default:
				this.isText = true;
		}
	}

	decideIfDisabled() {
		this.disabled = this.disabled === "true" || this.disabled === true ? true : false;
	}

	get showMainLabel() {
		return !(
			this.isCheckbox ||
			this.isRadio ||
			this.isDate ||
			this.isDateTime ||
			this.isFile ||
			this.isRichText
		);
	}

	get isCheckable() {
		return this.isCheckbox || this.isRadio;
	}

	get multipleFiles() {
		return !this.singleFile;
	}

	handleChange(evt) {
		evt.stopPropagation();
		let value =
			evt.detail && evt.detail.value !== undefined
				? evt.detail.value
				: evt.target.value;
		if (Array.isArray(value)) {
			value = value[0];
		}
		this.value = value;
		const fieldId =
			evt.detail && evt.detail.fieldId ? evt.detail.fieldId : this.fieldId;
		const label = this.label;
		const type = this.type;
		const valid = this.validateOnChange(value);
		if (valid) {
			// event must bubble in order for inputGroup to hear it where necessary
			this.validateRequired();
			this.dispatchEvent(new FlowAttributeChangeEvent("value", value));
			this.dispatchEvent(
				new CustomEvent("change", {
					bubbles: true,
					detail: {
						fieldId: fieldId,
						label: label,
						value: value,
						type: type
					}
				})
			);
		} else {
			if (this.isCheckbox) {
				evt.target.value = false;
			}
		}
	}

	handleSliderChange(evt) {
		evt.stopPropagation();
		const values =
			evt.detail && evt.detail.values !== undefined ? evt.detail.values : 0;
		const fieldId =
			evt.detail && evt.detail.fieldId ? evt.detail.fieldId : this.fieldId;
		const label = this.label;
		const type = this.type;
		this.values = values;
		// event must bubble in order for inputGroup to hear it where necessary
		this.dispatchEvent(new FlowAttributeChangeEvent("values", values));
		this.dispatchEvent(
			new CustomEvent("change", {
				bubbles: true,
				detail: {
					fieldId: fieldId,
					label: label,
					values: values,
					type: type
				}
			})
		);
	}

	handleFilesChange(evt) {
		evt.stopPropagation();
		const files = evt.target.files;
		const fieldId = this.fieldId;
		const label = this.label;
		const type = this.type;
		this.value = files;
		this.validateRequired();
		// filechange event must bubble in order for inputGroup to hear it where necessary
		this.dispatchEvent(new FlowAttributeChangeEvent("value", files));
		this.dispatchEvent(
			new CustomEvent("filechange", {
				bubbles: true,
				detail: {
					fieldId: fieldId,
					label: label,
					files: files,
					type: type
				}
			})
		);
	}

	validateOnChange(value) {
		if (this.bypassValidation) {
			return true;
		}
		if (this.isCurrency || this.isNumber || this.isPercent) {
			return this.validateType(value);
		}
		if (this.isEmailAddress || this.isText || this.isTextarea || this.isRichText) {
			return this.validateText(value);
		}
		return false;
	}

	validateText(value) {
		let length = this.validateMaxLength(value);
		return length;
	}

	validateMinLength(value) {
		return this.minLength && value ? value.length >= this.minLength : true;
	}

	validateMaxLength(value) {
		return this.maxLength && value ? value.length <= this.maxLength : true;
	}

	validateRequired() {
		let isValid = true;
		let errors = this.errors;
		// If we're dealing with a Salesforce base component, call the reportValidity function which returns false if error or true if valid
		if (this.isDate || this.isDateTime || this.isFile) {
			isValid = this.template.querySelector("lightning-input").reportValidity();
		} else {
			// If not a Salesforce base component, roll our own validation
			if (this.required) {
				if (
					this.value === undefined ||
					this.value === null ||
					this.value === "" ||
					this.value === false
				) {
					isValid = false;
					// display error
					if (!errors.includes(this.errorOnRequired)) {
						errors.push(this.errorOnRequired);
						this.errors = errors;
					}
				} else {
					// remove error
					if (errors && errors.length > 0) {
						errors = errors.filter((error) => error != this.errorOnRequired);
						this.errors = errors;
					}
				}
			}
		}
		return isValid;
	}

	validateLength() {
		let isValid = true;
		let errors = this.errors;
		if (
			this.value.hasOwnProperty("length") &&
			!this.isDateTime &&
			!this.isDate &&
			!this.isFile
		) {
			isValid =
				this.validateMinLength(this.value) && this.validateMaxLength(this.value);
			if (!isValid) {
				if (!errors.includes(this.errorOnLength)) {
					errors.push(this.errorOnLength);
					this.errors = errors;
				}
			} else {
				// remove error
				if (errors && errors.length > 0) {
					errors = errors.filter((error) => error != this.errorOnLength);
					this.errors = errors;
				}
			}
		}
		return isValid;
	}

validatePattern() {
let isValid = true;
let errors = this.errors;
	if (this.regexPattern) {
		if(
			this.value !== '' 
		)
		{
		isValid = this.regexPattern.test(this.value);
		}
		if (!isValid) {
			if (!errors.includes(this.errorOnPattern)) {
				errors.push(this.errorOnPattern);
				this.errors = errors;
			}
		} else {
			// remove error because either value is valid or user just typed in the field
			if (errors && errors.length > 0) {
				errors = errors.filter((error) => error != this.errorOnPattern);
				this.errors = errors;
			}
		}
	}

return isValid;
}

	validateType(value) {
		let isValid = true;
		let errors = this.errors;
		if (this.isNumber || this.isPercent || this.isCurrency) {
			isValid = this.validateMaxLength(value) && !isNaN(value);
		}
		if (!isValid) {
			if (!errors.includes(this.errorOnType)) {
				errors.push(this.errorOnType);
				this.errors = errors;
			}
		} else {
			// remove error
			if (errors && errors.length > 0) {
				errors = errors.filter((error) => error != this.errorOnType);
				this.errors = errors;
			}
		}
		return isValid;
	}

	toggleErrorStyles(isError) {
		if (this.hasRendered) {
			if (this.isTextarea) {
				isError
					? this.template.querySelector("textarea").classList.add("has-error")
					: this.template
							.querySelector("textarea")
							.classList.remove("has-error");
			} else if (this.isSelect) {
				let styleClass = this.template.querySelector("c-selectlist").styleClass;
				isError
					? (styleClass += " has-error")
					: (styleClass = styleClass.replace("has-error", ""));
				this.template.querySelector("c-selectlist").styleClass = styleClass;
			} else if (this.isCheckbox) {
				isError
					? this.template.querySelector("c-checkbox").classList.add("has-error")
					: this.template
							.querySelector("c-checkbox")
							.classList.remove("has-error");
			} else if (this.isDate || this.isDateTime) {
				isError
					? (this.styleClass = this.styleClass + " has-error")
					: this.styleClass.replace("has-error", "");
			} else {
				isError
					? this.template.querySelector("input").classList.add("has-error")
					: this.template.querySelector("input").classList.remove("has-error");
			}
		}
	}

	@api
	processUncheck(label) {
		if (this.label !== label) {
			if (this.isCheckbox) {
				this.template.querySelector("c-checkbox").uncheck();
			} else if (this.isRadio) {
				this.template.querySelector("c-radio").uncheck();
			}
		}
	}
	@api
	getType() {
		return this.type;
	}
	@api
	getLabel() {
		return this.label;
	}
	@api
	getChecked() {
		return this.isCheckbox
			? this.template.querySelector("c-checkbox").getChecked()
			: this.isRadio ? this.template.querySelector("c-radio").getChecked() : false;
	}
	@api
	click() {
		if (this.isCheckbox) {
			this.template.querySelector("c-checkbox").click();
		} else if (this.isRadio) {
			this.template.querySelector("c-radio").click();
		}
	}
	@api
	uncheck() {
		if (this.isCheckbox) {
			this.template.querySelector("c-checkbox").uncheck();
		} else if (this.isRadio) {
			this.template.querySelector("c-radio").uncheck();
		}
	}
	@api
	validate() {
		// Removed usage of _this 31/01/2022 as it was causing issues with validating multiple c-inputs at the same time
		//let _this = this;
		//this.errors = [];
		let requiredIsValid, lengthIsValid, patternIsValid, typeIsValid;
		requiredIsValid = this.validateRequired();
		if (requiredIsValid) {
			lengthIsValid = this.validateLength();
			typeIsValid = this.validateType(this.value);
			patternIsValid = this.validatePattern();
		}
		let returnObj = {
			fieldId: this.fieldId,
			isValid:
				requiredIsValid && lengthIsValid && patternIsValid && typeIsValid
					? true
					: false
		};
		return returnObj;
	}
	@api
	toggleCustomError(isError) {
		let errors = this.errors;
		if (isError) {
			if (!errors.includes(this.errorOnCustom)) {
				errors.push(this.errorOnCustom);
				this.errors = errors;
			}
		} else {
			// remove error
			if (errors && errors.length > 0) {
				errors = errors.filter((error) => error != this.errorOnCustom);
				this.errors = errors;
			}
		}
	}
	@api
	copyTextareaContent() {
		let textarea = this.template.querySelector("textarea");
		textarea.disabled = false;
		textarea.select();
		document.execCommand("copy");
		textarea.disabled = true;
	}
}