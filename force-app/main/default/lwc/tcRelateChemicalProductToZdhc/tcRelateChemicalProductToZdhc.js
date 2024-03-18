import { LightningElement, api, wire, track } from "lwc";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import toxLogo from "@salesforce/resourceUrl/toxLogo";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getUserAccessKey from "@salesforce/apex/ZDHCGatewayService.getUserAccessKey";
import getFormulatorId from "@salesforce/apex/TC_SearchFormulatorsController.getFormulatorId";
import makeCallout from "@salesforce/apex/ZDHCGatewayService.makeCallout";
import Id from "@salesforce/user/Id";
import { label } from "c/labelService";

import FontNeoSansW05 from "@salesforce/resourceUrl/FontNeoSansW05";
import { loadStyle } from "lightning/platformResourceLoader";

import oegenResources from "@salesforce/resourceUrl/oegenResources";

export default class TcRelateChemicalProductToZdhc extends LightningElement {
  //PUBLIC PROPERTIES
  @api recordId;

  //TEMPLATE PROPERTIES
  labels = label;
  toxLogo = toxLogo;
  noUserAccessKeyFound;
  linkedToZdhc;
  showModal;
  showConfirmModal = false;
  @track searchParams;

  //INTERNAL PROPERTIES
  _userId = Id;
  _chemicalProduct;
  _userAccessKey;
  _selectedRow;

  /**
   * @returns true if their is a userAccessKey and the product is not currently linked to ZDHC
   */
  get linkToZdhc() {
    return this._userAccessKey && !this.linkedToZdhc;
  }

  loadStyles() {
    /*  Import font */
    loadStyle(this, FontNeoSansW05 + "/FontNeoSansW05Import.css");

    /* Import css file because Brand.css not accessible in CRM view. */
    loadStyle(
      this,
      oegenResources + "/css/other/tcRelateChemicalProductToZdhc.css"
    );
  }

