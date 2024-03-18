import { LightningElement, api } from "lwc";

export default class Icon extends LightningElement {
  @api icon;
  @api fill;
  @api stroke;
  hasRendered = false;

  get iconarrowsvg() {
    return this.icon == "iconarrowsvg";
  }

  renderedCallback() {
    if (this.hasRendered) return;
    this.hasRendered = true;
    if (this.fill || this.stroke) {
      let style = "";
      if (this.fill) {
        style += "fill:" + this.fill + ";";
      }
      if (this.stroke) {
        style += "stroke:" + this.stroke + ";";
      }
      this.template.querySelector(".icon").style = style;
    }
  }
}