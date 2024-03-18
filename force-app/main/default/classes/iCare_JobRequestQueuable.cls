/*******************************************************************************************
 * @Name         iCare_JobRequestQueuable
 * @Test Class :  iCare_JobTriggerHandlerTest
 * @Author       Praveen Kumar R
 * @Description  This acts as the queuable class to iCare_JobTrigger trigger.
 *******************************************************************************************/
public class iCare_JobRequestQueuable extends icare_QueueableVirtual implements Queueable, Database.AllowsCallouts {
  public iCare_JobRequestQueuable() {
    super();
  }

  public iCare_JobRequestQueuable(
    List<iCare_Job__c> jobList,
    List<iCare_Job__c> jobUpdateList,
    List<iCare_Integration_Audit_Log__c> auditLogList
  ) {
    super(jobList, jobUpdateList, auditLogList);
  }

  public void execute(QueueableContext context) {
    try {
      icare_Job_Request__c jobReq = [
        SELECT
          Id,
          Name,
          iCare_Agency_Name__c,
          iCare_Agency_Contact_Person_Name__c,
          iCare_Agency_Email__c,
          iCare_Agency_Fax__c,
          iCare_Fabric_Units__c,
          iCare_Country__c,
          iCare_Agency_Telephone_External__c,
          iCare_Form_Version__c,
          iCare_Applicant_Company__r.AccountNumber,
          iCare_Additional_Instructions__c,
          iCare_Manufacturer_Name__c,
          iCare_Applicant_Company__r.Name,
          iCare_Applicant_Company__r.iCare_Contact_Full_Name__c,
          iCare_Other_Statement__c,
          iCare_Comment_on_Test_Result__c,
          iCare_Applicant_Company__r.iCare_Contact_Phone__c,
          iCare_Applicant_Company__r.iCare_Contact_Email__c,
          iCare_Applicant_Company__r.BillingCity,
          iCare_Applicant_Company__r.BillingCountryCode,
          iCare_Applicant_Company__r.BillingPostalCode,
          iCare_Applicant_Company__r.BillingStateCode,
          iCare_Applicant_Company__r.iCare_Supplier_Unique_ID__c,
          iCare_Applicant_Company__r.BillingStreet,
          iCare_Applicant_Email__c,
          iCare_Applicant_Contact_Person_Name__c,
          iCare_Applicant_Fax__c,
          iCare_Applicant_Telephone_External__c,
          iCare_Applicant_Tax_Office_Number__c,
          iCare_Applicant_Tax_Office__c,
          iCare_Applicant_Address__City__s,
          iCare_Applicant_Address__CountryCode__s,
          iCare_Applicant_Address__PostalCode__s,
          iCare_Applicant_Address__StateCode__s,
          iCare_Applicant_Address__Street__s,
          iCare_Buyer_Region__c,
          iCare_Other_Region__c,
          iCare_Buyer_Name__c,
          iCare_Service_Term__c,
          iCare_Company_to_be_invoiced__r.AccountNumber,
          iCare_Service_Term_Remarks__c,
          iCare_Company_to_be_invoiced__r.Name,
          iCare_Company_to_be_invoiced__r.iCare_Supplier_Unique_ID__c,
          iCare_Company_to_be_invoiced__r.iCare_Contact_Full_Name__c,
          iCare_Company_to_be_invoiced__r.iCare_Contact_Phone__c,
          iCare_Company_to_be_invoiced__r.iCare_Contact_Email__c,
          iCare_Company_to_be_invoiced__r.BillingCity,
          iCare_Company_to_be_invoiced__r.BillingCountryCode,
          iCare_Company_to_be_invoiced__r.BillingPostalCode,
          iCare_Company_to_be_invoiced__r.BillingStateCode,
          iCare_Company_to_be_invoiced__r.BillingStreet,
          iCare_Invoiced_Company_Email__c,
          iCare_Invoiced_Co_Contact_Person_Name__c,
          iCare_Invoiced_Company_Fax__c,
          iCare_Invoiced_Co_Telephone_External__c,
          iCare_Invoiced_Company_Tax_Office_Number__c,
          iCare_Invoice_Company_Tax_Office__c,
          iCare_Invoiced_Company_Address__City__s,
          iCare_Invoiced_Company_Address__CountryCode__s,
          iCare_Invoiced_Company_Address__PostalCode__s,
          iCare_Invoiced_Company_Address__StateCode__s,
          iCare_Invoiced_Company_Address__Street__s,
          iCare_SupplierLab__r.iCare_Testing_Location_ID__c,
          iCare_SupplierLab__r.Name,
          iCare_Previous_Report_Number__c,
          iCare_Number_of_Samples__c,
          iCare_Order_Number__c,
          iCare_Colour__c,
          iCare_Sample_Description__c,
          iCare_Model_Style_Number__c,
          iCare_End_Use__c,
          iCare_Other_End_Use__c,
          iCare_Child_Age_End_Use__c,
          iCare_Product_Type__c,
          iCare_Other_Product_Type__c,
          iCare_Fabric_Weight__c,
          iCare_Fiber_Composition__c,
          iCare_Season__c,
          iCare_Dimensional_Stability__c,
          Dimensional_Stability_No_of_Washes__c,
          iCare_Colourfastness__c,
          iCare_Physical__c,
          iCare_Chemical__c,
          iCare_Grade__c,
          iCare_Abrasion_Cycle__c,
          iCare_Full_Test_up_to_the_standard__c,
          iCare_Appearance__c,
          Appearance_No_of_Washes__c,
          iCare_Heavy_Metals__c,
          iCare_Pilling_ASTM_ISO_Cycle_Hours__c,
          iCare_Pilling_ICI_ISO_Cycle_Hours__c,
          iCare_Care_Label_Control__c,
          iCare_Care_Label_Recommendation__c,
          iCare_Care_Label_Display_Mode__c,
          iCare_Print_Durability__c,
          Print_Durability_No_of_Washes__c,
          iCare_Spirality__c,
          Spirality_No_of_Washes__c,
          iCare_Other_Tests__c,
          iCare_Shrinkage__c,
          iCare_Footwear__c,
          Special_Request__c,
          iCare_Specimen_Return_Request__c,
          iCare_Type_of_Finish__c,
          iCare_Type_of_Print__c,
          iCare_Standard_Selection__c,
          After_Dry_Cleaning_No_of_Washes__c,
          After_Washing_No_Washes__c,
          Dry_Cleaning_No_of_Washes__c,
          Steaming_No_of_Washes__c,
          iCare_Pilling_Martindale_ISO_Cycle_Hours__c,
          iCare_Other_Organic_Tin_Cmp__c,
          iCare_Form_Completion_Date__c,
          iCare_Other_Test_Packages__c,
          iCare_Test_Packages__c,
          Owner.Name,
          Owner.Email,
          Owner.Phone,
          (
            SELECT
              Id,
              iCare_Buyer_Program__r.iCare_Buyer_Code__c,
              iCare_Buyer_Program__r.Name,
              iCare_Buyer_Program__c
            FROM Jobs__r
            WHERE Id = :jobList[0].Id
          ),
          (
            SELECT Id, iCare_Job_Request__c, iCare_Care_Label__c
            FROM Care_Label_Junctions__r
          )
        FROM icare_Job_Request__c
        WHERE Id = :jobList[0].iCare_ETRF__c
      ];

      Boolean originNirvana = jobReq.iCare_Form_Version__c == null ||
        (jobReq.iCare_Form_Version__c != null &&
        jobReq.iCare_Form_Version__c == 'TR')
        ? true
        : false;

      // headers
      Map<String, String> headersMap = new Map<String, String>();
      this.setHeaders(originNirvana ? 'Create_Job_Nirvana' : 'Create_Job_TIPS');

      if (!Test.isRunningTest() && !this.integrationDetails.Is_Active__c) {
        return;
      }

      headersMap.put('etrfNumber', jobReq.Name);
      headersMap.put('jobId', jobList[0].Id);
      headersMap.put('jobNumber', jobList[0].iCare_Job_ID__c);
      headersMap.put('testingLocationCode', originNirvana ? 'nirvana' : 'tips');

      iCare_JobRequestWrapper wrapper = new iCare_JobRequestWrapper();
      iCare_JobRequestWrapper.JobRequestHeader jobRequestHeader = new iCare_JobRequestWrapper.JobRequestHeader();
      iCare_JobRequestWrapper.Agency agency = new iCare_JobRequestWrapper.Agency();
      iCare_JobRequestWrapper.ApplicantInformation applicantInformation = new iCare_JobRequestWrapper.ApplicantInformation();
      iCare_JobRequestWrapper.ApplicantInformation invoicingInformation = new iCare_JobRequestWrapper.ApplicantInformation();
      iCare_JobRequestWrapper.Address address = new iCare_JobRequestWrapper.Address();
      iCare_JobRequestWrapper.Account account = new iCare_JobRequestWrapper.Account();
      iCare_JobRequestWrapper.Contact contact = new iCare_JobRequestWrapper.Contact();
      iCare_JobRequestWrapper.BuyerProgramme buyerProgramme = new iCare_JobRequestWrapper.BuyerProgramme();
      iCare_JobRequestWrapper.TestingLocation testingLocation = new iCare_JobRequestWrapper.TestingLocation();
      iCare_JobRequestWrapper.TestsRequired testsRequired = new iCare_JobRequestWrapper.TestsRequired();
      iCare_JobRequestWrapper.Products products = new iCare_JobRequestWrapper.Products();
      iCare_JobRequestWrapper.JobDetails jobDetails = new iCare_JobRequestWrapper.JobDetails();
      iCare_JobRequestWrapper.Samples samples = new iCare_JobRequestWrapper.Samples();

      // Job field mapping
      jobRequestHeader.jobNumber = jobList[0].iCare_Job_ID__c;
      jobRequestHeader.jobDescription = jobList[0].iCare_Job_Description__c;
      jobRequestHeader.etrfNumber = jobReq.Name;
      jobRequestHeader.buyerName = jobReq.iCare_Buyer_Name__c;

      if (
        !jobReq.Jobs__r.isEmpty() &&
        jobReq.Jobs__r[0]?.iCare_Buyer_Program__c != null
      ) {
        buyerProgramme.intertekBuyerId = jobReq.Jobs__r[0]
          ?.iCare_Buyer_Program__r
          ?.iCare_Buyer_Code__c;
        buyerProgramme.buyerAccountName = jobReq.Jobs__r[0]
          ?.iCare_Buyer_Program__r
          ?.Name;
        jobRequestHeader.buyerProgramme = buyerProgramme;
      }

      // Job Request Header field mapping : start
      jobRequestHeader.buyerRegion = jobReq.iCare_Buyer_Region__c;
      jobRequestHeader.otherBuyerRegion = jobReq.iCare_Other_Region__c;
      jobRequestHeader.serviceTerm = jobReq.iCare_Service_Term__c;
      jobRequestHeader.formVersion = jobReq.iCare_Form_Version__c;
      jobRequestHeader.serviceTermRemarks = jobReq.iCare_Service_Term_Remarks__c;
      wrapper.jobRequestHeader = jobRequestHeader;

      // Agency
      agency.agencyName = jobReq.iCare_Agency_Name__c;
      agency.contactName = jobReq.iCare_Agency_Contact_Person_Name__c;
      agency.email = jobReq.iCare_Agency_Email__c;
      agency.fax = jobReq.iCare_Agency_Fax__c;
      agency.telephone = jobReq.iCare_Agency_Telephone_External__c;
      wrapper.jobRequestHeader.agency = agency;

      // Applicant Company
      account.accountName = jobReq.iCare_Applicant_Company__r?.Name;
      account.opsSystemAccountNumber = jobReq.iCare_Applicant_Company__r
        ?.iCare_Supplier_Unique_ID__c;
      if (originNirvana) {
        //account.accountId = jobReq.iCare_Applicant_Company__c;
        //account.nirvanaUniqueId = jobReq.iCare_Applicant_Company__r
        //  ?.iCare_Supplier_Unique_ID__c;
        //IB-7 changes start
        contact.contactFullName = jobReq.Owner.Name;
        contact.contactPhone = jobReq.Owner.Phone;
        contact.contactEmail = jobReq.Owner.Email;
        //IB-7 changes end
      } else {
        contact.contactFullName = jobReq.iCare_Applicant_Company__r
          ?.iCare_Contact_Full_Name__c;
        contact.contactPhone = jobReq.iCare_Applicant_Company__r
          ?.iCare_Contact_Phone__c;
        contact.contactEmail = jobReq.iCare_Applicant_Company__r
          ?.iCare_Contact_Email__c;
      }

      address.city = jobReq.iCare_Applicant_Company__r?.BillingCity;
      address.countryCode = jobReq.iCare_Applicant_Company__r
        ?.BillingCountryCode;
      address.postalCode = jobReq.iCare_Applicant_Company__r?.BillingPostalCode;
      address.stateCode = jobReq.iCare_Applicant_Company__r?.BillingStateCode;
      address.street = jobReq.iCare_Applicant_Company__r?.BillingStreet;
      account.address = address;
      account.contact = contact;
      applicantInformation.account = account;

      String formVersionTranslated = jobReq.iCare_Form_Version__c == 'Türkiye'
        ? 'Turkey'
        : jobReq.iCare_Form_Version__c;

      // Applicant Information
      applicantInformation.email = jobReq.iCare_Applicant_Email__c;
      applicantInformation.contactPersonName = jobReq.iCare_Applicant_Contact_Person_Name__c;
      applicantInformation.fax = jobReq.iCare_Applicant_Fax__c;
      applicantInformation.telephone = jobReq.iCare_Applicant_Telephone_External__c;
      applicantInformation.taxNumber = jobReq.iCare_Applicant_Tax_Office_Number__c;
      applicantInformation.taxOffice = jobReq.iCare_Applicant_Tax_Office__c;
      address = new iCare_JobRequestWrapper.Address();
      address.city = jobReq.iCare_Applicant_Address__City__s;
      address.countryCode = jobReq.iCare_Applicant_Address__CountryCode__s;
      address.postalCode = jobReq.iCare_Applicant_Address__PostalCode__s;
      address.stateCode = jobReq.iCare_Applicant_Address__StateCode__s;
      address.street = jobReq.iCare_Applicant_Address__Street__s;
      applicantInformation.address = address;

      account.opsSystem = iCare_Country_specific_information__mdt.getInstance(
          formVersionTranslated
        )
        ?.iCare_Ops_System__c;
      applicantInformation.account = account;
      wrapper.jobRequestHeader.applicantInformation = applicantInformation;

      // Invoicing Information
      address = new iCare_JobRequestWrapper.Address();
      account = new iCare_JobRequestWrapper.Account();
      contact = new iCare_JobRequestWrapper.Contact();
      if (jobReq.iCare_Company_to_be_invoiced__c != null) {
        account.accountName = jobReq.iCare_Company_to_be_invoiced__r?.Name;
        account.opsSystemAccountNumber = jobReq.iCare_Company_to_be_invoiced__r
          ?.iCare_Supplier_Unique_ID__c;
        if (originNirvana) {
          //account.accountNumber = jobReq.iCare_Company_to_be_invoiced__r
          //  ?.AccountNumber;
          //account.accountId = jobReq.iCare_Company_to_be_invoiced__c;
          //account.nirvanaUniqueId = jobReq.iCare_Company_to_be_invoiced__r
          //  ?.iCare_Supplier_Unique_ID__c;
          //IB-7 changes start
          contact.contactFullName = jobReq.Owner.Name;
          contact.contactPhone = jobReq.Owner.Phone;
          contact.contactEmail = jobReq.Owner.Email;
          //IB-7 changes end
        } else {
          contact.contactFullName = jobReq.iCare_Company_to_be_invoiced__r
            ?.iCare_Contact_Full_Name__c;
          contact.contactPhone = jobReq.iCare_Company_to_be_invoiced__r
            ?.iCare_Contact_Phone__c;
          contact.contactEmail = jobReq.iCare_Company_to_be_invoiced__r
            ?.iCare_Contact_Email__c;
        }
      } else {
        account = null;
      }
      if (account != null) {
        account.opsSystem = iCare_Country_specific_information__mdt.getInstance(
            formVersionTranslated
          )
          ?.iCare_Ops_System__c;
        address.city = jobReq.iCare_Company_to_be_invoiced__r?.BillingCity;
        address.countryCode = jobReq.iCare_Company_to_be_invoiced__r
          ?.BillingCountryCode;
        address.postalCode = jobReq.iCare_Company_to_be_invoiced__r
          ?.BillingPostalCode;
        address.stateCode = jobReq.iCare_Company_to_be_invoiced__r
          ?.BillingStateCode;
        address.street = jobReq.iCare_Company_to_be_invoiced__r?.BillingStreet;
        account.address = address;
        account.contact = contact;
        invoicingInformation.account = account;
      }

      invoicingInformation.email = jobReq.iCare_Invoiced_Company_Email__c;
      invoicingInformation.contactPersonName = jobReq.iCare_Invoiced_Co_Contact_Person_Name__c;
      invoicingInformation.fax = jobReq.iCare_Invoiced_Company_Fax__c;
      invoicingInformation.telephone = jobReq.iCare_Invoiced_Co_Telephone_External__c;
      invoicingInformation.taxNumber = jobReq.iCare_Invoiced_Company_Tax_Office_Number__c;
      invoicingInformation.taxOffice = jobReq.iCare_Invoice_Company_Tax_Office__c;
      address = new iCare_JobRequestWrapper.Address();
      address.city = jobReq.iCare_Invoiced_Company_Address__City__s;
      address.countryCode = jobReq.iCare_Invoiced_Company_Address__CountryCode__s;
      address.postalCode = jobReq.iCare_Invoiced_Company_Address__PostalCode__s;
      address.stateCode = jobReq.iCare_Invoiced_Company_Address__StateCode__s;
      address.street = jobReq.iCare_Invoiced_Company_Address__Street__s;
      invoicingInformation.address = address;
      wrapper.jobRequestHeader.invoicingInformation = invoicingInformation;

      // testingLocation
      testingLocation.locationCode = jobReq.iCare_SupplierLab__r
        ?.iCare_Testing_Location_ID__c;
      testingLocation.locationName = jobReq.iCare_SupplierLab__r?.Name;
      testingLocation.systemInstance = iCare_Country_specific_information__mdt.getInstance(
          formVersionTranslated
        )
        ?.iCare_System_Instance__c;
      wrapper.jobRequestHeader.testingLocation = testingLocation;
      // Job Request Header field mapping : end

      // jobDetails field mapping
      jobDetails.previousReportNumber = jobReq.iCare_Previous_Report_Number__c;
      products.numberOfSamples = Integer.valueOf(
        jobReq.iCare_Number_of_Samples__c
      );
      products.orderNumber = jobReq.iCare_Order_Number__c;
      products.season = jobReq.iCare_Season__c;
      products.additionalCareLabels = jobReq.iCare_Additional_Instructions__c;
      products.careLabelControl = jobReq.iCare_Care_Label_Control__c;
      products.otherStatement = jobReq.iCare_Other_Statement__c;
      products.commentOnTestResult = jobReq.iCare_Comment_on_Test_Result__c;
      products.careLabelRecommend = jobReq.iCare_Care_Label_Recommendation__c;
      products.careLabelDisplayMode = jobReq.iCare_Care_Label_Display_Mode__c;
      samples.colour = jobReq.iCare_Colour__c;
      samples.sampleDescription = jobReq.iCare_Sample_Description__c;
      samples.modelNumber = jobReq.iCare_Model_Style_Number__c;
      samples.endUse = jobReq.iCare_End_Use__c;
      samples.endUseOther = jobReq.iCare_Other_End_Use__c;
      samples.endUseChildAge = jobReq.iCare_Child_Age_End_Use__c != null
        ? String.valueOf(jobReq.iCare_Child_Age_End_Use__c)
        : null;
      samples.productType = jobReq.iCare_Product_Type__c;
      samples.otherProductType = jobReq.iCare_Other_Product_Type__c;
      samples.fabricWeight = jobReq.iCare_Fabric_Weight__c != null
        ? String.valueOf(jobReq.iCare_Fabric_Weight__c)
        : null;
      samples.fabricUnits = jobReq.iCare_Fabric_Units__c;
      samples.fibreComposition = jobReq.iCare_Fiber_Composition__c;
      samples.manufacturerName = jobReq.iCare_Manufacturer_Name__c;
      products.samples = new List<iCare_JobRequestWrapper.Samples>();
      products.samples.add(samples);

      testsRequired.dimensionalStability = jobReq.iCare_Dimensional_Stability__c;
      testsRequired.dimensionalStabilityNumberOfWashes = Integer.valueOf(
        jobReq.Dimensional_Stability_No_of_Washes__c
      );
      testsRequired.appearance = jobReq.iCare_Appearance__c;
      testsRequired.appearanceNumberOfWashes = Integer.valueOf(
        jobReq.Appearance_No_of_Washes__c
      );
      testsRequired.printDurability = jobReq.iCare_Print_Durability__c;
      testsRequired.printDurabilityNumberOfWashes = Integer.valueOf(
        jobReq.Print_Durability_No_of_Washes__c
      );
      testsRequired.spirality = jobReq.iCare_Spirality__c;
      testsRequired.spiralityNumberOfWashes = Integer.valueOf(
        jobReq.Spirality_No_of_Washes__c
      );
      testsRequired.colourfastness = jobReq.iCare_Colourfastness__c;
      testsRequired.physical = jobReq.iCare_Physical__c;
      testsRequired.chemical = jobReq.iCare_Chemical__c;
      testsRequired.lightGrade = jobReq.iCare_Grade__c;
      testsRequired.abrasionCycles = Integer.valueOf(
        jobReq.iCare_Abrasion_Cycle__c
      );
      testsRequired.fullTestUpToTheStandard = Boolean.valueOf(
        jobReq.iCare_Full_Test_up_to_the_standard__c
      );
      testsRequired.heavyMetals = jobReq.iCare_Heavy_Metals__c;
      testsRequired.pillingASTMISOCycleHours = Integer.valueOf(
        jobReq.iCare_Pilling_ASTM_ISO_Cycle_Hours__c
      );
      testsRequired.pillingICIISOCycleHours = Integer.valueOf(
        jobReq.iCare_Pilling_ICI_ISO_Cycle_Hours__c
      );
      testsRequired.pillingMartindaleISOCycleHours = Integer.valueOf(
        jobReq.iCare_Pilling_Martindale_ISO_Cycle_Hours__c
      );
      testsRequired.otherOrganicTinComposition = jobReq.iCare_Other_Organic_Tin_Cmp__c;
      testsRequired.shrinkage = jobReq.iCare_Shrinkage__c;
      testsRequired.footwear = jobReq.iCare_Footwear__c;
      testsRequired.afterDryCleaningNoOfWashes = Integer.valueOf(
        jobReq.After_Dry_Cleaning_No_of_Washes__c
      );
      testsRequired.afterWashingNoWashes = Integer.valueOf(
        jobReq.After_Washing_No_Washes__c
      );
      testsRequired.dryCleaningNoOfWashes = Integer.valueOf(
        jobReq.Dry_Cleaning_No_of_Washes__c
      );
      testsRequired.steamingNoOfWashes = Integer.valueOf(
        jobReq.Steaming_No_of_Washes__c
      );
      testsRequired.typeOfPrint = jobReq.iCare_Type_of_Print__c;
      testsRequired.typeOfFinish = jobReq.iCare_Type_of_Finish__c;
      testsRequired.standardSelection = jobReq.iCare_Standard_Selection__c;
      jobDetails.formCompletionDate = jobReq.iCare_Form_Completion_Date__c !=
        null
        ? String.valueOf(
            jobReq.iCare_Form_Completion_Date__c.formatGMT(
              'yyyy-MM-dd\'T\'HH:mm:ss\'Z\''
            )
          )
        : null;
      jobDetails.otherTestPackages = jobReq.iCare_Other_Test_Packages__c != null
        ? String.valueOf(jobReq.iCare_Other_Test_Packages__c)
        : null;
      jobDetails.otherTests = jobReq.iCare_Other_Tests__c;
      jobDetails.specialRequests = jobReq.Special_Request__c;
      jobDetails.testPackagesRequired = jobReq.iCare_Test_Packages__c;
      jobDetails.specimenReturnRequest = jobReq.iCare_Specimen_Return_Request__c;

      // Care Label field mapping
      if (!jobReq.Care_Label_Junctions__r.isEmpty()) {
        Set<Id> careLabIdSet = new Set<Id>();
        products.careLabels = new List<iCare_JobRequestWrapper.CareLabels>();

        for (
          iCare_Care_Label_Junction__c careLabJun : jobReq.Care_Label_Junctions__r
        ) {
          careLabIdSet.add(careLabJun.iCare_Care_Label__c);
        }

        for (iCare_Care_Label__c careLabel : [
          SELECT
            Id,
            Name,
            iCare_Category__c,
            iCare_Country__c,
            iCare_Country_Code__c,
            iCare_English_Wordings__c,
            iCare_File_Name__c,
            iCare_Localised_Wordings__c,
            iCare_Pictogram__c,
            iCare_Standard__c,
            icare_statementCode__c,
            iCare_Sub_Category__c
          FROM iCare_Care_Label__c
          WHERE Id IN :careLabIdSet
        ]) {
          iCare_JobRequestWrapper.CareLabels careLabels = new iCare_JobRequestWrapper.CareLabels();
          careLabels.careLabelId = careLabel.Id;
          careLabels.careLabelStandardCode = careLabel.iCare_Standard__c;
          careLabels.countryCode = careLabel.iCare_Country_Code__c;
          products.careLabelCountry = careLabel.iCare_Country_Code__c;
          careLabels.category = careLabel.iCare_Category__c;
          careLabels.subCategory = careLabel.iCare_Sub_Category__c;
          careLabels.pictogram = careLabel.iCare_File_Name__c;
          careLabels.statementCode = careLabel.icare_statementCode__c;
          careLabels.localisedStatementText = careLabel.iCare_Localised_Wordings__c;
          products.careLabels.add(careLabels);
        }
      }
      jobDetails.testsRequired = testsRequired;
      jobDetails.products = new List<iCare_JobRequestWrapper.Products>();
      jobDetails.products.add(products);
      wrapper.jobDetails = jobDetails;

      String payload = JSON.serialize(wrapper, true);

      // basic Callout
      String response = this.callOut(payload);
      Integer intStatusCode = this.statusCode();

      // to insert the logs
      auditLogList.add(
        new iCare_Integration_Audit_Log__c(
          iCare_Request_Payload__c = payload,
          iCare_Response_Payload__c = response.substringAfter(':responseBody:'),
          iCare_Integration_Reference__c = originNirvana
            ? Label.iCare_Job_Request_IntegRef
            : Label.iCare_JobRequest_IntegRef_TIPS,
          iCare_Job__c = jobList[0].Id,
          iCare_Sync_Status__c = intStatusCode == 200 ? 'Success' : 'Failure'
        )
      );

      // process the next record by calling Queuable constructor
      if (!jobList.isEmpty() && jobList.size() > 1) {
        jobList.remove(0);
        new GTS_QueueJob().excuteClass(jobList, auditLogList, context);
      } else {
        insert auditLogList;
      }
    } catch (Exception ex) {
      // to insert the logs
      insert new iCare_Integration_Audit_Log__c(
        iCare_Response_Payload__c = ex.getStackTraceString() +
          ' : ' +
          ex.getMessage(),
        iCare_Integration_Reference__c = Label.iCare_Job_Request_IntegRef,
        iCare_Job__c = jobList[0].Id,
        iCare_Sync_Status__c = 'Failure'
      );
    }
  }
}