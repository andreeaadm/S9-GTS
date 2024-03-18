import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import USER_ID from "@salesforce/user/Id";

export default class TcInventoriesTab extends NavigationMixin(
  LightningElement
) {
  userId = USER_ID;

  @wire(getRecord, {
    recordId: "$userId",
    fields: [
      "User.Contact.AccountId",
      "User.Contact.Account.Name",
      "User.Contact.Account.ToxClear_Account_Type__c"
    ]
  })
  wiredRecord({ error, data }) {
    if (data) {
      let acctId = data.fields.Contact?.value?.fields?.AccountId?.value;
      let acctName = data.fields.Contact?.value?.fields?.Account?.displayValue;
      let tcType =
        data.fields.Contact?.value?.fields?.Account?.value?.fields
          ?.ToxClear_Account_Type__c?.value;

      if (tcType === "Supplier") {
        this.redirectToFacilities();
      } else if (tcType === "Facility") {
        this.redirectToInventories(acctId, acctName);
      }
    } else if (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: error?.body?.message,
          variant: "error"
        })
      );
    }
  }

  redirectToFacilities() {
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        actionName: "list",
        objectApiName: "Account"
      }
    });
  }

  redirectToInventories(acctId, acctName) {
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: "Inventory__c",
        actionName: "list"
      },
      state: {
        facilityId: acctId,
        facilityName: acctName
      }
    });
  }
}