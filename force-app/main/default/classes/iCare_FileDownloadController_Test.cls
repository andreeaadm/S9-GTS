/*
* ________________________________________________________________________________________________
* Class to test the iCare_FileDownloadController Class
* ________________________________________________________________________________________________
* @author       Andres Morales
* @created      2023-05-08
* ________________________________________________________________________________________________
* @changes
* 
* ________________________________________________________________________________________________
*/
@isTest
private class iCare_FileDownloadController_Test {
    private static final String METADATA_NAME_FOR_CONTENT_URL = 'URL_Portal_ContentDownload';
    private static final String FILE_NAME = 'FileDownloadTest';

    @testSetup static void setup() {
        // Create a test job
        iCare_Job__c testJob = new iCare_Job__c();
        testJob.iCare_Job_ID__c = 'TUR-IST-240500006';
        testJob.iCare_Job_Description__c = 'Job description test';
        insert testJob;

        // Create a File
        // Create a Content Version record
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.Title = FILE_NAME;
        cv.PathOnClient = 'PathFileDownloadTest.pdf';
        cv.VersionData = Blob.valueOf('Test PDF File Content');
        insert cv;

        List<ContentDocument> cntDocuments = [SELECT Id, Title FROM ContentDocument];

        // Create Content Document Link record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = testJob.Id;
        cdl.ContentDocumentId = cntDocuments[0].Id;
        cdl.shareType = 'V';
        insert cdl;
    }

    @isTest static void test_GetFile() {
        iCare_Portal__mdt contentUrlSetting = iCare_Portal__mdt.getAll().get(METADATA_NAME_FOR_CONTENT_URL);
        
        Id jobId = [SELECT Id FROM iCare_Job__c LIMIT 1].Id;

        Test.startTest();
        Map<String, String> mapFile = iCare_FileDownloadController.getRelatedFilesByRecordId(jobId);
        Test.stopTest();

        String urlFile = mapFile.get(FILE_NAME);

        // Verify the expected results
        System.assertEquals(1, mapFile.size(), 'The number of records should be 1');
        System.assertEquals(true, urlFile.startsWith(contentUrlSetting.Variable_Value__c), contentUrlSetting.Variable_Value__c);        
    }

    @isTest static void test_getSingleDownloadLink(){
        iCare_Portal__mdt contentUrlSetting = iCare_Portal__mdt.getAll().get(METADATA_NAME_FOR_CONTENT_URL);
        
        Id jobId = [SELECT Id FROM iCare_Job__c LIMIT 1].Id;

        Test.startTest();
        String fileLink = iCare_FileDownloadController.getSingleDownloadLink(jobId);
        Test.stopTest();

        
        // Verify the expected results
        System.assertNotEquals(null, fileLink, 'The file link should not be null');
        System.assertEquals(true, fileLink.startsWith(contentUrlSetting.Variable_Value__c), contentUrlSetting.Variable_Value__c);        
    }
}