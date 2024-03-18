/*
 * Author: Kamlesh.kahar@intertek.com
 * History:
 * 		14-09-2023	MBS-4	Created test class	Kamlesh.kahar
*/

@isTest
public class AuditLogEventTriggerHandlerTest {
    @TestSetup
    public static void setupTestData(){
        TestDataFactory.ISTEST_FOR_MTC = true;
        Account a = TestDataFactory.createAccount();
        TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
        TestDataFactory.createCommunityUser('MTC Standard Login', a.Id);
        System.runAs(new User(Id = UserInfo.getUserId())) {
        TestDataFactory.createAdminUser();
        }
        TestDataFactory.createContactGroup(a.Id);
        TestDataFactory.createReportForAccount(a.Id, true);
        User u = [
        SELECT Contact.AccountId, ContactId, Id
        FROM User
        WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
        LIMIT 1
        ];
        TestDataFactory.updateAccountContactRelation(
        u.Contact.AccountId,
        u.ContactId,
        'CGA'
        );
    }

    @isTest
    public static void testAuditLogs(){
        Test.startTest();
        String mtcRole_NoAccess = 'No-Access';
        String mtcRole_Admin = 'Admin';
        AccountContactRelation acr = [SELECT Id, MTC_Role__c, AccountId,Account.Is_MTC_Account__c, ContactId FROM AccountContactRelation WHERE MTC_Role__c = :mtcRole_NoAccess];
        acr.MTC_Role__c = mtcRole_Admin;
        update acr;
        Test.stopTest();
        List<Audit_Log__c> auditLog = [SELECT Old_Value__c, New_Value__c FROM Audit_Log__c WHERE Account__c = :acr.AccountId];
        System.assertEquals(auditLog.isEmpty(), false);
    }
}