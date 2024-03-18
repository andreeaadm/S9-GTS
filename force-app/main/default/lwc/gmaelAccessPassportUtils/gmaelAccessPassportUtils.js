import { ShowToastEvent } from "lightning/platformShowToastEvent";
import retrieveData from "@salesforce/apex/GMAEL_AccessPassportController.getData";
import retrieveRegionsByCountries from "@salesforce/apex/GMAEL_AccessPassportController.retrieveRegionsByCountries";
import retrieveProductTypeByCategoryId from "@salesforce/apex/GMAEL_AccessPassportController.retrieveProductTypeByCategoryId";
import retrieveReportData from "@salesforce/apex/GMAEL_AccessPassportController.retrieveReportData";
import submitForApproval from "@salesforce/apex/GMAEL_AccessPassportController.submitForApproval";
import getDownloadLink from "@salesforce/apex/GmaelDownloadReportFile.getDownloadLink";
import resetGenerateReportFileValue from "@salesforce/apex/GmaelDownloadReportFile.resetGenerateReportFileValue";
import GMAEL_Country_List_View_Help_Text from "@salesforce/label/c.GMAEL_Country_List_View_Help_Text";
import GMAEL_Countries_Of_The_Selected_Region from "@salesforce/label/c.GMAEL_Countries_Of_The_Selected_Region";
import GMAEL_Regions_Countries_Model_Header_Text from "@salesforce/label/c.GMAEL_Regions_Countries_Model_Header_Text";
import GMAEL_Search_Options from "@salesforce/label/c.GMAEL_Search_Options";
import GMAEL_Country_Map_View from "@salesforce/label/c.GMAEL_Country_Map_View";
import GMAEL_Country_List_View from "@salesforce/label/c.GMAEL_Country_List_View";
import GMAEL_Product_Category from "@salesforce/label/c.GMAEL_Product_Category";
import GMAEL_Product_Description from "@salesforce/label/c.GMAEL_Product_Description";
import GMAEL_Reset from "@salesforce/label/c.GMAEL_Reset";
import GMAEL_Preview from "@salesforce/label/c.GMAEL_Preview";
import GMAEL_Approval from "@salesforce/label/c.GMAEL_Approval";
import GMAEL_Download from "@salesforce/label/c.GMAEL_Download";
import GMAEL_Engineering_Governance from "@salesforce/label/c.GMAEL_Engineering_Governance";
import GMAEL_Legislation_Governance from "@salesforce/label/c.GMAEL_Legislation_Governance";
import GMAEL_Scheme from "@salesforce/label/c.GMAEL_Scheme";
import GMAEL_Governing_Body from "@salesforce/label/c.GMAEL_Governing_Body";
import GMAEL_Standard from "@salesforce/label/c.GMAEL_Standard";
import GMAEL_Country_Mark from "@salesforce/label/c.GMAEL_Country_Mark";
import GMAEL_CAB_Accreditation from "@salesforce/label/c.GMAEL_CAB_Accreditation";
import GMAEL_Conformity_Method from "@salesforce/label/c.GMAEL_Conformity_Method";
import GMAEL_Pre_Shipment_Requirement from "@salesforce/label/c.GMAEL_Pre_Shipment_Requirement";
import GMAEL_Additional_Information from "@salesforce/label/c.GMAEL_Additional_Information";
import GMAEL_Scheme_Documents from "@salesforce/label/c.GMAEL_Scheme_Documents";
import GMAEL_Map_Data_Not_Found from "@salesforce/label/c.GMAEL_Map_Data_Not_Found";
import GMAEL_Supply_Voltage from "@salesforce/label/c.GMAEL_Supply_Voltage";
import GMAEL_Result_Not_Found from "@salesforce/label/c.GMAEL_Result_Not_Found";
import GMAEL_Countries from "@salesforce/label/c.GMAEL_Countries";
import GMAEL_Available from "@salesforce/label/c.GMAEL_Available";
import GMAEL_Selected from "@salesforce/label/c.GMAEL_Selected";
import GMAEL_Plug_Type from "@salesforce/label/c.GMAEL_Plug_Type";

