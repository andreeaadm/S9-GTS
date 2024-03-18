import { LightningElement, api } from "lwc";

export default class PageHeader extends LightningElement {
  @api title;
  @api btnLabel;

  handleBtnClick(evt) {
    evt.preventDefault();
    evt.stopPropagation();
    this.dispatchEvent(new CustomEvent("click"));
  }
}