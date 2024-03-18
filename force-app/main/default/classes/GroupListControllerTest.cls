@isTest
public with sharing class GroupListControllerTest {
  @TestSetup
  static void createData() {
    Account a = TestDataFactory.createAccount();
    TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
    TestDataFactory.createCommunityUser('MTC Standard Login', a.Id);

    TestDataFactory.createContactGroup(a.Id);
    User u = [
      SELECT Contact.AccountId, ContactId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND AccountId = :a.Id
      LIMIT 1
    ];
    a.CGA_Id__c = u.ContactId;
    update a;
  }

  // getTableData with an MTC Admin Login (CGA) user who should have access to one group
  @isTest
  private static void Test_1_1() {
    User u = [
      SELECT Contact.AccountId, ContactId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'CGA'
    );
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = GroupListController.getTableData(
        6,
        'CreatedDate DESC',
        new List<String>(),
        '',
        '',
        ''
      );
    }
    Test.stopTest();
    System.assertEquals(2, result.table.rows.size());
  }

  // getTableData with an MTC Admin Login (Admin) user who should have access to one group
  @isTest
  private static void Test_1_2() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [SELECT Id FROM Contact_Group__c LIMIT 1];
    Group_Membership__c gm = TestDataFactory.createGroupMembership(
      u.ContactId,
      cg.Id
    );
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'Admin'
    );
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = GroupListController.getTableData(
        6,
        'CreatedDate DESC',
        new List<String>(),
        '',
        '',
        ''
      );
    }
    Test.stopTest();
    System.assertEquals(2, result.table.rows.size());
  }

  // getTableData with an MTC Standard Login user who should be able to see any groups related to their account
  @isTest
  private static void Test_1_3() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [SELECT Id FROM Contact_Group__c LIMIT 1];
    Group_Membership__c gm = TestDataFactory.createGroupMembership(
      u.ContactId,
      cg.Id
    );
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'Read-Only'
    );
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = GroupListController.getTableData(
        6,
        'CreatedDate DESC',
        new List<String>(),
        '',
        '',
        ''
      );
    }
    Test.stopTest();
    System.assertEquals(2, result.table.rows.size());
  }

  // getTableData with an MTC Admin Login (CGA) user who should have access to zero groups
  @isTest
  private static void Test_1_4() {
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
    delete [SELECT Id FROM Contact_Group__c WHERE Is_Default_Group__c = FALSE];
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = GroupListController.getTableData(
        6,
        'CreatedDate DESC',
        new List<String>(),
        '',
        '',
        ''
      );
    }
    Test.stopTest();
    System.assert(result.table.rows.size() == 1);
  }

  // getTableData with an MTC Admin Login (Admin) user who should have access to zero groups
  @isTest
  private static void Test_1_5() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'Admin'
    );
    delete [SELECT Id FROM Contact_Group__c WHERE Is_Default_Group__c = FALSE];

    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = GroupListController.getTableData(
        6,
        'CreatedDate DESC',
        new List<String>(),
        '',
        '',
        ''
      );
    }
    Test.stopTest();
    System.assert(result.table.rows.size() == 1);
  }

  // getTableData with an MTC Admin Login (CGA) user who should have access to one group, who has filtered using a valid keyword
  @isTest
  private static void Test_1_6() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [
      SELECT Id, Group_Name__c
      FROM Contact_Group__c
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'CGA'
    );
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = GroupListController.getTableData(
        6,
        'CreatedDate DESC',
        new List<String>(),
        cg.Group_Name__c,
        'test',
        ''
      );
    }
    Test.stopTest();
    System.assertEquals(1, result.table.rows.size());
  }

  // getTableData with an MTC Admin Login (CGA) user who should have access to one group, who has filtered using an invalid keyword
  @isTest
  private static void Test_1_7() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [
      SELECT Id, Group_Name__c
      FROM Contact_Group__c
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'CGA'
    );
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = GroupListController.getTableData(
        6,
        'CreatedDate DESC',
        new List<String>(),
        '',
        'NotAGroupName',
        ''
      );
    }
    Test.stopTest();
    System.assert(result.table.rows.size() == 0);
  }

  // getTableData for the home page with an MTC Admin Login (CGA) user who should have access to one group
  @isTest
  private static void Test_2_1() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [
      SELECT Id, Group_Name__c
      FROM Contact_Group__c
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'CGA'
    );
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = GroupListController.getTableData(
        6,
        'CreatedDate DESC',
        new List<String>(),
        'home',
        '',
        ''
      );
    }
    Test.stopTest();
    System.assertEquals(2, result.table.rows.size());
  }

  // Testing checkForDupeGroup with a dupe group name
  @isTest
  private static void Test_3_1() {
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
    Test.startTest();
    String result;
    System.runAs(u) {
      result = GroupListController.checkForDupeGroup(
        'Test',
        u.Contact.AccountId
      );
    }
    Test.stopTest();
    System.assertEquals('true', result);
  }

  // Testing checkForDupeGroup with a non-dupe group name
  @isTest
  private static void Test_3_2() {
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
    Test.startTest();
    String result;
    System.runAs(u) {
      result = GroupListController.checkForDupeGroup(
        'NotADupe',
        u.Contact.AccountId
      );
    }
    Test.stopTest();
    System.assertEquals('false', result);
  }

  // Testing insertGroup with a duplicate group name
  @isTest
  private static void Test_4_1() {
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
    Test.startTest();
    APIResponse result;
    System.runAs(u) {
      Contact_Group__c cg = new Contact_Group__c(
        Group_Name__c = 'Test',
        Account__c = u.Contact.AccountId
      );
      result = GroupListController.insertGroup(cg);
    }
    Test.stopTest();
    System.assertEquals('Bad Request', result.status);
  }

  // Testing insertGroup with a valid group name
  @isTest
  private static void Test_4_2() {
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
    Test.startTest();
    APIResponse result;
    System.runAs(u) {
      Contact_Group__c cg = new Contact_Group__c(
        Group_Name__c = 'NotADuplicate',
        Account__c = u.Contact.AccountId
      );
      result = GroupListController.insertGroup(cg);
    }
    Test.stopTest();
    System.assertEquals('OK', result.status);
  }

  // getAccountOptions
  @isTest
  private static void Test_5_1() {
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
    Test.startTest();
    List<Map<String, String>> result;
    System.runAs(u) {
      result = GroupListController.getAccountOptions();
    }
    Test.stopTest();
    System.assertEquals(1, result.size());
  }

  // updateGroup
  @isTest
  private static void Test_6_1() {
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
    Contact_Group__c cg = new Contact_Group__c(
      Group_Name__c = 'NotADuplicate',
      Account__c = u.Contact.AccountId
    );
    Test.startTest();
    insert cg;
    Test.stopTest();

    APIResponse result;
    cg.Group_Name__c = 'UPDATED NAME';
    System.runAs(u) {
      result = GroupListController.updateGroup(cg);
    }
    System.assertEquals('OK', result.status);
  }

  // updateGroup with duplicate group name
  @isTest
  private static void Test_7_1() {
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
    Contact_Group__c cg = new Contact_Group__c(
      Group_Name__c = 'Some name',
      Account__c = u.Contact.AccountId
    );
    GroupListController.insertGroup(cg);
    Contact_Group__c cg2 = new Contact_Group__c(
      Group_Name__c = 'Duplicate',
      Account__c = u.Contact.AccountId
    );
    GroupListController.insertGroup(cg2);
    Test.startTest();
    APIResponse result;
    cg.Group_Name__c = 'Duplicate';
    System.runAs(u) {
      result = GroupListController.updateGroup(cg);
    }
    Test.stopTest();
    System.assertEquals('Bad Request', result.status);
  }

  // deleteGroup
  @isTest
  private static void Test_8_1() {
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
    Test.startTest();
    APIResponse result;
    System.runAs(u) {
      List<Contact_Group__c> groups = new List<Contact_Group__c>{
        new Contact_Group__c(
          Group_Name__c = 'OneGroup',
          Account__c = u.Contact.AccountId
        ),
        new Contact_Group__c(
          Group_Name__c = 'AnotherGroup',
          Account__c = u.Contact.AccountId
        )
      };
      insert groups;
      result = GroupListController.deleteGroups(
        new List<String>{ groups[0].Id, groups[1].Id }
      );
    }
    Test.stopTest();
    System.assertEquals('OK', result.status);
  }

  // restoreGroups
  @isTest
  private static void Test_8_2() {
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
    Test.startTest();
    APIResponse result;
    System.runAs(u) {
      List<Contact_Group__c> groups = new List<Contact_Group__c>{
        new Contact_Group__c(
          Group_Name__c = 'OneGroup',
          Account__c = u.Contact.AccountId
        ),
        new Contact_Group__c(
          Group_Name__c = 'AnotherGroup',
          Account__c = u.Contact.AccountId,
          Expiry__c = System.today().addDays(-5) //Expired
        )
      };
      insert groups;
      result = GroupListController.restoreGroups(
        new List<String>{ groups[0].Id, groups[1].Id }
      );
    }
    Test.stopTest();
    System.assertEquals('OK', result.status);
  }

  @isTest
  static void exportGroupsToCSV() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Id accountId = u.Contact.AccountId;
    TestDataFactory.updateAccountContactRelation(accountId, u.ContactId, 'CGA');
    List<Contact_Group__c> moreGroups = new List<Contact_Group__c>();
    for (
      String g : new List<String>{
        'one',
        'another',
        'encore un autre',
        'otra mas',
        'viel mehr'
      }
    ) {
      moreGroups.add(
        new Contact_Group__c(Group_Name__c = g, Account__c = accountId)
      );
    }
    moreGroups.add(
      new Contact_Group__c(
        Group_Name__c = 'yet another with descr',
        Account__c = accountId,
        Group_Description__c = 'La description du groupe'
      )
    );
    insert moreGroups;
    Test.startTest();
    System.runAs(u) {
      String csv = GroupListController.exportAsCSV();
      System.debug(csv);
      System.assert(csv.length() > 100);
      System.assert(csv.contains('La description du groupe'));
    }
    Test.stopTest();
  }
}