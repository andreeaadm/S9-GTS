import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { label } from "c/labelService";
import userId from "@salesforce/user/Id";
import userTypeField from "@salesforce/schema/User.UserType";
import { getRecord } from "lightning/uiRecordApi";

export default class TcAddProductsSearchResults extends NavigationMixin(
  LightningElement
) {
  //PUBLIC PROPERTIES
  @api isInternalSalesforce;
  @api inventoryId;
  @api showLoader;
  @api
  set productData(value) {
    this._processSearchResults(value);
  }
  get productData() {}

  //TEMPLATE PROPERTIES
  tableColumns;
  @track searchResults;
  allResultsShown;
  noSearchResults = false;
  labels = label;

  //INTERNAL PROPERTIES
  _allSearchResults;
  _nextStartIndex = 0;
  _batchSize = 50;

  @api zdhcgwDiscColour;
  @api intertekDiscColour;
  @api crowdSourcedDiscColour;

  //GETTERS & SETTERS
  /**
   * call this public method to reset state.
   */
  @api reset() {
    this.noSearchResults = false;
    this.searchResults = [];
  }

  /**
   * @returns true if there are search results to display
   */
  get hasSearchResults() {
    return this.searchResults?.length > 0;
  }

  /**
   * @returns string that should be shown for add to ZDHC button
   */
  get createProductLabel() {
    return this.isInternalSalesforce ? this.labels.TC_ZDHC_ADD_PRODUCT_INTERNAL_BUTTON : this.labels.TC_ADD_NEW_PRODUCT;
  }

  /**
   * @returns true if a search has been performed
   */
  get showCreateProduct() {
    return (
      this.hasSearchResults || this.noSearchResults
    );
  }

  //LIFECYCLE HOOKS
  connectedCallback() {
    this._getDatatableColumns();
  }

  //PUBLIC FUNCTIONS
  /**
   * instructs the cmp to remove the row that was added as a line item
   */
  @api
  removeLinkedProduct(productGUID) {
    const foundIndex = this.searchResults.findIndex(
      (item) => item.rowId === productGUID
    );
    this.searchResults.splice(foundIndex, 1);
  }

  //EVENT HANDLERS
  /**
   * handles the user's request to view more search results
   */
  handleViewMore() {
    this._processNextBatch();
  }

  /**
   * handles the user clicking to add the product to the inventory
   * @param {object} event - cell click custom event on c-datatable
   */
  handleAddProduct(event) {
    this._processAddProduct(event.detail.rowId);
  }

  /**
   * handles the user choosing to create a new product if none is found in the results
   */
  handleCreateNewProduct() {
    if(this.isInternalSalesforce) {
      // Within SF backend, swap modals
      this.dispatchEvent(new CustomEvent('createproductsfbackend', {
        bubbles: true,
        composed: true
      }));
    } else {
      // Within experience site, navigate to create product page
      this._navigateToCreateProduct();
    }
  }

  //INTERNAL FUNCTIONS
  /**
   * builds the column data for the datatable cmp
   */
  _getDatatableColumns() {
    this.tableColumns = [
      { id: "productCategory", label: "" },
      {
        id: "chemicalProductName",
        label: this.labels.TC_CHEMICAL_PRODUCT_NAME
      },
      { id: "otherName", label: this.labels.TC_OTHER_NAME },
      { id: "formulatorName", label: this.labels.TC_FORMULATOR_NAME },
      { id: "substrate", label: this.labels.TC_SUBSTRATE },
      { id: "otherCertifications", label: this.labels.TC_OTHER_CERTIFICATIONS },
      { id: "productId", label: this.labels.TC_PRODUCT_ID },
      { id: "conformant", label: this.labels.TC_CONFORMANT },
      { id: "addProduct", label: "" }
    ];
  }

  /**
   * processes the results received from the wrapper cmp
   * @param {object} data - ListResponse object containing datatable cmp data
   */
  _processSearchResults(data) {
    this._nextStartIndex = 0;
    this._allSearchResults = data;
    this.searchResults = [];
    this._processNextBatch();
  }

  /**
   * processes the next batch of records to display in the c-datatable cmp
   */
  _processNextBatch() {
    let nextEndIndex =
      this._nextStartIndex + this._batchSize < this._allSearchResults.length
        ? this._nextStartIndex + this._batchSize
        : this._allSearchResults.length;
    if (this._nextStartIndex < nextEndIndex) {
      let nextBatch = this._allSearchResults.slice(
        this._nextStartIndex,
        nextEndIndex
      );
      const currentData = this.searchResults;
      const newData = currentData.concat(this._buildDatatableRows(nextBatch));
      this.searchResults = newData;
      this._nextStartIndex = nextEndIndex;
      this.allResultsShown =
        this._nextStartIndex >= this._allSearchResults.length;
    }
    this.noSearchResults = this.searchResults?.length === 0;
  }

  /**
   * builds the datatable rows for displaying to the user
   * @param {array} rowData - product data received from the server
   */
  _buildDatatableRows(rowData) {
    const datatableRows = [];
    rowData.forEach((data) => {
      let rowCells = [
        { value: "", styleClass: data.productCategory }, //Note For FE - when done remove value property
        { value: data.zdhcProductData.productName },
        { value: data.zdhcProductData.OtherName },
        { value: data.zdhcProductData.formulatorName },
        { value: data.salesforceProduct?.Substrate__c },
        { value: data.otherCertifications },
        { value: data.zdhcProductData.ProductID },
        {
          value: data.salesforceProduct
            ? data.salesforceProduct.Conformant__c
            : this._isMRSLConformant(data.zdhcProductData),
          isCheckbox: true,
          disabled: true
        },
        {
          value: this.isInternalSalesforce ? "Link" : "Add",
          isAction: true,
          isButton: true,
          actionName: "customEvent",
          styleClass: "clickable",
          buttonVariant: "IntkBrandOneBtn"
        }
      ];
      for (let i = 0; i < this.tableColumns.length; i++) {
        rowCells[i].id = this.tableColumns[i].id;
        rowCells[i].columnLabel = this.tableColumns[i].label;
      }
      datatableRows.push({
        rowId: data.zdhcProductData.productGUID,
        rowCells
      });
    });
    console.log('datatableRows::'+JSON.stringify(datatableRows));
    return datatableRows;
  }

  _isMRSLConformant(zdhcProductData) {
    let foundMRSL2 = zdhcProductData.ProductCertifications?.find(
      (element) => element.certification === "ZDHC MRSL v2.0"
    )

    let foundMRSL3 = zdhcProductData.ProductCertifications?.find(
      (element) => element.certification === "ZDHC MRSL v3.1"
    )

    let found;
    
    if(foundMRSL2 != null){
        found = foundMRSL2; 
    }
    if(foundMRSL3 != null){
        if(foundMRSL3.certificationResult === "Expired"){
          if(foundMRSL2 != null){
            if(foundMRSL2.certificationResult === "Level 1" ||
            foundMRSL2.certificationResult === "Level 2" ||
            foundMRSL2.certificationResult === "Level 3"){
              found = foundMRSL2;
            }
            else{
              found = foundMRSL3;
            }
          }
          else{
            found = foundMRSL3;
          }
        }
        else{
          found = foundMRSL3;
        }
        
    }

    return found
      ? found.certificationResult === "Level 1" ||
          found.certificationResult === "Level 2" ||
          found.certificationResult === "Level 3"
      : false;
  }

  /**
   * finds the row that was clicked by the user and sends it to the wrapper for
   * @param {string} rowId - either a Salesforce sObject Id or a product GUID
   */
  _processAddProduct(rowId) {
    let matchingRowIndex;
    let row = this._allSearchResults.find((obj, index) => {
      if (obj.zdhcProductData.productGUID == rowId) {
        matchingRowIndex = index;
        return obj;
      }
    });
    this.showLoader = !this.isInternalSalesforce;
    this.dispatchEvent(
      new CustomEvent("addinventoryline", {
        detail: {
          row,
          index: matchingRowIndex
        },
        bubbles: true,
        composed: true
      })
    );
  }

  /**
   * navigates the user to the Create Product standard page
   */
  _navigateToCreateProduct() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: "Create_Product__c"
      },
      state: {
        inventoryId: this.inventoryId
      }
    });
  }
}