const labels = {
  GMAEL_Countries,
  GMAEL_Available,
  GMAEL_Selected,
  GMAEL_Result_Not_Found,
  GMAEL_Supply_Voltage,
  GMAEL_Map_Data_Not_Found,
  GMAEL_Scheme_Documents,
  GMAEL_Additional_Information,
  GMAEL_Pre_Shipment_Requirement,
  GMAEL_Conformity_Method,
  GMAEL_CAB_Accreditation,
  GMAEL_Country_Mark,
  GMAEL_Standard,
  GMAEL_Governing_Body,
  GMAEL_Scheme,
  GMAEL_Legislation_Governance,
  GMAEL_Engineering_Governance,
  GMAEL_Download,
  GMAEL_Approval,
  GMAEL_Preview,
  GMAEL_Reset,
  GMAEL_Product_Description,
  GMAEL_Product_Category,
  GMAEL_Country_List_View,
  GMAEL_Search_Options,
  GMAEL_Country_Map_View,
  GMAEL_Country_List_View_Help_Text,
  GMAEL_Countries_Of_The_Selected_Region,
  GMAEL_Regions_Countries_Model_Header_Text,
  GMAEL_Plug_Type
};

const toast = (_this, title, msg, variant) => {
  const toastEvent = new ShowToastEvent({
    title: title,
    message: msg,
    variant: variant
  });

  _this.dispatchEvent(toastEvent);
};

const errorToast = (_this, msg) => {
  this.toast(_this, "Error", msg, "error");
};

const successToast = (_this, msg) => {
  this.toast(_this, "Success", msg, "success");
};

const reduceErrors = function (errors) {
  if (!Array.isArray(errors)) {
    errors = [errors];
  }
  return (
    errors
      // Remove null/undefined items
      .filter((error) => !!error)
      // Extract an error message
      .map((error) => {
        // UI API read errors
        if (Array.isArray(error.body)) {
          return error.body.map((e) => e.message);
        }
        // UI API DML, Apex and network errors
        else if (error.body && typeof error.body.message === "string") {
          return error.body.message;
        }
        // JS errors
        else if (typeof error.message === "string") {
          return error.message;
        }
        // Unknown error shape so try HTTP status text
        return error.statusText;
      })
      // Flatten
      .reduce((prev, curr) => prev.concat(curr), [])
      // Remove empty strings
      .filter((message) => !!message)
  );
};

const preparePicklist = function (records, isProductType) {
  let preparedList = [];

  records?.forEach((record) => {
    let pc = {};
    if (isProductType === true) {
      pc["value"] = record.Product_Type_Name__c;
    } else {
      pc["value"] = record.GMAEL_Product_Category_Name__c;
    }

    pc["key"] = record.Id;
    preparedList.push(pc);
  });

  return preparedList;
};

const resetCountries = function () {
  if (window.localStorage) {
    window.localStorage.removeItem("selected-regions");
  }
};

const fireCustomEvent = function (_this, eventName, data) {
  let ev = new CustomEvent(eventName, { detail: data });

  _this.dispatchEvent(ev);
};

const listOfReportCountriesToPrePopup = function (reportData) {
  let reportCountries = [];

  if (reportData?.reportRecordData?.GMAEL_Report_Countries__r) {
    reportData?.reportRecordData?.GMAEL_Report_Countries__r?.forEach((rc) => {
      reportCountries.push(rc.GMAEL_Country_ISO_Code__c);
    });
  }

  return reportCountries;
};

const utilFunctions = {
  toast,
  successToast,
  errorToast,
  retrieveData,
  retrieveProductTypeByCategoryId,
  preparePicklist,
  resetCountries,
  fireCustomEvent,
  labels,
  retrieveRegionsByCountries,
  retrieveReportData,
  listOfReportCountriesToPrePopup,
  submitForApproval,
  getDownloadLink,
  resetGenerateReportFileValue
};

export { utilFunctions, reduceErrors };