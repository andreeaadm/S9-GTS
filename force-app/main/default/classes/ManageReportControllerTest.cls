@isTest
public with sharing class ManageReportControllerTest {
  @TestSetup
  static void createData() {
    Account a = TestDataFactory.createAccount();
    TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
    TestDataFactory.createCommunityUser('MTC Standard Login', a.Id);

    TestDataFactory.createContactGroup(a.Id);
    TestDataFactory.createReportForAccount(a.Id, true);
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    a.CGA_Id__c = u.ContactId;
    update a;
  }

  // getTableData with an MTC Admin Login (CGA) user where 1 report is selected, in manage mode
  @isTest
  private static void Test_1_1() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [
      SELECT Id
      FROM Contact_Group__c
      WHERE Is_Default_Group__c = FALSE
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'CGA'
    );
    Id reportId = [SELECT Id FROM Asset LIMIT 1].Id;
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = ManageReportController.getTableData(
        6,
        '',
        '',
        'Group_Name__c DESC',
        new List<String>{ reportId },
        'manage'
      );
    }
    Test.stopTest();
    System.assertEquals(2, result.table.rows.size());
  }

  // getTableData with an MTC Admin Login (CGA) user where 1 report is selected, in assign mode
  @isTest
  private static void Test_1_2() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [SELECT Id FROM Contact_Group__c LIMIT 1];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'CGA'
    );
    Id reportId = [SELECT Id FROM Asset LIMIT 1].Id;
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = ManageReportController.getTableData(
        6,
        'Test',
        '',
        'Group_Name__c DESC',
        new List<String>{ reportId },
        'assign'
      );
    }
    Test.stopTest();
    System.assert(result.table.rows.size() == 1);
  }

  // getTableData with an MTC Admin Login (CGA) user where 1 report is selected, in retract mode
  @isTest
  private static void Test_1_3() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [SELECT Id FROM Contact_Group__c LIMIT 1];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'CGA'
    );
    Id reportId = [SELECT Id FROM Asset LIMIT 1].Id;
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = ManageReportController.getTableData(
        6,
        '',
        '',
        'Group_Name__c DESC',
        new List<String>{ reportId },
        'retract'
      );
    }
    Test.stopTest();
    System.assertEquals(2, result.table.rows.size());
  }

  // manage() with an MTC Admin Login (CGA) user where 1 report is selected, and 1 group is selected
  @isTest
  private static void Test_2_1() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [SELECT Id FROM Contact_Group__c LIMIT 1];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'CGA'
    );
    Id reportId = [SELECT Id FROM Asset LIMIT 1].Id;
    Test.startTest();
    APIResponse result;
    System.runAs(u) {
      result = ManageReportController.manage(
        new List<String>{ reportId },
        new List<String>{ cg.Id }
      );
    }
    Test.stopTest();
    System.assert(result.status == 'OK');
  }

  // assign() with an MTC Admin Login (CGA) user where 1 report is selected, and 1 group is selected
  @isTest
  private static void Test_2_2() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [SELECT Id FROM Contact_Group__c LIMIT 1];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'CGA'
    );
    Id reportId = [SELECT Id FROM Asset LIMIT 1].Id;
    Test.startTest();
    APIResponse result;
    System.runAs(u) {
      result = ManageReportController.assign(
        new List<String>{ reportId },
        new List<String>{ cg.Id }
      );
    }
    Test.stopTest();
    System.assert(result.status == 'OK');
  }

  // retract() with an MTC Admin Login (CGA) user where 1 report is selected, and 1 group is selected
  @isTest
  private static void Test_2_3() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [SELECT Id FROM Contact_Group__c LIMIT 1];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'CGA'
    );
    Id reportId = [SELECT Id FROM Asset LIMIT 1].Id;
    Test.startTest();
    APIResponse result;
    System.runAs(u) {
      result = ManageReportController.retract(
        new List<String>{ reportId },
        new List<String>{ cg.Id }
      );
    }
    Test.stopTest();
    System.assert(result.status == 'OK');
  }

  // manage() with an MTC Admin Login (Admin) user where 1 report is selected, and 1 group is selected
  @isTest
  private static void Test_2_5_As_Admin_Manage() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact_Group__c cg = [
      SELECT Id
      FROM Contact_Group__c
      WHERE Is_Default_Group__c = FALSE
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      u.Contact.AccountId,
      u.ContactId,
      'Admin'
    );
    Id reportId = [SELECT Id FROM Asset LIMIT 1].Id;
    Test.startTest();
    APIResponse result;
    System.runAs(u) {
      result = ManageReportController.manage(
        new List<String>{ reportId },
        new List<String>{ cg.Id }
      );
    }
    Test.stopTest();
    System.assert(result.status == 'OK');
  }
}