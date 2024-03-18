@isTest
public with sharing class AccountRelationUtilTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;

    List<Account> accounts = TestDataFactory.createAccounts(2, true);

    TestDataFactory.createAccountsWithContacts(accounts, 3);

    List<AccountContactRelation> acrs = [
      SELECT ContactId, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE
        Account.Name = 'account 2'
        AND Contact.Lastname IN ('contact 4', 'contact 5')
    ];
    acrs[0].MTC_Role__c = 'Restricted';
    acrs[1].MTC_Role__c = 'Restricted';
    update acrs;

    ReportAccessUtil.enableSharingProcessing();
  }
  // Set role to Restricted if was "No-Access"
  @isTest
  static void whenContactIsReportContactACRUpdated() {
    List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    List<Contact> contacts = [
      SELECT Id
      FROM Contact
      WHERE AccountId = :accounts[0].Id
    ];
    Contact con = contacts[0];
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      false
    );
    reports[0].ContactId = con.Id;

    Test.startTest();
    insert reports;
    Test.stopTest();

    List<AccountContactRelation> acrs = [
      SELECT ContactId, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(1, acrs.size());
    System.assertEquals('Restricted', acrs[0].MTC_Role__c);
  }
  // Do not change the MTC_Role for existing Contact/User
  @isTest
  static void whenContactIsReportContactExistingUserDoNothing() {
    List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    List<Contact> contacts = [
      SELECT Id
      FROM Contact
      WHERE AccountId = :accounts[0].Id
    ];
    Contact con = contacts[0];
    List<AccountContactRelation> acrs = [
      SELECT ContactId, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    acrs[0].MTC_Role__c = 'Read-Only';
    update acrs[0];

    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      false
    );
    reports[0].ContactId = con.Id;

    Test.startTest();
    insert reports;
    Test.stopTest();

    acrs = [
      SELECT ContactId, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(1, acrs.size());
    System.assertEquals('Read-Only', acrs[0].MTC_Role__c);
  }

  @isTest
  static void whenRestrictedBecomesCGAClearExpiryDate() {
    Contact con = [
      SELECT Id, AccountId, (SELECT MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Account.Name = 'Account 2' AND Lastname = 'Contact 5'
    ];
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      new List<Account>{ new Account(Id = con.AccountId) },
      false
    );
    reports[0].ContactId = con.Id;
    insert reports;

    User before = [
      SELECT Id, Date_Expires__c
      FROM User
      WHERE ContactId = :con.Id
    ];
    System.assertNotEquals(null, before.Date_Expires__c);

    Test.startTest();
    update new Contact(
      Id = con.Id,
      Approval_Status__c = Label.MTC_Approval_RequestedStatus
    );
    Test.stopTest();

    User after = [
      SELECT Id, Date_Expires__c
      FROM User
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(null, after.Date_Expires__c);
  }

  @isTest
  static void whenContactIsRestrictedUpdateDateExpires() {
    List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Account 2'];
    Contact con = [
      SELECT Id, Is_User_Required__c
      FROM Contact
      WHERE Account.Name = 'account 2' AND Lastname = 'contact 4'
    ];

    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      false
    );
    reports[0].ContactId = con.Id;
    reports[0].Date_Issued__c = Date.today();

    Test.startTest();
    insert reports;
    Test.stopTest();

    List<AccountContactRelation> acrs = [
      SELECT ContactId, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(1, acrs.size());
    System.assertEquals('Restricted', acrs[0].MTC_Role__c);
    User usr = [
      SELECT Id, ContactId, Date_Expires__c
      FROM User
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(
      Date.today().addDays(MTCUserUtil.DEFAULT_TEMP_USER_EXPIRY),
      usr.Date_Expires__c
    );
  }
  // scenario where we have a report issued in the past and a revised version today
  @isTest
  static void reportDateRevisedCorrectsUserExpiry() {
    List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Account 1'];
    List<Contact> contacts = [
      SELECT Id, AccountId, Is_User_Required__c
      FROM Contact
      WHERE AccountId = :accounts[0].Id
    ];
    Contact con = contacts[0];
    con.Is_User_Required__c = true;
    update contacts;

    TestDataFactory.createCommunityUser(
      'MTC Standard Login',
      con.AccountId,
      con.Id
    );

    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      false
    );
    reports[0].ContactId = con.Id;
    reports[0].Date_Issued__c = Date.today().addDays(-180);
    reports[0].Date_Revised__c = Date.today().addDays(-10);

    Test.startTest();
    insert reports;
    Test.stopTest();

    List<AccountContactRelation> acrs = [
      SELECT ContactId, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(1, acrs.size());
    System.assertEquals('Restricted', acrs[0].MTC_Role__c);
    User usr = [
      SELECT Id, ContactId, Date_Expires__c
      FROM User
      WHERE ContactId = :con.Id
    ];
    System.assertEquals(
      reports[0].Date_Revised__c.addDays(MTCUserUtil.DEFAULT_TEMP_USER_EXPIRY),
      usr.Date_Expires__c
    );
  }

  @isTest
  static void whenContactIsAddedToGroupMemebershipOnAccountDifferentThanParentAccountAnACRIsCreatedWhereNotPreExisting() {
    List<Account> accounts = [SELECT Id FROM Account ORDER BY Account.Name];
    List<Contact> contacts = [
      SELECT Id
      FROM Contact
      WHERE AccountId = :accounts[0].Id
    ];

    Id idOfContactGroupOnSecondAccount = TestDataFactory.createContactGroup(
        accounts[1].Id
      )
      .Id;
    Group_Membership__c cgm = new Group_Membership__c(
      Contact__c = contacts[0].Id,
      Contact_Group__c = idOfContactGroupOnSecondAccount,
      DupCheck__c = '' + contacts[0].Id + idOfContactGroupOnSecondAccount
    );

    System.AssertEquals(
      0,
      [
          SELECT ID, MTC_Role__c
          FROM AccountContactRelation
          WHERE AccountId = :accounts[1].Id AND ContactId = :contacts[0].Id
        ]
        .size()
    );

    Test.startTest();
    insert cgm;
    Test.stopTest();

    AccountContactRelation acr = [
      SELECT ID, MTC_Role__c
      FROM AccountContactRelation
      WHERE AccountId = :accounts[1].Id AND ContactId = :contacts[0].Id
    ];
    System.AssertEquals('Read-Only', acr.MTC_Role__c);
  }

  @isTest
  static void whenMultipleContactAreAddedAsGroupMemebershispOnAnAccountDifferentThanTheirParentAccountACRsAreCreated() {
    List<Account> accounts = [SELECT Id FROM Account ORDER BY Account.Name];
    Set<Id> contactIds = new Set<Id>();
    Id idOfContactGroupOnSecondAccount = TestDataFactory.createContactGroup(
        accounts[1].Id
      )
      .Id;
    List<Group_Membership__c> grmList = new List<Group_Membership__c>();
    for (Contact cnt : [
      SELECT Id
      FROM Contact
      WHERE AccountId = :accounts[0].Id
    ]) {
      contactIds.add(cnt.Id);
      grmList.add(
        new Group_Membership__c(
          Contact__c = cnt.Id,
          Contact_Group__c = idOfContactGroupOnSecondAccount,
          DupCheck__c = '' + cnt.Id + idOfContactGroupOnSecondAccount
        )
      );
    }

    System.AssertEquals(
      0,
      [
          SELECT ID, MTC_Role__c
          FROM AccountContactRelation
          WHERE AccountId = :accounts[1].Id AND ContactId = :contactIds
        ]
        .size()
    );

    Test.startTest();
    insert grmList;
    Test.stopTest();

    List<AccountContactRelation> acrs = [
      SELECT ID, MTC_Role__c
      FROM AccountContactRelation
      WHERE AccountId = :accounts[1].Id AND ContactId IN :contactIds
    ];
    System.AssertEquals(3, acrs.size());
    System.AssertEquals(
      'Read-Only Read-Only Read-Only',
      acrs[0].MTC_Role__c +
      ' ' +
      acrs[1].MTC_Role__c +
      ' ' +
      acrs[2].MTC_Role__c
    );
  }

  @isTest
  static void whenMultipleContactAreAddedAsGroupMemebershispOnAnAccountDifferentThanTheirParentAccountACRsAreCreatedWhereNotPreExisting() {
    List<Account> accounts = [SELECT Id FROM Account ORDER BY Account.Name];
    List<Id> contactIds = new List<Id>();
    Id idOfContactGroupOnSecondAccount = TestDataFactory.createContactGroup(
        accounts[1].Id
      )
      .Id;
    List<Group_Membership__c> grmList = new List<Group_Membership__c>();
    List<AccountContactRelation> acrsToPreInsert = new List<AccountContactRelation>();
    for (Contact cnt : [
      SELECT Id
      FROM Contact
      WHERE AccountId = :accounts[0].Id
    ]) {
      contactIds.add(cnt.Id);
      grmList.add(
        new Group_Membership__c(
          Contact__c = cnt.Id,
          Contact_Group__c = idOfContactGroupOnSecondAccount,
          DupCheck__c = '' + cnt.Id + idOfContactGroupOnSecondAccount
        )
      );
    }

    acrsToPreInsert.add(
      new AccountContactRelation(
        AccountId = accounts.get(1).Id,
        ContactId = contactIds[0],
        MTC_Role__c = 'Read-Only'
      )
    );
    acrsToPreInsert.add(
      new AccountContactRelation(
        AccountId = accounts.get(1).Id,
        ContactId = contactIds[1],
        MTC_Role__c = 'Admin'
      )
    );
    insert acrsToPreInsert;

    System.AssertEquals(
      2,
      [
          SELECT ID, MTC_Role__c
          FROM AccountContactRelation
          WHERE AccountId = :accounts[1].Id AND ContactId = :contactIds
        ]
        .size()
    );

    Test.startTest();
    insert grmList;
    Test.stopTest();

    Integer acrCounter = 0;
    for (AccountContactRelation acr : [
      SELECT ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE AccountId = :accounts[1].Id AND ContactId IN :contactIds
    ]) {
      if (acr.ContactId == contactIds[0] || acr.ContactId == contactIds[2]) {
        acr.MTC_Role__c = 'Read-Only';
      } else if (acr.ContactId == contactIds[1]) {
        acr.MTC_Role__c = 'Admin';
      }
      acrCounter += 1;
    }
    System.AssertEquals(3, acrCounter);
  }
  @isTest
  static void verifyAccountIdsWhenAssignedToGroup() {
    List<Account> accounts = [SELECT Name FROM Account];
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts) {
      name2Id.put(acc.Name, acc.Id);
    }
    List<Contact> contacts = [
      SELECT Id, (SELECT MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE AccountId = :name2Id.get('Account 1')
    ];
    update new List<AccountContactRelation>{
      new AccountContactRelation(
        Id = contacts[0].AccountContactRelations[0].Id,
        MTC_Role__c = 'Read-Only'
      ),
      new AccountContactRelation(
        Id = contacts[1].AccountContactRelations[0].Id,
        MTC_Role__c = 'Read-Only'
      )
    };
    System.assertEquals(
      false,
      AccountRelationUtil.accountIdsWhenAssignedToGroup(contacts[0].Id)
        .isEmpty()
    );
    System.assertEquals(
      false,
      AccountRelationUtil.accountIdsWhenAssignedToGroup(contacts[1].Id)
        .isEmpty()
    );
    Group_Membership__c gm = [
      SELECT Id
      FROM Group_Membership__c
      WHERE
        Contact_Group__r.Account__c = :name2Id.get('Account 1')
        AND Contact__c = :contacts[1].Id
    ];
    delete gm;
    System.assertEquals(
      false,
      AccountRelationUtil.accountIdsWhenAssignedToGroup(contacts[0].Id)
        .isEmpty()
    );
    System.assertEquals(
      true,
      AccountRelationUtil.accountIdsWhenAssignedToGroup(contacts[1].Id)
        .isEmpty()
    );
    insert new AccountContactRelation(
      ContactId = contacts[1].Id,
      AccountId = name2Id.get('Account 2'),
      MTC_Role__c = 'Read-Only'
    );
    Set<Id> accountIds = AccountRelationUtil.accountIdsWhenAssignedToGroup(
      contacts[1].Id
    );
    System.assertEquals(false, accountIds.isEmpty());
    System.assertEquals(true, accountIds.contains(name2Id.get('Account 2')));
  }
}