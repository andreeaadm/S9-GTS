@isTest
public class TC_InCheckSubscriptionCheckSchedulableT {
    @testSetup
    static void setup() {
        TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
            1,
            0, // inactive
            new List<Integer>{ 1 },
            new List<Integer>{ 0 }, // inactive
            1,
            0 // inactive
        );
        TC_TestDataFactory_Contacts tdfc = new TC_TestDataFactory_Contacts(
            tdfa,
            'unittest@example.com',
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 }
        );
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(tdfc, true);
        TC_TestDataFactory_Users.insertPermissionSetAssignments(
            tdfu.permissionSetAssignments
        );
        
        Account facilityAccount = [SELECT Id, Is_ToxClear_Account__c, ToxClear_Account_Type__c, ZDHC_Organisation_GUID__c, InCheck_Subscription_Expiration_Date__c, InCheck_Subscription_Start_Date__c, Facility_Manager__c, InCheck_Status__c FROM Account WHERE Id=:tdfa.facilities[0].Id];
        facilityAccount.ZDHC_Organisation_GUID__c = 'DC89793BB4AF2C5DE0530100007F89ED';
        update facilityAccount;
    }
    
    @IsTest
    private static void test_execute() {
        Test.startTest();
        String cronExpression = '0 0 0 * * ?';
        String jobId = System.schedule(
            'Get InCheck Subscription',
            cronExpression,
            new TC_InCheckSubscriptionCheckSchedulable()
        );
        Test.stopTest();
        cronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id=:jobId];
        system.assertEquals(cronExpression, ct.CronExpression);
    }
}