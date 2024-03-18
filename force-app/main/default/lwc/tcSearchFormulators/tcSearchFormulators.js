import { LightningElement, api, track, wire } from "lwc";
import getUserAccessKey from "@salesforce/apex/ZDHCGatewayService.getUserAccessKey";
import Id from "@salesforce/user/Id";
import getFormulators from "@salesforce/apex/TC_SearchFormulatorsController.getFormulators";
import addFormulator from "@salesforce/apex/TC_AddFormulators.addFormulator";
import { label, format } from "c/labelService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getFormulatorDatatableRows } from "c/tcSearchFormulatorDataProvider";

export default class TcSearchFormulators extends LightningElement {
  @api recordId;
  @api allowCreateFormulator;
  searchString = "";
  error;
  isLoading = false;
  noSearchResults = false;
  hasSearched = false;

  //TEMPLATE PROPERTIES
  tableColumns;
  @track searchResults;
  allResultsShown = false;
  labels = label;
  @track searchPerformed = false;
  showCreateFormulator = false;
  formulatorSearchResults = [];

  //GETTERS & SETTERS
  /**
   * @returns true if there are search results to display
   */
  get hasSearchResults() {
    return this.searchResults?.length > 0;
  }

  get showCreateFormulatorBtn() {
    return (
      this.allowCreateFormulator &&
      this.hasSearched &&
      !this.showCreateFormulator
    );
  }

  /**
   * @returns true if there are no search results or the user has manually selected to show
   */

  //LIFECYCLE HOOKS
  connectedCallback() {
    this.getDatatableColumns();
  }

  //LIGHTNING WIRE SERVICE
  /**
   * retrieve the UserAccessKey for the current user
   */
  @wire(getUserAccessKey, {
    recordId: "$_userId"
  })
  _userAccessKey;

  //INTERNAL PROPERTIES
  _userId = Id;
  _allSearchResults;
  _nextStartIndex = 0;
  batchSize = 10;
  batchNumber = 1;

  //EVENT HANDLERS
  /**
   * handles the user's request to view more search results
   */
  handleViewMore() {
    const newBatchNumber = this.batchNumber++;

    const dataTableRows = getFormulatorDatatableRows(
      this.formulatorSearchResults,
      this.batchSize,
      newBatchNumber,
      this.tableColumns
    );
    this.searchResults = dataTableRows;

    // update the property which tells the datatable component
    // to display or not, the load more button
    this.allResultsShown =
      dataTableRows.length >= this.formulatorSearchResults.length;
  }

  handleReset() {
    this._allSearchResults = [];
    this._nextStartIndex = 0;
    this.searchString = "";
    this.searchPerformed = false;
    this.searchResults = null;
    this.noSearchResults = false;
    this.showCreateFormulator = false;
    this.batchNumber = 1;
    this.allResultsShown = false;

    const searchCrit = this.template.querySelector(
      "c-input[data-id='formulatorName']"
    );
    searchCrit.value = '';
  }

  handleSelectFormulator(evt) {
    const rowId = evt.detail.rowId;

    let matchingRowIndex;
    let row = this.formulatorSearchResults.find((obj, index) => {
      if (obj.formulatorGUID == rowId) {
        matchingRowIndex = index;
        return obj;
      }
    });

    this.dispatchEvent(
      new CustomEvent("selectformulator", {
        detail: {
          row,
          index: matchingRowIndex
        },
        bubbles: true,
        composed: true
      })
    );

    // After we've let the parent know a formulator has been selected,
    // in the background check if a formulator with the given formulatorGUID
    // exists.  If one doesn't, create it.
    this.createFormulator(row);
  }

  handleSearch() {
    this.showCreateFormulator = false;
    const searchCrit = this.template.querySelector(
      "c-input[data-id='formulatorName']"
    );
    let validSearch = searchCrit.validate().isValid;
    this.searchString = searchCrit.value;

    if (validSearch) {
      this.searchPerformed = true;
      this.searchResults = [];
      this.isLoading = true;

      this.runFormulatorSearch(this.searchString);
    } else {
      this._showToastNotification(
        this.labels.ERROR,
        this.labels.TC_FORMULATOR_ENTER_INPUT_TEXT,
        "error"
      );

      this.showCreateFormulator = false;
      this.isLoading = false;
    }
  }

  runFormulatorSearch(queryParams) {
    this.noSearchResults = false;
    this.isLoading = true;

    getFormulators({
      userAccessKey: this._userAccessKey.data,
      searchCriteria: queryParams
    })
      .then((response) => {
        if (
          response.isSuccess &&
          response.formulatorsResponseData?.length > 0
        ) {
          this.formulatorSearchResults = response.formulatorsResponseData;
          const dataTableRows = getFormulatorDatatableRows(
            response.formulatorsResponseData,
            this.batchSize,
            this.batchNumber,
            this.tableColumns
          );
          this.searchResults = dataTableRows;
          this.batchNumber++;
        } else {
          this.noSearchResults = true;
        }
        this.hasSearched = true;
        this.isLoading = false;
      })
      .catch((error) => {
        this._showToastNotification(this.labels.ERROR, error, "error");
        this.isLoading = false;
      });
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent("closeformulatormodal"));
  }

  //INTERNAL FUNCTIONS
  /**
   * builds the column data for the datatable cmp
   */
  getDatatableColumns() {
    this.tableColumns = [
      { id: "organizationName", label: this.labels.TC_FORMULATOR_NAME },
      { id: "address", label: this.labels.TC_FORMULATOR_ADDRESS },
      { id: "supplierAID", label: this.labels.TC_FORMULATOR_SUPPLIER_AID },
      { id: "select", label: "" }
    ];
  }

  /**
   * displays a toast notification to the user
   * @param {string} title - title for the notification
   * @param {string} message - core message of the notification
   * @param {string} variant - type of message shown (success / info / warning / error)
   */
  _showToastNotification(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }

  /**
   * creates the Formulator__c sObject if the selected formulator doesn't exist
   */
  async createFormulator(row) {
    try {
      await addFormulator({
        organizationName: row.organizationName,
        formulatorGUID: row.formulatorGUID,
        address: row.address,
        supplierAID: row.supplierAID
      });
    } catch (error) {
      // comment further up says in the background
      console.error(
        format(
          label.OBJECT_NAMED_CREATE_ERROR_WITH_MESSAGE,
          "Formulator",
          "",
          error.body.message
        )
      );
    }
  }

  handleDisplayFormulatorForm() {
    this.showCreateFormulator = true;
  }

  /**
   * handles the user cancelling the create formulator process
   */
  handleCancelCreate() {
    this.showCreateFormulator = false;
  }
}