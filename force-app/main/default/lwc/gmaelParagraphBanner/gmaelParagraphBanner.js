import { LightningElement, api } from 'lwc';

export default class GmaelParagraphBanner extends LightningElement {
    @api title;
    @api paragraph1;
    @api paragraph2;
}