@isTest
public with sharing class CaseListControllerTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    List<Account> accounts = TestDataFactory.createAccounts(1, true);
    TestDataFactory.createAccountsWithContacts(accounts, 2);

    List<Contact> account1cons = [
      SELECT
        Id,
        FirstName,
        LastName,
        Email,
        AccountId,
        (SELECT Id, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Account.Name = 'Account 1'
      ORDER BY LastName
    ];
    TestDataFactory.createCommunityUsers(
      new List<String>{ 'MTC Admin Login', 'MTC Standard Login' },
      account1cons
    );

    List<AccountContactRelation> acrs = new List<AccountContactRelation>();
    for (Contact con : account1cons) {
      AccountContactRelation acr = con.AccountContactRelations[0];
      acrs.add(acr);
      if (con.Lastname.equalsIgnoreCase('Contact 0')) {
        acr.MTC_Role__c = 'Admin';
      } else {
        acr.MTC_Role__c = 'Read-Only';
      }
    }
    update acrs;
    List<Case> cases = new List<Case>{
      new Case(AccountId = accounts[0].Id, Subject = 'A test case')
    };
    insert cases;
  }
  @isTest
  static void test_1_1() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Account.Name = 'Account 1' AND Profile.Name = 'MTC Admin Login'
      LIMIT 1
    ];
    System.runAs(admin) {
      ListResponse response = CaseListController.getCases(10, 'CaseNumber');
      System.assertEquals(1, response.totalRows);
    }
  }
}