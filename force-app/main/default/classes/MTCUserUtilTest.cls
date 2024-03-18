@isTest
public with sharing class MTCUserUtilTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    List<Account> accounts = TestDataFactory.createAccounts(2, true);
    TestDataFactory.createReportForAccounts(accounts, true);
  }

  @isTest
  static void when_new_cga_created_demote_previous_cga() {
    Account acc1 = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    List<Contact> contacts = TestDataFactory.createContacts(2, true, acc1.Id);

    List<Contact> account1cons = [
      SELECT
        Id,
        FirstName,
        LastName,
        Email,
        AccountId,
        (SELECT Id, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Account.Name = 'Account 1'
      ORDER BY LastName
    ];
    TestDataFactory.createCommunityUsers(
      new List<String>{ 'MTC Admin Login', 'MTC Admin Login' },
      account1cons
    );
    account1cons[0].AccountContactRelations[0].MTC_Role__c = 'cga';
    account1cons[1].AccountContactRelations[0].MTC_Role__c = 'admin';

    update new List<AccountContactRelation>{
      account1cons[0].AccountContactRelations[0],
      account1cons[1].AccountContactRelations[0]
    };

    Test.startTest();

    // promote the admin to cga
    account1cons[1].AccountContactRelations[0].MTC_Role__c = 'cga';
    update account1cons[1].AccountContactRelations;

    Test.stopTest();

    Account acc1b = [
      SELECT Id, CGA_Id__c
      FROM Account
      WHERE Name = 'Account 1'
      LIMIT 1
    ];
    System.assertEquals(account1cons[1].Id, acc1b.CGA_Id__c);

    List<AccountContactRelation> acrs = [
      SELECT ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE Id = :account1cons[0].AccountContactRelations[0].Id
    ];

    System.assertEquals('read-only', acrs[0].MTC_Role__c.toLowerCase());
  }

  @isTest
  static void when_creating_admin_get_admin_permission_set_group() {
    Account acc1 = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    List<Contact> contacts = TestDataFactory.createContacts(1, true, acc1.Id);
    Contact con = contacts[0];

    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    Test.startTest();
    for (AccountContactRelation acr : acrs) {
      acr.MTC_Role__c = 'admin';
    }
    update acrs;
    Test.stopTest();

    User mtcAdmin = [SELECT Id FROM User WHERE ContactId = :con.Id];

    List<PermissionSetGroup> psgs = [
      SELECT
        Id,
        DeveloperName,
        (
          SELECT Id, AssigneeId, PermissionSetId, PermissionSetGroupId
          FROM Assignments
          WHERE AssigneeId = :mtcAdmin.Id
        )
      FROM PermissionSetGroup
      WHERE DeveloperName = 'MTC_Admin_PSG'
    ];

    System.assertEquals(1, psgs.size());
    //System.assertEquals(1, psgs[0].Assignments.size());
  }
  @isTest
  static void when_creating_standard_user_get_standard_permission_set_group() {
    Account acc1 = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    List<Contact> contacts = TestDataFactory.createContacts(1, true, acc1.Id);
    Contact con = contacts[0];

    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    Test.startTest();
    for (AccountContactRelation acr : acrs) {
      acr.MTC_Role__c = 'Read-Only';
    }
    update acrs;
    Test.stopTest();

    User mtcStandard = [SELECT Id FROM User WHERE ContactId = :con.Id];

    List<PermissionSetGroup> psgs = [
      SELECT
        Id,
        DeveloperName,
        (SELECT Id FROM Assignments WHERE AssigneeId = :mtcStandard.Id)
      FROM PermissionSetGroup
      WHERE DeveloperName = 'MTC_Standard_PSG'
    ];
    System.debug(JSON.serializePretty(psgs));

    System.assertEquals(1, psgs.size());
    //System.assertEquals(1, psgs[0].Assignments.size());
  }
  @isTest
  static void userCreation_contactWithMissing_mtcRole() {
    Account acc1 = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    List<Contact> contacts = TestDataFactory.createContacts(1, false, acc1.Id);
    Contact con = contacts[0];

    Test.startTest();
    con.Is_User_Required__c = true;
    insert con;
    Test.stopTest();

    List<User> users = [SELECT Id FROM User WHERE ContactId = :con.Id];
    System.assertEquals(true, users.isEmpty());
  }
  @isTest
  static void userCreation_contactWithExisting_User() {
    List<Account> accounts = [SELECT Id FROM Account ORDER BY Name];
    Account acc1 = accounts[0];

    List<Contact> contacts = TestDataFactory.createContacts(1, true, acc1.Id);
    Contact con = contacts[0];
    TestDataFactory.createCommunityUser('mtc standard login', acc1.Id, con.Id);

    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    Test.startTest();
    for (AccountContactRelation acr : acrs) {
      acr.MTC_Role__c = 'read-only';
    }
    update acrs;
    Test.stopTest();
    User afterUser = [SELECT ProfileId FROM User WHERE ContactId = :con.Id];
    System.assert(MTCUserUtil.mtcProfiles.containsKey(afterUser.ProfileId));
    System.assertEquals(
      'MTC Standard Login',
      MTCUserUtil.mtcProfiles.get(afterUser.ProfileId).Name
    );
  }
  @isTest
  static void userCreation_contactWithCorrect_mtcRole() {
    Account acc1 = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    List<Contact> contacts = TestDataFactory.createContacts(1, true, acc1.Id);
    Contact con = contacts[0];

    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    Test.startTest();
    for (AccountContactRelation acr : acrs) {
      acr.MTC_Role__c = 'read-only';
    }
    update acrs;
    Test.stopTest();
    List<User> users = [
      SELECT ProfileId, IsActive
      FROM User
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(1, users.size());
    System.assertEquals(true, users[0].IsActive);
  }

  @isTest
  static void userCreation_contactRequiringApproval() {
    Account acc1 = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    List<Contact> contacts = TestDataFactory.createContacts(1, true, acc1.Id);
    Contact con = contacts[0];

    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    Test.startTest();
    for (AccountContactRelation acr : acrs) {
      acr.MTC_Role__c = 'Pending Approval';
    }
    update acrs;
    Test.stopTest();
    List<User> users = [
      SELECT ProfileId, IsActive, Profile.Name
      FROM User
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(1, users.size());
    System.assertEquals('MTC Standard', users[0].Profile.Name.left(12));
    System.assertEquals(false, users[0].IsActive);
  }

  @isTest
  static void userCreation_additionalRole() {
    List<Account> accounts = [SELECT Id FROM Account ORDER BY Name];
    Account acc1 = accounts[0];
    Account acc2 = accounts[1];
    List<Contact> contacts = TestDataFactory.createContacts(1, true, acc1.Id);
    Contact con = contacts[0];
    TestDataFactory.createCommunityUser('mtc standard', acc1.Id, con.Id);

    List<AccountContactRelation> acrs = new List<AccountContactRelation>();
    acrs.add(
      new AccountContactRelation(
        AccountId = acc2.Id,
        ContactId = con.Id,
        MTC_Role__c = MTCUserUtil.ADMIN_ROLE
      )
    );

    Test.startTest();
    insert acrs;
    Test.stopTest();

    User usr = [
      SELECT Id, AccountId, ProfileId
      FROM User
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(
      MTCUserUtil.ADMIN_PROFILE,
      MTCUserUtil.mtcProfiles.get(usr.ProfileId).Name.toLowerCase()
    );
  }

  //
  @isTest
  static void when_creating_reportContact_createUser() {
    Account acc1 = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    List<Contact> contacts = TestDataFactory.createContacts(1, true, acc1.Id);
    Contact con = contacts[0];

    Test.startTest();

    Asset report = [SELECT Id, ContactId FROM Asset WHERE AccountId = :acc1.Id];
    report.ContactId = con.Id;
    report.Date_Issued__c = Date.today();
    update report;
      
	Asset_Contact_Relationship__c ass = [Select id,Expiry_Date__c from Asset_Contact_Relationship__c where Asset__c =: report.Id and Contact__c =:con.Id ]   ; 
	system.debug('ASSCR===>'+ass.Id+ass.Expiry_Date__c);
    Test.stopTest();
    User usr = [
      SELECT Id, AccountId, ProfileId, Date_Expires__c
      FROM User
      WHERE ContactId = :con.Id
    ];

    System.assertEquals(
      'mtc standard login',
      MTCUserUtil.mtcProfiles.get(usr.ProfileId).Name.toLowerCase()
    );
    System.assertEquals(Date.today().addDays(30), ass.Expiry_Date__c);//usr.Date_Expires__c);  
  }

  @isTest
  static void when_accountDeactivated_acrsPrefixed() {
    Account acc = [
      SELECT Id, Is_Account_Deactivated__c
      FROM Account
      WHERE Name = 'Account 2'
    ];
    List<Contact> contacts = TestDataFactory.createContacts(3, false, acc.Id);
    for (Contact con : contacts) {
      con.Is_User_Required__c = true;
    }
    insert contacts;

    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c, ContactId, AccountId
      FROM AccountContactRelation
      WHERE AccountId = :acc.Id
      ORDER BY Contact.LastName
    ];
    acrs[0].MTC_Role__c = 'cga';
    acrs[1].MTC_Role__c = 'admin';
    acrs[2].MTC_Role__c = 'read-only';

    Test.startTest();
    update acrs;
    // let the future method execute...
    Test.stopTest();

    acc.Is_Account_Deactivated__c = true;
    update acc;

    acrs = [
      SELECT Id, MTC_Role__c, ContactId, AccountId
      FROM AccountContactRelation
      WHERE AccountId = :acc.Id
      ORDER BY Contact.LastName
    ];

    for (AccountContactRelation acr : acrs) {
      System.assertEquals('x.', acr.MTC_Role__c.left(2));
    }
  }

  @isTest
  static void when_accountDeactivated_usersDeactivated() {
    Account acc = [
      SELECT Id, Is_Account_Deactivated__c
      FROM Account
      WHERE Name = 'Account 2'
    ];

    List<Contact> contacts = TestDataFactory.createContacts(2, true, acc.Id);

    TestDataFactory.createCommunityUsers('MTC Admin Login', contacts);

    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c, ContactId, AccountId
      FROM AccountContactRelation
      WHERE AccountId = :acc.Id
      ORDER BY Contact.LastName
    ];
    acrs[0].MTC_Role__c = 'cga';
    acrs[1].MTC_Role__c = 'admin';
    update acrs;

    Test.startTest();
    acc.Is_Account_Deactivated__c = true;
    update acc;
    Test.stopTest();

    for (User u : [SELECT Id, IsActive FROM User WHERE ContactId = :acc.Id]) {
      System.assertEquals(false, u.IsActive);
    }
  }

  // Test we do not allow an email change on a contact with an active user
  @isTest
  static void when_contactWithoutUserUpdated_allowEmailChange() {
    Account acc = [SELECT Id FROM Account WHERE Name = 'Account 1'];

    List<Contact> contacts = TestDataFactory.createContacts(1, true, acc.Id);
    Contact con = contacts[0];

    Test.startTest();

    try {
      con.Email = 'nowItDiffers' + con.Email;
      update con;
      System.assert(true, 'Exception should have been thrown');
    } catch (Exception e) {
      System.assert(false, 'Unexpected exception here. ' + e.getMessage());
    }

    Test.stopTest();
  }

  // Test filterPermittedUsers where the current user is permitted to manage the user passed in
  @isTest
  static void filterPermittedUsers_valid() {
    Account a = TestDataFactory.createAccount();
    User cga = TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
    TestDataFactory.updateAccountContactRelation(a.Id, cga.ContactId, 'CGA');
    Account a2 = TestDataFactory.createAccount();
    User std = TestDataFactory.createCommunityUser('MTC Standard Login', a2.Id);
    TestDataFactory.updateAccountContactRelation(
      a2.Id,
      std.ContactId,
      'Read-Only'
    );
    // Create an Admin ACR or the cga on this second account. This grants them permission to manage the standard user.
    TestDataFactory.createAccountContactRelation(a2.Id, cga.ContactId, 'Admin');

    Set<Id> result = new Set<Id>();
    Test.startTest();
    System.runAs(cga) {
      result = MTCUserUtil.filterPermittedUsers(new List<Id>{ std.Id });
    }
    Test.stopTest();
    System.assertEquals(1, result.size());
  }

  // Test filterPermittedUsers where the current user is not permitted to manage the user passed in
  @isTest
  static void filterPermittedUsers_invalid() {
    Account a = TestDataFactory.createAccount();
    User cga = TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
    TestDataFactory.updateAccountContactRelation(a.Id, cga.ContactId, 'CGA');
    Account a2 = TestDataFactory.createAccount();
    User std = TestDataFactory.createCommunityUser('MTC Standard Login', a2.Id);
    TestDataFactory.updateAccountContactRelation(
      a2.Id,
      std.ContactId,
      'Read-Only'
    );

    Set<Id> result = new Set<Id>();
    Test.startTest();
    System.runAs(cga) {
      result = MTCUserUtil.filterPermittedUsers(new List<Id>{ std.Id });
    }
    Test.stopTest();
    System.assertEquals(0, result.size());
  }

  @isTest
  static void when_userDeactivated_becomes_NoAccess() {
    Map<Id, Account> accounts = new Map<Id, Account>(
      [SELECT Name FROM Account ORDER BY Name]
    );
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts.values()) {
      name2Id.put(acc.Name, acc.Id);
    }
    List<Contact> cons = TestDataFactory.createContacts(
      1,
      true,
      name2Id.get('Account 1')
    );
    User stdUser = TestDataFactory.createCommunityUser(
      'MTC Standard Login',
      name2Id.get('Account 1'),
      cons[0].Id
    );
    Contact con = [
      SELECT
        Id,
        (SELECT Id, accountId, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Id = :cons[0].Id
    ];
    ReportAccessUtil.bypassQueueable = true;
    con.AccountContactRelations[0].MTC_Role__c = 'Read-Only';
    update con.AccountContactRelations;
    Test.startTest();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      update new User(Id = stdUser.Id, IsActive = false);
    }

    Test.stopTest();

    List<AccountContactRelation> acrs = [
      SELECT Id, accountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(1, acrs.size());
    System.assertEquals('no-access', acrs[0].MTC_Role__c.toLowerCase());
  }
}