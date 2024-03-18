@isTest
public with sharing class ReportDeliverableListControllerTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    ReportAccessUtil.disableSharingProcessing();
    List<Account> accounts = TestDataFactory.createAccounts(2, true);
    TestDataFactory.createAccountsWithContacts(accounts, 3);
    List<Contact> cons = [
      SELECT
        Id,
        FirstName,
        LastName,
        Email,
        AccountId,
        (SELECT MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      ORDER BY LastName
    ];
    TestDataFactory.createCommunityUsers(
      new List<String>{
        'MTC Admin Login',
        'MTC Admin Login',
        'MTC Standard Login',
        'MTC Admin Login',
        'MTC Admin Login',
        'MTC Standard Login'
      },
      cons
    );
    update new List<AccountContactRelation>{
      new AccountContactRelation(
        Id = cons[0].AccountContactRelations[0].Id,
        MTC_Role__c = 'CGA'
      ),
      new AccountContactRelation(
        Id = cons[1].AccountContactRelations[0].Id,
        MTC_Role__c = 'Admin'
      ),
      new AccountContactRelation(
        Id = cons[2].AccountContactRelations[0].Id,
        MTC_Role__c = 'Read-Only'
      ),
      new AccountContactRelation(
        Id = cons[3].AccountContactRelations[0].Id,
        MTC_Role__c = 'CGA'
      ),
      new AccountContactRelation(
        Id = cons[4].AccountContactRelations[0].Id,
        MTC_Role__c = 'Admin'
      ),
      new AccountContactRelation(
        Id = cons[5].AccountContactRelations[0].Id,
        MTC_Role__c = 'Read-Only'
      )
    };
    ReportAccessUtil.enableSharingProcessing();
  }
  @isTest
  static void allUserCanAccessDeliverables() {
    ReportAccessUtil.enableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;
    List<Account> accounts = [SELECT Id FROM Account];
    Test.startTest();
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      true
    );
    TestDataFactory.createDeliverableForReports(reports, true);

    Test.stopTest();
    List<User> users = [
      SELECT Id, Username, Profile.Name
      FROM User
      WHERE Account.Name = 'Account 1'
    ];
    for (User u : users) {
      System.runAs(u) {
        List<Asset> ass = [
          SELECT id, name, account.name, RecordType.Name
          FROM asset
        ];
        ListResponse accesses = ReportDeliverableListController.getTableData(
          10,
          'Name',
          null,
          reports[0].Id
        );
        System.assertEquals(1, accesses.totalRows);
      }
    }
  }
  @isTest
  static void allUserCanDownloadDeliverables() {
    Test.setMock(HttpCalloutMock.class, new APIUtil_CalloutMock());
    ReportAccessUtil.enableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;
    List<Account> accounts = [SELECT Id FROM Account];
    Test.startTest();
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      true
    );
    TestDataFactory.createDeliverableForReports(reports, true);

    Test.stopTest();
    List<User> users = [
      SELECT Id, Username, Profile.Name
      FROM User
      WHERE Account.Name = 'Account 1'
    ];
    for (User u : users) {
      System.runAs(u) {
        List<Asset> ass = [
          SELECT id, name, account.name, RecordType.Name, ParentId
          FROM asset
          WHERE ParentId != NULL
        ];
        Map<String, String> result = ReportDeliverableListController.downloadDeliverable(
          ass[0].ParentId,
          ass[0].Id
        );
      }
    }
  }
  @isTest
  static void allUserCanGetEphemeralURL() {
    ReportAccessUtil.enableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;
    List<Account> accounts = [SELECT Id FROM Account];
    Test.startTest();
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      true
    );
    Asset deli = TestDataFactory.createDeliverableForReports(reports, false)[0];
    deli.TruTesta_ID__c = 'I_am_checking_this_in_URL';
    insert deli;

    Test.stopTest();
    List<User> users = [
      SELECT Id, Username, Profile.Name
      FROM User
      WHERE Account.Name = 'Account 1'
    ];
    for (User u : users) {
      System.runAs(u) {
        List<Asset> ass = [
          SELECT
            id,
            name,
            account.name,
            RecordType.Name,
            ParentId,
            TruTesta_ID__c
          FROM asset
          WHERE ParentId != NULL
        ];
        String result = ReportDeliverableListController.getDocDownloadEphemeralURL(
          ass[0].ParentId,
          ass[0].Id
        );
        System.assert(result.contains(deli.TruTesta_ID__c));
      }
    }
  }
}