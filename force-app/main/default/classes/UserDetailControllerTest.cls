@isTest
public with sharing class UserDetailControllerTest {
  @TestSetup
  static void createData() {
    Account a = TestDataFactory.createAccount();
    TestDataFactory.createAccountsWithContacts(new List<Account>{ a }, 2);
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
      new List<String>{ 'MTC Admin Login', 'MTC Standard Login' },
      cons
    );
    update new List<AccountContactRelation>{
      new AccountContactRelation(
        Id = cons[0].AccountContactRelations[0].Id,
        MTC_Role__c = 'CGA'
      ),
      new AccountContactRelation(
        Id = cons[1].AccountContactRelations[0].Id,
        MTC_Role__c = 'Read-Only'
      )
    };
  }

  @isTest
  private static void getPrimaryAccounts() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    List<AccountContactRelation> acrs = new List<AccountContactRelation>(
      [
        SELECT Id
        FROM AccountContactRelation
        WHERE AccountId = :u.Contact.AccountId AND ContactId = :u.ContactId
      ]
    );

    List<AccountContactRelation> primaryAccounts = null;
    Test.startTest();
    System.runAs(u) {
      primaryAccounts = UserDetailController.getPrimaryAccountOptions(
        String.valueOf(UserInfo.getUserId())
      );
    }
    Test.stopTest();
    System.assertEquals(1, primaryAccounts.size());
  }

  @isTest
  private static void getCompanyListWithValid_ReturnsPopulatedList() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Test.startTest();
    List<UserDetailController.CompanyItem> companies = null;
    System.runAs(u) {
      companies = UserDetailController.getCompanyList(
        String.valueOf(UserInfo.getUserId())
      );
    }
    Test.stopTest();
    System.assertNotEquals(null, companies);
  }

  @isTest
  private static void asClientAdminUser_canUpdateACR() {
    List<User> users = [
      SELECT Contact.AccountId, ContactId, Id, Profile.Name
      FROM User
      WHERE Account.Name = 'Test'
    ];

    User admin;
    User standard;
    for (User user : users) {
      if (user.Profile.Name == 'MTC Admin Login') {
        admin = user;
      } else if (user.Profile.Name == 'MTC Standard Login') {
        standard = user;
      }
    }

    Map<Id, Contact> cons = new Map<Id, Contact>(
      [
        SELECT
          Id,
          FirstName,
          LastName,
          Email,
          AccountId,
          (SELECT MTC_Role__c FROM AccountContactRelations)
        FROM Contact
        ORDER BY LastName
      ]
    );

    Test.startTest();
    System.runAs(admin) {
      AccountContactRelation wasReadOnlyACR = cons.get(standard.ContactId)
        .AccountContactRelations[0];
      wasReadOnlyACR.MTC_Role__c = 'Admin';
      UserDetailController.updateRelationship(
        new List<AccountContactRelation>{ wasReadOnlyACR }
      );
    }
    System.runAs(standard) {
      UserDetailController.getCompanyList(UserInfo.getUserId());
    }
    Test.stopTest();

    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c
      FROM AccountContactRelation
      WHERE
        ContactId = :standard.ContactId
        AND AccountId = :standard.Contact.AccountId
    ];
    System.assertEquals('Admin', acrs[0].MTC_Role__c);
  }

  @isTest
  private static void asClientAdminUser_canViewListOfAccountsSelf() {
    List<User> users = [
      SELECT Contact.AccountId, ContactId, Id, Profile.Name
      FROM User
      WHERE Account.Name = 'Test'
    ];

    User admin;
    User standard;
    for (User user : users) {
      if (user.Profile.Name == 'MTC Admin Login') {
        admin = user;
      } else if (user.Profile.Name == 'MTC Standard Login') {
        standard = user;
      }
    }

    Account a = [SELECT Id FROM Account];

    Test.startTest();

    List<UserDetailController.CompanyItem> result = null;
    System.runAs(admin) {
      result = UserDetailController.getCompanyList(String.valueOf(admin.Id));
    }
    Test.stopTest();

    system.assertEquals(1, result.size());
  }

  @isTest
  private static void asClientAdminUser_canViewListOfAccountsForAnotherUser() {
    List<User> users = [
      SELECT Contact.AccountId, ContactId, Id, Profile.Name
      FROM User
      WHERE Account.Name = 'Test'
    ];

    User admin;
    User standard;
    for (User user : users) {
      if (user.Profile.Name == 'MTC Admin Login') {
        admin = user;
      } else if (user.Profile.Name == 'MTC Standard Login') {
        standard = user;
      }
    }

    List<UserDetailController.CompanyItem> result = null;
    Test.startTest();
    System.runAs(admin) {
      result = UserDetailController.getCompanyList(String.valueOf(standard.Id));
    }
    Test.stopTest();
    system.assertEquals(1, result.size());
    system.assertEquals(true, result[0].acr.IsDirect);
  }

  @isTest
  private static void asClientAdminUser_canRemoveAccountFromOtherUser_UserHasNoAccessRole() {
    List<User> users = [
      SELECT Contact.AccountId, ContactId, Id, Profile.Name
      FROM User
      WHERE Account.Name = 'Test'
    ];

    User admin;
    User standard;
    for (User user : users) {
      if (user.Profile.Name == 'MTC Admin Login') {
        admin = user;
      } else if (user.Profile.Name == 'MTC Standard Login') {
        standard = user;
      }
    }

    Contact conStandard = [
      SELECT
        Id,
        FirstName,
        LastName,
        Email,
        AccountId,
        (SELECT MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Id = :standard.ContactId
    ];

    Test.startTest();
    System.runAs(admin) {
      UserDetailController.removeRelationship(
        conStandard.AccountContactRelations[0].Id
      );
    }
    Test.stopTest();

    AccountContactRelation acrNoAccess = [
      SELECT MTC_Role__c, ContactId
      FROM AccountContactRelation
      WHERE Id = :conStandard.AccountContactRelations[0].Id
      LIMIT 1
    ];
    System.assertEquals('No-Access', acrNoAccess.MTC_Role__c);
  }

  @IsTest
  private static void asClientAdminUser_canAddAccountForUser_UserHasACR() {
    List<User> users = [
      SELECT Contact.AccountId, ContactId, Id, Profile.Name
      FROM User
      WHERE Account.Name = 'Test'
    ];

    User admin;
    User standard;
    for (User user : users) {
      if (user.Profile.Name == 'MTC Admin Login') {
        admin = user;
      } else if (user.Profile.Name == 'MTC Standard Login') {
        standard = user;
      }
    }

    Account a = [SELECT Id FROM Account];

    Account acc = TestDataFactory.createAccount();
    TestDataFactory.createAccountContactRelation(
      acc.Id,
      admin.ContactId,
      'CGA'
    );
    Test.startTest();
    System.runAs(admin) {
      Id accountId = UserDetailController.getAccountOptions(standard.Id)[0].Id;
      UserDetailController.addAccountRelationship(
        standard.Id,
        accountId,
        'Read-Only'
      );
    }
    Test.stopTest();

    List<AccountContactRelation> acrs = [
      SELECT Id
      FROM AccountContactRelation
      WHERE ContactId = :standard.ContactId
    ];
    System.assertEquals(2, acrs.size());
  }

  // createNewUser with dupe username
  @isTest
  private static void createNewUser_invalid() {
    List<User> users = [
      SELECT Contact.AccountId, ContactId, Id, Profile.Name, Username
      FROM User
      WHERE Account.Name = 'Test'
    ];

    User admin;
    User standard;
    for (User user : users) {
      if (user.Profile.Name == 'MTC Admin Login') {
        admin = user;
      } else if (user.Profile.Name == 'MTC Standard Login') {
        standard = user;
      }
    }

    Test.startTest();
    Contact c = new Contact(
      AccountId = admin.Contact.AccountId,
      LastName = 'Test 123',
      FirstName = 'Test 234',
      Email = standard.Username
    );
    String stringC = JSON.serializePretty(c);
    APIResponse result;
    System.runAs(admin) {
      result = UserDetailController.createNewUser('Admin', stringC);
    }
    Test.stopTest();

    System.assertEquals(400, result.statusCode);
  }

  // createNewUser with unique username
  @isTest
  private static void createNewUser_valid() {
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Test.startTest();
    Contact c = new Contact(
      AccountId = u.Contact.AccountId,
      LastName = 'Test',
      FirstName = 'Test',
      Email = 'createNewUser_valid@oegen.co.uk'
    );
    String stringC = JSON.serializePretty(c);
    APIResponse result;
    System.runAs(u) {
      result = UserDetailController.createNewUser('Admin', stringC);
    }
    Test.stopTest();
    System.assertEquals(200, result.statusCode);
  }

  @isTest
  private static void asAnAdminUser_WhenIRequestToGetTheGroupListAssociatedToAUser_TheGroupListIsReturned() {
    List<User> users = [
      SELECT Contact.AccountId, ContactId, Id, Profile.Name
      FROM User
      WHERE Account.Name = 'Test'
    ];

    User admin;
    User standard;
    for (User user : users) {
      if (user.Profile.Name == 'MTC Admin Login') {
        admin = user;
      } else if (user.Profile.Name == 'MTC Standard Login') {
        standard = user;
      }
    }

    Id cgId = (TestDataFactory.createContactGroup(admin.Contact.AccountId)).Id;
    List<Group_Membership__c> firstMembers = ContactGroupUtil.linkContactsToGroups(
      new Set<Id>{ standard.ContactId },
      new List<Id>{ cgId },
      true
    );
    System.assertEquals(firstmembers.size(), 1);

    List<Group_Membership__c> members;
    Test.startTest();
    System.runAs(admin) {
      members = UserDetailController.getGroupList(standard.Id);
    }

    Test.stopTest();

    System.assertEquals(2, members.size());
  }

  // updateUser
  @isTest
  private static void updateUser_Valid() {
    List<User> users = [
      SELECT Contact.AccountId, ContactId, Id, Profile.Name
      FROM User
      WHERE Account.Name = 'Test'
    ];
    User admin;
    User standard;
    for (User user : users) {
      if (user.Profile.Name == 'MTC Admin Login') {
        admin = user;
      } else if (user.Profile.Name == 'MTC Standard Login') {
        standard = user;
      }
    }
    TestDataFactory.updateAccountContactRelation(
      admin.Contact.AccountId,
      admin.ContactId,
      'Admin'
    );
    APIResponse result;
    Test.startTest();
    System.runAs(admin) {
      result = UserDetailController.updateUser(standard);
    }
    Test.stopTest();
    System.assertEquals(200, result.statusCode);
  }
}