@isTest
public with sharing class EmailUtilTest {
  @TestSetup
  static void createData() {
    ReportAccessUtil.disableSharingProcessing();
    Account a = TestDataFactory.createAccount();
    User siteAdmin = TestDataFactory.createCommunityUser(
      'MTC Admin Login',
      a.Id
    );
    siteAdmin = [
      SELECT Id, Contact.AccountId
      FROM User
      WHERE Id = :siteAdmin.Id
      LIMIT 1
    ];
    List<Contact> contacts = TestDataFactory.createContacts(
      10,
      true,
      siteAdmin.Contact.AccountId
    );
    List<User> users = TestDataFactory.createCommunityUsers(
      'MTC Standard Login',
      contacts
    );
    TestDataFactory.createReportForAccount(siteAdmin.Contact.AccountId, true);
  }

  // Send email to single recipient
  @isTest
  private static void Test_1_1() {
    ReportAccessUtil.disableSharingProcessing();
    User siteAdmin = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login'
      LIMIT 1
    ];
    Asset a = [SELECT Id FROM Asset LIMIT 1];
    Test.startTest();
    EmailUtil.sendEmails(
      new List<EmailUtil.Email>{
        new EmailUtil.Email(
          new List<sObject>{ siteAdmin },
          a.Id,
          'MTC_Report_New',
          'mark.ramsell@oegen.co.uk'
        )
      }
    );
    Test.stopTest();
  }

  // Send email to 200 recipients
  @isTest
  private static void Test_1_2() {
    ReportAccessUtil.disableSharingProcessing();
    List<User> users = [
      SELECT Id
      FROM User
      WHERE isActive = TRUE AND Contact.Account.Name = 'Test'
    ];
    Asset a = [SELECT Id FROM Asset LIMIT 1];
    Test.startTest();
    EmailUtil.sendEmails(
      new List<EmailUtil.Email>{
        new EmailUtil.Email(
          users,
          a.Id,
          'MTC_Report_New',
          'mark.ramsell@oegen.co.uk'
        )
      }
    );
    Test.stopTest();
  }
}