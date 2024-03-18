/**
 * @author Kaspars Rezgalis <kaspars.rezgalis@cloudshiftgroup.com>
 * @date 2022-09-28
 * @group CloudShiftGroup
 * @description Test class for Helper class that fetches cases for GMA portal listview
 *
 * Date          Author             Change Description
 * -----------------------------------------------------------------------------------
 * 28/09/2022    Kaspars Rezgalis   Created Class
*/
@isTest
public class GMAHLSLCasesListviewControllerTest {
	@testSetup
    private static void createCoreData() {
        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('GMA_General_Enquiry').getRecordTypeId();

        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        
        Case c = new Case(
            AccountId = accounts.get(0).Id,
            Subject = 'testCase',
            RecordTypeId = caseRT
        );
        insert c;

        TestDataFactory.triggerPermissionsetUpdateForGmaPortal();
    }
    
    /**
     * Method tested: GMAHLSLTokenTransactionController.getTokenTransaction()
     * Test Scenario: Fetch Token transaction records as per provided filters.
     * Expected Result: map of regulation id and test items.
    */
    @isTest
    private static void testRetrieveCases() {
        Id accountId = [SELECT AccountId FROM Case LIMIT 1].AccountId;
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);

        System.runAs(portalUser) {
            Test.startTest();
            List<GMAHLSLCasesListviewController.caseItem> casesList = GMAHLSLCasesListviewController.getCaseRecords('30');
            Test.stopTest();
            System.assertEquals(1, casesList.size(), 'Number of cases returned should be one - the only one created');
        }
    }
}