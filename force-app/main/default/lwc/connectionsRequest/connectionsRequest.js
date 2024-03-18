import { LightningElement, track, wire } from "lwc";
import getUserType from "@salesforce/apex/TC_ConnectionRequestController.getUserType";
import getSearchTable from "@salesforce/apex/TC_ConnectionRequestController.getSearchTable";
import createConnection from "@salesforce/apex/TC_ConnectionRequestController.createConnection";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label } from "c/labelService";
import { publish, MessageContext } from "lightning/messageService";
import tcMessageChannel from "@salesforce/messageChannel/TCMessageChannel__c";

export default class ConnectionsRequest extends LightningElement {
  @track modalShowing = false;
  @track userType = "";
  @track nameSearch = "";
  @track countrySearch = "";
  @track modalResultsFound = false;
  @track searchPerformed = false;
  @track noResults = false;
  @track modalTable;
  @track amountToShow = 10;
  @track allShown = false;
  @track loadingSearch = false;

  // Dynamic labels for either Brand or Supplier user, get set in connected callback
  @track buttonLabel = "";
  @track modalHeaderLabel = "";
  @track nameSearchLabel = "";
  @track preSearchLabel = "";

  @track labels = label;

  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    getUserType().then((result) => {
      this.userType = result;
      // Set all of the labels accordingly

      if (this.userType == "supplier") {
        this.buttonLabel = this.labels.TC_BRAND_CONNECT_BUTTONTEXT;
        this.modalHeaderLabel = this.labels.TC_BRAND_CONNECT_MODALHEADER;
        this.nameSearchLabel = this.labels.TC_BRAND_NAME;
        this.preSearchLabel = this.labels.TC_PRESEARCH_BRAND;
      } else {
        this.buttonLabel = this.labels.TC_SUPPLIER_CONNECT_BUTTONTEXT;
        this.modalHeaderLabel = this.labels.TC_SUPPLIER_CONNECT_MODALHEADER;
        this.nameSearchLabel = this.labels.TC_SUPPLIER_NAME;
        this.preSearchLabel = this.labels.TC_PRESEARCH_SUPPLIER;
      }
    });
  }

  toggleModal() {
    this.modalShowing = !this.modalShowing;

    if (!this.modalShowing) {
      this.resetSearch();
    }
  }

  nameChanged(evt) {
    this.nameSearch = evt.detail.value;
  }

  countryChanged(evt) {
    this.countrySearch = evt.detail.value;
  }

  resetSearch() {
    this.nameSearch = "";
    this.countrySearch = "";
    this.modalResultsFound = false;
    this.searchPerformed = false;
    this.noResults = false;
    this.allShown = false;
  }

  searchTable() {
    if (this.nameSearch.length < 3 && this.countrySearch.length < 3) {
      // Need to input more characters to search
      this.dispatchEvent(
        new ShowToastEvent({
          message: this.labels.TC_CONNECTION_REQUEST_INVALID_SEARCH_MESSAGE,
          variant: "error"
        })
      );
    } else {
      this.amountToShow = 10;
      this.allShown = false;
      this.doSearch();
    }
  }

  handleViewMore() {
    this.amountToShow += 10;
    this.doSearch();
  }

  doSearch() {
    this.loadingSearch = true;
    getSearchTable({
      userType: this.userType,
      amountToShow: this.amountToShow,
      nameSearch: this.nameSearch,
      countrySearch: this.countrySearch
    })
      .then((result) => {
        this.searchPerformed = true;
        if (result.table.rows.length == 0) {
          this.noResults = true;
          this.modalResultsFound = false;
        } else {
          this.modalResultsFound = true;
          this.noResults = false;
        }
        this.modalTable = result.table;
        if (this.amountToShow >= result.totalCount) {
          this.allShown = true;
        } else {
          this.allShown = false;
        }

        if (result.error) {
          console.debug(result.error);
        }

        this.loadingSearch = false;
      })
      .catch((error) => {
        console.debug(error);
      });
  }

  handleConnect(evt) {
    createConnection({
      userType: this.userType,
      otherAccountId: evt.detail.rowId
    }).then((result) => {
      if (result != "success") {
        this.dispatchEvent(
          new ShowToastEvent({
            message: this.labels.TC_CONNECTION_REQUEST_ERROR,
            variant: "error"
          })
        );
        console.debug(result);
      } else {
        this.toggleModal();
        this.dispatchEvent(
          new ShowToastEvent({
            message:
              this.labels.TC_CONNECTION_REQUEST_SUCCESS1 +
              " " +
              evt.detail.rowLabel +
              this.labels.TC_CONNECTION_REQUEST_SUCCESS2,
            variant: "success"
          })
        );
        publish(this.messageContext, tcMessageChannel, {
          messageType: "refreshConnections"
        });
      }
    });
  }
}