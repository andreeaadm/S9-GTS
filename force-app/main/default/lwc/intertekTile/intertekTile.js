import { LightningElement, api, track } from "lwc";

export default class IntertekTile extends LightningElement {
  @api hasLoaded = false;
  @api title = "";
  @api headerBtnLabel1 = "";
  @api headerBtnClass1 = "";
  @api headerBtnIcon1 = "";
  @api headerBtnLabel2 = "";
  @api headerBtnClass2 = "";
  @api headerBtnIcon2 = "";
  @api headerBtnIconFill;
  @api headerBtnIconStroke;
  @api additionalClasses = "intertek-tile";
  @track intertekTileClasses;
  // merge grey tile

  handleBtnClick1() {
    this.dispatchEvent(new CustomEvent("btn1click"));
  }
  handleBtnClick2() {
    this.dispatchEvent(new CustomEvent("btn2click"));
  }

  renderedCallback() {
    if (this.additionalClasses) {
      this.intertekTileClasses = this.additionalClasses + " greytile";
    }
  }
}