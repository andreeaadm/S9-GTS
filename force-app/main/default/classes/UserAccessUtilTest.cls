@isTest
public with sharing class UserAccessUtilTest {
  static Map<String, Id> buildName2Id() {
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : [SELECT Name FROM Account]) {
      name2Id.put(acc.Name, acc.Id);
    }
    return name2Id;
  }
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;

    List<Account> accounts = TestDataFactory.createAccounts(4, true);
    Map<String, Id> name2Id = buildName2Id();
    TestDataFactory.createAccountsWithContacts(accounts, 1);

    List<Contact> contacts = [
      SELECT
        Id,
        AccountId,
        Account.Name,
        (
          SELECT AccountId, Account.Name, MTC_Role__c
          FROM AccountContactRelations
        )
      FROM Contact
    ];
    // grab one contact per account
    Map<Id, Contact> consByAccId = new Map<Id, Contact>();
    for (Contact con : contacts) {
      // Just need one contact per account
      consByAccId.put(con.AccountId, con);
    }
    Contact conAcc1Admin = consByAccId.get(name2Id.get('Account 1'));
    Contact conAcc2 = consByAccId.get(name2Id.get('Account 2'));

    upsert new List<AccountContactRelation>{
      new AccountContactRelation(
        Id = conAcc1Admin.AccountContactRelations[0].Id,
        MTC_Role__c = 'Admin'
      ),
      new AccountContactRelation(
        Id = conAcc2.AccountContactRelations[0].Id,
        MTC_Role__c = 'Read-Only'
      ),
      new AccountContactRelation(
        AccountId = name2Id.get('Account 3'),
        ContactId = conAcc2.Id,
        MTC_Role__c = 'Read-Only'
      ),
      new AccountContactRelation(
        AccountId = name2Id.get('Account 4'),
        ContactId = conAcc1Admin.Id,
        MTC_Role__c = 'Admin'
      )
    };
  }
  // To test the scenario when a User's primary account is not part of the related accounts of an Admin or CGA
  // but the users relate via an ACR
  // userA.account = A
  // userB.account = B
  // userB.acr = C and isAdmin (so should see all users of C)
  // userC.acr = C
  @isTest
  static void userVisibilityWhenNotCoveredBySharingSet() {
    Map<String, Id> name2Id = buildName2Id();
    List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
    // grab one contact per account
    Map<Id, Contact> consByAccId = new Map<Id, Contact>();
    for (Contact con : contacts) {
      consByAccId.put(con.AccountId, con);
    }
    Contact conAcc1Admin = consByAccId.get(name2Id.get('Account 1'));
    Contact conAcc2 = consByAccId.get(name2Id.get('Account 2'));

    // The account we use to relate our contacts
    Account aThirdAccount = new Account(
      Name = '3rd account',
      Is_MTC_Account__c = true
    );
    insert aThirdAccount;

    Test.startTest();

    insert new List<AccountContactRelation>{
      new AccountContactRelation(
        ContactId = conAcc1Admin.Id,
        AccountId = aThirdAccount.Id,
        MTC_Role__c = 'Admin'
      ),
      new AccountContactRelation(
        ContactId = conAcc2.Id,
        AccountId = aThirdAccount.Id,
        MTC_Role__c = 'Read-Only'
      )
    };
    Test.stopTest();

    Set<Id> contactIds = new Set<Id>{ conAcc2.Id, conAcc1Admin.Id };
    Map<Id, Id> c2u = new Map<Id, Id>();
    for (User usr : [
      SELECT Id, ContactId
      FROM User
      WHERE ContactId IN :contactIds
    ]) {
      c2u.put(usr.ContactId, usr.Id);
    }
    System.assertEquals(2, c2u.size());
    // running as the admin, see if we can see the users for aThirdAccount
    System.runAs(new User(Id = c2u.get(conAcc1Admin.Id))) {
      List<User> visibleUsers = [SELECT Id, AccountId, Name FROM User];
      System.assertEquals(2, visibleUsers.size());
    }
    System.runAs(new User(Id = c2u.get(conAcc2.Id))) {
      List<User> visibleUsers = [SELECT Id, AccountId, Name FROM User];
      System.assertEquals(2, visibleUsers.size());
    }
  }
  @isTest
  static void userVisibilityWhenContactBecomesAdmin() {
    Map<String, Id> name2Id = buildName2Id();
    List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
    // grab one contact per account
    Map<Id, Contact> consByAccId = new Map<Id, Contact>();
    for (Contact con : contacts) {
      consByAccId.put(con.AccountId, con);
    }
    Contact conAcc1Admin = consByAccId.get(name2Id.get('Account 1'));
    Contact conAcc2 = consByAccId.get(name2Id.get('Account 2'));

    Test.startTest();
    insert new List<AccountContactRelation>{
      new AccountContactRelation(
        ContactId = conAcc1Admin.Id,
        AccountId = name2Id.get('Account 3'),
        MTC_Role__c = 'Admin'
      )
    };
    Test.stopTest();

    Set<Id> contactIds = new Set<Id>{ conAcc2.Id, conAcc1Admin.Id };
    Map<Id, Id> c2u = new Map<Id, Id>();
    for (User usr : [
      SELECT Id, ContactId
      FROM User
      WHERE ContactId IN :contactIds
    ]) {
      c2u.put(usr.ContactId, usr.Id);
    }
    System.assertEquals(2, c2u.size());
    // running as the admin, see if we can see the users for aThirdAccount
    System.runAs(new User(Id = c2u.get(conAcc1Admin.Id))) {
      List<User> visibleUsers = [SELECT Id, AccountId, Name FROM User];
      System.assertEquals(2, visibleUsers.size());
    }
    System.runAs(new User(Id = c2u.get(conAcc2.Id))) {
      List<User> visibleUsers = [SELECT Id, AccountId, Name FROM User];
      System.assertEquals(2, visibleUsers.size());
    }
  }

  @isTest
  static void accountVisibilityWhenContactBecomesAdmin() {
    Map<String, Id> name2Id = buildName2Id();
    List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
    // grab one contact per account
    Map<Id, Contact> consByAccId = new Map<Id, Contact>();
    for (Contact con : contacts) {
      consByAccId.put(con.AccountId, con);
    }
    Contact conAcc1Admin = consByAccId.get(name2Id.get('Account 1'));
    Contact conAcc2 = consByAccId.get(name2Id.get('Account 2'));

    Test.startTest();
    insert new List<AccountContactRelation>{
      new AccountContactRelation(
        ContactId = conAcc1Admin.Id,
        AccountId = name2Id.get('Account 3'),
        MTC_Role__c = 'Admin'
      )
    };
    Test.stopTest();

    Set<Id> contactIds = new Set<Id>{ conAcc2.Id, conAcc1Admin.Id };
    Map<Id, Id> c2u = new Map<Id, Id>();
    for (User usr : [
      SELECT Id, ContactId
      FROM User
      WHERE ContactId IN :contactIds
    ]) {
      c2u.put(usr.ContactId, usr.Id);
    }
    System.assertEquals(2, c2u.size());
    // running as the admin, see if we can see the users for aThirdAccount
    System.runAs(new User(Id = c2u.get(conAcc1Admin.Id))) {
      List<User> visibleUsers = [SELECT Id, AccountId, Name FROM User];
      System.assertEquals(2, visibleUsers.size());
      List<Contact> cons = [SELECT Name FROM Contact WHERE Id = :conAcc2.Id];
      System.assertEquals(1, cons.size());
    }
  }
  @isTest
  static void accountVisibilityWhenContactAddedToAdministeredAccount() {
    Map<String, Id> name2Id = buildName2Id();
    List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
    // grab one contact per account
    Map<Id, Contact> consByAccId = new Map<Id, Contact>();
    for (Contact con : contacts) {
      consByAccId.put(con.AccountId, con);
    }
    Contact conAcc1Admin = consByAccId.get(name2Id.get('Account 1'));
    Contact conAcc2 = consByAccId.get(name2Id.get('Account 2'));

    Test.startTest();
    insert new List<AccountContactRelation>{
      new AccountContactRelation(
        ContactId = conAcc2.Id,
        AccountId = name2Id.get('Account 4'),
        MTC_Role__c = 'Read-Only'
      )
    };
    Test.stopTest();

    Set<Id> contactIds = new Set<Id>{ conAcc2.Id, conAcc1Admin.Id };
    Map<Id, Id> c2u = new Map<Id, Id>();
    for (User usr : [
      SELECT Id, ContactId
      FROM User
      WHERE ContactId IN :contactIds
    ]) {
      c2u.put(usr.ContactId, usr.Id);
    }
    System.assertEquals(2, c2u.size());
    // running as the admin, see if we can see the users for aThirdAccount
    System.runAs(new User(Id = c2u.get(conAcc1Admin.Id))) {
      List<User> visibleUsers = [SELECT Id, AccountId, Name FROM User];
      System.assertEquals(2, visibleUsers.size());
      List<Contact> cons = [SELECT Name FROM Contact WHERE Id = :conAcc2.Id];
      System.assertEquals(1, cons.size());
    }
  }
}