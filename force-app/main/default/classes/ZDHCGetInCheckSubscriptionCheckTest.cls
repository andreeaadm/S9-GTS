@isTest
public class ZDHCGetInCheckSubscriptionCheckTest {
    
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
    }
    
    @isTest
    public static void byOrgGUID() {
        TC_TestDataFactory_Contacts tdfc = new TC_TestDataFactory_Contacts();
        StaticResourceMockResponseGenerator.setMock(
            'SubscriptionStatusResponse',
            200,
            'OK',
            null
        );
        
        List<ZDHC_Error_Log__c> calloutLogEntries = new List<ZDHC_Error_Log__c>();
        ZDHCGetInCheckSubscriptionCheck ZDHCGetInCheckSubscriptionCheck =  new ZDHCGetInCheckSubscriptionCheck(
            calloutLogEntries,
            tdfc.facilityContacts[0].Id,
            new Map<String, Object>{
                'organizationGUID' => 'DC89793BB4AF2C5DE0530100007F89ED'
                    }
        );
        Test.StartTest();
        Boolean result = ZDHCGetInCheckSubscriptionCheck.call();
        Test.stopTest();
        
        System.assertEquals(true, result, 'OK');
    }
}