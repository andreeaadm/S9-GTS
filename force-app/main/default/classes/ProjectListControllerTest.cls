@isTest
public with sharing class ProjectListControllerTest {
  @TestSetup
  static void createData() {
    Account a = TestDataFactory.createAccount();
    TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
    TestDataFactory.createCommunityUser('MTC Standard Login', a.Id);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      TestDataFactory.createAdminUser();
    }
    TestDataFactory.createContactGroup(a.Id);
    TestDataFactory.createProject(a.Id, true);
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    a.CGA_Id__c = u.ContactId;
    update a;
  }

  @isTest
  private static void getRelatedReportsAsTableData() {
    MTC_Project__c project = [SELECT Id FROM MTC_Project__c LIMIT 1];
    Asset a = new Asset(
      Name = 'Something',
      Type__c = 'PDF',
      MTC_Project__c = project.Id
    );
    insert a;

    // ListResponse getRelatedReportsAsTableData(Id projectId)
    Test.startTest();
    ListResponse result = ProjectListController.getRelatedReportsAsTableData(
      project.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
  }

  // getTableData with an MTC Admin Login (CGA) user who should have access to one project
  @isTest
  private static void Test_1_1() {
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
      result = ProjectListController.getTableData(
        6,
        'Name DESC',
        '',
        '',
        '',
        '',
        ''
      );
    }
    Test.stopTest();
    System.assert(result.table.rows.size() == 1);
  }

  // getTableData with an MTC Admin Login user who shouldn't have access to any projects
  @isTest
  private static void Test_1_3() {
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
    delete [SELECT Id FROM MTC_Project__c];
    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = ProjectListController.getTableData(
        6,
        'Schedule_Complete__c DESC',
        '',
        '',
        '',
        '',
        ''
      );
    }
    Test.stopTest();
    System.assert(result.table.rows.size() == 0);
  }

  // getTableData with an MTC Admin Login (CGA) user who should have access to one project after filtering
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
    MTC_Project__c p = [SELECT Id FROM MTC_Project__c LIMIT 1];
    p.Status__c = 'In Process';
    p.Name = 'Test';
    update p;

    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = ProjectListController.getTableData(
        6,
        'Status__c DESC',
        '',
        'In Process',
        'Test',
        String.valueOf(Date.today()),
        String.valueOf(Date.today())
      );
    }
    Test.stopTest();
   System.assertEquals(1, result.table.rows.size(), 'It is expected that a table with one row of data would be returned. Actual size: ' + result);
  }
  @isTest
  private static void exportingProjects() {
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
    MTC_Project__c p = [SELECT Id FROM MTC_Project__c LIMIT 1];

    Test.startTest();

    String result = '';
    System.runAs(u) {
      result = ProjectListController.exportAsCSV();
    }
    Test.stopTest();

    System.assert(result.containsIgnoreCase('test'));
    System.assert(result.containsIgnoreCase('in process'));
    System.assert(result.length() > 150);
  }
}