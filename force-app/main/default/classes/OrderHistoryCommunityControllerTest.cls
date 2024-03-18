/*******************************************************************************************
* @Name         OrderHistoryCommunityControllerTest 
* @Author       Anay Karkhanis
* @Date         10/04/2022
* @Description  Test Class for OrderHistoryCommunityComponentController.
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0             Anay K             10/04/2022         Initial Development for GSH-159                                                      
*******************************************************************************************/
@isTest
private class OrderHistoryCommunityControllerTest {

    private static final String GMA_PROFILE_NAME = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;

    @TestSetup
    public static void testSetup(){
        Account acc = new Account(Name='Test Account');
        insert acc;
        Contact con = new Contact(FirstName='Test',LastName='Contact',Email='standarduser@testorg.com.invalid',AccountId=acc.Id);
        insert con;
        Order__c orderRecord = new Order__c(Account__c=acc.Id,EService__c='Regulatory Sheet', Token_Cost_Count__c=90,Product__c='Aprons',Market__c='Argentina');
        insert orderRecord;
        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test.' + OrderHistoryCommunityComponentController.ORDER_DOCUMENT_FILE_EXTENSION;           
        cv.VersionData =Blob.valueOf('Unit Test Attachment Body');          
        insert cv;        
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId 
            FROM ContentDocument
        ];        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = orderRecord.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'I';
        cdl.Visibility = 'AllUsers';
        insert cdl;        
        Order_Line_Item__c orderLine = new Order_Line_Item__c(Order__c=orderRecord.Id);
        insert orderLine;

        TestDataFactory.triggerPermissionsetUpdateForGmaPortal();

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            Profile p = [SELECT Id FROM Profile WHERE Name =:GMA_PROFILE_NAME]; 
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com.invalid', 
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id,ContactId=con.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.invalid',Source__c ='Self-Registration'); 
            insert u;
        }
    }
    
    @isTest
    public static void testGetOrderHistory(){
        User u = [Select Id from User where UserName='standarduser@testorg.com.invalid'];
        System.runAs(u){         
            System.assertNotEquals(OrderHistoryCommunityComponentController.getOrderHistory().size(), 0,'List should not be empty');
        }
    }
    
    @isTest
    public static void testGetDownloadLink(){
        User u = [Select Id from User where UserName='standarduser@testorg.com.invalid'];
        System.runAs(u){
            System.assertNotEquals(OrderHistoryCommunityComponentController.getDownloadLink([Select Id from Order__c].Id), '','Download link should not be empty');
        }
    }    
}