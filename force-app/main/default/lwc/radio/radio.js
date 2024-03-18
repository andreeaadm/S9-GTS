import { LightningElement, api } from 'lwc';

export default class Radio extends LightningElement {
    @api label;
    @api fieldId;
    @api checked;
    @api disabled;
    @api hideLabel;

    connectedCallback() {
        this.checked = (!this.checked || this.checked === "false") ? false : true;
    }

    handleChange(evt) {
        evt.stopPropagation();
        if (!this.checked) {
            this.checked = true;
            this.dispatchEvent(new CustomEvent('change', { detail: { value: this.label } }));
        }
    }

    @api uncheck() {
        if (this.checked) {
            this.checked = !this.checked;
        }
    }

    @api click() {
        this.template.querySelector('input').click();
    }

    @api getChecked() {
        return this.checked;
    }
}