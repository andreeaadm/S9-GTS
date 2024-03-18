/**
 * @author Vikash <vikash.kumar@cloudshiftgroup.com>
 * @date 2022-08-17
 * @group CloudShiftGroup
 * @description Test class for GMAHLSLTokenTransactionController which is controller class for tokenTransaction component.
 *
 * Date          Author             Change Description
 * -----------------------------------------------------------------------------------
 * 17/08/2022    Vikash Kumar       Created Class
*/
@isTest
public class GMAHLSLTokenTransactionControllerTest {
	@testSetup
    private static void createCoreData() {
        String CREDIT_RT_NAME = GMA_Variable__mdt.getInstance('GMA_CREDIT_TRANSACTION_RT').Variable_Value__c;
        Id CREDIT_RT_ID = Schema.SObjectType.Token_Transaction__c.getRecordTypeInfosByDeveloperName().get(CREDIT_RT_NAME).getRecordTypeId();

        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        
        Token_Transaction__c credits = new Token_Transaction__c(
            Account__c = accounts.get(0).Id,
            Amount__c = 100,
            Expired__c = false,
            RecordTypeId = CREDIT_RT_ID
        );
        insert credits;

        TestDataFactory.triggerPermissionsetUpdateForGmaPortal();
    }
    
    /**
     * Method tested: GMAHLSLTokenTransactionController.getTokenTransaction()
     * Test Scenario: Fetch Token transaction records as per provided filters.
     * Expected Result: map of regulation id and test items.
    */
    @isTest
    private static void testRetrieveTokens() {
        Id accountId = [SELECT Account__c FROM Token_Transaction__c LIMIT 1].Account__c;
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);

        System.runAs(portalUser) {
            Test.startTest();
            List<GMAHLSLTokenTransactionController.tokenHistoryItem> tokenTransactionList = GMAHLSLTokenTransactionController.getTokenTransaction('30');
            Test.stopTest();
            System.assertEquals(tokenTransactionList.size(),1, 'Size of tokenTransactionList should match with the number of tokens created in this class');
        }
    }
}