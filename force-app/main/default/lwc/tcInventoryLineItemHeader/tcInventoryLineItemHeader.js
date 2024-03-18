import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import INVENTORY_LINE_ITEM_OBJECT from "@salesforce/schema/Inventory_Line_Item__c";
import FORMULATOR_NAME_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Formulator_Name__c";
import CHEMICAL_PRODUCT_NAME_FIELD from "@salesforce/schema/Inventory_Line_Item__c.Chemical_Product_Name__c";
import { label } from "c/labelService";

export default class TcInventoryLineItemHeader extends LightningElement {
  @api recordId;
  labels = label;

  get headerSegments() {
    let segments = [this.labels.EDIT_INVENTORY_LINE_ITEM];
    if (this.wiredRecord?.data) {
      if (getFieldValue(this.wiredRecord.data, FORMULATOR_NAME_FIELD)) {
        segments.push(
          getFieldValue(this.wiredRecord.data, FORMULATOR_NAME_FIELD)
        );
      }
      if (getFieldValue(this.wiredRecord.data, CHEMICAL_PRODUCT_NAME_FIELD)) {
        segments.push(
          getFieldValue(this.wiredRecord.data, CHEMICAL_PRODUCT_NAME_FIELD)
        );
      }
    }
    return segments;
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [FORMULATOR_NAME_FIELD, CHEMICAL_PRODUCT_NAME_FIELD]
  })
  wiredRecord;
}