@isTest
public with sharing class NotificationsControllerTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    ReportAccessUtil.bypassQueueable = true;
    Account a = TestDataFactory.createAccount();
    User admin = TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
    Contact con = [
      SELECT
        Id,
        Email,
        Is_User_Required__c,
        (
          SELECT Id, MTC_Role__c
          FROM AccountContactRelations
          WHERE AccountId = :a.Id
        )
      FROM Contact
      WHERE Id = :admin.ContactId
    ];
    con.Email = admin.Email;
    con.Is_User_Required__c = true;
    update con;

    con.AccountContactRelations[0].MTC_Role__c = 'cga';
    update con.AccountContactRelations;

    Test.getEventBus().deliver();

    Account b = new Account(Name = 'Account B', Is_MTC_Account__c = true);
    insert b;

    Contact tempoCon = new Contact(
      AccountId = b.Id,
      FirstName = 'tempo',
      LastName = 'rary',
      Email = 'temporari' + StringUtil.random(3) + '@oegen.co.uk',
      Phone = StringUtil.random(12, '0123456789'),
      Is_User_Required__c = true
    );
    insert tempoCon;
    Asset report = TestDataFactory.createReportForAccount(b.Id, false);
    report.ContactId = tempoCon.Id;
    insert report;
  }

  @isTest
  static void notificationsForUsersRequestingApproval() {
    User u1 = [
      SELECT Id, AccountId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact newContactForApproval = TestDataFactory.createContacts(
      1,
      false,
      u1.AccountId
    )[0];
    newContactForApproval.LastName = 'approveMe';
    insert newContactForApproval;

    newContactForApproval = [
      SELECT
        Id,
        Email,
        Is_User_Required__c,
        (
          SELECT Id, MTC_Role__c
          FROM AccountContactRelations
          WHERE AccountId = :u1.AccountId
        )
      FROM Contact
      WHERE Id = :newContactForApproval.Id
    ];
    newContactForApproval.AccountContactRelations[0]
      .MTC_Role__c = 'pending approval';
    update newContactForApproval.AccountContactRelations;

    Test.getEventBus().deliver();

    Test.startTest();
    Test.stopTest();
    List<NotificationsController.Notification> notifications;
    System.runAs(u1) {
      notifications = NotificationsController.getNotifications(6);
    }
    System.assertEquals(1, notifications.size());
  }

  @isTest
  static void tempUserGetsNotificationForReport() {
    Test.startTest();
    User tempoUser = [
      SELECT Id, AccountId, ContactId, Name
      FROM User
      WHERE Account.Name = 'Account B' AND FirstName = 'tempo'
    ];
    Test.stopTest();
    List<NotificationsController.Notification> notifications;
    System.runAs(tempoUser) {
      System.assertEquals(
        1,
        [SELECT COUNT() FROM Asset WHERE AccountId = :tempoUser.AccountId]
      );
      notifications = NotificationsController.getNotifications(6);
    }
    System.assertEquals(1, notifications.size());
  }

  // Test in a scenario where no notifications should be returned
  @isTest
  static void test_1_1() {
    ReportAccessUtil.bypassQueueable = true;
    List<NotificationsController.Notification> notifications = new List<NotificationsController.Notification>();
    User u1 = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Test.startTest();
    System.runAs(u1) {
      notifications = NotificationsController.getNotifications(6);
    }
    Test.stopTest();
    System.assertEquals(0, notifications.size());
  }

  // One case updated notification should be returned
  @isTest
  static void test_2_1() {
    ReportAccessUtil.bypassQueueable = true;
    List<NotificationsController.Notification> notifications = new List<NotificationsController.Notification>();
    User u = [
      SELECT Id, ContactId, Contact.AccountId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    System.runAs(u) {
      u.Notifications_Cutoff__c = DateTime.now().addMinutes(-10);
      update u;
    }
    Test.startTest();
    Case c = new Case(
      Subject = 'Test',
      AccountId = u.Contact.AccountId,
      Description = 'Test'
    );
    insert c;
    Test.setFixedSearchResults(new List<Id>{ c.Id });
    c.Subject = 'Updated';
    update c;

    Test.stopTest();

    System.runAs(u) {
      notifications = NotificationsController.getNotifications(6);
    }
    System.assertEquals(1, notifications.size());
  }

  // One report created notification should be returned
  @isTest
  static void test_3_1() {
    ReportAccessUtil.bypassQueueable = true;
    List<NotificationsController.Notification> notifications = new List<NotificationsController.Notification>();
    User u = [
      SELECT Id, ContactId, Contact.AccountId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    System.runAs(u) {
      u.Notifications_Cutoff__c = DateTime.now().addMinutes(-10);
      update u;
    }
    Test.startTest();
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      new List<Account>{ new Account(Id = u.Contact.AccountId) },
      true
    );
    Test.setFixedSearchResults(new List<Id>{ reports[0].Id });
    System.runAs(u) {
      notifications = NotificationsController.getNotifications(6);
    }
    Test.stopTest();
    System.assertEquals(1, notifications.size());
  }

  @isTest
  static void test_4_1_getUserNotifications() {
    ReportAccessUtil.bypassQueueable = true;
    User u = [
      SELECT Id, ContactId, Contact.AccountId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    List<NotificationsController.Notification> notifications = new List<NotificationsController.Notification>();

    List<Account> accounts = [SELECT Id FROM Account];
    TestDataFactory.createAccountsWithContacts(accounts, 1);
    List<Contact> account1cons = [
      SELECT
        Id,
        AccountId,
        (SELECT Id, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE LastName = 'Contact 0'
      ORDER BY LastName
    ];
    Test.startTest();
    account1cons[0].AccountContactRelations[0].MTC_Role__c = 'Read-Only';
    update account1cons[0].AccountContactRelations;

    Test.stopTest();
    System.runAs(u) {
      notifications = NotificationsController.getNotifications(6);
    }
    System.assertNotEquals(0, notifications.size());
  }

  // One access created notification should be returned
  @isTest
  static void test_5_1() {
    ReportAccessUtil.bypassQueueable = true;

    List<NotificationsController.Notification> notifications = new List<NotificationsController.Notification>();
    User u = [
      SELECT Id, ContactId, Contact.AccountId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    System.runAs(u) {
      u.Notifications_Cutoff__c = DateTime.now().addMinutes(-10);
      update u;
    }
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      new List<Account>{ new Account(Id = u.Contact.AccountId) },
      true
    );
    Contact_Group__c cg = TestDataFactory.createContactGroup(
      u.Contact.AccountId
    );
    Group_Membership__c gm = TestDataFactory.createGroupMembership(
      u.ContactId,
      cg.Id
    );
    Test.startTest();
    Access__c a = TestDataFactory.createAccess(cg.Id, reports[0].Id);
    Test.setFixedSearchResults(new List<Id>{ a.Id });
    System.runAs(u) {
      notifications = NotificationsController.getNotifications(6);
    }
    Test.stopTest();
    System.assertEquals(1, notifications.size());
  }

  // One report revised notification should be returned
  @isTest
  static void test_6_1() {
    List<NotificationsController.Notification> notifications = new List<NotificationsController.Notification>();
    User u = [
      SELECT Id, ContactId, Contact.AccountId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    System.runAs(new User(Id = UserInfo.getUserId())) {
      u.Notifications_Cutoff__c = DateTime.now().addMinutes(-10);
      update u;
    }

    List<Asset> reports = TestDataFactory.createReportForAccounts(
      new List<Account>{ new Account(Id = u.Contact.AccountId) },
      true
    );
    Test.startTest();
    reports[0].Date_Revised__c = Date.today();
    update reports;
    Test.setFixedSearchResults(new List<Id>{ reports[0].Id });
    System.runAs(u) {
      notifications = NotificationsController.getNotifications(6);
    }
    Test.stopTest();
    System.assertEquals(1, notifications.size());
  }

  // One case closed notification should be returned
  @isTest
  static void test_7_1() {
    List<NotificationsController.Notification> notifications = new List<NotificationsController.Notification>();
    User u = [
      SELECT Id, ContactId, Contact.AccountId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];

    Case c;
    System.runAs(u) {
      u.Notifications_Cutoff__c = DateTime.now().addMinutes(-10);
      update u;
      c = new Case(
        Subject = 'Test',
        AccountId = u.Contact.AccountId,
        Description = 'Test'
      );
      insert c;
    }

    Test.startTest();
    Test.setFixedSearchResults(new List<Id>{ c.Id });
    System.runAs(new User(Id = UserInfo.getUserId())) {
      c.Status = 'Closed';
      update c;
    }
    System.runAs(u) {
      notifications = NotificationsController.getNotifications(6);
    }
    Test.stopTest();
    System.assertEquals(1, notifications.size());
  }
}