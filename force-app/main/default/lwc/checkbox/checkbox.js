import { LightningElement, api } from 'lwc';

export default class Checkbox extends LightningElement {
    @api label;
    @api checked;
    @api required;
    @api disabled;
    @api hideLabel;

    blockDispatchEvent = false;

    connectedCallback() {
        this.checked = (!this.checked || this.checked === "false") ? false : true;
    }

    handleChange(evt) {
        evt.stopPropagation();
        this.checked = !this.checked;
        if (!this.blockDispatchEvent) {
            this.dispatchEvent(new CustomEvent('change', { detail: { value: this.checked } }));
        }
        this.blockDispatchEvent = false;
    }

    get labelClass() {
        return this.disabled ? 'checkbox disabled' : 'checkbox';
    }

    @api uncheck(blockDispatchEvent) {
        if (this.checked) {
            this.blockDispatchEvent = blockDispatchEvent || blockDispatchEvent == undefined ? true : false;
            this.template.querySelector('input').click();
        }
    }

    @api click() {
        this.template.querySelector('input').click();
    }

    @api getChecked() {
        return this.checked;
    }

    @api setIndeterminate(value) {
        this.template.querySelector('input').indeterminate = value;
    }
}