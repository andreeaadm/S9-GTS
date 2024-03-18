import { LightningElement, api } from 'lwc';

export default class DisplayText extends LightningElement {

    @api text;
    @api styleClass = 'error';

}