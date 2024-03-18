@IsTest
private class ContentDocumentLinkHandler_Test {
  private static final String METADATA_NAME_FOR_CONTENT_URL = 'URL_Portal_ContentDownload';
  private static final String FILE_NAME = 'TestFileDownload';

  @TestSetup
  static void setup() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Id customerProfileId = [
      SELECT Id
      FROM Profile
      WHERE Name = 'iCare External Standard User'
      LIMIT 1
    ]
    .Id;

    //Using system.runAs to avoid mixed DML errors
    System.runAs(currentUser) {
      Account customerAccount = GTSTestDataFactory.createAccount(
        'CustomerAccount',
        true
      );
    }
  }
  @IsTest
  static void checkContentJob_JobParent() {
    RecordType cocRecordType = [
      SELECT Id
      FROM RecordType
      WHERE
        DeveloperName = 'GTS_Certificate_of_Conformity'
        AND SobjectType = 'iCare_Job__c'
    ];
    Account customerAccount = [
      SELECT Id, (SELECT Id FROM Jobs__r)
      FROM Account
      WHERE Name = 'CustomerAccount'
      LIMIT 1
    ];

    iCare_Job__c jobRecord = GTSTestDataFactory.createJob(
      cocRecordType.Id,
      customerAccount.Id,
      true
    );

    // Create a File
    // Create a Content Version record
    ContentVersion cv = GTSTestDataFactory.createContentVersion(
      'TestJobDoc',
      true
    );

    List<ContentDocument> cntDocuments = [
      SELECT Id, Title
      FROM ContentDocument
      WHERE LatestPublishedVersionId = :cv.Id
    ];

    Test.startTest();
    ContentDocumentLink cdl = GTSTestDataFactory.createContentDocumentLink(
      jobRecord.Id,
      cntDocuments[0].Id,
      true
    );
    Test.stopTest();

    List<ContentDocumentLink> newCdl = [
      SELECT Id, ShareType, Visibility
      FROM ContentDocumentLink
      WHERE Id = :cdl.Id
    ];

    System.assert(newCdl != null);
    System.assert(newCdl[0].ShareType == 'V');
    System.debug('vizib' + newCdl[0].Visibility);
    System.assert(newCdl[0].Visibility == 'AllUsers');
  }
  @IsTest
  static void checkContentJob_JobRequestParent() {
    icare_Job_Request__c jobRecord = new icare_Job_Request__c();
    insert jobRecord;

    ContentVersion cv = GTSTestDataFactory.createContentVersion(
      System.Label.GTS_Conga_File_Name + 'TestJobDoc',
      true
    );

    List<ContentDocument> cntDocuments = [
      SELECT Id, Title
      FROM ContentDocument
      WHERE LatestPublishedVersionId = :cv.Id
    ];

    Test.startTest();
    ContentDocumentLink cdl = GTSTestDataFactory.createContentDocumentLink(
      jobRecord.Id,
      cntDocuments[0].Id,
      true
    );
    Test.stopTest();

    List<ContentDocumentLink> newCdl = [
      SELECT Id, ShareType, Visibility
      FROM ContentDocumentLink
      WHERE Id = :cdl.Id
    ];

    System.assert(newCdl != null);
    System.assert(newCdl[0].ShareType == 'V');
    System.debug('vizib' + newCdl[0].Visibility);
    System.assert(newCdl[0].Visibility == 'AllUsers');
  }
}