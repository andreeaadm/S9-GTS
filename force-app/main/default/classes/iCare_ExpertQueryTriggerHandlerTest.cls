/*******************************************************************************************
* @Name         iCare_ExpertQueryTriggerHandlerTest 
* @Author       Praveen Kumar R
* @Description  This acts as the test class to iCare_ExpertQueryTriggerHandler.
*******************************************************************************************/
@isTest
public class iCare_ExpertQueryTriggerHandlerTest {
    
    @TestSetup
    static void createData() {
        Account a = TestDataFactory.createAccount();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            TestDataFactory.createAdminUser();
        }
    }
    
    
    @isTest
    static void triggerTest() {
        Test.startTest();
        User usr = [SELECT Id FROM User LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new iCare_MockHttpResponseGenerator());
        
        List<iCare_Expert_Query__c> expList = new List<iCare_Expert_Query__c>();
        for (Integer i=0; i<2; i++) {
            iCare_Expert_Query__c exp 
                = new iCare_Expert_Query__c(iCare_Source__c='Web',
                                            iCare_Subject__c='Enso Subject'+i, 
                                            iCare_Your_Query__c='Enso Query'+i, 
                                            iCare_User__c= usr.Id,
                                            iCare_Source_Application_Name__c='iCare',
                                            iCare_Account__c=acc.Id);
            expList.add(exp);
        }
        
        insert expList;
        
        iCare_Expert_Query__c expQ = [SELECT Id,iCare_Retry_Sync__c, iCare_iConnect_Sync_Status__c FROM iCare_Expert_Query__c LIMIT 1];
        expQ.iCare_Retry_Sync__c += 1;
        update expQ;
        
        Test.stopTest();
    }
}