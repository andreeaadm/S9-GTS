@isTest
private with sharing class ContactGroupUtilTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    List<Account> accounts = TestDataFactory.createAccounts(2, true);
    TestDataFactory.createAccountsWithContacts(accounts, 2);
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      true
    );
    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = accounts[0].Id,
      Group_Name__c = 'group-g'
    );
    insert groupG;
    List<Contact> cons = [
      SELECT Id, FirstName, LastName, Email, AccountId
      FROM Contact
      WHERE Account.Name = 'Account 2'
    ];
    TestDataFactory.createCommunityUsers('MTC Admin Login', cons);
  }
  @isTest
  static void verifyUpdateHasExpiredFieldOnUpdateNoDML() {
    Account acc = new Account(Name = 'Account One', Is_MTC_Account__c = true);
    insert acc;

    Contact_Group__c cg = new Contact_Group__c(
      Account__c = acc.Id,
      Group_Name__c = 'group-a',
      Expiry__c = Date.today() - 1
    );
    insert cg;

    cg = [
      SELECT Expiry__c, Has_Expired__c
      FROM Contact_Group__c
      WHERE Id = :cg.Id
    ];
    System.assertEquals(true, cg.Has_Expired__c);

    cg.Expiry__c = Date.today() + 10;
    update cg;

    cg = [
      SELECT Expiry__c, Has_Expired__c
      FROM Contact_Group__c
      WHERE Id = :cg.Id
    ];
    System.assertEquals(false, cg.Has_Expired__c);
  }

  @isTest
  static void customerCannotRenameDefaultGroup() {
    User mtcAdmin = [
      SELECT Id, AccountId
      FROM User
      WHERE Account.Name = 'Account 2'
      LIMIT 1
    ];
    Contact_Group__c defaultGroup = [
      SELECT Id, Group_Name__c
      FROM Contact_Group__c
      WHERE Is_Default_Group__c = TRUE AND Account__r.Name = 'Account 2'
    ];
    System.runAs(mtcAdmin) {
      try {
        defaultGroup.Group_Name__c = 'something';
        update defaultGroup;
        System.assert(
          false,
          'This statement should not be reached. The customer was able to rename a defaultGroup.'
        );
      } catch (Exception e) {
      }
    }
  }
  @isTest
  static void customerCannotDeleteDefaultGroup() {
    User mtcAdmin = [
      SELECT Id, AccountId
      FROM User
      WHERE Account.Name = 'Account 2'
      LIMIT 1
    ];
    Contact_Group__c defaultGroup = [
      SELECT Id, Group_Name__c
      FROM Contact_Group__c
      WHERE Is_Default_Group__c = TRUE AND Account__r.Name = 'Account 2'
    ];
    System.runAs(mtcAdmin) {
      try {
        delete defaultGroup;
        System.assert(
          false,
          'This statement should not be reached. The customer was able to delete a defaultGroup.'
        );
      } catch (Exception e) {
      }
    }
  }

  @isTest
  static void emptyParameters() {
    Asset rep;
    Contact con;
    Contact_Group__c cg;

    System.assertNotEquals(
      null,
      ContactGroupUtil.linkGroupToReport(cg, rep, false)
    );

    System.assertNotEquals(
      null,
      ContactGroupUtil.linkContactToGroup(con, cg, false)
    );
  }

  @isTest
  static void verifyLinkGroupToReport() {
    Contact_Group__c groupG = [
      SELECT Account__c, Group_Name__c
      FROM Contact_Group__c
      WHERE Group_Name__c = 'group-g'
    ];

    Asset report = [
      SELECT Id
      FROM Asset
      WHERE AccountId = :groupG.Account__c
      LIMIT 1
    ];

    System.assertEquals(
      0,
      [SELECT Id FROM Access__c WHERE Contact_Group__c = :groupG.Id].size()
    );

    Test.startTest();
    ContactGroupUtil.linkGroupToReport(groupG, report, true);
    Test.stopTest();

    List<Access__c> accesses = [
      SELECT Id, Report_Asset__c, DupCheck__c
      FROM Access__c
      WHERE Contact_Group__c = :groupG.Id
    ];
    System.assertEquals(1, accesses.size());
    System.assertEquals(report.Id, accesses[0].Report_Asset__c);
    System.assertEquals('' + groupG.Id + report.Id, accesses[0].DupCheck__c);
  }

  @isTest
  static void verifyLinkContactToGroup() {
    Contact_Group__c groupG = [
      SELECT Account__c, Group_Name__c
      FROM Contact_Group__c
      WHERE Group_Name__c = 'group-g'
    ];
    Contact con = [SELECT Id FROM Contact LIMIT 1];

    System.assertEquals(
      0,
      [SELECT Id, Contact_Group__c, Contact__c FROM Group_Membership__c].size()
    );

    Test.startTest();
    ContactGroupUtil.linkContactToGroup(con, groupG, true);
    Test.stopTest();

    List<Group_Membership__c> members = [
      SELECT Id, Contact_Group__c, Contact__c, DupCheck__c
      FROM Group_Membership__c
    ];
    System.assertEquals(1, members.size());
    System.assertEquals(groupG.Id, members[0].Contact_Group__c);
    System.assertEquals(con.Id, members[0].Contact__c);
    System.assertEquals('' + con.Id + groupG.Id, members[0].DupCheck__c);
  }

  @isTest
  static void verifyUnlinkContactsFromGroup() {
    Contact_Group__c groupG = [
      SELECT Account__c, Group_Name__c
      FROM Contact_Group__c
      WHERE Group_Name__c = 'group-g'
    ];
    List<Group_Membership__c> members = new List<Group_Membership__c>();
    for (Contact con : [SELECT Id FROM Contact]) {
      members.add(ContactGroupUtil.linkContactToGroup(con, groupG, false));
    }
    insert members;

    Test.startTest();
    ContactGroupUtil.unlinkContactsFromGroup([SELECT Id FROM Contact], groupG);
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT Id FROM Group_Membership__c WHERE Contact_Group__c = :groupG.Id]
        .size()
    );
  }

  @isTest
  static void verifyUnlinkContactsFromGroups() {
    Contact_Group__c groupG = [
      SELECT Id, Account__c, Group_Name__c
      FROM Contact_Group__c
      WHERE Group_Name__c = 'group-g'
    ];
    List<Group_Membership__c> members = new List<Group_Membership__c>();
    Set<Id> contactIds = new Set<Id>();
    for (Contact con : [SELECT Id FROM Contact]) {
      contactIds.add(con.Id);
    }
    members = ContactGroupUtil.linkContactsToGroups(
      contactIds,
      new List<Id>{ groupG.Id },
      true
    );
    System.assert(members.size() > 0);

    Test.startTest();
    ContactGroupUtil.unlinkContactsFromGroups(
      contactIds,
      new List<Id>{ groupG.Id }
    );
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT Id FROM Group_Membership__c WHERE Contact_Group__c = :groupG.Id]
        .size()
    );
  }

  @isTest
  static void verifyinkContactsToGroups() {
    Contact_Group__c groupG = [
      SELECT Id, Account__c, Group_Name__c
      FROM Contact_Group__c
      WHERE Group_Name__c = 'group-g'
    ];
    List<Group_Membership__c> members = new List<Group_Membership__c>();
    Set<Id> contactIds = new Set<Id>();
    for (Contact con : [SELECT Id FROM Contact]) {
      contactIds.add(con.Id);
    }
    Test.startTest();
    members = ContactGroupUtil.linkContactsToGroups(
      contactIds,
      new List<Id>{ groupG.Id },
      true
    );
    Test.stopTest();
    System.assert(members.size() > 0);
    System.assertEquals(
      members.size(),
      [SELECT Id FROM Group_Membership__c WHERE Contact_Group__c = :groupG.Id]
        .size()
    );
  }

  @isTest
  static void verifyGroupMembershipsForUser() {
    Contact_Group__c groupG = [
      SELECT Id, Account__c, Group_Name__c
      FROM Contact_Group__c
      WHERE Group_Name__c = 'group-g'
    ];

    User commUser = TestDataFactory.createCommunityUser(
      'MTC Admin Login',
      groupG.Account__c
    );
    Id contactId = [SELECT ContactId FROM User WHERE Id = :commUser.Id]
    .ContactId;

    ContactGroupUtil.linkContactsToGroups(
      new Set<Id>{ contactId },
      new List<Id>{ groupG.Id },
      true
    );
    Test.startTest();
    List<Group_Membership__c> members = ContactGroupUtil.getGroupMembershipsForUser(
      commUser.Id
    );
    Test.stopTest();

    System.assertEquals(members.size(), 1);
  }

  @isTest
  static void asaMTCAdminIcanCreateAContactGroup() {
    Contact adminCon = [
      SELECT AccountId
      FROM Contact
      WHERE Account.Name = 'Account 2'
      LIMIT 1
    ];
    User adminUser = [SELECT Id FROM User WHERE ContactId = :adminCon.Id];
    System.runAs(adminUser) {
      Contact_Group__c cg1 = ContactGroupUtil.constructGroup(
        adminCon.AccountId,
        'group1account2'
      );
      insert cg1;
    }
  }

  @isTest
  static void verifyGetAssociatedAccountIdsPerContactFromGroupMemberships() {
    Contact_Group__c cgrp = [
      SELECT Id
      FROM Contact_Group__c
      WHERE Is_Default_Group__c = FALSE
    ];
    List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
    List<Group_Membership__c> members = ContactGroupUtil.linkContactsToGroups(
      new Set<Id>{ contacts.get(0).Id, contacts.get(1).Id },
      new List<Id>{ cgrp.Id },
      true
    );
    //List<Group_Membership__c> members = [SELECT Contact__c FROM Group_Membership__c];

    Test.startTest();
    Map<Id, Id> accountIdsPerContacts = ContactGroupUtil.getAssociatedAccountIdsPerContactFromGroupMemberships(
      members
    );
    Test.stopTest();

    System.AssertEquals(
      contacts.get(0).AccountId,
      accountIdsPerContacts.get(contacts.get(0).Id)
    );
    System.AssertEquals(
      contacts.get(1).AccountId,
      accountIdsPerContacts.get(contacts.get(1).Id)
    );
  }

  @isTest
  static void verifyGetContactGroupIdsAndAssociatedAccountIdsFromGroupMemberships() {
    Contact_Group__c cgrp = [
      SELECT Id
      FROM Contact_Group__c
      WHERE Is_Default_Group__c = FALSE
    ];
    List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
    List<Group_Membership__c> members = ContactGroupUtil.linkContactsToGroups(
      new Set<Id>{ contacts.get(0).Id },
      new List<Id>{ cgrp.Id },
      true
    );

    Test.startTest();
    Map<Id, Id> contactGroupToAccountIds = ContactGroupUtil.getContactGroupIdsAndAssociatedAccountIdsFromGroupMemberships(
      members
    );
    Test.stopTest();

    System.AssertEquals(
      contacts.get(0).AccountId,
      contactGroupToAccountIds.get(cgrp.Id)
    );
  }
}