/*******************************************************************************************
* @Name         RegulationUpdatesDisplayControllerTest 
* @Author       Anay Karkhanis
* @Date         18/05/2022
* @Description  Test Class for RegulationUpdatesDisplayController.
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0             Anay K             18/05/2022         Initial Development for GSH-55                                                      
*******************************************************************************************/
@isTest
private class RegulationUpdatesDisplayControllerTest {
    private static final String GMA_PROFILE_NAME = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;

    @TestSetup
    public static void testSetup(){
        Account acc = new Account(Name='Test Account');
        insert acc;
        Contact con = new Contact(FirstName='Test',LastName='Contact',Email='standarduser@testorg.com.invalid',AccountId=acc.Id);
        insert con;
		Regulation__c regulation = TestDataFactory.createRegulation('Aprons','United Kingdom','Accessories','Adult', false);
        regulation.Name='Test Regulation';
        regulation.Legal_Regulation_Name__c = 'Test Legal Name';
        regulation.Material__c='Adhesive';
        insert regulation;
		Regulation_Update__c regulationUpdate = new Regulation_Update__c(Name='Test Regulation Update',Regulation__c=regulation.Id);
		insert regulationUpdate;
        Order__c orderRecord = new Order__c(Account__c=acc.Id,EService__c='Regulatory Sheet',Stage__c='Completed',Token_Cost_Count__c=90);
        insert orderRecord;
        Order_Line_Item__c orderLine = new Order_Line_Item__c(Order__c=orderRecord.Id,Regulation__c=regulation.Id);
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
    public static void testGetRegulationUpdateData(){
        User u = [Select Id from User where UserName='standarduser@testorg.com.invalid'];
        System.runAs(u){         
            System.assertNotEquals(RegulationUpdatesDisplayController.getRegulationUpdateData().size(), 0,'List should not be empty');
        }
    }    

}