  //LIGHTNING DATA SERVICE
  @wire(getUserAccessKey, {
    recordId: "$_userId"
  })
  wiredUserAccessKey({ error, data }) {
    if (error) {
      console.error(error);
    } else if (data) {
      this._userAccessKey = data;
      this.noUserAccessKeyFound = false;
    } else {
      this.noUserAccessKeyFound = true;
    }
  }
  /**
   * get Chemical_Product__c data for the current record
   */
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "Chemical_Product__c.ZDHC_Product_GUID__c",
      "Chemical_Product__c.Formulator__c",
      "Chemical_Product__c.ZDHC_Formulator_GUID__c",
      "Chemical_Product__c.Chemical_Product_Name__c",
      "Chemical_Product__c.ZDHC_Description__c",
      "Chemical_Product__c.Substrate__c",
      "Chemical_Product__c.Category__c",
      "Chemical_Product__c.Type__c",
      "Chemical_Product__c.Product_Trade_Name_Other_Name__c",
      "Chemical_Product__c.ZDHC_Product_Code__c"
    ]
  })
  wiredRecord({ error, data }) {
    if (data) {
      this._chemicalProduct = data.fields;
      this.linkedToZdhc = data.fields.ZDHC_Product_GUID__c.value != null;
    } else if (error) {
      console.error(error);
    }
  }

  //EVENT HANDLERS
  /**
   * handles the user's request to relate the product to ZDHC
   */
  handleRelateProduct() {
    this.showModal = true;
  }

  /**
   * handles the User requesting to unrelate the product from ZDHC
   */
  handleUnrelateProduct() {
    this._processUnrelateProduct();
  }

  /**
   * handles the user requesting a search of ZDHC product data
   * @param {object} event - search custom event
   */
  handleSearch(event) {
    this.searchParams = event.detail;
  }

  /**
   * handles the user's request to reset the search views
   */
  handleReset() {
    this.template.querySelector("c-tc-add-products-search").reset();
  }

  /**
   * handles the search component firing a search error event
   */
  handleSearchError() {
    this._showToastNotification(
      this.labels.ERROR,
      this.labels.TC_SEARCHING_PRODUCTS_ERROR,
      "error"
    );
  }

  /**
   * handles the user cancelling the action - closes the action modal
   */
  handleCancel() {
    this.showModal = false;
  }

  /**
   * handles the user selecting a product to link to the Salesforce record
   * @param {object} event - addinventoryline custom event
   */
  handleLinkProduct(event) {
    event.stopPropagation();
    this._selectedRow = event.detail.row;
    this._processLinkProduct();
  }

  //INTERNAL FUNCTIONS
  /**
   * links the Chemical_Product__c sObject to the ZDHC product data
   */
  async _processLinkProduct() {
    const formulatorId = await getFormulatorId({
      userAccessKey: this._userAccessKey,
      formulatorGUID: this._selectedRow.zdhcProductData.formulatorGUID
    });

    const recordInput = {
      fields: {
        Id: this.recordId,
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
        Other_Certifications__c: this._selectedRow.otherCertifications,
        ZDHC_MRSL_v2_0__c: this._selectedRow.mrsl2Level,
        ZDHC_Status__c: "Success",
        Product_Status__c: "Active",
        Formulator__c: formulatorId,
        ZDHC_Formulator_GUID__c:
          this._selectedRow.zdhcProductData.formulatorGUID
      }
    };
    updateRecord(recordInput)
      .then(() => {
        this.showModal = false;
        this._showToastNotification(
          this.labels.SUCCESS,
          this.labels.TC_RELATE_PRODUCT_ZDHC_SUCCESS,
          "success"
        );
      })
      .catch((error) => {
        console.error(error);
        this._showToastNotification(
          this.labels.ERROR,
          this.labels.TC_RELATE_PRODUCT_ZDHC_ERROR,
          "error"
        );
      });
  }
  /**
   * processes the user's request to unrelated to ZDHC by clearing relevant fields
   */
  _processUnrelateProduct() {
    const recordInput = {
      fields: {
        Id: this.recordId,
        Product_Trade_Name_Other_Name__c: null,
        ZDHC_Product_GUID__c: null,
        ZDHC_Product_Code__c: null,
        ZDHC_PID__c: null,
        Registered__c: null,
        ZDHC_Product_Id__c: null,
        Last_Verified_Date__c: null,
        ZDHC_Certification_JSON__c: null,
        ZDHC_MRSL_v2_0__c: null,
        ZDHC_Formulator_GUID__c: null,
        ZDHC_Status__c: null,
        Other_Certifications__c: null,
        Product_Status__c: "Pending"
      }
    };
    updateRecord(recordInput)
      .then(() => {
        this._showToastNotification(
          this.labels.SUCCESS,
          this.labels.TC_UNRELATE_PRODUCT_ZDHC_SUCCESS,
          "success"
        );
      })
      .catch((error) => {
        console.error(error);
        this._showToastNotification(
          this.labels.ERROR,
          this.labels.TC_UNRELATE_PRODUCT_ZDHC_ERROR,
          "error"
        );
      });
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

  connectedCallback() {
    this.loadStyles();
  }

  handleCreateProduct() {
    this.showModal = false;
    this.showConfirmModal = true;
  }

  handleConfirmCancel() {
    this.showConfirmModal = false;
    this.showModal = true;
  }

  handleConfirmCreateProduct() {
    const zdhcRequest = {
      apiName: "products",
      method: "POST",
      userAccessKey: this._userAccessKey,
      requestBody: {
        name: this._chemicalProduct.Chemical_Product_Name__c.value,
        formulatorGUID: this._chemicalProduct.ZDHC_Formulator_GUID__c.value,
        description: this._chemicalProduct.ZDHC_Description__c.value,
        substrate: this._chemicalProduct.Substrate__c.value,
        category: this._chemicalProduct.Category__c.value,
        type: this._chemicalProduct.Type__c.value,
        otherName: this._chemicalProduct.Product_Trade_Name_Other_Name__c.value,
        productCode: this._chemicalProduct.ZDHC_Product_Code__c.value
      }
    };
    if (this._chemicalProduct.ZDHC_Formulator_GUID__c.value) {
      makeCallout({
        zdhcRequest: zdhcRequest
      })
        .then((zdhcResponse) => {
          if (
            zdhcResponse?.isSuccess &&
            zdhcResponse?.response?.result?.success
          ) {
            this.updateRecordAfterCreate(zdhcResponse.response.productGUID);
          } else {
            this._showToastNotification(
              this.labels.ERROR,
              zdhcResponse.errors[0],
              "error"
            );
          }
        })
        .catch((error) => {
          console.error(error);
          this._showToastNotification(
            this.labels.ERROR,
            this.labels.TC_ZDHC_CALLOUT_ERROR,
            "error"
          );
        });
    } else {
      this._showToastNotification(
        this.labels.ERROR,
        label.TC_ZDHC_ADD_PRODUCT_NO_FORMULATOR,
        "error"
      );
    }
  }

  updateRecordAfterCreate(productGUID) {
    const recordInput = {
      fields: {
        Id: this.recordId,
        ZDHC_Product_GUID__c: productGUID
      }
    };
    updateRecord(recordInput)
      .then(() => {
        this._showToastNotification(
          this.labels.SUCCESS,
          this.labels.TC_ZDHC_ADD_PRODUCT_INTERNAL_SUCCESS,
          "success"
        );
        this.showConfirmModal = false;
      })
      .catch((error) => {
        console.error(error);
        this._showToastNotification(
          this.labels.ERROR,
          this.labels.TC_RELATE_PRODUCT_ZDHC_ERROR,
          "error"
        );
      });
  }
}