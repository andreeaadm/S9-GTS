@IsTest
public class iCare_TestDataFactory {
  public static Account createICareCustomerAccount(Boolean doInsert) {
    Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('iCare_Customer')
      .getRecordTypeId();

    Account objAccount = new Account();
    objAccount.Name = 'iCare Account Inc';
    objAccount.AccountNumber = 'Icare-0401';
    objAccount.iCare_Supplier_Unique_ID__c = 'iCare-TR-01';
    objAccount.iCare_Contact_Full_Name__c = 'Nick Gareth';
    objAccount.iCare_Contact_Phone__c = '+90 (422) 237 54 50';
    objAccount.iCare_Contact_Email__c = 'Nick.Gareth@intertek.com';
    objAccount.BillingCity = 'Buca Izmir';
    objAccount.BillingCountryCode = 'TR';
    objAccount.BillingPostalCode = '35390';
    objAccount.BillingStreet = '1409 Sok. No:34 D:19 Buca Koop Mah.';
    objAccount.RecordTypeId = recordTypeId;

    if (doInsert) {
      insert objAccount;
    }
    return objAccount;
  }

  public static icare_Buyer_Program__c createBuyerProgram(Boolean doInsert) {
    icare_Buyer_Program__c buyerProgram = new icare_Buyer_Program__c(
      Name = 'Test Buyer Program',
      iCare_Buyer_Code__c = 'M&S Clothing',
      iCare_Interlink_Buyer_Code__c = 'dfd79547-d143-47b6-919e'
    );
    if (doInsert) {
      insert buyerProgram;
    }
    return buyerProgram;
  }

  public static List<iCare_Job__c> createJobs(
    Integer nrOfRecords,
    Id accountId,
    Id jobRequest,
    Boolean doInsert
  ) {
    List<iCare_Job__c> jobs = new List<iCare_Job__c>();
    for (Integer i = 0; i < nrOfRecords; i++) {
      iCare_Job__c job = new iCare_Job__c(
        iCare_Job_ID__c = '123456' + i,
        iCare_Job_Description__c = 'Enso Subject' + i,
        iCare_ETRF__c = jobRequest,
        iCare_Job_Outcome__c = 'Pass',
        iCare_Job_Status__c = 'Test Report Issued',
        iCare_Supplier__c = accountId
      );
      jobs.add(job);
    }
    if (doInsert) {
      insert jobs;
    }
    return jobs;
  }

