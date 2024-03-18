import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class Button extends NavigationMixin(LightningElement) {
  @api label;
  @api get variant() {
    return this._variant;
  }
  set variant(value) {
    this._variant = value;
    this.getContainerClass();
  }
  @api indexOne;
  @api indexTwo;
  @api destinationPage;
  @api destinationUrl;
  @api destinationRecordId;
  @api icon;
  @api iconFill;
  @api iconStroke;
  @api get disabled() {
    return this._disabled;
  }
  set disabled(value) {
    this._disabled = value;
    this.containerClass = value ? "disabled " + this.variant : this.variant;
  }
  @track containerClass;
  @track showButton = false;
  _variant = "main";
  _disabled;

  connectedCallback() {
    this.containerClass = this.disabled
      ? "disabled " + this.variant
      : this.variant;
    this.showButton = true;
  }

  getContainerClass() {
    this.containerClass = this.disabled
      ? "disabled " + this.variant
      : this.variant;
  }

  doClick(evt) {
    evt.stopPropagation();

    if (
      this.destinationPage ||
      this.destinationUrl ||
      this.destinationRecordId
    ) {
      this.doNavClick();
    } else {
      this.dispatchEvent(
        new CustomEvent("click", {
          detail: {
            label: this.label,
            variant: this.variant,
            indexOne: this.indexOne,
            indexTwo: this.indexTwo
          }
        })
      );
    }
  }

  doNavClick() {
    if (this.destinationPage) {
      if (this.destinationPage == "Back") {
        if (window.history.length && window.history.length > 1) {
          window.history.back();
        } else {
          window.close();
        }
      } else {
        this[NavigationMixin.Navigate]({
          type: "comm__namedPage",
          attributes: {
            name: this.destinationPage
          }
        });
      }
    } else if (this.destinationUrl) {
      this[NavigationMixin.Navigate]({
        type: "standard__webPage",
        attributes: {
          url: this.destinationUrl
        }
      });
    } else if (this.destinationRecordId) {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: this.destinationRecordId,
          actionName: "view" //Experience cloud doesn't support edit or other modes(as of Jan 2022)
        }
      });
    }
  }
}