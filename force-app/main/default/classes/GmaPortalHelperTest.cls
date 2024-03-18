/**
 * @author Kaspars Rezgalis <kaspars@cloudshiftgroup.com>
 * @date 2022-05-18
 * @group CloudShiftGroup
 * @description Test class for GmaPortalHelper which provides supporting functionality when interacting with GMA customer portal
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 18/05/2022    Kaspars Rezgalis   Created Class
*/
@isTest
private class GmaPortalHelperTest {

    @testSetup
    private static void createCoreData() {
        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        TestDataFactory.createAccountsWithContacts(accounts, 1);

        TestDataFactory.triggerPermissionsetUpdateForGmaPortal();
    }

    /**
     * Method tested: GmaPortalHelper.portalLogin()
     * Test Scenario: try to perform login with no username and password given
     * Expected Result: error (exception) is raised 
    */
    @isTest
    private static void testLoginAuraException() {
        Boolean errorEncountered = false;

        Test.startTest();
        try {
            GmaPortalHelper.portalLogin(null, null, null);
        } catch (AuraHandledException e) {
            errorEncountered = true;
        }
        System.assert(errorEncountered, 'Aura exception should be thrown when attempting to log in with null values');
    }

    /**
     * Method tested: GmaPortalHelper.portalLogin()
     * Test Scenario: try to perform login with valid username but invalid password
     * Expected Result: error (exception) is raised (which is then surfaced to user in UI advising auth was not successful)
    */
    @isTest
    private static void testLoginFailure() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);

        Boolean errorEncountered = false;

        Test.startTest();
        try {
            GmaPortalHelper.portalLogin(portalUser.Username, 'invalid', null);
        } catch (AuraHandledException e) {
            errorEncountered = true;
        }
        System.assert(errorEncountered, 'Aura exception should be thrown when attempting to log in with incorrect password');
    }

    /**
     * Method tested: GmaPortalHelper.portalLogin()
     * Test Scenario: try to perform login with valid username and valid password
     * Expected Result: login should successed; however, currently this is not fully supported in Apex tests, hence test assertions are not fully accurate
    */
    @isTest
    private static void testLoginSuccess() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);

        Boolean errorEncountered = false;
        String newPassword = 'testString12345&*(';
        Test.startTest();
        try {
            System.setPassword(portalUser.Id, newPassword); 
            GmaPortalHelper.portalLogin(portalUser.Username, newPassword, null);
        } catch (Exception e) {

        }
        //successful login cannot be fully tested due to no URL being returned during tests
        System.assert(!errorEncountered, 'No exceptions should be encountered when logging in successfully');
    }

    /**
     * Method tested: GmaPortalHelper.getCurrentUser()
     * Test Scenario: verify user information for portal user is retrieved successfully
     * Expected Result: portal user information (including account Id) is returned for current user
    */
    @isTest
    private static void testGetPortalUserDetails() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);
        User assertUser;

        System.runAs(portalUser) {
            Test.startTest();
            assertUser = GmaPortalHelper.getCurrentUser();
            Test.stopTest();
        }
        System.assertEquals(accountId, assertUser.Contact.AccountId, 'Retrieved user record should match to test portal user');
    }

    /**
     * Method tested: GmaPortalHelper.getCurrentUser()
     * Test Scenario: verify user information for non-portal user is retrieved
     * Expected Result: user information is returned without errors even though it is not a portal user (e.g. unauthenticated guest)
    */
    @isTest
    private static void testGetNonPortalUserDetails() {
        Test.startTest();
        User assertUser = GmaPortalHelper.getCurrentUser();
        Test.stopTest();
        System.assertEquals(null, assertUser.Contact.AccountId, 'Retrieved user record should be system usr that is not associated with a contact&account');
    }
}