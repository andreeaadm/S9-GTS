import { LightningElement, track, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getEphemeralURL from "@salesforce/apex/DirectConnectController.getDirectConnectEphemeralURL";
import { label } from "c/labelService";

export default class DirectConnect extends NavigationMixin(LightningElement) {
  @api title = this.labels ? this.labels.DIRECTCONNECT : "";
  @api contentText = this.labels ? this.labels.ACCESS_DIRECTCONNECT : "";
  @api btnLabel = this.labels ? this.labels.LOG_IN : "";
  @api btnVariant = "IntkBrandTwoBtn";
  directConnectURL;
  labels = label;

  handleNavToDirectConnect(evt) {
    getEphemeralURL()
      .then((response) => {
        this.directConnectURL = response;
        this.error = null;
        this[NavigationMixin.Navigate]({
          type: "standard__webPage",
          attributes: {
            url: this.directConnectURL
          }
        });
      })
      .catch((error) => {
        if (error) {
          this.error = error;
        }
      });
  }
}