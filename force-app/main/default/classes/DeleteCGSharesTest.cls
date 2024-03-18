@isTest
public class DeleteCGSharesTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.ISTEST_FOR_MTC = true;
        List<Account> accounts = TestDataFactory.createAccounts(1, true);
    }
    public static testMethod void createPortalUser(){
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Account 1'];
        List<Contact> contacts = TestDataFactory.createContacts(1, true, acc1.Id);
        Contact con = contacts[0];
        List<AccountContactRelation> acrs = [
            SELECT Id, MTC_Role__c
            FROM AccountContactRelation
            WHERE ContactId = :con.Id
        ];
        Test.startTest();
        for (AccountContactRelation acr : acrs) {
            acr.MTC_Role__c = 'admin';
        }
        update acrs;
        Test.stopTest();
        User mtcAdmin = [SELECT Id FROM User WHERE ContactId = :con.Id];
        DeleteCGSharesTest.disablePortalUser();
    }
    
    @future
    public static void disablePortalUser(){
        User mtcAdmin = [SELECT Id FROM User WHERE Contact.Name = 'Test Contact 0'];
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Account 1'];
        mtcAdmin.IsActive = false;
        update mtcAdmin;
    }
}