@isTest
public with sharing class GTS_AssociatedJobRequest_TriggerHandTest {
  @isTest
  public static void testOnAfterInsertMethod() {
    ContentVersion cv = new ContentVersion();
    cv.VersionData = Blob.valueOf('Test file content');
    cv.Title = 'Test File';
    cv.PathOnClient = 'TestFile.txt';
    insert cv;

    icare_Job_Request__c jobReq = new icare_Job_Request__c();
    insert jobReq;

    String documentId = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cv.Id
      LIMIT 1
    ]
    .ContentDocumentId;

    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = documentId;
    cdl.LinkedEntityId = jobReq.Id;
    cdl.ShareType = 'V';
    insert cdl;

    iCare_Job__c job = new iCare_Job__c();
    insert job;

    GTS_Associated_Job_Request__c assJobReq = new GTS_Associated_Job_Request__c();
    assJobReq.GTS_Job_Request__c = jobReq.Id;
    assJobReq.GTS_Job__c = job.Id;

    Test.startTest();
    insert assJobReq;
    Test.stopTest();

    List<ContentDocumentLink> lstContDocLinks = [
      SELECT Id, ContentDocumentId, LinkedEntityId
      FROM ContentDocumentLink
      WHERE ContentDocumentId = :documentId
    ];

    System.assertEquals(
      true,
      lstContDocLinks.size() > 0,
      'createContentDocumentLink method failed'
    );
  }
}