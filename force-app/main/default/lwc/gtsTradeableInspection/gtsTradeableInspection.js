import { LightningElement, api, wire } from "lwc";
import COMPANY_ADDRESS from "@salesforce/label/c.GTS_Company_Address";
import COMPANY_NAME from "@salesforce/label/c.GTS_Company_Name";
import CONTACT_NUMBER from "@salesforce/label/c.GTS_Contact_Number";
import CONTACT_PERSON from "@salesforce/label/c.GTS_Contact_Person";
import EMAIL from "@salesforce/label/c.GTS_Email";
import SEARCH_PERSON from "@salesforce/label/c.GTS_Search_Person";
import INSPECTION from "@salesforce/label/c.GTS_Inspection_PageTitle";
import GOODS_CONDITION from "@salesforce/label/c.GTS_Goods_Condition";
import OTHER_VALUE from "@salesforce/label/c.GTS_Other_Value";
import GOODS_AVAILABILITY_DATE from "@salesforce/label/c.GTS_Goods_Availability_Date";
import PROPOSED_INSPECTION_DATE from "@salesforce/label/c.GTS_Proposed_Inspection_Date";
import SHIPMENT_TYPE from "@salesforce/label/c.GTS_Shipment_Type";
import SHIPMENT_MODE from "@salesforce/label/c.GTS_Shipment_Mode";
import SPECIFY_NUMBER_FCL from "@salesforce/label/c.GTS_Specify_Number_FCL";
import SHIPMENT_MODE_FIELD from "@salesforce/schema/icare_Job_Request__c.GTS_Shipment_Mode__c";
import SHIPMENT_TYPE_FIELD from "@salesforce/schema/icare_Job_Request__c.GTS_Shipment_Type__c";
import GOODS_CONDITION_FIELD from "@salesforce/schema/icare_Job_Request__c.GTS_Goods_Condition__c";
import { getPicklistValues } from "lightning/uiObjectInfoApi";

import INVIEW_REQUESTED_LABEL from "@salesforce/label/c.GTS_Inview_Requested_Label";
import INVIEW_REQUESTED_TITLE1 from "@salesforce/label/c.GTS_Inview_Requested_Title1";
import INVIEW_REQUESTED_TITLE2 from "@salesforce/label/c.GTS_Inview_Requested_Title2";
import INVIEW_TECHNOLOGY_LINK from "@salesforce/label/c.GTS_Inview_Technology_Link";
import FUTURE_DATE_VALIDATION from "@salesforce/label/c.GTS_FutureDate_Validation";

export default class GtsTradeableInspection extends LightningElement {
  @api isReadOnly = false;
  @api jobRequestRecord;
  @api goodsAvailableDate;
  @api proposedInspectionDate;
  @api recordTypeId;
  isGoodsAvailPastDate = false;
  isProInspPastDate = false;
  inspectionLocationDetails;

  shipmentTypeOptions = [];
  shipmentModeOptions = [];
  goodsOptions = [];
  inviewRequested = false;

  @api shipmentType;
  @api shipmentMode;
  @api fclNumber;
  @api goodsCondition;
  @api isOtherValue = false;
  @api otherShipmentMode;
  @api accountRecordType;

  labels = {
    COMPANY_ADDRESS,
    COMPANY_NAME,
    CONTACT_NUMBER,
    CONTACT_PERSON,
    EMAIL,
    SEARCH_PERSON,
    INSPECTION,
    GOODS_CONDITION,
    GOODS_AVAILABILITY_DATE,
    PROPOSED_INSPECTION_DATE,
    SHIPMENT_TYPE,
    SHIPMENT_MODE,
    SPECIFY_NUMBER_FCL,
    OTHER_VALUE,
    INVIEW_REQUESTED_LABEL,
    INVIEW_REQUESTED_TITLE1,
    INVIEW_REQUESTED_TITLE2,
    INVIEW_TECHNOLOGY_LINK,
    FUTURE_DATE_VALIDATION
  };

