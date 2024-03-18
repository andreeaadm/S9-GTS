import { LightningElement, api } from "lwc";

export default class TcDynamicHeader extends LightningElement {
  //PUBLIC PROPERTIES
  @api headerSegments;
  @api subHeaderSegments;

  //GETTERS & SETTERS
  /**
   * @returns the header segments formatted as a string for the UI
   */
  get header() {
    let headerText;
    if (this.headerSegments) {
      if (this.headerSegments instanceof Array) {
        headerText = this.headerSegments.join(" - ");
      } else headerText = this.headerSegments;
    }
    return headerText;
  }
  /**
   * @returns the subheader segments formatted as a string for the UI
   */
  get subHeader() {
    let subHeaderText;
    if (this.subHeaderSegments) {
      if (this.subHeaderSegments instanceof Array) {
        subHeaderText = this.subHeaderSegments.join(" - ");
      } else subHeaderText = this.subHeaderSegments;
    }
    return subHeaderText;
  }
}