@isTest
private class GTSFileDownloadController_Test {
  private static final String METADATA_NAME_FOR_CONTENT_URL = 'URL_Portal_ContentDownload';
  private static final String FILE_NAME = 'TestFileDownload';

  @testSetup
  static void setup() {
    RecordType cocRecordType = [
      SELECT Id
      FROM RecordType
      WHERE
        DeveloperName = 'GTS_Certificate_of_Conformity'
        AND SobjectType = 'iCare_Job__c'
    ];

    // Create a test job
    iCare_Job__c jobCOC = new iCare_Job__c(
      RecordTypeId = cocRecordType.Id,
      iCare_Sample_Description__c = 'Certificate of Conformity'
    );
    insert jobCOC;

    // Create a File
    // Create a Content Version record
    ContentVersion cv = new ContentVersion();
    cv.ContentLocation = 'S';
    cv.Title = FILE_NAME;
    cv.PathOnClient = 'PathFileDownloadTest.pdf';
    cv.VersionData = Blob.valueOf('Test PDF File Content');
    cv.GTS_Document_Type__c = 'Type1';
    cv.GTS_Document_Super_Type__c = 'Certificate';
    insert cv;

    List<ContentDocument> cntDocuments = [
      SELECT Id, Title
      FROM ContentDocument
    ];

    // Create Content Document Link record
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.LinkedEntityId = jobCOC.Id;
    cdl.ContentDocumentId = cntDocuments[0].Id;
    cdl.shareType = 'V';
    insert cdl;
  }

  @isTest
  static void getRelatedFilesByRecordId_test() {
    iCare_Portal__mdt contentUrlSetting = iCare_Portal__mdt.getAll()
      .get(METADATA_NAME_FOR_CONTENT_URL);

    Id jobId = [SELECT Id FROM iCare_Job__c LIMIT 1].Id;

    Test.startTest();
    String result = GTSFileDownloadController.getRelatedFilesByRecordId(jobId);
    Test.stopTest();

    System.assert(result != null, 'No response received');

    List<GTSFileDownloadController.FileWrapper> fileWrappersResponse = (List<GTSFileDownloadController.FileWrapper>) JSON.deserialize(
      result,
      List<GTSFileDownloadController.FileWrapper>.class
    );

    // Verify the expected results
    System.assertEquals(
      1,
      fileWrappersResponse.size(),
      'The number of records should be 1'
    );
  }

  @isTest
  static void getCongaDocumentDownloadLink_test() {
    iCare_Portal__mdt contentUrlSetting = iCare_Portal__mdt.getAll()
      .get(METADATA_NAME_FOR_CONTENT_URL);

    Id jobId = [SELECT Id FROM iCare_Job__c LIMIT 1].Id;

    ContentVersion cv = new ContentVersion();
    cv.ContentLocation = 'S';
    cv.Title = 'CAP-FRM-0001';
    cv.PathOnClient = 'CAP-FRM-0001.pdf';
    cv.VersionData = Blob.valueOf('Test PDF File Content');
    cv.GTS_Document_Type__c = 'Type1';
    insert cv;

    ContentVersion congaContentVersion = [
      SELECT Id, ContentDocument.Id
      FROM ContentVersion
      WHERE Id = :cv.Id
      LIMIT 1
    ];

    // Create Content Document Link record
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.LinkedEntityId = jobId;
    cdl.ContentDocumentId = congaContentVersion.ContentDocument.Id;
    cdl.shareType = 'V';
    insert cdl;

    Test.startTest();
    String fileLink = GTSFileDownloadController.getCongaDocumentDownloadLink(
      jobId
    );
    Test.stopTest();

    // Verify the expected results
    System.assertNotEquals(null, fileLink, 'The file link should not be null');
    System.assertEquals(
      true,
      fileLink.startsWith(contentUrlSetting.Variable_Value__c),
      contentUrlSetting.Variable_Value__c
    );
  }

  @isTest
  static void getCertificate_test() {
    iCare_Portal__mdt contentUrlSetting = iCare_Portal__mdt.getAll()
      .get(METADATA_NAME_FOR_CONTENT_URL);

    Id jobId = [SELECT Id FROM iCare_Job__c LIMIT 1].Id;

    Test.startTest();
    String result = GTSFileDownloadController.getCertificate(jobId);
    Test.stopTest();

    System.assert(result != null, 'No response received');
  }
}