  public static icare_Job_Request__c createJobRequest(
    Id accountId,
    Boolean doInsert
  ) {
    icare_Job_Request__c jobRequest = new icare_Job_Request__c();
    jobRequest.iCare_Agency_Name__c = 'Holmes Agency';
    jobRequest.iCare_Agency_Contact_Person_Name__c = 'Terry Holmes';
    jobRequest.iCare_Agency_Email__c = 'Terry.Holmes@holmes.co.uk';
    jobRequest.iCare_Agency_Fax__c = '+90 (422) 237 54 87';
    jobRequest.iCare_Agency_Telephone_External__c = '+90 (422) 237 54 64';
    jobRequest.iCare_Buyer_Region__c = 'Other';
    jobRequest.iCare_Other_Region__c = 'APAC';
    jobRequest.iCare_Applicant_Company__c = accountId;
    jobRequest.iCare_Applicant_Email__c = 'Nick.Gareth@intertek.com';
    jobRequest.iCare_Applicant_Contact_Person_Name__c = 'Nick Gareth';
    jobRequest.iCare_Applicant_Fax__c = '+90 (422) 237 54 58';
    jobRequest.iCare_Applicant_Telephone_External__c = '+90 (422) 237 54 51';
    jobRequest.iCare_Applicant_Tax_Office_Number__c = '+90 (422) 237 54 01';
    jobRequest.iCare_Applicant_Tax_Office__c = 'INC-TUR-01';
    jobRequest.iCare_Applicant_Address__City__s = 'Buca Izmir';
    jobRequest.iCare_Applicant_Address__CountryCode__s = 'US';
    jobRequest.iCare_Applicant_Address__PostalCode__s = '35390';
    jobRequest.iCare_Applicant_Address__StateCode__s = 'AK';
    jobRequest.iCare_Applicant_Address__Street__s = '1409 Sok. No:34 D:19 Buca Koop Mah.';
    jobRequest.iCare_Company_to_be_invoiced__c = accountId;
    jobRequest.iCare_Invoiced_Company_Email__c = 'Tiffany.Gareth@intertek.com';
    jobRequest.iCare_Invoiced_Co_Contact_Person_Name__c = 'Tiffany Gareth';
    jobRequest.iCare_Invoiced_Company_Fax__c = '+90 (422) 237 54 81';
    jobRequest.iCare_Invoiced_Co_Telephone_External__c = '+90 (422) 237 54 51';
    jobRequest.iCare_Invoiced_Company_Tax_Office_Number__c = '+90 (422) 237 54 00';
    jobRequest.iCare_Invoice_Company_Tax_Office__c = 'INC-TUR-02';
    jobRequest.iCare_Invoiced_Company_Address__City__s = 'Yeşilyurt';
    jobRequest.iCare_Invoiced_Company_Address__CountryCode__s = 'US';
    jobRequest.iCare_Invoiced_Company_Address__PostalCode__s = '44900';
    jobRequest.iCare_Invoiced_Company_Address__StateCode__s = 'AK';
    jobRequest.iCare_Invoiced_Company_Address__Street__s = 'Street 44900 Yeşilyurt';
    jobRequest.iCare_Previous_Report_Number__c = 'TUR-01-X11';
    jobRequest.iCare_Number_of_Samples__c = 4;
    jobRequest.iCare_Order_Number__c = 'Order-3467';
    jobRequest.iCare_Colour__c = 'Blue';
    jobRequest.iCare_Sample_Description__c = 'Test Sample DEscription';
    jobRequest.iCare_Model_Style_Number__c = '7293-B';
    jobRequest.iCare_End_Use__c = 'Woman;Man';
    jobRequest.iCare_Other_End_Use__c = '';
    jobRequest.iCare_Child_Age_End_Use__c = '14';
    jobRequest.iCare_Product_Type__c = 'Trousers';
    jobRequest.iCare_Other_Product_Type__c = '';
    jobRequest.iCare_Fabric_Weight__c = '48';
    jobRequest.iCare_Fiber_Composition__c = '90% cotton, 10% Nylon';
    jobRequest.iCare_Season__c = 'Spring';
    jobRequest.iCare_Dimensional_Stability__c = 'Dry Cleaning';
    jobRequest.iCare_Colourfastness__c = 'Dry Cleaning';
    jobRequest.iCare_Physical__c = 'Tensile Strength';
    jobRequest.iCare_Chemical__c = 'pH value';
    jobRequest.iCare_Grade__c = '10';
    jobRequest.iCare_Abrasion_Cycle__c = 4;
    jobRequest.iCare_Full_Test_up_to_the_standard__c = true;
    jobRequest.iCare_Form_Version__c = 'TR';
    jobRequest.iCare_Appearance__c = 'After Washing';
    jobRequest.iCare_Heavy_Metals__c = 'Heavy Metals in Packaging (CONEG)';
    jobRequest.iCare_Pilling_ASTM_ISO_Cycle_Hours__c = 5;
    jobRequest.iCare_Pilling_ICI_ISO_Cycle_Hours__c = 4;
    jobRequest.iCare_Pilling_Martindale_ISO_Cycle_Hours__c = 4;
    jobRequest.iCare_Other_Organic_Tin_Cmp__c = 'Other';
    jobRequest.iCare_Form_Completion_Date__c = System.now();
    jobRequest.iCare_Other_Test_Packages__c = '10';
    jobRequest.iCare_Test_Packages__c = 'CPSIA Lead';
    jobRequest.iCare_Service_Term__c = 'Same Day';

    if (doInsert) {
      insert jobRequest;
    }
    return jobRequest;
  }

  public static icare_Job_Timestamp__c createTimeStamp(
    Id jobId,
    Boolean doInsert
  ) {
    icare_Job_Timestamp__c timestamp = new icare_Job_Timestamp__c(
      iCare_Job__c = jobId,
      iCare_Job_Status__c = 'Test Report Issued',
      iCare_External_Id__c = 'test' + jobId,
      iCare_Job_Timestamp__c = Datetime.now().addDays(-5)
    );
    if (doInsert) {
      insert timestamp;
    }
    return timestamp;
  }

  public static Testing_Location__c createTestLocation(
    Id accountId,
    Boolean doInsert
  ) {
    Testing_Location__c testLocation = new Testing_Location__c(
      Name = 'Turkey',
      iCare_Laboratory_Site_Code__c = 'MUM',
      iCare_Testing_Location_ID__c = 'EMEA-TUR-IST',
      iCare_Account__c = accountId
    );
    if (doInsert) {
      insert testLocation;
    }
    return testLocation;
  }
}