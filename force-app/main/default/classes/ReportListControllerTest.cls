@isTest
public with sharing class ReportListControllerTest {
  @TestSetup
  static void createData() {
    Account a = TestDataFactory.createAccount();
    TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
    TestDataFactory.createCommunityUser('MTC Standard Login', a.Id);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      TestDataFactory.createAdminUser();
    }
    TestDataFactory.createContactGroup(a.Id);
    TestDataFactory.createReportForAccount(a.Id, true);
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
  }

  // getTableData with an MTC Admin Login (CGA) user who should have access to one report
  @isTest
  private static void Test_1_1() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = ReportListController.getTableData(
        6,
        'Type__c DESC',
        new List<String>(),
        '',
        '',
        '',
        '',
        '',
        '',
        false,
        false,
        false,
        null
      );
    }
    Test.stopTest();
    System.assert(result.table.rows.size() == 1);
  }

  // getTableData with an MTC Admin Login (CGA) user, in the home context, who has access to one report
  @isTest
  private static void Test_1_2() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = ReportListController.getTableData(
        6,
        'Date_Issued__c DESC',
        new List<String>(),
        'home',
        '',
        '',
        '',
        '',
        '',
        false,
        false,
        false,
        null
      );
    }
    Test.stopTest();
    System.assert(result.table.rows.size() == 1);
  }

  // getTableData with an MTC Admin Login (CGA) user who has access to one report, with filters applied in a way which should give 1 result
  @isTest
  private static void Test_1_3() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    Asset asset = [SELECT Id FROM Asset LIMIT 1];
    asset.Is_Hidden_By_Intertek__c = false;
    asset.Name = 'Report';
    update asset;

    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = ReportListController.getTableData(
        6,
        'Client_Reference__c DESC',
        new List<String>(),
        '',
        '',
        'Report',
        'Report',
        String.valueOf(Date.today()),
        String.valueOf(Date.today()),
        true,
        false,
        false,
        null
      );
    }
    Test.stopTest();
    System.assertEquals(1, result.table.rows.size(), 'It is expected that a table with one row of data would be returned. Actual: ' + result);
  }

  // getTableData with an MTC Admin Login (CGA) user who has access to one report, with filters applied in a way which should give 0 results
  @isTest
  private static void Test_1_4() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = ReportListController.getTableData(
        6,
        'Client_Reference__c DESC',
        new List<String>(),
        '',
        'Invalid',
        'Invalid',
        'Invalid',
        String.valueOf(Date.today()),
        String.valueOf(Date.today()),
        false,
        false,
        false,
        null
      );
    }
    Test.stopTest();
    System.assert(result.table.rows.size() == 0);
  }

  // hideReports with an MTC Admin Login (CGA) user who has access to one report
  // @isTest
  private static void Test_2_1() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    Asset asset = [SELECT Id FROM Asset LIMIT 1];

    Test.startTest();
    APIResponse result;
    System.runAs(u) {
      result = ReportListController.hideReports(new List<String>{ asset.Id });
    }
    Test.stopTest();
    // needs reimplementing at user/contact level
    // asset = [
    //   SELECT Is_Hidden_By_CustomerXXXX__c
    //   FROM Asset
    //   WHERE Id = :asset.Id
    //   LIMIT 1
    // ];
  }

  // report hidden by Intertek should not be returned
  @isTest
  private static void Test_3_1() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    Asset asset = [SELECT Id FROM Asset LIMIT 1];
    asset.Is_Hidden_By_Intertek__c = true;
    update asset;

    Test.startTest();
    ListResponse result;
    System.runAs(u) {
      result = ReportListController.getTableData(
        6,
        'Client_Reference__c DESC',
        new List<String>(),
        '',
        'Official',
        'Report',
        'Report',
        String.valueOf(Date.today()),
        String.valueOf(Date.today()),
        false,
        false,
        false,
        null
      );
    }
    Test.stopTest();
    System.assertEquals(0, result.table.rows.size());
  }

  @isTest
  private static void exportingReports() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    Test.startTest();
    String result;
    System.runAs(u) {
      result = ReportListController.exportAsCSV();
    }
    Test.stopTest();
    System.assert(result.length() > 100);
  }
}