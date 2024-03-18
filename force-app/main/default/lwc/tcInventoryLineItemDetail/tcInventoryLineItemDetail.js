import { LightningElement, api, track, wire } from "lwc";
import {
  getRecord,
  getFieldValue,
  updateRecord,
  deleteRecord
} from "lightning/uiRecordApi";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import userId from "@salesforce/user/Id";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label } from "c/labelService";
import COMMODITY_CHEMICAL_STANDARD_NAME_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Commodity_Chemical_Standard_Name__c";
import TYPE_OF_CHEMICALS_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Type_of_Chemicals__c";
import INVENTORY_LINE_ITEM_OBJECT from "@salesforce/schema/Inventory_Line_Item__c";
import ID_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Id";
import INVENTORY_ID_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Inventory__c";
import RECORD_TYPE_DEVNAME_FIELD from "@salesforce/schema/Inventory_Line_Item__c.RecordType.DeveloperName";
import RECORD_TYPE_ID_FIELD from "@salesforce/schema/Inventory_Line_Item__c.RecordTypeId";
import FORMULATOR_NAME_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Formulator_Name__c";
import CHEMICAL_PRODUCT_NAME_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Chemical_Product_Name__c";
import UNIT_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Unit__c";
import DELIVERED_STOCK_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Delivered_Stock_This_Month__c";
import STOCK_TAKE_BEGIN from "@salesforce/schema/Inventory_Line_Item__c.Stock_Take_Month_Begin__c";
import STOCK_TAKE_END from "@salesforce/schema/Inventory_Line_Item__c.Stock_Take_Month_End__c";
import CALCULATED_USAGE from "@salesforce/schema/Inventory_Line_Item__c.Calculated_Usage__c";
import CALCULATED_WEIGHT from "@salesforce/schema/Inventory_Line_Item__c.Calculated_Weight_kg__c";
import DELIVERED_STOCK_HISTORY_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Delivered_Stock_History__c";
import STORAGE_LOCATION_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Storage_Location__c";
import LOT_NUMBER_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Lot_Number__c";
import EXPIRY_DATE_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Expiry_Date__c";
import OTHER_NAME_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Product_Trade_Name_Other_Name__c";
import ZDHC_V2_FIELD from "@salesforce/schema/Inventory_Line_Item__c.ZDHC_MRSL_v2_0__c";
import ZDHC_Version_FIELD from "@salesforce/schema/Inventory_Line_Item__c.ZDHC_MRSL_Version__c";
import ZDHC_ID_FIELD from "@salesforce/schema/Inventory_Line_Item__c.ZDHC_Product_Id__c";
import ZDHC_GUID_FIELD from "@salesforce/schema/Inventory_Line_Item__c.ZDHC_Product_GUID__c";
import STATUS_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Inventory__r.Status__c";
import Supplier_Reference_Number from "@salesforce/schema/Inventory_Line_Item__c.Supplier_Reference_Number__c";
import Supplier_Reference_Name from "@salesforce/schema/Inventory_Line_Item__c.Supplier_Reference_Name__c";
import Product_Name_Local_Language from "@salesforce/schema/Inventory_Line_Item__c.Product_Name_Local_Language__c";
import Formulator_Name_Local_Language from "@salesforce/schema/Inventory_Line_Item__c.Formulator_Name_Local_Language__c";
import USER_NAME_FIELD from "@salesforce/schema/User.Name";
import INDITEX_CLASSIFICATION_FOR_BABIES from "@salesforce/schema/Inventory_Line_Item__c.Inditex_Classification_for_Babies__c";
import INDITEX_CLASSIFICATION_FOR_CHILDREN_ADULT from "@salesforce/schema/Inventory_Line_Item__c.Inditex_Classification_for_Child_Adult__c";


