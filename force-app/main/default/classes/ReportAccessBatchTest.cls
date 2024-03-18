@isTest
public with sharing class ReportAccessBatchTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    ReportAccessUtil.disableSharingProcessing();
    List<Account> accounts = TestDataFactory.createAccounts(2, true);

    TestDataFactory.createAccountsWithContacts(accounts, 2);

    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      true
    );
    List<Asset> deliverables = TestDataFactory.createDeliverableForReports(
      new List<Asset>{ reports[1] },
      true
    );

    List<AccountContactRelation> acrs = [
      SELECT Id, ContactId
      FROM AccountContactRelation
      WHERE Account.Name = 'Account 1'
    ];
    for (AccountContactRelation acr : acrs) {
      acr.MTC_Role__c = 'Read-Only';
    }
    update acrs;

    ReportAccessUtil.enableSharingProcessing();
  }
  @isTest
  static void sharingProcessedViaBatchClassSimplified() {
    List<User> users = [
      SELECT Id, UserName, ContactId, Contact.LastName, AccountId, Account.Name
      FROM User
      WHERE Account.Name = 'Account 1'
    ];

    Test.startTest();
    Database.executeBatch(new ReportAccessBatch());
    Test.stopTest();

    for (User usr : users) {
      System.runAs(usr) {
        System.assertNotEquals(0, [SELECT Id, Name FROM Asset].size());
      }
    }
  }
  @isTest
  static void sharingProcessedViaBatchClassViaGroup() {
    ReportAccessUtil.disableSharingProcessing();
    List<User> users = [
      SELECT Id, UserName, ContactId, Contact.LastName, AccountId, Account.Name
      FROM User
      WHERE Account.Name = 'Account 1'
    ];

    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = users[0].AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;

    Asset report = [SELECT Id, Name FROM Asset WHERE Name = 'Report 1'];
    ContactGroupUtil.linkGroupToReport(groupG, report, true);

    Set<Id> userIds = new Set<Id>();
    for (User usr : users) {
      ContactGroupUtil.linkContactToGroup(usr.Contact, groupG, true);
      userIds.add(usr.Id);
    }

    List<AssetShare> assetShares = [
      SELECT Id
      FROM AssetShare
      WHERE UserOrGroupId IN :userIds AND AssetId = :report.Id
    ];
    delete assetShares;

    ReportAccessUtil.enableSharingProcessing();

    for (User usr : users) {
      System.runAs(usr) {
        System.assertEquals(0, [SELECT Id, Name FROM Asset].size());
      }
    }

    Test.startTest();
    Database.executeBatch(new ReportAccessBatch());
    Test.stopTest();

    for (User usr : users) {
      System.runAs(usr) {
        System.assertNotEquals(0, [SELECT Id, Name FROM Asset].size());
      }
    }
  }

  @isTest
  static void sharingProcessedViaBatchWithIds() {
    List<User> users = [
      SELECT Id, UserName, ContactId, Contact.LastName, AccountId, Account.Name
      FROM User
      WHERE Account.Name = 'Account 1'
    ];
    Map<Id, Asset> reports = new Map<Id, Asset>(
      [SELECT Id, Name FROM Asset WHERE Name = 'Report 1']
    );

    Test.startTest();
    Database.executeBatch(new ReportAccessBatch(reports.keySet()));
    Test.stopTest();

    for (User usr : users) {
      System.runAs(usr) {
        System.assertNotEquals(0, [SELECT Id, Name FROM Asset].size());
      }
    }
  }
}