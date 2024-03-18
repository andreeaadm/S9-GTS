@isTest
public with sharing class ManageCompaniesPanelControllerTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    ReportAccessUtil.disableSharingProcessing();
    Account a = TestDataFactory.createAccount();
    User mtcAdmin = TestDataFactory.createCommunityUser(
      'MTC Admin Login',
      a.Id
    );
    User mtcStandard = TestDataFactory.createCommunityUser(
      'MTC Standard Login',
      a.Id
    );

    ReportAccessUtil.enableSharingProcessing();
  }

  // Test as a community user who is a CGA account contact relation on their account
  @isTest
  private static void test_1_1() {
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
    Map<String, Object> results;
    System.runAs(u) {
      results = ManageCompaniesPanelController.getData();
    }
    Test.stopTest();
    System.assert(results.get('message') == '');
    System.assert(results.get('isCga') == true);
    System.assert(results.get('isAdmin') == true);
  }

  // Test as a community user who is an Admin account contact relation on their account, where there is no CGA
  @isTest
  private static void test_1_2() {
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
    Test.startTest();
    Map<String, Object> results;
    System.runAs(u) {
      results = ManageCompaniesPanelController.getData();
    }
    Test.stopTest();
    System.assert(results.get('message') == '');
    System.assert(results.get('isCga') == false);
    System.assert(results.get('isAdmin') == true);
  }

  // Test as a community user who is an Admin account contact relation on their account, where there is a CGA
  @isTest
  private static void test_1_3() {
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
    Account a = [SELECT Id FROM Account LIMIT 1];
    User cga = TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
    cga = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Id = :cga.Id
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      cga.Contact.AccountId,
      cga.ContactId,
      'CGA'
    );
    Test.startTest();
    Map<String, Object> results;
    System.runAs(u) {
      results = ManageCompaniesPanelController.getData();
    }
    Test.stopTest();
    System.assert(results.get('message') != '');
    System.assert(results.get('isCga') == false);
    System.assert(results.get('isAdmin') == true);
  }
}