  get inspectionLocationFieldsFiltering() {
    return JSON.stringify({
      GTS_Account__c: this.jobRequestRecord.iCare_Applicant_Company__c,
      GTS_Role__c: "Inspection Location"
    });
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: SHIPMENT_MODE_FIELD
  })
  getPicklistValuesForShipmenMode({ data, error }) {
    if (error) {
      console.error(error);
    } else if (data) {
      console.log("data : ", data);
      this.shipmentModeOptions = data.values.map((item) => ({
        label: item.label,
        value: item.value
      }));
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: SHIPMENT_TYPE_FIELD
  })
  getPicklistValuesForShipmentType({ data, error }) {
    if (error) {
      console.error(error);
    } else if (data) {
      console.log("data : ", data);
      this.shipmentTypeOptions = data.values.map((item) => ({
        label: item.label,
        value: item.value
      }));
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: GOODS_CONDITION_FIELD
  })
  getPicklistValuesForField({ data, error }) {
    if (error) {
      console.error(error);
    } else if (data) {
      console.log("data : ", data);
      this.goodsOptions = data.values.map((item) => ({
        label: item.label,
        value: item.value
      }));
    }
  }

  connectedCallback() {
    if (this.jobRequestRecord && this.jobRequestRecord.GTS_Shipment_Mode__c) {
      this.shipmentMode = this.jobRequestRecord.GTS_Shipment_Mode__c;
      if (this.shipmentMode && this.shipmentMode.includes("Other")) {
        this.isOtherValue = true;
      }
    }
  }

  handleInviewRequestedChange(event) {
    this.inviewRequested = event.target.checked;
    this.dispatchChangeDataEvent();
  }

  handleShipmentTypeChange(event) {
    this.shipmentType = event.detail.value;
    this.dispatchChangeDataEvent();
  }

  handleShipmentModeChange(event) {
    this.shipmentMode = event.detail.value;

    if (this.shipmentMode.includes("Other")) {
      this.isOtherValue = true;
    } else {
      this.isOtherValue = false;
    }

    this.dispatchChangeDataEvent();
  }

  handleOtherShipmentModeChange(event) {
    this.otherShipmentMode = event.detail.value;
    this.dispatchChangeDataEvent();
  }

  handleFCLNumberChange(event) {
    this.fclNumber = event.detail.value;
    this.dispatchChangeDataEvent();
  }

  handleGoodConditionChange(event) {
    this.goodsCondition = event.detail.value;
    this.dispatchChangeDataEvent();
  }

  handleGoodsDateChange(event) {
    // Custom validation for a future date
    const selectedDate = new Date(event.target.value);
    var currentDate = new Date();
    var options = { day: '2-digit', month: '2-digit', year: 'numeric' };

    if (selectedDate < currentDate && selectedDate.toLocaleDateString('en-GB', options) != currentDate.toLocaleDateString('en-GB', options)) {
      this.isGoodsAvailPastDate = true;
      event.target.setCustomValidity(this.labels.FUTURE_DATE_VALIDATION);
    } else {
      event.target.setCustomValidity(""); // Reset the custom validity message
      this.goodsAvailableDate = event.target.value;
      this.isGoodsAvailPastDate = false;
      this.dispatchChangeDataEvent();
    }
    event.target.reportValidity(); // Show the error message if validation fails
    this.dispatchValidationEvent();
  }

  handleProposedDateChange(event) {
    // Custom validation for a future date
    const selectedDate = new Date(event.target.value);
    var currentDate = new Date();
    var options = { day: '2-digit', month: '2-digit', year: 'numeric' };

    if (selectedDate < currentDate && selectedDate.toLocaleDateString('en-GB', options) != currentDate.toLocaleDateString('en-GB', options)) {
      this.isProInspPastDate = true;
      event.target.setCustomValidity(this.labels.FUTURE_DATE_VALIDATION);
    } else {
      event.target.setCustomValidity(""); // Reset the custom validity message
      this.proposedInspectionDate = event.target.value;
      this.isProInspPastDate = false;
      this.dispatchChangeDataEvent();
    }
    event.target.reportValidity(); // Show the error message if validation fails
    this.dispatchValidationEvent();
  }

  dispatchValidationEvent() {
    if (this.isGoodsAvailPastDate || this.isProInspPastDate) {
      this.dispatchEvent(new CustomEvent("datevalidation", { detail: true }));
    } else {
      this.dispatchEvent(new CustomEvent("datevalidation", { detail: false }));
    }
  }

  handleUpdateInspectionInfo(event) {
    this.inspectionLocationDetails = event.detail;
    this.dispatchChangeDataEvent();
  }

  dispatchChangeDataEvent() {
    const oEvent = new CustomEvent("updateinspectionpage", {
      detail: {
        inspectionLocationDetails: this.inspectionLocationDetails,
        goodsAvailableDate: this.goodsAvailableDate,
        proposedInspectionDate: this.proposedInspectionDate,
        shipmentType: this.shipmentType,
        shipmentMode: this.shipmentMode,
        fclNumber: this.fclNumber,
        otherShipmentMode: this.otherShipmentMode,
        goodsCondition: this.goodsCondition,
        inviewRequested: this.inviewRequested
      }
    });

    this.dispatchEvent(oEvent);
  }
}