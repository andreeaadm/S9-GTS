/*
* Class to test the iCare_FileDownloadController Class
* @author       Globant
* @created      31-Aug-2023
* @description  Class contains logic to create ContentDistribution record with public link for Country Mark Uploaded.
*/
@IsTest
private class GAMEL_CountryMarkLogoTest {
    
	/**
     * Description: method for generating test data used for all subsequent tests
    */
    @testSetup
    private static void setupData(){
        GMAEL_Country_Mark__c testCountryMark = new GMAEL_Country_Mark__c(GMAEL_Country_Mark_Description__c='Test LOGO');
        insert testCountryMark;
    }
    
    @isTest
    private static void testCountryMarkLogo(){
        GMAEL_Country_Mark__c[] logoData = [Select Id from GMAEL_Country_Mark__c limit 1];
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'TestMarkLogo';
        contentVersion.PathOnClient = 'TestMarkLogo.jpg';
		contentVersion.VersionData = Blob.valueOf('TestMarkLogo');
		contentVersion.IsMajorVersion = true;
        insert contentVersion;
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        // Create ContentDocumentLink record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = logoData[0].Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        logoData = [Select Id,GMAEL_Logo_File_URL__c from GMAEL_Country_Mark__c limit 1];
        
        //System.assert((logoData[0].GMAEL_Logo_File_URL__c!=null));
    }
}