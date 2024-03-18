import { LightningElement, api } from 'lwc';

export default class Selectitem extends LightningElement {
    @api value;
    @api label;
    @api currentValue;

    get styleClass() {
        return this.value === this.currentValue ? 'selected' : '';
    }

    handleMouseDown(evt) {
        evt.stopPropagation();
        this.dispatchEvent(new CustomEvent('change', { detail: { value: this.value, label: this.label } }));
    }
}