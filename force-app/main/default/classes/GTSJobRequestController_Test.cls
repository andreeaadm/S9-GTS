/********************************************************************************************
 * @Name         GTSJobRequestController_Test
 * @Author       Globant
 * @Created      05-Mar-2024
 * @Description  Test class for GTSJobRequestController.
 *
 *********************************************************************************************/
@isTest
public class GTSJobRequestController_Test {
  @TestSetup
  static void createData() {
    Id certConfRecordTypeId = Schema.SObjectType.iCare_Job__c.getRecordTypeInfosByDeveloperName()
      .get('GTS_Certificate_of_Conformity')
      .getRecordTypeId();
    // Create a test job
    iCare_Job__c objJob = new iCare_Job__c();
    objJob.GTS_Request_for_Inspection_Number__c = 'TestInspectionNumber';
    objJob.RecordtypeId = CertConfRecordTypeId;
    insert objJob;

    // Create Job Timestamps
    icare_Job_Timestamp__c objJobTS = new icare_Job_Timestamp__c();
    objJobTS.iCare_Job__c = objJob.Id;
    objJobTS.iCare_External_Id__c = '123';
    objJobTS.iCare_Job_Status__c = System.Label.GTS_Cancelled;
    objJobTS.iCare_Job_Timestamp__c = datetime.now();
    insert objJobTS;

    // Create Shipment(Certificate) Timestamps
    GTS_Certificate__c objCert = new GTS_Certificate__c();
    objCert.Name = 'New Certificate';
    objCert.GTS_Job__c = objJob.Id;
    insert objCert;

    ContentVersion objContVer = new ContentVersion();
    objContVer.VersionData = Blob.valueOf('Test file content');
    objContVer.Title = 'Test File';
    objContVer.PathOnClient = 'TestFile.txt';
    insert objContVer;

    String strDocumentId = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :objContVer.Id
      LIMIT 1
    ]
    .ContentDocumentId;

    Id certConfRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName()
      .get('GTS_Certificate_of_Conformity_Request')
      .getRecordTypeId();
    List<icare_Job_Request__c> lstJRCreate = new List<icare_Job_Request__c>();
    icare_Job_Request__c objJobReq = new icare_Job_Request__c();
    objJobReq.iCare_Favourite_Name__c = 'FavTest';
    objJobReq.iCare_Draft_ETRF__c = false;
    objJobReq.RecordTypeId = certConfRecTypeId;
    lstJRCreate.add(objJobReq);

    Id licenseRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName()
      .get('GTS_Registration_License_Product_Certificate_Request')
      .getRecordTypeId();
    icare_Job_Request__c objJobReq2 = new icare_Job_Request__c();
    objJobReq2.RecordTypeId = licenseRecTypeId;
    objJobReq2.iCare_Draft_ETRF__c = true;
    lstJRCreate.add(objJobReq2);

    insert lstJRCreate;

    ContentDocumentLink objContDocLnk = new ContentDocumentLink();
    objContDocLnk.ContentDocumentId = strDocumentId;
    objContDocLnk.LinkedEntityId = objJobReq.Id;
    objContDocLnk.ShareType = 'V';
    insert objContDocLnk;
  }

  @isTest
  static void getCertTest() {
    Test.startTest();
    String strCert = GTSJobRequestController.getCertifications();
    Test.stopTest();

    System.assertNotEquals(
      null,
      strCert,
      'The returned certificate should not be null.'
    );
  }

  @isTest
  static void getContDocVerDraftJRTest() {
    List<icare_Job_Request__c> lstJobReq = [
      SELECT Id
      FROM icare_Job_Request__c
      LIMIT 1
    ];
    Test.startTest();
    List<Id> lstContVerId = GTSJobRequestController.getContentDocumentVersion(
      lstJobReq.get(0).Id
    );
    icare_Job_Request__c objJRDraft = new icare_Job_Request__c();
    objJRDraft = GTSJobRequestController.createDraftJobRequest(
      objJRDraft,
      'GTS_Certificate_of_Conformity_Request'
    );
    List<icare_Job_Request__c> lstJR = GTSJobRequestController.getJobRequests();
    List<icare_Job_Request__c> lstJRAllDraft = GTSJobRequestController.getAllDraftJobRequests(
      1,
      1
    );
    List<icare_Job_Request__c> lstJRAllFav = GTSJobRequestController.getAllFavJobRequests(
      1,
      1
    );
    icare_Job_Request__c objJR = GTSJobRequestController.getJobRequest(
      lstJobReq.get(0).Id
    );
    Integer intTotalJRFav = GTSJobRequestController.totalRecords(true);
    Integer intTotalJRDraft = GTSJobRequestController.totalRecords(false);
    Test.stopTest();

    System.assertEquals(
      1,
      lstContVerId.size(),
      'There should be one content version Id.'
    );
  }

  @isTest
  static void getMandFieldsTest() {
    Test.startTest();
    List<String> lstMandFields = GTSJobRequestController.getMandatoryFieldsFromProgramName(
      'TANZANIA PVOC - TAZ'
    );
    Test.stopTest();

    System.assertEquals(
      false,
      lstMandFields.isEmpty(),
      'There should be mandatory fields on the list.'
    );
  }
  @isTest
  static void getRecordTypeByApiNameTest() {
    Test.startTest();
    String recordTypeId = GTSJobRequestController.getRecordTypeByApiName('GTS_Certificate_of_Conformity_Request	');
    Test.stopTest();

    System.assert(
      recordTypeId != null && !String.isEmpty(recordTypeId),
      'There should be a RecordTypeId returned.'
    );
  }
}