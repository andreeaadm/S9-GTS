import { LightningElement, wire, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label, format } from "c/labelService";
import postInCheckReportForInventory from "@salesforce/apex/ZDHCPostInCheckReportController.postInCheckReportForInventory";
import { publish, MessageContext } from "lightning/messageService";
import tcMessageChannel from "@salesforce/messageChannel/TCMessageChannel__c";

export default class zdhcPostInCheckReport extends LightningElement {
  labels = label;

  @wire(MessageContext)
  messageContext;

  @api doSubmitInventoryCallout(inventoryId) {
    postInCheckReportForInventory({
      inventoryId: inventoryId
    })
      .then((response) => {
        if (response !== null) {
          dispatchEvent(
            new ShowToastEvent({
              title: this.labels.ERROR,
              message: format(label.TC_ZDHC_CALLOUT_ERROR, response),
              variant: "error"
            })
          );
        } else {
          dispatchEvent(
            new ShowToastEvent({
              title: this.labels.SUCCESS,
              message: this.labels.TC_SUBMIT_INVENTORY_SUCCESS,
              variant: "success"
            })
          );
        }
      })
      .catch((error) => {
        dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR,
            message: format(label.TC_ZDHC_CALLOUT_ERROR, error.body.message),
            variant: "error"
          })
        );
      })
      .finally(() => {
        publish(this.messageContext, tcMessageChannel, {
          messageType: "refreshInventory"
        });
      });
  }
}