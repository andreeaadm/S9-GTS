/*******************************************************************************************
 * @Name         iCare_JobTriggerHandlerTest
 * @Author       Praveen Kumar R
 * @Description  This acts as the test class to iCare_JobTrigger, iCare_JobTriggerHandler, iCare_JobRequestQueuable.
 *******************************************************************************************/
@isTest
public class iCare_JobTriggerHandlerTest {
  @TestSetup
  static void createData() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      TestDataFactory.createAdminUser();
    }
    // Applicant Information
    Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('iCare_Customer')
      .getRecordTypeId();

    List<Account> objAccounts = create_iCareAccounts();
    insert objAccounts;
      System.debug('new accounts: '+[Select Id, BillingAddress, BillingCountryCode,BillingCountry FROM Account with system_mode]);
    // Testing Location
    Testing_Location__c objTestingLoc = new Testing_Location__c(
      Name = 'Turkey',
      iCare_Testing_Location_ID__c = 'EMEA-TUR-IST',
      iCare_Account__c = objAccounts[0].Id,
      iCare_Laboratory_Site_Code__c = 'IST'
    );
    insert objTestingLoc;

    //Buyer Program
    icare_Buyer_Program__c objBuyerProg = new icare_Buyer_Program__c(
      Name = 'Test Buyer Program',
      iCare_Buyer_Code__c = 'M&S Clothing',
      iCare_Interlink_Buyer_Code__c = 'dfd79547-d143-47b6-919e'
    );
    insert objBuyerProg;

    // Care Label
    iCare_Care_Label__c careLabelSO = createCareLabel();
    insert careLabelSO;

    // Job Request
    icare_Job_Request__c objJobReq = createJobRequest(objAccounts);
    insert objJobReq;

    // Junction object between care label & Job Request
    iCare_Care_Label_Junction__c objCareJunc = createCareLabelJunction(
      careLabelSO,
      objJobReq
    );
    insert objCareJunc;
  }

  static List<Account> create_iCareAccounts() {
    // Applicant Information
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
    objAccount.BillingCountryCode = 'BD';
    objAccount.iCare_Form_Version__c = 'BD';
    objAccount.BillingPostalCode = '35390';
    objAccount.BillingStreet = '1409 Sok. No:34 D:19 Buca Koop Mah.';
    objAccount.RecordTypeId = recordTypeId;

    //Invoice Company Information
    Account accountSO = new Account();
    accountSO.Name = 'Intertek Account Inc';
    accountSO.AccountNumber = 'Icare-0402';
    accountSO.iCare_Supplier_Unique_ID__c = 'iCare-TR-02';
    accountSO.iCare_Contact_Full_Name__c = 'Tiffany Gareth';
    accountSO.iCare_Contact_Phone__c = '+90 (422) 237 54 51';
    accountSO.iCare_Contact_Email__c = 'Tiffany.Gareth@intertek.com';
    accountSO.BillingCity = 'Yeşilyurt';
    accountSO.BillingCountryCode = 'US';
    accountSO.BillingPostalCode = '44900';
    accountSO.BillingStateCode = 'AK';
    accountSO.BillingStreet = 'Street 44900 Yeşilyurt';
    accountSO.RecordTypeId = recordTypeId;

    return new List<Account>{ objAccount, accountSO };
  }

  static iCare_Care_Label__c createCareLabel() {
    // Care Label
    iCare_Care_Label__c careLabelSO = new iCare_Care_Label__c();
    careLabelSO.iCare_Standard__c = 'EUR';
    careLabelSO.iCare_Country_Code__c = 'GB';
    careLabelSO.iCare_Category__c = 'Bleaching';
    careLabelSO.iCare_Sub_Category__c = 'Bleaching';
    careLabelSO.iCare_File_Name__c = 'NUS';
    careLabelSO.iCare_English_Wordings__c = 'Do not wash';
    careLabelSO.iCare_Localised_Wordings__c = 'Do not wash';
    return careLabelSO;
  }

  static icare_Job_Request__c createJobRequest(List<Account> objAccounts) {
    // Job Request
    icare_Job_Request__c objJobReq = new icare_Job_Request__c();
    objJobReq.iCare_Agency_Name__c = 'Holmes Agency';
    objJobReq.iCare_Agency_Contact_Person_Name__c = 'Terry Holmes';
    objJobReq.iCare_Agency_Email__c = 'Terry.Holmes@holmes.co.uk';
    objJobReq.iCare_Agency_Fax__c = '+90 (422) 237 54 87';
    objJobReq.iCare_Agency_Telephone_External__c = '+90 (422) 237 54 64';
    objJobReq.iCare_Buyer_Region__c = 'Other';
    objJobReq.iCare_Other_Region__c = 'APAC';
    objJobReq.iCare_Applicant_Company__c = objAccounts[0].Id;
    objJobReq.iCare_Applicant_Email__c = 'Nick.Gareth@intertek.com';
    objJobReq.iCare_Applicant_Contact_Person_Name__c = 'Nick Gareth';
    objJobReq.iCare_Applicant_Fax__c = '+90 (422) 237 54 58';
    objJobReq.iCare_Applicant_Telephone_External__c = '+90 (422) 237 54 51';
    objJobReq.iCare_Applicant_Tax_Office_Number__c = '+90 (422) 237 54 01';
    objJobReq.iCare_Applicant_Tax_Office__c = 'INC-TUR-01';
    objJobReq.iCare_Applicant_Address__City__s = 'Buca Izmir';
    objJobReq.iCare_Applicant_Address__CountryCode__s = 'US';
    objJobReq.iCare_Applicant_Address__PostalCode__s = '35390';
    objJobReq.iCare_Applicant_Address__StateCode__s = 'AK';
    objJobReq.iCare_Applicant_Address__Street__s = '1409 Sok. No:34 D:19 Buca Koop Mah.';
    objJobReq.iCare_Company_to_be_invoiced__c = objAccounts[1].Id;
    objJobReq.iCare_Invoiced_Company_Email__c = 'Tiffany.Gareth@intertek.com';
    objJobReq.iCare_Invoiced_Co_Contact_Person_Name__c = 'Tiffany Gareth';
    objJobReq.iCare_Invoiced_Company_Fax__c = '+90 (422) 237 54 81';
    objJobReq.iCare_Invoiced_Co_Telephone_External__c = '+90 (422) 237 54 51';
    objJobReq.iCare_Invoiced_Company_Tax_Office_Number__c = '+90 (422) 237 54 00';
    objJobReq.iCare_Invoice_Company_Tax_Office__c = 'INC-TUR-02';
    objJobReq.iCare_Invoiced_Company_Address__City__s = 'Yeşilyurt';
    objJobReq.iCare_Invoiced_Company_Address__CountryCode__s = 'US';
    objJobReq.iCare_Invoiced_Company_Address__PostalCode__s = '44900';
    objJobReq.iCare_Invoiced_Company_Address__StateCode__s = 'AK';
    objJobReq.iCare_Invoiced_Company_Address__Street__s = 'Street 44900 Yeşilyurt';
    objJobReq.iCare_Previous_Report_Number__c = 'TUR-01-X11';
    objJobReq.iCare_Number_of_Samples__c = 4;
    objJobReq.iCare_Order_Number__c = 'Order-3467';
    objJobReq.iCare_Colour__c = 'Blue';
    objJobReq.iCare_Sample_Description__c = 'Test Sample DEscription';
    objJobReq.iCare_Model_Style_Number__c = '7293-B';
    objJobReq.iCare_End_Use__c = 'Woman;Man';
    objJobReq.iCare_Other_End_Use__c = '';
    objJobReq.iCare_Child_Age_End_Use__c = '14';
    objJobReq.iCare_Product_Type__c = 'Trousers';
    objJobReq.iCare_Other_Product_Type__c = '';
    objJobReq.iCare_Fabric_Weight__c = '48';
    objJobReq.iCare_Fiber_Composition__c = '90% cotton, 10% Nylon';
    objJobReq.iCare_Season__c = 'Spring';
    objJobReq.iCare_Dimensional_Stability__c = 'Dry Cleaning';
    objJobReq.iCare_Colourfastness__c = 'Washing';
    objJobReq.iCare_Physical__c = 'Tensile Strength';
    objJobReq.iCare_Chemical__c = 'pH value';
    objJobReq.iCare_Grade__c = '10';
    objJobReq.iCare_Abrasion_Cycle__c = 4;
    objJobReq.iCare_Full_Test_up_to_the_standard__c = true;
    objJobReq.iCare_Form_Version__c = 'IN';
    objJobReq.iCare_Appearance__c = 'After Washing';
    objJobReq.iCare_Pilling_ASTM_ISO_Cycle_Hours__c = 5;
    objJobReq.iCare_Pilling_ICI_ISO_Cycle_Hours__c = 4;
    objJobReq.iCare_Pilling_Martindale_ISO_Cycle_Hours__c = 4;
    objJobReq.iCare_Other_Organic_Tin_Cmp__c = 'Other';
    objJobReq.iCare_Form_Completion_Date__c = System.now();
    objJobReq.iCare_Other_Test_Packages__c = '10';
    objJobReq.iCare_Test_Packages__c = 'CPSIA Lead';
    objJobReq.iCare_Service_Term__c = 'Same Day';

    return objJobReq;
  }

  static iCare_Care_Label_Junction__c createCareLabelJunction(
    iCare_Care_Label__c careLabelSO,
    icare_Job_Request__c objJobReq
  ) {
    // Junction object between care label & Job Request
    iCare_Care_Label_Junction__c objCareJunc = new iCare_Care_Label_Junction__c();
    objCareJunc.iCare_Care_Label__c = careLabelSO.Id;
    objCareJunc.iCare_Job_Request__c = objJobReq.Id;
    return objCareJunc;
  }

  @isTest
  static void triggerTest() {
    Test.startTest();
    icare_Job_Request__c jobReq = [SELECT Id FROM icare_Job_Request__c LIMIT 1];
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Testing_Location__c testingLocation = [
      SELECT Id
      FROM Testing_Location__c
      LIMIT 1
    ];
    Id softLinesRecordTypeId = Schema.SObjectType.iCare_Job__c.getRecordTypeInfosByName()
      .get('Softlines')
      .getRecordTypeId();
    // Set mock callout class
    Test.setMock(HttpCalloutMock.class, new iCare_MockHttpResponseGenerator());

    List<iCare_Job__c> jobList = new List<iCare_Job__c>();
    for (Integer i = 1; i < 3; i++) {
      iCare_Job__c job = new iCare_Job__c(
        iCare_Job_ID__c = 'TUR-IST-2300000000' + i,
        iCare_Job_Description__c = 'Enso Subject' + i,
        iCare_ETRF__c = jobReq.Id,
        iCare_Job_Status__c = 'Job Submitted (iCare)',
        iCare_Supplier__c = acc.Id,
        iCare_Testing_Location__c = testingLocation.Id,
        RecordTypeId = softLinesRecordTypeId
      );
      jobList.add(job);
    }

    insert jobList;

    iCare_Job__c job = [
      SELECT Id, iCare_Retry_Sync__c
      FROM iCare_Job__c
      LIMIT 1
    ];
    job.iCare_Retry_Sync__c = job.iCare_Retry_Sync__c != null
      ? job.iCare_Retry_Sync__c + 1
      : 1;
    update job;

    Test.stopTest();
  }

  @isTest
  static void verifySingleSoftlinesJobId() {
    icare_Job_Request__c jobReq = [SELECT Id FROM icare_Job_Request__c LIMIT 1];
    Account acc = [SELECT Id,BillingAddress , BillingCountryCode, BillingCountry FROM Account LIMIT 1];
      System.debug('test acc'+acc);
    Testing_Location__c testingLocation = [
      SELECT Id, iCare_Laboratory_Site_Code__c
      FROM Testing_Location__c
      LIMIT 1
    ];
      System.debug('testingLocation' + testingLocation);
    Id softLinesRecordTypeId = Schema.SObjectType.iCare_Job__c.getRecordTypeInfosByName()
      .get('Softlines')
      .getRecordTypeId();

    iCare_Job__c jobRecord = new iCare_Job__c(
      iCare_Job_Description__c = 'Subject',
      iCare_ETRF__c = jobReq.Id,
      iCare_Job_Status__c = 'Sample Received',
      iCare_Supplier__c = acc.Id,
      iCare_Testing_Location__c = testingLocation.Id,
      RecordTypeId = softLinesRecordTypeId
    );

    Test.startTest();
    insert jobRecord;
    Test.stopTest();

    //Fetch the Job Id from the newly inserted job
    List<iCare_Job__c> softlinesJobIdList = [
      SELECT iCare_Job_ID__c
      FROM iCare_Job__c
      WHERE RecordTypeId = :softLinesRecordTypeId
    ];

    String currentYearValue = String.valueOf(System.today().year())
      .substring(2);
    String expectedFormat = 'BGD-IST-' + currentYearValue + '0000001';
    System.assertEquals(
      expectedFormat,
      softlinesJobIdList[0].iCare_Job_ID__c,
      'The Job ID did not match the expected format (BGD-IST-...)'
    );
  }

  @isTest
  static void verifyBulkSoftlinesJobIds() {
    icare_Job_Request__c jobReq = [SELECT Id FROM icare_Job_Request__c LIMIT 1];
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Testing_Location__c testingLocation = [
      SELECT Id
      FROM Testing_Location__c
      LIMIT 1
    ];
    Id softLinesRecordTypeId = Schema.SObjectType.iCare_Job__c.getRecordTypeInfosByName()
      .get('Softlines')
      .getRecordTypeId();
    //Insert 200 records
    List<iCare_Job__c> jobList = new List<iCare_Job__c>();
    for (Integer i = 1; i <= 200; i++) {
      iCare_Job__c jobRecord = new iCare_Job__c(
        iCare_Job_Description__c = 'Subject',
        iCare_ETRF__c = jobReq.Id,
        iCare_Job_Status__c = 'Sample Received',
        iCare_Supplier__c = acc.Id,
        iCare_Testing_Location__c = testingLocation.Id,
        RecordTypeId = softLinesRecordTypeId
      );
      jobList.add(jobRecord);
    }

    Test.startTest();
    insert jobList;
    Test.stopTest();

    //Fetch the Job Id from the newly inserted job
    List<iCare_Job__c> softlinesJobIdList = [
      SELECT iCare_Job_ID__c
      FROM iCare_Job__c
      WHERE RecordTypeId = :softLinesRecordTypeId
    ];

    String currentYearValue = String.valueOf(System.today().year())
      .substring(2);
    String expectedFormatFirstRecord =
      'BGD-IST-' +
      currentYearValue +
      '0000001';
    String expectedFormatLastRecord = 'BGD-IST-' + currentYearValue + '0000200';
    System.assertEquals(
      expectedFormatFirstRecord,
      softlinesJobIdList[0].iCare_Job_ID__c,
      'The Job ID on the first job did not match the expected format (BGD-IST-...1)'
    );
    System.assertEquals(
      expectedFormatLastRecord,
      softlinesJobIdList[199].iCare_Job_ID__c,
      'The Job ID on the last job did not match the expected format (BGD-IST-...200)'
    );
  }

  @isTest
  static void verifySingleGTSJobId() {
    icare_Job_Request__c jobReq = [SELECT Id FROM icare_Job_Request__c LIMIT 1];
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Id gtsRecordTypeId = Schema.SObjectType.iCare_Job__c.getRecordTypeInfosByDeveloperName()
      .get('GTS_Certificate_of_Conformity')
      .getRecordTypeId();

    iCare_Job__c jobRecord = new iCare_Job__c(
      iCare_Job_Description__c = 'Subject',
      iCare_ETRF__c = jobReq.Id,
      iCare_Job_Status__c = 'In Progress',
      iCare_Supplier__c = acc.Id,
      RecordTypeId = gtsRecordTypeId
    );

    Test.startTest();
    insert jobRecord;
    Test.stopTest();

    //Fetch the Job Id from the newly inserted job
    List<iCare_Job__c> gtsJobIdList = [
      SELECT iCare_Job_ID__c
      FROM iCare_Job__c
      WHERE RecordTypeId = :gtsRecordTypeId
    ];

    String expectedFormat = 'GTS-000000001';
    System.assertEquals(
      expectedFormat,
      gtsJobIdList[0].iCare_Job_ID__c,
      'The Job ID did not match the expected format (GTS-000...)'
    );
  }

  //In order to verify functionality works for multiple records
  @isTest
  static void verifyTwoGTSJobIds() {
    icare_Job_Request__c jobReq = [SELECT Id FROM icare_Job_Request__c LIMIT 1];
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Id gtsRecordTypeId = Schema.SObjectType.iCare_Job__c.getRecordTypeInfosByDeveloperName()
      .get('GTS_Certificate_of_Conformity')
      .getRecordTypeId();

    iCare_Job__c jobRecord = new iCare_Job__c(
      iCare_Job_Description__c = 'Subject 1',
      iCare_ETRF__c = jobReq.Id,
      iCare_Job_Status__c = 'In Progress',
      iCare_Supplier__c = acc.Id,
      RecordTypeId = gtsRecordTypeId
    );
    insert jobRecord;

    iCare_Job__c secondJobRecord = new iCare_Job__c(
      iCare_Job_Description__c = 'Subject 2',
      iCare_ETRF__c = jobReq.Id,
      iCare_Job_Status__c = 'In Progress',
      iCare_Supplier__c = acc.Id,
      RecordTypeId = gtsRecordTypeId
    );

    Test.startTest();
    insert secondJobRecord;
    Test.stopTest();

    //Fetch the Job Id from the newly inserted job
    List<iCare_Job__c> gtsJobIdList = [
      SELECT iCare_Job_ID__c
      FROM iCare_Job__c
      WHERE Id = :secondJobRecord.Id
    ];

    String expectedFormat = 'GTS-000000002';
    System.assertEquals(
      expectedFormat,
      gtsJobIdList[0].iCare_Job_ID__c,
      'The Job ID did not match the expected format (GTS-000...)'
    );
  }

  @isTest
  static void verifyBulkGTSJobIds() {
    icare_Job_Request__c jobReq = [SELECT Id FROM icare_Job_Request__c LIMIT 1];
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Id gtsRecordTypeId = Schema.SObjectType.iCare_Job__c.getRecordTypeInfosByDeveloperName()
      .get('GTS_Certificate_of_Conformity')
      .getRecordTypeId();

    //Insert 200 records
    List<iCare_Job__c> jobList = new List<iCare_Job__c>();
    for (Integer i = 1; i <= 200; i++) {
      iCare_Job__c jobRecord = new iCare_Job__c(
        iCare_Job_Description__c = 'Subject ' + i,
        iCare_ETRF__c = jobReq.Id,
        iCare_Job_Status__c = 'InProgress',
        iCare_Supplier__c = acc.Id,
        RecordTypeId = gtsRecordTypeId
      );
      jobList.add(jobRecord);
    }

    Test.startTest();
    insert jobList;
    Test.stopTest();

    //Fetch the Job Id from all of the newly inserted jobs
    Set<Id> resultIds = (new Map<Id, SObject>(jobList)).keySet();
    List<iCare_Job__c> gtsJobIdList = [
      SELECT iCare_Job_ID__c
      FROM iCare_Job__c
      WHERE ID IN :resultIds
    ];

    String expectedFormatFirstRecord = 'GTS-000000001';
    String expectedFormatLastRecord = 'GTS-000000200';
    System.assertEquals(
      expectedFormatFirstRecord,
      gtsJobIdList[0].iCare_Job_ID__c,
      'The Job ID on the first job did not match the expected format (GTS-000...)'
    );
    System.assertEquals(
      expectedFormatLastRecord,
      gtsJobIdList[199].iCare_Job_ID__c,
      'The Job ID on the last job did not match the expected format (GTS-000...)'
    );
  }

  @isTest
  static void verifyExternalContacts() {
    icare_Job_Request__c jobReq = [SELECT Id FROM icare_Job_Request__c LIMIT 1];
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Testing_Location__c testingLocation = [
      SELECT Id
      FROM Testing_Location__c
      LIMIT 1
    ];
    Id softLinesRecordTypeId = Schema.SObjectType.iCare_Job__c.getRecordTypeInfosByName()
      .get('Softlines')
      .getRecordTypeId();
    List<Contact> contacts = TestDataFactory.createContacts(2, true, acc.Id);
    List<User> users = TestDataFactory.createCommunityUsers(
      'iCare External Standard User',
      contacts
    );

    List<iCare_JobTriggerHandler.ContactInfo> contactInformation = new List<iCare_JobTriggerHandler.ContactInfo>();
    for (Contact con : contacts) {
      iCare_JobTriggerHandler.ContactInfo contactInfo = new iCare_JobTriggerHandler.ContactInfo();
      contactInfo.FirstName = con.FirstName;
      contactInfo.LastName = con.LastName;
      contactInfo.Email = con.Email;
      contactInformation.add(contactInfo);
    }

    iCare_Job__c jobRecord = new iCare_Job__c(
      iCare_Job_Description__c = 'Subject',
      iCare_ETRF__c = jobReq.Id,
      iCare_Job_Status__c = 'Sample Received',
      iCare_Supplier__c = acc.Id,
      iCare_Testing_Location__c = testingLocation.Id,
      iCare_External_Contacts__c = JSON.serialize(contactInformation),
      RecordTypeId = softLinesRecordTypeId
    );

    Test.startTest();
    insert jobRecord;
    Test.stopTest();

    List<iCare_Job__Share> jobShareRecords = [
      SELECT Id
      FROM iCare_Job__Share
      WHERE AccessLevel = 'Read'
    ];
    System.assertEquals(1, jobShareRecords.size());
  }

  @isTest
  static void jobUtilGTSMethods() {
    //calling empty methods to increase code coverage in the iCare_GTSJobUtil class. Methods are empty as the class implements an interface
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Id gtsRecordTypeId = Schema.SObjectType.iCare_Job__c.getRecordTypeInfosByDeveloperName()
      .get('GTS_Certificate_of_Conformity')
      .getRecordTypeId();

    iCare_Job__c jobRecord = new iCare_Job__c(
      iCare_Job_Description__c = 'Subject',
      iCare_Job_Status__c = 'In Progress',
      iCare_Supplier__c = acc.Id,
      RecordTypeId = gtsRecordTypeId
    );
    insert jobRecord;

    List<iCare_Job__c> jobList = new List<iCare_Job__c>();
    Map<Id, iCare_Job__c> jobMap = new Map<Id, iCare_Job__c>();
    jobList.add(jobRecord);
    jobMap.put(jobRecord.Id, jobRecord);

    iCare_GTSJobUtil gtsClass = new iCare_GTSJobUtil();

    gtsClass.setiCarePortalURL(jobList);
    gtsClass.updatePortalStatusValues(jobList, jobMap);
    gtsClass.translateLabelValue('iCare_Abrasion_Cycle', '');
  }
}