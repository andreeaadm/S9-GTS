@isTest
public with sharing class ReportAccessListControllerTest {
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
  static void adminGetsAllColumns() {
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;
    List<Account> accounts = [SELECT Id FROM Account];
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      true
    );
    Contact_Group__c cg = new Contact_Group__c(
      Account__c = accounts[0].Id,
      Group_Name__c = 'abc'
    );
    insert cg;
    //TestDataFactory.createDeliverableForReports(reports, true);
    ReportAccessUtil.enableSharingProcessing();
    Test.startTest();
    TestDataFactory.createAccess(cg.Id, reports[0].Id);
    Test.stopTest();
    List<User> users = [
      SELECT Id, Username, ProfileId
      FROM User
      WHERE Account.Name = 'Account 1'
    ];
    for (User u : users) {
      System.runAs(u) {
        ListResponse accesses = ReportAccessListController.getTableData(
          10,
          'Name',
          null,
          reports[0].Id
        );
        Access__c access = [
          SELECT Id, UserRecordAccess.HasEditAccess
          FROM Access__c
          WHERE Contact_Group__c = :cg.Id
        ];
        System.assertEquals(2, accesses.totalRows);
        if (
          MTCUserUtil.mtcProfiles.get(u.ProfileId)
            .Name.containsIgnoreCase('admin')
        ) {
          System.assertEquals(true, access.UserRecordAccess.HasEditAccess);
        } else {
          System.assertEquals(false, access.UserRecordAccess.HasEditAccess);
        }
      }
    }
  }
  @isTest
  static void adminCanDeleteAccess() {
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;
    List<Account> accounts = [SELECT Id FROM Account];
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      true
    );
    Contact_Group__c cg = new Contact_Group__c(
      Account__c = accounts[0].Id,
      Group_Name__c = 'abc'
    );
    insert cg;
    //TestDataFactory.createDeliverableForReports(reports, true);
    ReportAccessUtil.enableSharingProcessing();
    Test.startTest();
    Access__c access = TestDataFactory.createAccess(cg.Id, reports[0].Id);
    Test.stopTest();
    List<User> users = [
      SELECT Id, Username, ProfileId
      FROM User
      WHERE
        Account.Name = 'Account 1'
        AND Profile.Name = :MTCUserUtil.ADMIN_PROFILE
      LIMIT 1
    ];
    for (User u : users) {
      System.runAs(u) {
        APIResponse response = ReportAccessListController.deleteAccess(
          access.Id
        );
        System.assertEquals('OK', response.status);
        // Again, already deleted
        APIResponse response2 = ReportAccessListController.deleteAccess(
          access.Id
        );
        System.assertEquals('Bad Request', response2.status);
      }
    }
  }
}