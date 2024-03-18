import { LightningElement, api } from 'lwc';

export default class ICarePathElement extends LightningElement {
    @api progressimage;
    @api progresslabel;
    @api progressdate;
    @api progresstrackimage;
}