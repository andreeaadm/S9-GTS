export function getJobRequestStructure() {
  return {
    GTS_Applicant_Type__c: "",
    GTS_Client_Reference__c: "",
    GTS_CoC_Declaration_1__c: false,
    GTS_CoC_Declaration_2__c: false,
    GTS_CoC_Declaration_3__c: false,
    iCare_Draft_ETRF__c: true,
    iCare_Applicant_Company__c: "",
    GTS_Applicant_Company_Name__c: "",
    iCare_Applicant_Address__City__s: "",
    iCare_Applicant_Address__CountryCode__s: "",
    iCare_Applicant_Address__PostalCode__s: "",
    iCare_Applicant_Address__Street__s: "",
    iCare_Applicant_Address__StateCode__s: "",
    GTS_Commercial_Registration_No_TIN__c: "",
    GTS_Applicant_Contact_Person__c: "",
    GTS_Applicant_Contact_Number__c: "",
    iCare_Applicant_Contact_Person_Name__c: "",
    iCare_Applicant_Email__c: "",
    GTS_Importer_Company_Name__c: "",
    GTS_Importer_Company_Name_Text__c: "",
    GTS_Importer_Company_Address__City__s: "",
    GTS_Importer_Company_Address__CountryCode__s: "",
    GTS_Importer_Company_Address__PostalCode__s: "",
    GTS_Importer_Company_Address__Street__s: "",
    GTS_Importer_Company_Address__StateCode__s: "",
    GTS_Importer_Contact_Person__c: "",
    GTS_Importer_Contact_Person_Name_Text__c: "",
    GTS_Importer_Email__c: "",
    GTS_Importer_Contact_Number__c: "",
    GTS_Importer_Commercial_Reg_No_TIN__c: "",
    GTS_Inspection_Location_Company_Name__c: "",
    GTS_Inspection_Location_Company_Address__City__s: "",
    GTS_Inspection_Location_Company_Address__CountryCode__s: "",
    GTS_Inspection_Location_Company_Address__PostalCode__s: "",
    GTS_Inspection_Location_Company_Address__Street__s: "",
    GTS_Inspection_Location_Company_Address__StateCode__s: "",
    GTS_Inspection_Location_Contact_Number__c: "",
    GTS_Inspection_Location_Contact_Person__c: "",
    GTS_Inspection_Location_Email__c: "",
    GTS_Inspection_Location_Company_Text__c: "",
    GTS_Inspection_Loc_Contact_Name_Text__c: "",
    GTS_Payer_Company_Name__c: "",
    GTS_Payer_Company_Name_Text__c: "",
    GTS_Payer_Company_Address__City__s: "",
    GTS_Payer_Company_Address__CountryCode__s: "",
    GTS_Payer_Company_Address__PostalCode__s: "",
    GTS_Payer_Company_Address__Street__s: "",
    GTS_Payer_Company_Address__StateCode__s: "",
    GTS_Payer_Contact_Person__c: "",
    GTS_Payer_Contact_Person_Text__c: "",
    GTS_Payer_Email__c: "",
    GTS_Payer_Contact_Number__c: "",
    GTS_Purchase_Order_Number__c: "",
    RecordTypeId: "",
    GTS_Program__c: "",
    ProgramName: "",
    iCare_Applicant_Address__City__s: "",
    iCare_Applicant_Address__Street__s: "",
    iCare_Applicant_Address__PostalCode__s: "",
    iCare_Applicant_Address__CountryCode__s: "",
    GTS_Payer_Company_Address__City__s: "",
    GTS_Payer_Company_Address__Street__s: "",
    GTS_Payer_Company_Address__PostalCode__s: "",
    GTS_Payer_Company_Address__CountryCode__s: "",
    GTS_ACID_No__c: "",
    GTS_AWB_No__c: "",
    GTS_BL_No__c: "",
    GTS_Certificate_Origin_No__c: "",
    GTS_Certificate_Origin_Date__c: "",
    GTS_Customer_Dealer_No__c: "",
    GTS_Transport_Document_No__c: "",
    GTS_Transport_Document_Date__c: "",
    GTS_Commercial_Registration_No_TIN__c: "",
    GTS_FASEH_Request_No__c: "",
    GTS_FDI_No__c: "",
    GTS_IDF_No__c: "",
    GTS_Import_Licence_No__c: "",
    GTS_Importer_Code__c: "",
    GTS_Importer_Commercial_Reg_No_TIN__c: "",
    GTS_ICE_No__c: "",
    GTS_LC_No__c: "",
    GTS_LC_Date__c: "",
    GTS_No_of_Exporter__c: "",
    GTS_No_of_Importer__c: "",
    GTS_PR_No__c: "",
    GTS_Invoice_No__c: "",
    GTS_Invoice_Date__c: "",
    GTS_UESW_Application_No__c: "",
    GTS_UCR_No__c: "",
    GTS_Other_No_please_specify__c: "",
    iCare_Active_Favourite__c: false,
    iCare_Favourite_Name__c: "",
    GTS_Type_of_Application__c: "",
    GTS_Other_No_please_specify__c: "",
    GTS_LRF_Declaration_1__c: false,
    GTS_LRF_Declaration_2__c: false,
    GTS_LRF_Declaration_3__c: false,
    GTS_ComSer_Declaration_1__c: false,
    GTS_ComSer_Declaration_2__c: false,
    GTS_ComServ_Declaration_3__c: false,
    GTS_ComSer_Declaration_4__c: false,
    GTS_CoC_Declaration_3__c: false,
    GTS_Specify_Number_of_FCLs__c: "",
    GTS_Shipment_Mode_Please_Specify__c: "",
    GTS_Shipment_Mode__c: "",
    GTS_Shipment_Type__c: "",
    GTS_Goods_Condition__c: "",
    GTS_Goods_Available_Date__c: "",
    GTS_Proposed_Inspection_Date__c: "",
    GTS_Statement_of_Work__c: "",
    GTS_ComSer_Prog_Please_Specify__c: "",
    iCare_Sample_Description__c: "",
    GTS_Inview_Requested__c: false
  };
}

export function getJobRequestSimpleDescription(jobRequestRecord, formType) {
  let descriptionValue;
  if (
    jobRequestRecord.GTS_Purchase_Order_Number__c != undefined &&
    jobRequestRecord.GTS_Purchase_Order_Number__c.toString().length > 0
  ) {

    descriptionValue = jobRequestRecord.GTS_Purchase_Order_Number__c.toString();
  } else {
    const currentDate = new Date();
    descriptionValue =
      formType +
      " " +
      currentDate.getDate() +
      "/" +
      (currentDate.getMonth() + 1) +
      "/" +
      currentDate.getFullYear();
  }
  return descriptionValue;
}

export function validatePageRequiredFields(listOfFields, jobRequestRecord) {
 let isValid = true;
  for (const key of listOfFields) {
    if (!jobRequestRecord.hasOwnProperty(key) || jobRequestRecord[key] === null || jobRequestRecord[key] === undefined || jobRequestRecord[key] === ''
       || (typeof jobRequestRecord[key] === 'boolean' && jobRequestRecord[key] === false)
    ) {
      isValid = false;
    }
  }
  return isValid;
}