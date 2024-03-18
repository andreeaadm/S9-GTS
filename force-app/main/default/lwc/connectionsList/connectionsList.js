import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { label } from "c/labelService";
import { subscribe, MessageContext } from "lightning/messageService";
import tcMessageChannel from "@salesforce/messageChannel/TCMessageChannel__c";

import getConnectionList from "@salesforce/apex/TC_ConnectionsListController.getConnectionList";

export default class ConnectionsList extends NavigationMixin(LightningElement) {
  @api listType;

  @track amountToShow = 50;
  @track connectionTable;
  @track allShown = false;
  @track isLoaded = false;
  @track noResults = false;

  labels = label;

  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    this.getConnectionTable();

    if (this.listType === "sent") {
      subscribe(this.messageContext, tcMessageChannel, (message) =>
        this.handleMessage(message)
      );
    }
  }

  handleMessage(message) {
    if (message.messageType === "refreshConnections") {
      this.getConnectionTable();
    }
  }

  handleViewMore() {
    this.amountToShow += 50;
    this.getConnectionTable();
  }

  getConnectionTable() {
    getConnectionList({
      listType: this.listType,
      amountToShow: this.amountToShow
    })
      .then((result) => {
        if (result.table.rows.length == 0) {
          this.noResults = true;
        }
        this.connectionTable = result.table;
        if (this.amountToShow >= result.totalCount) {
          this.allShown = true;
        }
        this.isLoaded = true;
        if (result.error) {
          console.debug(result.error);
        }
      })
      .catch((error) => {
        console.debug(error);
      });
  }

  navToPage(evt) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: evt.detail.rowId,
        objectApiName: "Brand_Supplier_Connection__c",
        actionName: "view"
      }
    });
  }
}