import { LightningElement, api } from "lwc";

export default class Recorddetail extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api layoutType;
  @api mode;
  @api title = "Record Detail";
  @api columns = 2;
  @api fields = [];

  @api
  get showForm() {
    return this.recordId && this.objectApiName ? true : false;
  }
}