export default class TcInventoryLineItemDetail extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @track showModal = false;
  @track labels = label;
  @track recordTypeId;
  @track wiredRecord;
  @track disableDeliveredStockInput = true;
  @track userId = userId;
  @track disableBtn = false;

  addStockRegex = /^\d{0,16}(\.\d{1,2})?$/;

  @wire(getPicklistValues, {
    recordTypeId: "",
    fieldApiName: COMMODITY_CHEMICAL_STANDARD_NAME_FIELD
  })
  typeOfcommodityChemicalDefaultOptions;
  
  get commodityChemicalOptions() {
    let newPicklistValues = [];
    let tempPicklist = 
      this.typeOfcommodityChemicalOptions?.data?.values
      ? this.typeOfcommodityChemicalOptions.data.values
      : this.typeOfcommodityChemicalDefaultOptions?.data?.values
      ? this.typeOfcommodityChemicalDefaultOptions.data.values
      : [];
      newPicklistValues.push({ value: "", label: "--" });

      for(let i=0 ; i<tempPicklist.length ; i++ ){
        newPicklistValues.push({value: tempPicklist[i].value, label: tempPicklist[i].label});
      }
    return newPicklistValues;
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: TYPE_OF_CHEMICALS_FIELD
  })
  typeOfChemicalsOptions;
  
  get typeOfChemicalOptions() {
    let newPicklistValues = [];
    let tempPicklist = 
      this.typeOfChemicalsOptions?.data?.values
      ? this.typeOfChemicalsOptions.data.values
      : [];
      newPicklistValues.push({ value: "", label: "--" });

      for(let i=0 ; i<tempPicklist.length ; i++ ){
        newPicklistValues.push({value: tempPicklist[i].value, label: tempPicklist[i].label});
      }
    return newPicklistValues;
  }
  
  @wire(getRecord, { recordId: "$userId", fields: [USER_NAME_FIELD] })
  userInfo;

  @wire(getObjectInfo, { objectApiName: INVENTORY_LINE_ITEM_OBJECT })
  objInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: UNIT_FIELD
  })
  typeOfUnitOptions;

  @wire(getPicklistValues, {
    recordTypeId: "$objInfo.data.defaultRecordTypeId",
    fieldApiName: UNIT_FIELD
  })
  typeOfUnitDefaultOptions;
  
  get unitOptions() {
    return this.typeOfUnitOptions?.data?.values
      ? this.typeOfUnitOptions.data.values
      : this.typeOfUnitDefaultOptions?.data?.values
      ? this.typeOfUnitDefaultOptions.data.values
      : [{ value: "", label: "" }];
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: COMMODITY_CHEMICAL_STANDARD_NAME_FIELD
  })
  typeOfcommodityChemicalOptions;
  
  get disableComChem(){
    return ( !this.commodityChemicalOptions || this.isNotPending )  ? true : false ;
  }

  get disableTypeOfChem(){
    return ( !this.typeOfChemicalOptions || this.isNotPending )  ? true : false ;
  }

  get disableUnitInput() {
    return (this.deliveredStock && this.unit) || this.isNotPending
      ? true
      : false;
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      RECORD_TYPE_DEVNAME_FIELD,
      RECORD_TYPE_ID_FIELD,
      INVENTORY_ID_FIELD,
      FORMULATOR_NAME_FIELD,
      CHEMICAL_PRODUCT_NAME_FIELD,
      UNIT_FIELD,
      DELIVERED_STOCK_FIELD,
      STOCK_TAKE_BEGIN,
      STOCK_TAKE_END,
      CALCULATED_USAGE,
      CALCULATED_WEIGHT,
      DELIVERED_STOCK_HISTORY_FIELD,
      STORAGE_LOCATION_FIELD,
      LOT_NUMBER_FIELD,
      EXPIRY_DATE_FIELD,
      OTHER_NAME_FIELD,
      ZDHC_V2_FIELD,
      ZDHC_Version_FIELD,
      ZDHC_ID_FIELD,
      ZDHC_GUID_FIELD,
      STATUS_FIELD,
      COMMODITY_CHEMICAL_STANDARD_NAME_FIELD,
      TYPE_OF_CHEMICALS_FIELD,
      Supplier_Reference_Name,
      Supplier_Reference_Number,
      Product_Name_Local_Language,
      Formulator_Name_Local_Language,
      INDITEX_CLASSIFICATION_FOR_BABIES,
      INDITEX_CLASSIFICATION_FOR_CHILDREN_ADULT
    ]
  })
  record(response) {
    this.wiredRecord = response;
    if (response.data) {
      this.recordTypeId = getFieldValue(response.data, RECORD_TYPE_ID_FIELD);
    }
    this.disableBtn = this.isNotPending;
  }
  get inditexClassificationForBabies() {
    return getFieldValue(this.wiredRecord.data, INDITEX_CLASSIFICATION_FOR_BABIES);
  }
  get isBabies() {
    return this.inditexClassificationForBabies ? true : false;
  }
  get inditexClassificationForChildAdult() {
    return getFieldValue(this.wiredRecord.data, INDITEX_CLASSIFICATION_FOR_CHILDREN_ADULT);
  }
  get isChildAdult() {
    return this.inditexClassificationForChildAdult ? true : false;
  }

  get isUsageType() {
    return (
      getFieldValue(this.wiredRecord.data, RECORD_TYPE_DEVNAME_FIELD) &&
      getFieldValue(this.wiredRecord.data, RECORD_TYPE_DEVNAME_FIELD) ===
        "Usage_Inventory_Line_Item"
    );
  }
  get disableUnitInput() {
    return (this.deliveredStock && this.unit) || this.isNotPending
      ? true
      : false;
  }
  get commodityChemicalStandardName() {
    return getFieldValue(this.wiredRecord.data, COMMODITY_CHEMICAL_STANDARD_NAME_FIELD);
  }
  get typeOfChemicals() {
    return getFieldValue(this.wiredRecord.data, TYPE_OF_CHEMICALS_FIELD);
  }
  get unit() {
    return getFieldValue(this.wiredRecord.data, UNIT_FIELD);
  }
  get deliveredStock() {
    return getFieldValue(this.wiredRecord.data, DELIVERED_STOCK_FIELD);
  }
  get calculatedWeight() {
    return getFieldValue(this.wiredRecord.data, CALCULATED_WEIGHT);
  }
  get calculatedUsage() {
    return getFieldValue(this.wiredRecord.data, CALCULATED_USAGE);
  }
  get stockMonthBegin() {
    return getFieldValue(this.wiredRecord.data, STOCK_TAKE_BEGIN);
  }
  get stockMonthEnd() {
    return getFieldValue(this.wiredRecord.data, STOCK_TAKE_END);
  }
  get deliveredStockHistory() {
    return getFieldValue(this.wiredRecord.data, DELIVERED_STOCK_HISTORY_FIELD);
  }
  get storageLocation() {
    return getFieldValue(this.wiredRecord.data, STORAGE_LOCATION_FIELD);
  }
  get lotNumber() {
    return getFieldValue(this.wiredRecord.data, LOT_NUMBER_FIELD);
  }
  get expiryDate() {
    return getFieldValue(this.wiredRecord.data, EXPIRY_DATE_FIELD);
  }
  get productName() {
    return getFieldValue(this.wiredRecord.data, CHEMICAL_PRODUCT_NAME_FIELD);
  }
  get formulatorName() {
    return getFieldValue(this.wiredRecord.data, FORMULATOR_NAME_FIELD);
  }
  get otherName() {
    return getFieldValue(this.wiredRecord.data, OTHER_NAME_FIELD);
  }
  get zdhcMrsl() {
    return getFieldValue(this.wiredRecord.data, ZDHC_V2_FIELD);
  }
  get zdhcMrslVersion() {
    return getFieldValue(this.wiredRecord.data, ZDHC_Version_FIELD);
  }
  get productId() {
    return getFieldValue(this.wiredRecord.data, ZDHC_ID_FIELD);
  }
  get productGUID() {
    return getFieldValue(this.wiredRecord.data, ZDHC_GUID_FIELD);
  }
  get isPending() {
    return getFieldValue(this.wiredRecord.data, STATUS_FIELD) === "Pending";
  }
  get isNotPending() {
    return getFieldValue(this.wiredRecord.data, STATUS_FIELD) !== "Pending";
  }
  get supplierReferenceName(){
    return getFieldValue(this.wiredRecord.data, Supplier_Reference_Name);
  }
  get supplierReferenceNumber(){
    return getFieldValue(this.wiredRecord.data, Supplier_Reference_Number);
  }
  get productNameLocalLanguage(){
    return getFieldValue(this.wiredRecord.data, Product_Name_Local_Language);
  }
  get formulatorNameLocalLanguage(){
    return getFieldValue(this.wiredRecord.data, Formulator_Name_Local_Language);
  }

  handleAddStock() {
    // do something with the c-input with data-id "AddMoreStock"
    let addStockField = this.template.querySelector("[data-id='AddMoreStock']");
    if (addStockField.value && addStockField.validate().isValid) {
      this.disableBtn = true;
      const deliveredStock =
        getFieldValue(this.wiredRecord.data, DELIVERED_STOCK_FIELD) || 0;
      const fields = {};
      fields[ID_FIELD.fieldApiName] = this.recordId;
      fields[DELIVERED_STOCK_FIELD.fieldApiName] =
        parseFloat(deliveredStock) + parseFloat(addStockField.value);
      // build some html and add it to the the delivered stock history field
      const history = getFieldValue(
        this.wiredRecord.data,
        DELIVERED_STOCK_HISTORY_FIELD
      );
      let timeNow = new Date();
      const newHistory =
        "<p><span>+" +
        parseFloat(addStockField.value) +
        " = " +
        parseFloat(
          parseFloat(deliveredStock) + parseFloat(addStockField.value)
        ) +
        "</span><span> (" +
        getFieldValue(this.userInfo.data, USER_NAME_FIELD) +
        ") </span><span>" +
        timeNow.toLocaleDateString() +
        " " +
        timeNow.toLocaleTimeString([], { timeZoneName: "short" }) +
        "</span></p>";
      fields[DELIVERED_STOCK_HISTORY_FIELD.fieldApiName] = history
        ? history + newHistory
        : newHistory;

      const recordInput = { fields };

      updateRecord(recordInput)
        .then(() => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.SUCCESS,
              message: this.labels.DELIVERED_STOCK_ADDED,
              variant: "success"
            })
          );
          // disable delivered stock input
          if (!this.disableDeliveredStockInput) this.toggleDeliveredStockEdit();
          // reset Add More Stock field
          this.resetAddStockField();
          this.disableBtn = false;
          // Display fresh data in the form
          return refreshApex(this.wiredRecord);
        })
        .catch((error) => {
          this.disableBtn = false;
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.ERROR,
              message: error.body.message,
              variant: "error"
            })
          );
        });
    }
  }

  handleDelete() {
    this.toggleModal();
  }

  handleCancel() {
    // disable delivered stock input
    if (!this.disableDeliveredStockInput) this.toggleDeliveredStockEdit();
    // reset Add More Stock field
    this.resetAddStockField();
    this.resetInputs();
  }

  handleSave() {
    this.disableBtn = false;
    // updateRecord
    const allValid = [...this.template.querySelectorAll("c-input:not([data-id='AddMoreStock'])")].reduce(
      (validSoFar, inputField) => {
        const response = inputField.validate();
        return validSoFar && response.isValid;
      },
      true
    );
    
    const typeOfChemField = this.template.querySelector("[data-id='Type_of_Chemicals__c']").value;
    const commStdNameField = this.template.querySelector("[data-id='Commodity_Chemical_Standard_Name__c']").value;
    if (typeOfChemField !== '' && commStdNameField !== '') {
      this.disableBtn = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: 'Commodity Name and Type of Chemicals can not be selected together',
          variant: "error"
        })
      );
    }
    else {

    if (allValid) {
      this.disableBtn = true;
      // Create the recordInput object
      const fields = {};
      fields[ID_FIELD.fieldApiName] = this.recordId;
      fields[UNIT_FIELD.fieldApiName] = this.template.querySelector(
        "[data-id='Unit__c']"
      ).value;
      fields[DELIVERED_STOCK_FIELD.fieldApiName] =
        this.template.querySelector("[data-id='Delivered_Stock_This_Month__c']")
          .value || 0;
      fields[STORAGE_LOCATION_FIELD.fieldApiName] = this.template.querySelector(
        "[data-id='Storage_Location__c']"
      ).value;
      fields[LOT_NUMBER_FIELD.fieldApiName] = this.template.querySelector(
        "[data-id='Lot_Number__c']"
      ).value;
      fields[EXPIRY_DATE_FIELD.fieldApiName] = this.template.querySelector(
        "[data-id='Expiry_Date__c']"
      ).value;
      fields[COMMODITY_CHEMICAL_STANDARD_NAME_FIELD.fieldApiName] = this.template.querySelector(
        "[data-id='Commodity_Chemical_Standard_Name__c']"
        ).value;
      fields[TYPE_OF_CHEMICALS_FIELD.fieldApiName] = this.template.querySelector(
        "[data-id='Type_of_Chemicals__c']"
        ).value;
      if (this.isUsageType) {
        fields[STOCK_TAKE_BEGIN.fieldApiName] = this.template.querySelector(
          "[data-id='Stock_Take_Month_Begin__c']"
        ).value;
        fields[STOCK_TAKE_END.fieldApiName] = this.template.querySelector(
          "[data-id='Stock_Take_Month_End__c']"
        ).value;
      }

      const oldDeliveredStockValue =
        getFieldValue(this.wiredRecord.data, DELIVERED_STOCK_FIELD) || 0;
      // If the delivered stock was edited, update the delivered stock history
      if (
        fields[DELIVERED_STOCK_FIELD.fieldApiName] != oldDeliveredStockValue
      ) {
        // build some html and add it to the the delivered stock history field
        const history = getFieldValue(
          this.wiredRecord.data,
          DELIVERED_STOCK_HISTORY_FIELD
        );
        let timeNow = new Date();
        const newHistory =
          "<p>" +
          this.labels.EDIT_TO +
          " " +
          parseFloat(fields[DELIVERED_STOCK_FIELD.fieldApiName]) +
          " (" +
          getFieldValue(this.userInfo.data, USER_NAME_FIELD) +
          ") " +
          timeNow.toLocaleDateString() +
          " " +
          timeNow.toLocaleTimeString([], { timeZoneName: "short" }) +
          "</p>";
        fields[DELIVERED_STOCK_HISTORY_FIELD.fieldApiName] = history
          ? history + newHistory
          : newHistory;
      }

      const recordInput = { fields };

      updateRecord(recordInput)
        .then(() => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.SUCCESS,
              message: this.labels.YOUR_INVENTORY_LINE_CHANGES_SAVED,
              variant: "success"
            })
          );
          // Navigate back to the parent Inventory record
          this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
              recordId: getFieldValue(
                this.wiredRecord.data,
                INVENTORY_ID_FIELD
              ),
              objectApiName: "Inventory__c",
              actionName: "view"
            }
          });
        })
        .catch((error) => {
          this.disableBtn = false;
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.ERROR,
              message: error.body.message,
              variant: "error"
            })
          );
        });
    } else {
      this.disableBtn = false;
      // The form is not valid
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: this.labels.CORRECT_ANY_PROBLEMS,
          variant: "error"
        })
      );
    }
  }
  }

  handleConfirmDelete() {
    this.disableBtn = true;
    deleteRecord(this.recordId)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.SUCCESS,
            message: this.labels.INVENTORY_LINE_DELETED,
            variant: "success"
          })
        );
        // Navigate back to the parent Inventory record
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: getFieldValue(this.wiredRecord.data, INVENTORY_ID_FIELD),
            objectApiName: "Inventory__c",
            actionName: "view"
          }
        });
      })
      .catch((error) => {
        this.disableBtn = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR_DELETING_RECORD,
            message: error.body.message,
            variant: "error"
          })
        );
      });
  }

  toggleModal() {
    this.showModal = !this.showModal;
  }

  resetInputs() {
    this.template.querySelectorAll("c-input").forEach((input) => {
      input.value = this.wiredRecord.data.fields[input.fieldId]
        ? this.wiredRecord.data.fields[input.fieldId].value
        : undefined;
    });
  }

  resetAddStockField() {
    this.template.querySelector("[data-id='AddMoreStock']").value = undefined;
  }

  resetDeliveredStockField() {
    this.template.querySelector(
      "[data-id='Delivered_Stock_This_Month__c']"
    ).value = this.wiredRecord.data.fields["Delivered_Stock_This_Month__c"]
      ? this.wiredRecord.data.fields["Delivered_Stock_This_Month__c"].value
      : undefined;
  }

  toggleDeliveredStockEdit() {
    this.disableDeliveredStockInput = !this.disableDeliveredStockInput;
    if (this.disableDeliveredStockInput) {
      this.resetDeliveredStockField();
    }
  }

}