import { LightningElement, api } from 'lwc';

export default class Heartsvg extends LightningElement {
    @api active = false;
    get styleClass() {
        return this.active ? 'active' : 'inactive';
    }
}