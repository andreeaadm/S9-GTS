@isTest
public with sharing class UserManagementBatchTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    ReportAccessUtil.disableSharingProcessing();
    List<Account> accounts = TestDataFactory.createAccounts(1, true);

    List<Contact> cons = TestDataFactory.createContacts(
      1,
      false,
      accounts[0].Id
    );
    cons[0].Is_User_Required__c = false;
    insert cons;

    List<AccountContactRelation> acrs = [
      SELECT Id, ContactId
      FROM AccountContactRelation
      WHERE Account.Name = 'Account 1'
    ];
    for (AccountContactRelation acr : acrs) {
      acr.MTC_Role__c = 'Read-Only';
    }
    update acrs;
  }
  @isTest
  static void usersCreatedViaBatchClass() {
    List<User> users = [
      SELECT Id, UserName, IsActive, Profile.Name
      FROM User
      WHERE Account.Name = 'Account 1'
    ];
    System.assertEquals(0, users.size());

    Contact con = [
      SELECT Id, Is_User_Required__c
      FROM Contact
      WHERE Account.Name = 'Account 1'
    ];

    Test.startTest();
    con.Is_User_Required__c = true;
    update new List<Contact>{ con };
    Database.executeBatch(new UserManagementBatch());
    Test.stopTest();

    users = [
      SELECT Id, UserName, IsActive, Profile.Name
      FROM User
      WHERE Account.Name = 'Account 1'
    ];
    System.assertEquals(1, users.size());
    System.assertEquals(true, users[0].IsActive);
  }
}