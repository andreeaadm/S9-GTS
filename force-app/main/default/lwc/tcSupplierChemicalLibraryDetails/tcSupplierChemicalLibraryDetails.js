import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import CHEMICALPRODUCT_OBJECT from "@salesforce/schema/Chemical_Product__c";
import ID_FIELD from "@salesforce/schema/Chemical_Product__c.Id";
import NAME_FIELD from "@salesforce/schema/Chemical_Product__c.Name";
import CHEMICALPRODUCT_NAME_FIELD from "@salesforce/schema/Chemical_Product__c.Chemical_Product_Name__c";
import FORMULATOR_NAME_FIELD from "@salesforce/schema/Chemical_Product__c.Formulator_Name__c";
import OTHER_NAME_FIELD from "@salesforce/schema/Chemical_Product__c.Product_Trade_Name_Other_Name__c";
import ZDHC_MRSL_LEVEL_FIELD from "@salesforce/schema/Chemical_Product__c.ZDHC_MRSL_v2_0__c";
import ZDHC_MRSL_VERSION_FIELD from "@salesforce/schema/Chemical_Product__c.ZDHC_MRSL_Version__c";
import PRODUCT_ID_FIELD from "@salesforce/schema/Chemical_Product__c.ZDHC_Product_Id__c";
import PRODUCT_GUID_FIELD from "@salesforce/schema/Chemical_Product__c.ZDHC_Product_GUID__c";
import CAS_NUMBER_FIELD from "@salesforce/schema/Chemical_Product__c.CAS_Number__c";
import SUPPLIER_REFERENCE_NAME_FIELD from "@salesforce/schema/Chemical_Product__c.Supplier_Reference_Name__c";
import SUPPLIER_REFERENCE_NUMBER_FIELD from "@salesforce/schema/Chemical_Product__c.Supplier_Reference_Number__c";
import PRODUCT_NAME_LOCAL_LANGUAGE_FIELD from "@salesforce/schema/Chemical_Product__c.Product_Name_Local_Language__c";
import FORMULATOR_NAME_LOCAL_LANGUAGE_FIELD from "@salesforce/schema/Chemical_Product__c.Formulator_Name_Local_Language__c";

export default class TcSupplierChemicalLibraryDetails extends LightningElement {
 @api recordId;
 @api isBrandUser;
 @track editMode = false;
 @track isWorking = false;
 @track chemicalProductDetails = 'Chemical Product Details';
 @track casNumberAfterChange;
 @track SupplierReferenceNameChange;
 @track SupplierReferenceNumberChange;
 @track ProductNameLocalLanguageChange;
 @track FormulatorNameLocalLanguageChange;

 fields = [
    NAME_FIELD,
    CHEMICALPRODUCT_NAME_FIELD, 
    FORMULATOR_NAME_FIELD, 
    OTHER_NAME_FIELD, 
    ZDHC_MRSL_LEVEL_FIELD,
    ZDHC_MRSL_VERSION_FIELD,
    PRODUCT_ID_FIELD,
    PRODUCT_GUID_FIELD,
    CAS_NUMBER_FIELD,
    SUPPLIER_REFERENCE_NAME_FIELD,
    SUPPLIER_REFERENCE_NUMBER_FIELD,
    FORMULATOR_NAME_LOCAL_LANGUAGE_FIELD,
    PRODUCT_NAME_LOCAL_LANGUAGE_FIELD
];

 @wire(getRecord, {
    recordId: "$recordId",
    fields: [
        NAME_FIELD,
        CHEMICALPRODUCT_NAME_FIELD, 
        CAS_NUMBER_FIELD,
        SUPPLIER_REFERENCE_NAME_FIELD,
        SUPPLIER_REFERENCE_NUMBER_FIELD,
        FORMULATOR_NAME_LOCAL_LANGUAGE_FIELD,
        PRODUCT_NAME_LOCAL_LANGUAGE_FIELD
    ]
  })
chemicalProduct;

get Name() {
return getFieldValue(this.chemicalProduct.data, NAME_FIELD);
}

get chemicalProductName() {
return getFieldValue(this.chemicalProduct.data, CHEMICALPRODUCT_NAME_FIELD);
}

get casNumber() {
return getFieldValue(this.chemicalProduct.data, CAS_NUMBER_FIELD);
}

get supplierReferencName() {
  return getFieldValue(this.chemicalProduct.data, SUPPLIER_REFERENCE_NAME_FIELD);
}

get supplierReferenceNumber() {
  return getFieldValue(this.chemicalProduct.data, SUPPLIER_REFERENCE_NUMBER_FIELD);
}

get formulatorNameLocalLanguage() {
  return getFieldValue(this.chemicalProduct.data, FORMULATOR_NAME_LOCAL_LANGUAGE_FIELD);
}

get productNameLocalLangauge() {
  return getFieldValue(this.chemicalProduct.data, PRODUCT_NAME_LOCAL_LANGUAGE_FIELD);
}

toggleEdit() {
this.editMode = !this.editMode;
}

toggleIsWorking() {
this.isWorking = !this.isWorking;
}

handleChange(event) {
  if(event.target.name == 'CASNumber'){
    this.casNumberAfterChange = event.detail.value;
  }else if (event.target.name == 'SupplierReferenceName'){
  this.SupplierReferenceNameChange = event.detail.value;
}else if (event.target.name == 'SupplierReferenceNumber'){
  this.SupplierReferenceNumberChange = event.detail.value;
} else if (event.target.name == 'ProductNameLocalLanguage'){
  this.ProductNameLocalLanguageChange = event.detail.value;
} else if (event.target.name == 'FormulatorNameLocalLanguage'){
  this.FormulatorNameLocalLanguageChange = event.detail.value;
}
}

handleUpdateChemicalProduct() {
      this.toggleIsWorking();
      const fields = {
        Id : this.recordId,
        CAS_Number__c :  this.casNumberAfterChange,
        Formulator_Name_Local_Language__c : this.FormulatorNameLocalLanguageChange,
        Product_Name_Local_Language__c : this.ProductNameLocalLanguageChange,
        Supplier_Reference_Name__c : this.SupplierReferenceNameChange,
        Supplier_Reference_Number__c : this.SupplierReferenceNumberChange

      };
      const recordInput = { fields };
      updateRecord(recordInput)
        .then((result) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: "Your changes have been saved",
              variant: "success"
            })
          );
          this.toggleEdit();
          this.toggleIsWorking();
        })
        .catch((error) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: "Please contact an administrator",
              variant: "error"
            })
          );
          this.toggleIsWorking();
        });
  }

}