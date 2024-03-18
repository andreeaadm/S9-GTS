@isTest
public with sharing class UserListControllerTest {
  @TestSetup
  static void createData() {
    Account a = TestDataFactory.createAccount();
    User admUser = TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
    User stdUser = TestDataFactory.createCommunityUser(
      'MTC Standard Login',
      a.Id
    );

    TestDataFactory.createContactGroup(a.Id);
    admUser = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Id = :admUser.Id
    ];
    stdUser = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Id = :stdUser.Id
    ];

    a.CGA_Id__c = admUser.ContactId;
    update a;

    TestDataFactory.updateAccountContactRelation(
      a.Id,
      admUser.ContactId,
      'cga'
    );
    TestDataFactory.updateAccountContactRelation(
      a.Id,
      stdUser.ContactId,
      'read-only'
    );
  }

  @isTest
  private static void UserListController_WithUserData_DisplaysUsersAndCorrectRelatedColumns() {
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
    ListResponse result;
    System.runAs(u) {
      result = UserListController.getTableData(
        10,
        '',
        new List<String>(),
        '',
        '',
        '',
        '',
        '',
        false,
        null
      );
    }
    Test.stopTest();
    System.assertEquals(2, result.table.rows.size());
  }

  @isTest
  private static void userList_Home() {
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
    ListResponse result;
    System.runAs(u) {
      result = UserListController.getTableData(
        10,
        '',
        new List<String>(),
        'home',
        '',
        '',
        '',
        '',
        false,
        null
      );
    }
    Test.stopTest();
    System.assertEquals(2, result.table.rows.size());
  }

  @isTest
  private static void userList_TestingMoreFilters() {
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
    ListResponse result;
    System.runAs(u) {
      result = UserListController.getTableData(
        10,
        'LastLoginDate DESC',
        new List<String>(),
        '',
        'Active',
        'test@test.com',
        String.valueOf(Date.today()),
        String.valueOf(Date.today()),
        false,
        null
      );
    }
    Test.stopTest();
    System.assert(result.table.rows.size() == 0);
  }

  @isTest
  private static void exportingUsers() {
    User u = [
      SELECT Contact.AccountId, ContactId, Username, Contact.Email
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    Test.startTest();
    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c, Contact.Email
      FROM AccountContactRelation
      WHERE Account.Name = 'Test'
    ];
    for (AccountContactRelation acr : acrs) {
      acr.MTC_Role__c = 'Admin';
    }
    update acrs;

    Test.stopTest();

    String result;
    System.runAs(u) {
      result = UserListController.exportAsCSV();
    }

    System.assert(result.length() > 100);
    System.assertEquals(true, result.containsIgnoreCase(u.Contact.Email));
  }
}