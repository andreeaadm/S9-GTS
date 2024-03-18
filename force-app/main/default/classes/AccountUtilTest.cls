@isTest
private with sharing class AccountUtilTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    TestDataFactory.CONTACTS_USER_REQD_FLAG = false;
    List<Account> accounts = TestDataFactory.createAccounts(5, true);
    TestDataFactory.createAccountsWithContacts(accounts, 3);
  }
  @isTest
  static void checkSetsIsMTCAccountField() {
    TestDataFactory.ISTEST_FOR_MTC = false;
    insert new Account(Name = 'rather random 123', TruTesta_ID__c = '123');
    Account a = [
      SELECT Is_MTC_Account__c
      FROM Account
      WHERE Name = 'rather random 123'
      LIMIT 1
    ];
    System.assertEquals(true, a.Is_MTC_Account__c);
  }
  // verifies that the CGA_Id field on account gets set when the MTC_Role field
  // is set to "CGA" on the Account Contact Relation record
  @isTest
  static void setsCGAfieldOnAccount() {
    AccountContactRelation acr = [
      SELECT Id, AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE Account.Name = 'Account 1' AND Contact.LastName = 'Contact 1'
    ];
    Test.startTest();
    acr.MTC_Role__c = 'CGA';
    update acr;
    Test.stopTest();
    Account acc = [SELECT Id, CGA_Id__c FROM Account WHERE Id = :acr.AccountId];
    System.assertEquals(acr.ContactId, acc.CGA_Id__c);
  }

  @isTest
  static void unsetsCGAfieldOnAccount() {
    AccountContactRelation acr = [
      SELECT Id, AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE Account.Name = 'Account 1' AND Contact.LastName = 'Contact 1'
    ];
    acr.MTC_Role__c = 'CGA';
    update acr;
    Test.startTest();
    acr.MTC_Role__c = 'No-Access';
    update acr;
    Test.stopTest();
    Account acc = [SELECT Id, CGA_Id__c FROM Account WHERE Id = :acr.AccountId];
    System.assertEquals(null, acc.CGA_Id__c);
  }

  @isTest
  static void setUnsetSameUpdateCGAfieldOnAccount() {
    List<AccountContactRelation> acrs = [
      SELECT Id, AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE
        Account.Name = 'Account 1'
        AND Contact.LastName IN ('Contact 1', 'Contact 2')
    ];
    acrs[0].MTC_Role__c = 'CGA';
    update acrs;

    Test.startTest();

    acrs[1].MTC_Role__c = 'CGA';
    acrs[0].MTC_Role__c = 'No-Access';
    update acrs;

    Test.stopTest();
    Account acc = [
      SELECT Id, CGA_Id__c
      FROM Account
      WHERE Id = :acrs[0].AccountId
    ];
    System.assertEquals(acrs[1].ContactId, acc.CGA_Id__c);
  }

  @isTest
  static void setUnsetLaterDemotionCGAfieldOnAccount() {
    List<AccountContactRelation> acrs = [
      SELECT Id, AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE
        Account.Name = 'Account 1'
        AND Contact.LastName IN ('Contact 1', 'Contact 2')
    ];
    acrs[0].MTC_Role__c = 'CGA';
    update acrs;

    acrs[1].MTC_Role__c = 'CGA';
    update acrs;

    Test.startTest();

    acrs[0].MTC_Role__c = 'No-Access';
    update acrs;

    Test.stopTest();
    Account acc = [
      SELECT Id, CGA_Id__c
      FROM Account
      WHERE Id = :acrs[0].AccountId
    ];
    System.assertEquals(acrs[1].ContactId, acc.CGA_Id__c);
  }

  @isTest
  static void setsCGAfieldOnAccountSecondary() {
    List<Account> accounts = [
      SELECT Name
      FROM Account
      WHERE Name IN ('Account 1', 'Account 2')
      ORDER BY Name
    ];
    List<AccountContactRelation> acrs = [
      SELECT Id, AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE Account.Name IN ('Account 1', 'Account 2')
      ORDER BY Account.Name
    ];
    Id contactId = acrs[0].ContactId;
    Test.startTest();
    // create a CGA relation between an Account 1 contact and account 2
    AccountContactRelation acr = new AccountContactRelation(
      AccountId = accounts[1].Id,
      ContactId = contactId,
      MTC_Role__c = 'CGA'
    );
    insert acr;
    Test.stopTest();
    Account acc = [SELECT Id, CGA_Id__c FROM Account WHERE Id = :acr.AccountId];
    System.assertEquals(acr.ContactId, acc.CGA_Id__c);
  }
}