import { LightningElement, api } from 'lwc';

export default class Filters extends LightningElement {
    @api filters = [];

    filterClick(evt) {
        this.dispatchEvent(new CustomEvent('filterclick', {
            detail: evt.currentTarget.dataset.id
        }));
    }
}