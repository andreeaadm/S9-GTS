@isTest
public  with sharing class TC_getUploadedFilesOfChemicalProductTest {
    @isTest
    static void testGetUploadedFilesOnChemicalProduct(){
        Chemical_Product__c cp = new Chemical_Product__c();
        cp.Chemical_Product_Name__c = 'Test Product 1';
        insert cp;
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = cp.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
        
        Test.startTest();
        String filesData = TC_getUploadedFilesOfChemicalProduct.getContentDetails(cp.Id);
        system.assertEquals(false, String.isEmpty(filesData));
        Test.stopTest();
    }
}