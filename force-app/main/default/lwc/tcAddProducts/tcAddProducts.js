import { LightningElement, wire, api } from "lwc";
import { createRecord, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Id from "@salesforce/user/Id";
import getUserAccessKey from "@salesforce/apex/ZDHCGatewayService.getUserAccessKey";
import searchProducts from "@salesforce/apex/TC_AddProducts.searchProducts";
import getFormulatorId from "@salesforce/apex/TC_SearchFormulatorsController.getFormulatorId";
import getLineItemForProduct from "@salesforce/apex/TC_InventoryLineItems.getLineItemForProduct";
import getLineItemProductGUIDs from "@salesforce/apex/TC_InventoryLineItems.getLineItemProductGUIDs";
import { refreshApex } from "@salesforce/apex";
import { label } from "c/labelService";

export default class TcAddProducts extends LightningElement {
  //TEMPLATE PROPERTIES
  showResultsLoader = false;
  labels = label;
  inventoryId;

  //INTERNAL PROPERTIES
  _userId = Id;
  _selectedRow;
  _selectedRowIndex;
  _productOrigin = "ZDHC Gateway";
  _userAccessKey;

  @api zdhcgwDiscColour;
  @api intertekDiscColour;
  @api crowdSourcedDiscColour;

  //LIGHTNING WIRE SERVICE
  /**
   * retrieve the UserAccessKey for the current user
   */
  @wire(getUserAccessKey, {
    recordId: "$_userId"
  })
  wiredUserAccessKey(response) {
    this._userAccessKey = response;
    if (!response.data) {
      this._showToastNotification(
        this.labels.ERROR,
        this.labels.TC_GET_USER_ACCESS_KEY_ERROR,
        "error"
      );
    }
  }

  @wire(getLineItemProductGUIDs, { inventoryId: "$inventoryId" })
  existingProductGUID;

  //EVENT HANDLERS
  /**
   * handles the page reference cmp retrieving the Inventory__c record Id
   * @param {object} event - retrievedstate custom event
   */
  handleRetrievedState(event) {
    this.inventoryId = event.detail.recordId;
  }

  /**
   * handles the user's request to search for products
   * @param {object} event - search custom event
   */
  handleSearch(event) {
    this._processSearch(event.detail);
  }

  /**
   * handles the user's request to reset the search views
   */
  handleReset() {
    this.template.querySelector("c-tc-add-products-search-results").reset();
  }

  /**
   * handles the user requesting to add a chemical product to the inventory
   * @param {object} event - addinventoryline custom event
   */
  handleAddInventoryLine(event) {
    this._selectedRow = event.detail.row;
    this._selectedRowIndex = event.detail.index;
    if (this._selectedRow.salesforceProduct) {
      this._updateChemicalProduct(this._selectedRow.salesforceProduct.Id);
    } else {
      this._createChemicalProduct();
    }
  }

  /**
   * calls the server to get products from ZDHC and the master chemical list (Salesforce)
   * @param {object} queryParams - params used on the ZDHC API to filter the results
   */
  _processSearch(queryParams) {
    if (this._userAccessKey?.data) {
      this.showResultsLoader = true;
      searchProducts({
        userAccessKey: this._userAccessKey.data,
        queryParams: queryParams
      })
        .then((response) => {
          this._processSearchResponse(response);
        })
        .catch((error) => {
          this._showToastNotification(
            this.labels.ERROR,
            this.labels.TC_SEARCHING_PRODUCTS_ERROR,
            "error"
          );
          this.showResultsLoader = false;
        });
    }
  }

  /**
   * processes the response from the server
   * @param {object} response - ListResponse for c-datatable if successfuly or a gateway service response if not
   */
  _processSearchResponse(response) {
    refreshApex(this.existingProductGUID);
    const resultsCmp = this.template.querySelector(
      "c-tc-add-products-search-results"
    );
    resultsCmp.productData = [];
    const combinedProducts =
      response.isSuccess &&
      response.combinedProducts?.length > 0 &&
      this.existingProductGUID?.data?.length > 0
        ? response.combinedProducts.filter(
            (element) =>
              !this.existingProductGUID.data.includes(
                element.zdhcProductData.productGUID
              )
          )
        : response.combinedProducts;
    if (response.isSuccess && combinedProducts.length > 0) {
      resultsCmp.productData = combinedProducts;
    } else {
      resultsCmp.noSearchResults = true;
      if (!response.errors?.[0] === "No results found.") {
        this._showToastNotification(
          this.labels.ERROR,
          this.labels.TC_SEARCHING_PRODUCTS_ERROR,
          "error"
        );
      }
    }
    resultsCmp.showLoader = this.showResultsLoader = false;
  }

  /**
   * creates the Chemical_Product__c sObject if the user has selected a row without an existing record
   */
  async _createChemicalProduct() {
    try {
      const formulatorId = await getFormulatorId({
        userAccessKey: this._userAccessKey?.data,
        formulatorGUID: this._selectedRow.zdhcProductData.formulatorGUID
      });

      let mrslLevel;
      let mrslVersion;

      if (
        this._selectedRow.mrsl2Level == "Level 1" ||
        this._selectedRow.mrsl2Level == "Level 2" ||
        this._selectedRow.mrsl2Level == "Level 3"
      ) {
        mrslVersion = "ZDHC MRSL v2.0";
        mrslLevel = this._selectedRow.mrsl2Level;
      }
      if (this._selectedRow.mrsl2Level == "Expired") {
        mrslVersion = "ZDHC MRSL v2.0";
        mrslLevel = this._selectedRow.mrsl2Level;
      }
      if (this._selectedRow.mrsl2Level == "Registered") {
        mrslVersion = "ZDHC MRSL v2.0";
        mrslLevel = this._selectedRow.mrsl2Level;
      }

      if (
        this._selectedRow.mrsl3Level == "Level 1" ||
        this._selectedRow.mrsl3Level == "Level 2" ||
        this._selectedRow.mrsl3Level == "Level 3"
      ) {
        mrslVersion = "ZDHC MRSL v3.1";
        mrslLevel = this._selectedRow.mrsl3Level;
      }
      if (this._selectedRow.mrsl3Level == "Expired") {
        if (
          this._selectedRow.mrsl2Level == "Level 1" ||
          this._selectedRow.mrsl2Level == "Level 2" ||
          this._selectedRow.mrsl2Level == "Level 3"
        ) {
          mrslVersion = "ZDHC MRSL v2.0";
          mrslLevel = this._selectedRow.mrsl2Level;
        } else {
          mrslVersion = "ZDHC MRSL v3.1";
          mrslLevel = this._selectedRow.mrsl3Level;
        }
      }
      if (this._selectedRow.mrsl3Level == "Registered") {
        if (
          this._selectedRow.mrsl2Level == "Level 1" ||
          this._selectedRow.mrsl2Level == "Level 2" ||
          this._selectedRow.mrsl2Level == "Level 3"
        ) {
          mrslVersion = "ZDHC MRSL v2.0";
          mrslLevel = this._selectedRow.mrsl2Level;
        } else {
          mrslVersion = "ZDHC MRSL v3.1";
          mrslLevel = this._selectedRow.mrsl3Level;
        }
      }

      if (
        this._selectedRow.mrsl3Level == null &&
        this._selectedRow.mrsl2Level == null
      ) {
        mrslVersion = "-";
        mrslLevel = "-";
      }

      const fields = {
        Chemical_Product_Name__c: this._selectedRow.zdhcProductData.productName,
        Product_Trade_Name_Other_Name__c:
          this._selectedRow.zdhcProductData.OtherName,
        ZDHC_Product_GUID__c: this._selectedRow.zdhcProductData.productGUID,
        ZDHC_Product_Code__c: this._selectedRow.zdhcProductData.productCode,
        ZDHC_PID__c: this._selectedRow.zdhcProductData.zdhcPID,
        Registered__c: this._selectedRow.zdhcProductData.registered,
        ZDHC_Product_Id__c: this._selectedRow.zdhcProductData.ProductID,
        Last_Verified_Date__c: new Date().toISOString(),
        ZDHC_Certification_JSON__c: JSON.stringify(
          this._selectedRow.zdhcProductData.ProductCertifications
        ),
        Other_Certifications__c: this._selectedRow.otherCertifications
          ? this._selectedRow.otherCertifications
          : null,

        ZDHC_MRSL_v2_0__c: mrslLevel,
        ZDHC_MRSL_Version__c: mrslVersion,
        ZDHC_Status__c: "Success",
        Product_Status__c: "Active",
        Origin__c: this._productOrigin,
        ZDHC_Formulator_GUID__c:
          this._selectedRow.zdhcProductData.formulatorGUID,
        Formulator__c: formulatorId.data
      };
      const recordInput = {
        apiName: "Chemical_Product__c",
        fields
      };
      const chemicalProduct = await createRecord(recordInput);
      this._createInventoryLineItem(chemicalProduct.id);
    } catch (error) {
      console.error(error);
      this._showToastNotification(
        this.labels.ERROR,
        this.labels.TC_ADD_PRODUCT_TO_INVENTORY_ERROR,
        "error"
      );
      const resultsCmp = this.template.querySelector(
        "c-tc-add-products-search-results"
      );
      resultsCmp.showLoader = false;
    }
  }

  /**
   * updates the Chemical_Product__c sObject if the user has selected a row with an existing record
   */
  async _updateChemicalProduct(productRecordId) {
    try {
      const formulatorId = await getFormulatorId({
        userAccessKey: this._userAccessKey?.data,
        formulatorGUID: this._selectedRow.zdhcProductData.formulatorGUID
      });

      let mrslLevel;
      let mrslVersion;

      if (
        this._selectedRow.mrsl2Level == "Level 1" ||
        this._selectedRow.mrsl2Level == "Level 2" ||
        this._selectedRow.mrsl2Level == "Level 3"
      ) {
        mrslVersion = "ZDHC MRSL v2.0";
        mrslLevel = this._selectedRow.mrsl2Level;
      }
      if (this._selectedRow.mrsl2Level == "Expired") {
        mrslVersion = "ZDHC MRSL v2.0";
        mrslLevel = this._selectedRow.mrsl2Level;
      }
      if (this._selectedRow.mrsl2Level == "Registered") {
        mrslVersion = "ZDHC MRSL v2.0";
        mrslLevel = this._selectedRow.mrsl2Level;
      }

      if (
        this._selectedRow.mrsl3Level == "Level 1" ||
        this._selectedRow.mrsl3Level == "Level 2" ||
        this._selectedRow.mrsl3Level == "Level 3"
      ) {
        mrslVersion = "ZDHC MRSL v3.1";
        mrslLevel = this._selectedRow.mrsl3Level;
      }
      if (this._selectedRow.mrsl3Level == "Expired") {
        if (
          this._selectedRow.mrsl2Level == "Level 1" ||
          this._selectedRow.mrsl2Level == "Level 2" ||
          this._selectedRow.mrsl2Level == "Level 3"
        ) {
          mrslVersion = "ZDHC MRSL v2.0";
          mrslLevel = this._selectedRow.mrsl2Level;
        } else {
          mrslVersion = "ZDHC MRSL v3.1";
          mrslLevel = this._selectedRow.mrsl3Level;
        }
      }
      if (this._selectedRow.mrsl3Level == "Registered") {
        if (
          this._selectedRow.mrsl2Level == "Level 1" ||
          this._selectedRow.mrsl2Level == "Level 2" ||
          this._selectedRow.mrsl2Level == "Level 3"
        ) {
          mrslVersion = "ZDHC MRSL v2.0";
          mrslLevel = this._selectedRow.mrsl2Level;
        } else {
          mrslVersion = "ZDHC MRSL v3.1";
          mrslLevel = this._selectedRow.mrsl3Level;
        }
      }

      if (
        this._selectedRow.mrsl3Level == null &&
        this._selectedRow.mrsl2Level == null
      ) {
        mrslVersion = "-";
        mrslLevel = "-";
      }

      const chemFields = {
        Id: productRecordId,
        Chemical_Product_Name__c: this._selectedRow.zdhcProductData.productName,
        Product_Trade_Name_Other_Name__c:
          this._selectedRow.zdhcProductData.OtherName,
        ZDHC_Product_GUID__c: this._selectedRow.zdhcProductData.productGUID,
        ZDHC_Product_Code__c: this._selectedRow.zdhcProductData.productCode,
        ZDHC_PID__c: this._selectedRow.zdhcProductData.zdhcPID,
        Registered__c: this._selectedRow.zdhcProductData.registered,
        ZDHC_Product_Id__c: this._selectedRow.zdhcProductData.ProductID,
        Last_Verified_Date__c: new Date().toISOString(),
        Origin__c: this._selectedRow.salesforceProduct
          ? this._selectedRow.salesforceProduct.Origin__c
          : this._productOrigin,
        ZDHC_Certification_JSON__c: JSON.stringify(
          this._selectedRow.zdhcProductData.ProductCertifications
        ),
        Other_Certifications__c: this._selectedRow.otherCertifications
          ? this._selectedRow.otherCertifications
          : null,
        ZDHC_MRSL_v2_0__c: mrslLevel,
        ZDHC_MRSL_Version__c: mrslVersion,
        ZDHC_Status__c: "Success",
        ZDHC_Formulator_GUID__c:
          this._selectedRow.zdhcProductData.formulatorGUID,
        Formulator__c: formulatorId.data
      };
      const chemRecordInput = {
        fields: chemFields
      };
      await updateRecord(chemRecordInput);
      this._createInventoryLineItem(productRecordId);
    } catch (error) {
      console.error(error);
      this._showToastNotification(
        label.ERROR,
        label.TC_ADD_PRODUCT_TO_INVENTORY_ERROR,
        "error"
      );
      const resultsCmp = this.template.querySelector(
        "c-tc-add-products-search-results"
      );
      resultsCmp.showLoader = false;
    }
  }

  /**
   * creates the Inventory_Line_Item__c sObject for the Inventory
   * @param {string} productRecordId - the record Id of the Chemical_Product__c being added to the inventory
   */
  async _createInventoryLineItem(productRecordId) {
    try {
      // First check if Line Item for this productId already exists.
      let lineItem = await getLineItemForProduct({
        inventoryId: this.inventoryId,
        productId: productRecordId
      });

      if (lineItem.length !== 0) {
        // Still tidy up. This product already exists in the inventory.
        this._tidyResultsTable();
        // A harmless error.
        this._showToastNotification(
          label.ERROR,
          label.TC_PRODUCT_ALREADY_IN_THE_INVENTORY,
          "info"
        );
        return;
      }

      let mrslLevel;
      let mrslVersion;

      if (
        this._selectedRow.mrsl2Level == "Level 1" ||
        this._selectedRow.mrsl2Level == "Level 2" ||
        this._selectedRow.mrsl2Level == "Level 3"
      ) {
        mrslVersion = "ZDHC MRSL v2.0";
        mrslLevel = this._selectedRow.mrsl2Level;
      }
      if (this._selectedRow.mrsl2Level == "Expired") {
        mrslVersion = "ZDHC MRSL v2.0";
        mrslLevel = this._selectedRow.mrsl2Level;
      }
      if (this._selectedRow.mrsl2Level == "Registered") {
        mrslVersion = "ZDHC MRSL v2.0";
        mrslLevel = this._selectedRow.mrsl2Level;
      }

      if (
        this._selectedRow.mrsl3Level == "Level 1" ||
        this._selectedRow.mrsl3Level == "Level 2" ||
        this._selectedRow.mrsl3Level == "Level 3"
      ) {
        mrslVersion = "ZDHC MRSL v3.1";
        mrslLevel = this._selectedRow.mrsl3Level;
      }
      if (this._selectedRow.mrsl3Level == "Expired") {
        if (
          this._selectedRow.mrsl2Level == "Level 1" ||
          this._selectedRow.mrsl2Level == "Level 2" ||
          this._selectedRow.mrsl2Level == "Level 3"
        ) {
          mrslVersion = "ZDHC MRSL v2.0";
          mrslLevel = this._selectedRow.mrsl2Level;
        } else {
          mrslVersion = "ZDHC MRSL v3.1";
          mrslLevel = this._selectedRow.mrsl3Level;
        }
      }
      if (this._selectedRow.mrsl3Level == "Registered") {
        if (
          this._selectedRow.mrsl2Level == "Level 1" ||
          this._selectedRow.mrsl2Level == "Level 2" ||
          this._selectedRow.mrsl2Level == "Level 3"
        ) {
          mrslVersion = "ZDHC MRSL v2.0";
          mrslLevel = this._selectedRow.mrsl2Level;
        } else {
          mrslVersion = "ZDHC MRSL v3.1";
          mrslLevel = this._selectedRow.mrsl3Level;
        }
      }

      if (
        this._selectedRow.mrsl3Level == null &&
        this._selectedRow.mrsl2Level == null
      ) {
        mrslVersion = "-";
        mrslLevel = "-";
      }

      const fields = {
        Inventory__c: this.inventoryId,
        Chemical_Product__c: productRecordId,
        Other_Certifications__c: this._selectedRow.otherCertifications
          ? this._selectedRow.otherCertifications
          : null,
        ZDHC_MRSL_v2_0__c: mrslLevel,
        ZDHC_MRSL_Version__c: mrslVersion,
        ZDHC_Certification_JSON__c: JSON.stringify(
          this._selectedRow.zdhcProductData.ProductCertifications
        ),
        ZDHC_Product_Id__c: this._selectedRow.zdhcProductData.ProductID,
        ZDHC_Product_GUID__c: this._selectedRow.zdhcProductData.productGUID,
        Origin__c: this._selectedRow.salesforceProduct
          ? this._selectedRow.salesforceProduct.Origin__c
          : this._productOrigin,
        Commodity_Chemical_Standard_Name__c: this._selectedRow.salesforceProduct
          ? this._selectedRow.salesforceProduct
              .Commodity_Chemical_Standard_Name__c
            ? this._selectedRow.salesforceProduct
                .Commodity_Chemical_Standard_Name__c
            : null
          : null,
        Inditex_Classification_for_Babies__c: this._selectedRow
          .salesforceProduct
          ? this._selectedRow.salesforceProduct
              .Inditex_Classification_for_Babies__c
          : null,
        Inditex_Classification_for_Child_Adult__c: this._selectedRow
          .salesforceProduct
          ? this._selectedRow.salesforceProduct
              .Inditex_Classification_for_Child_Adult__c
          : null
      };
      const recordInput = {
        apiName: "Inventory_Line_Item__c",
        fields
      };
      lineItem = await createRecord(recordInput);

      this._tidyResultsTable();
      this._showToastNotification(
        this.labels.SUCCESS,
        this.labels.TC_ADD_PRODUCT_TO_INVENTORY_SUCCESS,
        "success"
      );
    } catch (error) {
      console.error(error);
      this._showToastNotification(
        label.ERROR,
        label.TC_ADD_PRODUCT_TO_INVENTORY_ERROR,
        "error"
      );
      const resultsCmp = this.template.querySelector(
        "c-tc-add-products-search-results"
      );
      resultsCmp.showLoader = false;
    }
  }

  /**
   * removes the row that has been added to the inventory and stops the loader
   */
  _tidyResultsTable() {
    const resultsCmp = this.template.querySelector(
      "c-tc-add-products-search-results"
    );
    resultsCmp.showLoader = false;
    resultsCmp.removeLinkedProduct(
      this._selectedRow.zdhcProductData.productGUID
    );
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
}