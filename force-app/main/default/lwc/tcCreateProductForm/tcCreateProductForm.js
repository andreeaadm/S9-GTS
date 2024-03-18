import { LightningElement, wire } from "lwc";
import { getRecord, createRecord, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import Id from "@salesforce/user/Id";
import CHEMICAL_PRODUCT_OBJECT from "@salesforce/schema/Chemical_Product__c";
import CHEMICAL_PRODUCT_NAME_FIELD from "@salesforce/schema/Chemical_Product__c.Chemical_Product_Name__c";
import TRADE_NAME_OTHER_NAME_FIELD from "@salesforce/schema/Chemical_Product__c.Product_Trade_Name_Other_Name__c";
import PRODUCT_CODE_FIELD from "@salesforce/schema/Chemical_Product__c.ZDHC_Product_Code__c";
import DESCRIPTION_FIELD from "@salesforce/schema/Chemical_Product__c.ZDHC_Description__c";
import SUBSTRATE_FIELD from "@salesforce/schema/Chemical_Product__c.Substrate__c";
import CATEGORY_FIELD from "@salesforce/schema/Chemical_Product__c.Category__c";
import TYPE_FIELD from "@salesforce/schema/Chemical_Product__c.Type__c";
import FORMULATOR_GUID_FIELD from "@salesforce/schema/Chemical_Product__c.ZDHC_Formulator_GUID__c";
import PRODUCT_GUID_FIELD from "@salesforce/schema/Chemical_Product__c.ZDHC_Product_GUID__c";
import PRODUCT_STATUS_FIELD from "@salesforce/schema/Chemical_Product__c.Product_Status__c";
import SUPPLIER_REFERENCE_NAME from "@salesforce/schema/Chemical_Product__c.Supplier_Reference_Name__c";
import SUPPLIER_REFERENCE_NUMBER from "@salesforce/schema/Chemical_Product__c.Supplier_Reference_Number__c";
import PRODUCT_NAME_LOCAL_LANGUAGE from "@salesforce/schema/Chemical_Product__c.Product_Name_Local_Language__c";
import FORMULATOR_NAME_LOCAL_LANGUAGE from "@salesforce/schema/Chemical_Product__c.Formulator_Name_Local_Language__c";
import LAST_VERIFIED_DATE_FIELD from "@salesforce/schema/Chemical_Product__c.Last_Verified_Date__c";
import INVENTORY_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Inventory__c";
import CHEMICAL_PRODUCT_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Chemical_Product__c";
import LINE_ITEM_PRODUCT_GUID_FIELD from "@salesforce/schema/Inventory_Line_Item__c.ZDHC_Product_GUID__c";
import ORIGIN_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Origin__c";
import getUserAccessKey from "@salesforce/apex/ZDHCGatewayService.getUserAccessKey";
import makeCallout from "@salesforce/apex/ZDHCGatewayService.makeCallout";
import { label } from "c/labelService";

export default class TcCreateProductForm extends NavigationMixin(
  LightningElement
) {
  //TEMPLATE PROPERTIES
  showLoader;
  labels = label;

  //INTERNAL PROPERTIES
  _userId = Id;
  _productId;
  _chemicalProduct;
  _formulatorGUID;
  _submittedToZdhc;
  _inventoryRecordId;

  //LIGHTNING DATA SERVICE
  /**
   * retrieve the UserAccessKey for the current user
   */
  @wire(getUserAccessKey, {
    recordId: "$_userId"
  })
  _userAccessKey;

  /**
   * retrieves the Chemical_Product__c record for sending to ZDHC
   */
  @wire(getRecord, {
    recordId: "$_productId",
    fields: [
      CHEMICAL_PRODUCT_NAME_FIELD,
      TRADE_NAME_OTHER_NAME_FIELD,
      PRODUCT_CODE_FIELD,
      PRODUCT_GUID_FIELD,
      DESCRIPTION_FIELD,
      SUBSTRATE_FIELD,
      CATEGORY_FIELD,
      TYPE_FIELD,
      FORMULATOR_GUID_FIELD,
      FORMULATOR_NAME_LOCAL_LANGUAGE,
      PRODUCT_NAME_LOCAL_LANGUAGE,
      SUPPLIER_REFERENCE_NAME,
      SUPPLIER_REFERENCE_NUMBER
    ]
  })
  wiredProduct({ error, data }) {
    if (data) {
      this._chemicalProduct = data;
      if (!this._submittedToZdhc) {
        this._submitProductToZdhc();
      } else {
        this._createInventoryLineItem();
      }
    } else if (error) {
      console.error(error);
      this._handleError(error);
    }
  }

  //GETTERS & SETTERS
  /**
   * @returns the object api name for the c-form cmp
   */
  get objectApiName() {
    return CHEMICAL_PRODUCT_OBJECT.objectApiName;
  }

  /**
   * @returns an array of field api names for fhe c-form cmp
   */
  get fieldApiNames() {
    return [
      CHEMICAL_PRODUCT_NAME_FIELD.fieldApiName,
      TRADE_NAME_OTHER_NAME_FIELD.fieldApiName,
      PRODUCT_CODE_FIELD.fieldApiName,
      DESCRIPTION_FIELD.fieldApiName,
      SUBSTRATE_FIELD.fieldApiName,
      CATEGORY_FIELD.fieldApiName,
      TYPE_FIELD.fieldApiName,
      SUPPLIER_REFERENCE_NUMBER.fieldApiName,
      SUPPLIER_REFERENCE_NAME.fieldApiName,
      FORMULATOR_NAME_LOCAL_LANGUAGE.fieldApiName,
      PRODUCT_NAME_LOCAL_LANGUAGE.fieldApiName
    ];
  }

  /**
   * @returns an array of labels for the c-form cmp inputs
   */
  get fieldLabels() {
    return [
      this.labels.TC_PRODUCT_NAME,
      this.labels.TC_TRADE_NAME_OTHER_NAME,
      this.labels.TC_PRODUCT_CODE,
      this.labels.DESCRIPTION,
      this.labels.TC_SUBSTRATE,
      this.labels.TC_CATEGORY,
      this.labels.TC_TYPE,
      this.labels.TC_SUPPLIER_REFERENCE_NUMBER,
      this.labels.TC_SUPPLIER_REFERENCE_NAME,
      this.labels.TC_FORMULATOR_NAME_LOCAL_LANGAUGE,
      this.labels.TC_PRODUCT_NAME_LOCAL_LANGUAGE
    ];
  }

  /**
   * @returns array of required field api names for the c-form cmp
   */
  get requiredFieldApiNames() {
    return [CHEMICAL_PRODUCT_NAME_FIELD.fieldApiName];
  }

  //EVENT HANDLERS
  /**
   * handles the page url params being parsed from the page reference data cmp
   * @param {object} event retrievedstate custom event
   */
  handleRetrievedState(event) {
    this._inventoryRecordId = event.detail.inventoryId;
  }

  /**
   * handles the user selecting a formulator record
   * @param {object} event - selectformulator custom event
   */
  handleSelectFormulator(event) {
    event.stopPropagation();
    this._formulatorGUID = event.detail.row.formulatorGUID;
  }

  /**
   * handles the user successfully creating a formulator
   * @param {object} event - createdformulator custom event
   */
  handleCreatedFormulator(event) {
    event.stopPropagation();
    this._formulatorGUID = event.detail.ZDHC_Formulator_GUID__c;
  }

  /**
   * handles the user choosing to remove a selected formulator
   */
  handleRemoveFormulator() {
    this._formulatorGUID = null;
  }

  /**
   * handles the user requesting to create the product from thge form details
   */
  handleCreateProduct() {
    this._validateFormulator();
  }
  /**
   * handles the c-form cmp successfully inserting the Chemical_Product__c record
   * @param {object} event - success custom event
   */
  handleSuccess(event) {
    this.showLoader = true;
    this._productId = event.detail.recordId;
  }

  /**
   * handles the c-form cmp catching an error when inserting the Chemical_Product__c record
   * @param {object} event - error custom event
   */
  handleError(event) {
    this._showToastNotification(
      this.labels.ERROR,
      this.labels.TC_OBJECT_NAMED_UPDATE_ERROR_WITH_MESSAGE.replace(
        "{0} {1}",
        "The Product"
      ).replace("{2}", event.detail.message),
      "error"
    );
  }

  //INTERNAL FUNCTIONS
  /**
   * validates we have a formulator before attempting to save the form
   */
  _validateFormulator() {
    if (this._formulatorGUID) {
      this.template.querySelector("c-form").save();
    } else {
      this._showToastNotification(
        this.labels.ERROR,
        this.labels.TC_FORMULATOR_NOT_SELECTED_ERROR,
        "error"
      );
    }
  }

  /**
   * submits the newly created product data to ZDHC
   */
  _submitProductToZdhc() {
    if (this._userAccessKey?.data && this._chemicalProduct) {
      const zdhcRequest = {
        apiName: "products",
        method: "POST",
        userAccessKey: this._userAccessKey.data,
        requestBody: {
          name: this._chemicalProduct.fields[
            CHEMICAL_PRODUCT_NAME_FIELD.fieldApiName
          ]?.value,
          formulatorGUID: this._formulatorGUID,
          description:
            this._chemicalProduct.fields[DESCRIPTION_FIELD.fieldApiName]?.value,
          substrate:
            this._chemicalProduct.fields[SUBSTRATE_FIELD.fieldApiName]
              ?.displayValue,
          category:
            this._chemicalProduct.fields[CATEGORY_FIELD.fieldApiName]
              ?.displayValue,
          type: this._chemicalProduct.fields[TYPE_FIELD.fieldApiName]
            ?.displayValue,
          otherName:
            this._chemicalProduct.fields[
              TRADE_NAME_OTHER_NAME_FIELD.fieldApiName
            ]?.value,
          productCode:
            this._chemicalProduct.fields[PRODUCT_CODE_FIELD.fieldApiName]?.value
        }
      };
      makeCallout({
        zdhcRequest: zdhcRequest
      })
        .then((zdhcResponse) => {
          if (
            zdhcResponse?.isSuccess &&
            zdhcResponse?.response?.result?.success
          ) {
            this._submittedToZdhc = true;
            this._updateProductWithZdhcResponse(zdhcResponse);
          } else {
            console.error(zdhcResponse);
            this.showLoader = false;
            this._showToastNotification(
              this.labels.ERROR,
              this.labels.TC_SUBMITTING_PRODUCT_TO_ZDHC_ERROR,
              "error"
            );
          }
        })
        .catch((error) => {
          console.error(error);
          this._handleError(error);
        });
    }
  }

  /**
   * updates the Chemical_Product__c record with the product GUID from ZDHC
   * @param {object} zdhcResponse - object containing a response from the post/products ZDHC api
   */
  _updateProductWithZdhcResponse(zdhcResponse) {
    const recordInput = {
      fields: {
        Id: this._productId,
        [PRODUCT_GUID_FIELD.fieldApiName]: zdhcResponse.response.productGUID,
        [FORMULATOR_GUID_FIELD.fieldApiName]: this._formulatorGUID,
        [PRODUCT_STATUS_FIELD.fieldApiName]: "Active",
        [LAST_VERIFIED_DATE_FIELD.fieldApiName]: new Date().toISOString()
      }
    };
    updateRecord(recordInput)
      .then((result) => {
        this.showLoader = false;
        this._showToastNotification(
          this.labels.SUCCESS,
          this.labels.OBJECT_NAMED_UPDATE_SUCCESS.replace(
            "{0} {1}",
            "The Product"
          ),
          "success"
        );
      })
      .catch((error) => {
        console.error(error);
        this._handleError(error);
      });
  }

  /**
   * creates the Inventory_Line_Item__c sObject for the Inventory
   */
  _createInventoryLineItem() {
    const recordInput = {
      apiName: "Inventory_Line_Item__c",
      fields: {
        [INVENTORY_FIELD.fieldApiName]: this._inventoryRecordId,
        [CHEMICAL_PRODUCT_FIELD.fieldApiName]: this._productId,
        [LINE_ITEM_PRODUCT_GUID_FIELD.fieldApiName]:
          this._chemicalProduct.fields[PRODUCT_GUID_FIELD.fieldApiName]?.value,
        [ORIGIN_FIELD.fieldApiName]: "Supplier"
      }
    };
    createRecord(recordInput)
      .then((result) => {
        this._showToastNotification(
          this.labels.SUCCESS,
          this.labels.TC_ADD_PRODUCT_TO_INVENTORY_SUCCESS,
          "success"
        );
        this._navigateToViewInventory();
      })
      .catch((error) => {
        console.error(error);
        this._showToastNotification(
          this.labels.ERROR,
          this.labels.TC_ADD_PRODUCT_TO_INVENTORY_ERROR,
          "error"
        );
      });
  }

  /**
   * navigates the user to the view inventory page for the inventory that started the process
   */
  _navigateToViewInventory() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this._inventoryRecordId,
        actionName: "view"
      }
    });
  }

  /**
   * handles a caught exception and notifies the user
   * @param {object} error - exception caught when communicating with the server
   */
  _handleError(error) {
    let errorMessage;
    if (Array.isArray(error.body)) {
      errorMessage = error.body.map((e) => e.message).join(", ");
    } else if (typeof error.body.message === "string") {
      errorMessage = error.body.message;
    }
    this._showToastNotification(
      this.labels.ERROR,
      this.labels.TC_OBJECT_NAMED_UPDATE_ERROR_WITH_MESSAGE.replace(
        "{0} {1}",
        "The Product"
      ).replace("{2}", errorMessage),
      "error"
    );
    this.showLoader = false;
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