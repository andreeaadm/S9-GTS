import { LightningElement, api } from "lwc";

export default class Modal extends LightningElement {
  @api additionalClasses;
  @api modalcontentclass = "slds-modal__content";
  @api showmodal = false;
  @api maxheight;
  @api maxwidth;

  renderedCallback() {
    if (this.showmodal) {
      if (this.additionalClasses)
        this.template.querySelector(".oegenCustomModal").className =
          "oegenCustomModal " + this.additionalClasses;
      if (this.maxheight)
        this.template
          .querySelector(".oegenCustomModal")
          .style.setProperty(
            "max-height",
            this.maxheight.endsWith("px")
              ? this.maxheight
              : this.maxheight + "px"
          );
      if (this.maxwidth)
        this.template
          .querySelector(".slds-modal__container")
          .style.setProperty(
            "max-width",
            this.maxwidth.endsWith("px") ? this.maxwidth : this.maxwidth + "px"
          );
    }
  }
}