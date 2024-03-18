@isTest
public class TC_InCheckSubscriptionCheckBatchableTest {
    @TestSetup
    static void setup() {
        // 4 Supplers, first supplier to have 25 facilities, second 10 facilities, third 3 facility
        TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
            4,
            1, // inactive
            new List<Integer>{ 25, 10, 3 },
            new List<Integer>{0}, // inactive
            1,
            1 // inactive
        );
        TC_TestDataFactory_Contacts tdfc = new TC_TestDataFactory_Contacts(
            tdfa,
            'unittest@example.com',
            new List<Integer>{ 0 },
            new List<Integer>{ 0 },
            new List<Integer>{ 0 },
            new List<Integer>{ 1 },
            new List<Integer>{ 0 },
            new List<Integer>{ 0 }
        );
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(tdfc, true);
        tdfu.insertPermissionSetAssignments();
        
        Map<Integer,String> orgGUIDsForFacilitiesMap = new Map<Integer,String>{
            0 =>'D77D2CB25ABB5BABE0530100007F44A5', 
                1 =>   '9281631729E67F0CE0530100007FFD4B', 
                2 =>  '4CDE5F6F15E1416FE0530100007F256A', 
                3 =>  '6F731E04E38F6BFBE0530100007F90C8',
                4 =>  '9010B9336CB85B14E0530100007FA3D9', 
                5 => '896197B6C7CD0B67E0530100007F7CF4', 
                6 =>  '7E0DA640555F1B6FE0530100007F5348', 
                7 =>   'B1142E0F542A5467E0530100007FEB0A', 
                8 =>  '90426863F26007D1E0530100007F7DA8', 
                9 =>   '5A01F02025207C05E0530100007F79BD', 
                10 =>  '7397A19C068F2F6BE0530100007F69C9', 
                11 =>  '8B09054ADA8366E0E0530100007F1FD7', 
                12 =>  '9C0ACD17FFC66CEBE0530100007FFA84', 
                13 =>  '877FB7B0F0C2124BE0530100007F7C0A', 
                14 =>  '7E76598DF53B3439E0530100007F8029', 
                15 =>  '8756DEE1C86231C6E0530100007F274B', 
                16 =>  '628D479F070E7261E0530100007F90C3', 
                17 =>  '416685DBDF9777FFE0530100007F9205', 
                18 =>  '9863F9D7B4CA3E8BE0530100007F890A', 
                19 => '6DDD5205A9957D8EE0530100007F4AF4', 
                20 => 'B07D73CC40AB541AE0530100007FB907', 
                21 => '54013893EDD747F6E0530100007F8A01', 
                22 =>  '5C4827F331A671E1E0530100007FB2E8', 
                23 =>  '773BA3FF579B110DE0530100007F8F19', 
                24 =>  '5A01F02027FD7C05E0530100007F79BD', 
                25 =>  '8D049071E69E4C00E0530100007FD488', 
                26 =>  '8CFDDE43E65F70EAE0530100007FF4B5', 
                27 =>  '98357423DCE15326E0530100007F8905', 
                28 =>  '7397AF93ED4F3371E0530100007F1C26', 
                29 =>  '89A586854362151EE0530100007F783A', 
                30 =>  '6498421CE2842F93E0530100007FEDA6', 
                31 =>  '5A8CE1DF10F65052E0530100007FFCCF', 
                32 =>  '9980AA535CF23BD4E0530100007FE2F8', 
                33 => '9BB52CFA80564DD2E0530100007FFD58', 
                34 => '674283E762183E79E0530100007F426A', 
                35 => '9458BE1313371B3CE0530100007FE4BE', 
                36 => '5D9C762C1C7522EAE0530100007F1C24', 
                37 => '6E9359D43BE8766EE0530100007F30EF' 
                };
                    List<Account> accountsToBeUpdated = new List<Account>();
        Map<Id,Account> facilitiesMap = new Map<Id,Account>(tdfa.facilities);
        Map<Id,Account> facilityAccountsMap = new Map<Id,Account>([SELECT Id, ZDHC_Organisation_GUID__c, InCheck_Subscription_Expiration_Date__c, InCheck_Subscription_Start_Date__c, InCheck_Status__c, Facility_Manager__c FROM Account WHERE Id IN :facilitiesMap.KeySet()]);
        Integer Key = 0;
        for(Account acc : facilityAccountsMap.values()){
            acc.ZDHC_Organisation_GUID__c = orgGUIDsForFacilitiesMap.get(key);
            if(Key == 0 && Key <= 14 ) {
                acc.InCheck_Status__c = 'Active';
            }
            if(Key == 15 && Key <= 24 ) {
                acc.InCheck_Status__c = 'Inactive'; 
            }
            if(Key == 25 && Key <= 37 ) {
                acc.InCheck_Status__c = 'Subscribed but not yet activated/used'; 
            }
            accountsToBeUpdated.add(acc);
            key++;
            
        }
        update accountsToBeUpdated; 
    }
    
    @isTest
    public static void executeBatch() {
        IncheckSubBatchableMockResponseGenerator mock = new IncheckSubBatchableMockResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.StartTest();
        TC_InCheckSubscriptionCheckBatchable tisc = new TC_InCheckSubscriptionCheckBatchable();
        Id batchId = Database.executeBatch(tisc);
        Test.StopTest();
        
        List<Account> facilitiesToBeAsserted = [SELECT Id, ZDHC_Organisation_GUID__c, InCheck_Subscription_Expiration_Date__c, InCheck_Subscription_Start_Date__c, InCheck_Status__c, Facility_Manager__c 
                                                FROM Account 
                                                WHERE ZDHC_Organisation_GUID__c IN ('628D479F070E7261E0530100007F90C3', 
                                                                                    '416685DBDF9777FFE0530100007F9205', 
                                                                                    '9863F9D7B4CA3E8BE0530100007F890A', 
                                                                                    '6DDD5205A9957D8EE0530100007F4AF4', 
                                                                                    'B07D73CC40AB541AE0530100007FB907', 
                                                                                    '54013893EDD747F6E0530100007F8A01')];
        for(Account acc : facilitiesToBeAsserted){
            system.assertEquals(false, String.isEmpty(String.valueOf(acc.InCheck_Subscription_Expiration_Date__c)));
            system.assertEquals(false, String.isEmpty(String.valueOf(acc.InCheck_Subscription_Start_Date__c)));
        }
    }
}