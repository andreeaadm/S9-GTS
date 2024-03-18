@isTest
public with sharing class SimplifiedSharingTest {
  // @TestSetup
  // static void makeData() {
  //   TestDataFactory.ISTEST_FOR_MTC = true;
  //   List<Account> accounts = TestDataFactory.createAccounts(3, true);

  //   TestDataFactory.createAccountsWithContacts(accounts, 2);

  //   List<Contact> account1cons = [
  //     SELECT Id, FirstName, LastName, AccountId
  //     FROM Contact
  //     WHERE Account.Name = 'Account 1'
  //     ORDER BY LastName
  //   ];
  //   TestDataFactory.createCommunityUser(
  //     'MTC Admin Login',
  //     account1cons[0].AccountId,
  //     account1cons[0].Id
  //   );
  //   TestDataFactory.createCommunityUser(
  //     'MTC Standard Login',
  //     account1cons[1].AccountId,
  //     account1cons[1].Id
  //   );
  //   List<AccountContactRelation> acrs = [
  //     SELECT Id, ContactId
  //     FROM AccountContactRelation
  //     WHERE AccountId = :account1cons[0].AccountId
  //   ];
  //   for (AccountContactRelation acr : acrs) {
  //     if (acr.ContactId == account1cons[0].Id) {
  //       acr.MTC_Role__c = 'Read-Only';
  //     } else {
  //       acr.MTC_Role__c = 'Admin';
  //     }
  //   }
  //   update acrs;
  // }
  // // Helper method to set mtc role to Read-Only
  // static void updateACRsToReadOnly(Set<Id> contactIds) {
  //   List<AccountContactRelation> acrs = [
  //     SELECT Id, MTC_Role__c
  //     FROM AccountContactRelation
  //     WHERE ContactId IN :contactIds
  //   ];

  //   for (AccountContactRelation acr : acrs) {
  //     acr.MTC_Role__c = 'Read-Only';
  //   }
  //   update acrs;
  // }

  // @isTest
  // static void whenAssetCreated_allContactsWithUser_ShouldGainAccess() {
  //   List<Account> accounts = [
  //     SELECT Id, Name, (SELECT Id FROM Contacts)
  //     FROM Account
  //     WHERE Name = 'Account 1'
  //   ];
  //   Account acc = accounts[0];

  //   // updateACRsToReadOnly((new Map<Id, Contact>(acc.Contacts)).keySet());

  //   Test.startTest();
  //   List<Asset> reports = TestDataFactory.createReportForAccounts(
  //     accounts,
  //     true
  //   );
  //   List<Asset> deliverables = TestDataFactory.createDeliverableForReports(
  //     reports,
  //     true
  //   );
  //   Test.stopTest();

  //   List<User> users = [
  //     SELECT Id, ContactId, AccountId, Profile.Name
  //     FROM User
  //     WHERE AccountId = :acc.Id
  //   ];

  //   for (User usr : users) {
  //     System.runAs(usr) {
  //       List<Asset> assets = [
  //         SELECT Id, RecordType.Name, Name
  //         FROM Asset
  //         WHERE AccountId = :usr.AccountId
  //       ];
  //       System.assertNotEquals(0, assets.size());
  //       System.debug(JSON.serializePretty(assets));
  //     }
  //   }
  // }

  // // When a relation is created between a contact with user and a non primary account
  // // the user should gain access to the reports if in simplified sharing
  // @isTest
  // static void whenACRCreated_allContactsWithUser_ShouldGainAccess() {
  //   List<Account> accounts = [
  //     SELECT Id, Name, (SELECT Id, AccountId FROM Contacts)
  //     FROM Account
  //     ORDER BY Name
  //   ];
  //   Account acc1 = accounts[0];
  //   Account acc2 = accounts[1];

  //   List<Asset> reports = TestDataFactory.createReportForAccounts(
  //     accounts,
  //     true
  //   );

  //   Test.startTest();
  //   AccountRelationUtil.linkAccountToContacts(
  //     acc1.Id,
  //     acc2.Contacts,
  //     'Read-Only'
  //   );
  //   Test.stopTest();

  //   List<User> users = [
  //     SELECT Id, ContactId, AccountId, Profile.Name
  //     FROM User
  //     WHERE AccountId = :acc2.Id
  //   ];
  //   System.assertEquals(2, users.size());

  //   System.runAs(users[0]) {
  //     List<Asset> assets = [
  //       SELECT Id, RecordType.Name, Name
  //       FROM Asset
  //       WHERE AccountId = :acc1.Id
  //     ];
  //     System.assertNotEquals(0, assets.size());
  //   }
  // }

  // @isTest
  // static void whenAccountToggledToSimplifed_allContactsWithUser_ShouldGainAccess() {
  //   List<Account> accounts = [
  //     SELECT
  //       Id,
  //       Name,
  //       (SELECT Id, AccountId FROM Contacts)
  //     FROM Account
  //     WHERE Is_Simplified_Sharing__c = FALSE
  //     ORDER BY Name
  //   ];
  //   Account acc1 = accounts[0];

  //   List<Asset> reports = TestDataFactory.createReportForAccounts(
  //     accounts,
  //     true
  //   );

  //   User usr1 = TestDataFactory.createCommunityUser(
  //     'MTC Standard Login',
  //     acc1.Id,
  //     acc1.Contacts[0].Id
  //   );

  //   updateACRsToReadOnly(new Set<Id>{ acc1.Contacts[0].Id });

  //   System.runAs(usr1) {
  //     List<Asset> assets = [SELECT Id, RecordType.Name, Name FROM Asset];
  //     System.assertEquals(0, assets.size());
  //   }

  //   Test.startTest();
  //   acc1.Is_Simplified_Sharing__c = true;
  //   update acc1;
  //   Test.stopTest();

  //   System.runAs(usr1) {
  //     List<Asset> assets = [SELECT Id, RecordType.Name, Name FROM Asset];
  //     System.assertEquals(1, assets.size());
  //   }
  // }
}