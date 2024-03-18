@isTest
public with sharing class GroupAccessUtilTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    ReportAccessUtil.disableSharingProcessing();
    List<Account> accounts = TestDataFactory.createAccounts(2, true);
    TestDataFactory.createAccountsWithContacts(accounts, 2);
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
        'MTC Standard Login',
        'MTC Admin Login',
        'MTC Standard Login'
      },
      cons
    );
    update new List<AccountContactRelation>{
      new AccountContactRelation(
        Id = cons[0].AccountContactRelations[0].Id,
        MTC_Role__c = 'Admin'
      ),
      new AccountContactRelation(
        Id = cons[1].AccountContactRelations[0].Id,
        MTC_Role__c = 'Read-Only'
      ),
      new AccountContactRelation(
        Id = cons[2].AccountContactRelations[0].Id,
        MTC_Role__c = 'Admin'
      ),
      new AccountContactRelation(
        Id = cons[3].AccountContactRelations[0].Id,
        MTC_Role__c = 'Read-only'
      )
    };
    ReportAccessUtil.enableSharingProcessing();
  }

  @isTest
  static void verifySharingBypassMethods() {
    System.assertEquals(false, GroupAccessUtil.sharingProcessingDisabled);
    GroupAccessUtil.disableSharingProcessing();
    System.assertEquals(true, GroupAccessUtil.sharingProcessingDisabled);
    GroupAccessUtil.enableSharingProcessing();
    System.assertEquals(false, GroupAccessUtil.sharingProcessingDisabled);
  }

  @isTest
  static void whenNewContactGroupCreated_existingAdminGainAccess() {
    AccountContactRelation acr = [
      SELECT
        Contact.FirstName,
        Contact.LastName,
        Contact.Email,
        Contact.Account.Name,
        Contact.AccountId
      FROM AccountContactRelation
      WHERE Account.Name = 'Account 1' AND MTC_Role__c = 'admin'
    ];
    Contact con = acr.Contact;

    Test.startTest();
    Contact_Group__c cg1 = ContactGroupUtil.constructGroup(
      con.AccountId,
      'group1account1'
    );
    insert cg1;
    Test.stopTest();

    User adminUser = [SELECT Id FROM User WHERE ContactId = :con.Id];
    System.runAs(adminUser) {
      List<Contact_Group__c> groups = [
        SELECT Id, Group_Name__c, Is_Default_Group__c
        FROM Contact_Group__c
        WHERE Account__c = :con.AccountId
      ];
      System.assertEquals(2, groups.size());
      for (Contact_Group__c cg : groups) {
        if (!cg.Is_Default_Group__c) {
          System.assertEquals('group1account1', cg.Group_Name__c);
        }
      }
    }
  }

  @isTest
  static void whenContactCreatedAfterCustomGroup_existingAdminGainAccess() {
    Account acc = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    Contact_Group__c cg1 = ContactGroupUtil.constructGroup(
      acc.Id,
      'group1account1'
    );
    insert cg1;

    Contact con = TestDataFactory.createContacts(1, true, acc.Id)[0];

    Test.startTest();
    AccountContactRelation acr = [
      SELECT Id, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id AND AccountId = :acc.Id
    ];
    acr.MTC_Role__c = 'admin';
    update acr;
    Test.stopTest();

    User adminUser = [SELECT Id FROM User WHERE ContactId = :con.Id];
    System.runAs(adminUser) {
      List<Contact_Group__c> groups = [
        SELECT Id, Group_Name__c, Is_Default_Group__c
        FROM Contact_Group__c
        WHERE Account__c = :con.AccountId
      ];
      System.assertEquals(2, groups.size());
      for (Contact_Group__c cg : groups) {
        if (!cg.Is_Default_Group__c) {
          System.assertEquals('group1account1', cg.Group_Name__c);
        }
      }
    }
  }

  @isTest
  static void whenUpdatedToAdmin_gainAccessToContactGroups() {
    ReportAccessUtil.disableSharingProcessing();
    User u1 = [
      SELECT Id, ContactId
      FROM User
      WHERE Account.Name = 'Account 1' AND Profile.Name = 'MTC Standard Login'
    ];
    Contact con1 = [
      SELECT
        FirstName,
        LastName,
        Account.Name,
        AccountId,
        (SELECT MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Id = :u1.ContactId
    ];
    Contact_Group__c cg1 = ContactGroupUtil.constructGroup(
      con1.AccountId,
      'group1account1'
    );
    insert cg1;

    AccountContactRelation acr = con1.AccountContactRelations[0];

    Test.startTest();
    acr.MTC_Role__c = 'Admin';
    update acr;
    Test.stopTest();
    ReportAccessUtil.enableSharingProcessing();

    System.runAs(u1) {
      List<Contact_Group__c> cgs = [
        SELECT Id, Group_Name__c, Account__c
        FROM Contact_Group__c
        WHERE Is_Default_Group__c = FALSE
      ];
      System.assertEquals(1, cgs.size());
      Contact_Group__c cg = cgs[0];
      System.assertEquals('group1account1', cg.Group_Name__c);
      Schema.DescribeSObjectResult cgDescr = Contact_Group__c.SObjectType.getDescribe();
      System.assert(cgDescr.accessible);
      System.assert(cgDescr.createable);
    }

  }
  @isTest
  static void whenDemotedFromAdmin_loseEditAccessToContactGroups() {
    ReportAccessUtil.disableSharingProcessing();
    User u1 = [
      SELECT Id, ContactId
      FROM User
      WHERE Account.Name = 'Account 1' AND Profile.Name = 'MTC Admin Login'
    ];
    Contact con1 = [
      SELECT
        FirstName,
        LastName,
        Account.Name,
        AccountId,
        (SELECT MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Id = :u1.ContactId
    ];
    Contact_Group__c cg1 = ContactGroupUtil.constructGroup(
      con1.AccountId,
      'group1account1'
    );
    insert cg1;

    Test.startTest();
    AccountContactRelation acr = con1.AccountContactRelations[0];
    acr.MTC_Role__c = 'Read-Only';
    update acr;
    Test.stopTest();

    System.runAs(u1) {
      List<Contact_Group__c> cgs = [
        SELECT Id, Group_Name__c, Account__c, UserRecordAccess.HasEditAccess
        FROM Contact_Group__c
        WHERE Is_Default_Group__c = FALSE
      ];
      System.assertEquals(1, cgs.size());
      System.assertEquals(false, cgs[0].UserRecordAccess.HasEditAccess);
    }

  }
}