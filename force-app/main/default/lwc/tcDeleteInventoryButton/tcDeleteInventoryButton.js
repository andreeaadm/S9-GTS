import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { label } from "c/labelService";
import deleteInventory from "@salesforce/apex/TC_DeleteInventoryController.deleteInventory";

export default class TcDeleteInventoryButton extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api lineItemsLoaded = false;

  facilityId;
  facilityName;
  inventoryRecord;

  labels = label;
  showModal = false;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "Inventory__c.Status__c",
      "Inventory__c.Facility__c",
      "Inventory__c.Facility__r.Name"
    ]
  })
  processData({ error, data }) {
    if (data) {
      this.facilityId = data.fields.Facility__c.value;
      this.facilityName = data.fields.Facility__r.displayValue;
      this.inventoryRecord = data;
    }
  }

  get showButton() {
    return (
      this.inventoryRecord &&
      this.inventoryRecord.fields.Status__c.value === "Pending" &&
      this.lineItemsLoaded
    );
  }

  handleDelete() {
    this.showModal = true;
  }

  handleCancel() {
    this.showModal = false;
  }

  handleConfirmDelete() {
    deleteInventory({ inventoryToDelete: this.recordId })
      .then((result) => {
        if (result === true) {
          this.handleSuccessfulDelete();
        } else {
          this.handleUnsuccessfulDelete();
        }
      })
      .catch((error) => {
        this.handleUnsuccessfulDelete();
      });
  }

  handleUnsuccessfulDelete() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: this.labels.ERROR,
        message: this.labels.TC_INVENTORY_DELETE_ERROR,
        variant: "error"
      })
    );
    this.showModal = false;
  }

  handleSuccessfulDelete() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: this.labels.SUCCESS,
        message: this.labels.TC_INVENTORY_DELETE_SUCCESS,
        variant: "success"
      })
    );

    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        actionName: "list",
        objectApiName: "Inventory__c"
      },
      state: {
        facilityId: this.facilityId,
        facilityName: this.facilityName
      }
    });
  }
}