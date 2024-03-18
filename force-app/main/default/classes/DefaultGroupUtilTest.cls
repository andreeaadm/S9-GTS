@isTest
public with sharing class DefaultGroupUtilTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    Account accA = new Account(Name = 'Account A', Is_MTC_Account__c = true);
    Account accB = new Account(Name = 'Account B', Is_MTC_Account__c = true);
    Account accC = new Account(Name = 'Account C', Is_MTC_Account__c = true);
    insert new List<Account>{ accA, accB, accC };
    Contact_Group__c expiredGroup = new Contact_Group__c(
      Account__c = accB.Id,
      Group_Name__c = 'expired group',
      Expiry__c = Date.today() - 1,
      Has_Expired__c = true
    );
    Contact_Group__c activeGroup = new Contact_Group__c(
      Account__c = accC.Id,
      Group_Name__c = 'valid active custom group',
      Has_Expired__c = false
    );
    insert new List<Contact_Group__c>{ expiredGroup, activeGroup };
  }
  @isTest
  static void defaultGroupCreatedOnAccountCreation() {
    Account acc = new Account(Name = 'Account One', Is_MTC_Account__c = true);
    Test.startTest();
    insert acc;
    Test.stopTest();
    List<Contact_Group__c> groupsForAcc = [
      SELECT Id, Group_Name__c, Group_Description__c, Is_Default_Group__c
      FROM Contact_Group__c
      WHERE Account__c = :acc.Id
    ];
    System.assertEquals(false, groupsForAcc.isEmpty());
    System.assertEquals('Default Group', groupsForAcc[0].Group_Name__c);
    System.assert(String.isBlank(groupsForAcc[0].Group_Description__c));
    System.assertEquals(true, groupsForAcc[0].Is_Default_Group__c);
  }

  @isTest
  static void verifyGetDefaultGroupsForAccounts() {
    Map<Id, Account> accounts = new Map<Id, Account>(
      [SELECT Name FROM Account ORDER BY Name]
    );
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts.values()) {
      name2Id.put(acc.Name, acc.Id);
    }

    Map<Id, Contact_Group__c> defaultGroups = DefaultGroupUtil.getDefaultGroupsForAccounts(
      accounts.keySet()
    );

    System.assertEquals(
      true,
      defaultGroups.containsKey(name2Id.get('Account A'))
    );
    System.assertEquals(
      true,
      defaultGroups.get(name2Id.get('Account A')).Is_Default_Group__c
    );

    System.assertEquals(
      true,
      defaultGroups.containsKey(name2Id.get('Account B'))
    );
    System.assertEquals(
      true,
      defaultGroups.get(name2Id.get('Account B')).Is_Default_Group__c
    );

    System.assertEquals(
      false,
      defaultGroups.containsKey(name2Id.get('Account C'))
    );
  }

  @isTest
  static void whenACRcreatedContactAddedToDefaultGroup() {
    List<Account> accounts = new List<Account>(
      [SELECT Name FROM Account ORDER BY Name]
    );
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts) {
      name2Id.put(acc.Name, acc.Id);
    }

    List<Contact> cons = TestDataFactory.createContacts(
      1,
      true,
      name2Id.get('Account A')
    );
    Contact con = [
      SELECT
        Id,
        (SELECT Id, accountId, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Id = :cons[0].Id
    ];
    List<Group_Membership__c> memberships = [
      SELECT Id, Contact__c, Contact_Group__c, Contact_Group__r.Account__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];
    System.assertEquals(true, memberships.isEmpty());

    Test.startTest();
    con.AccountContactRelations[0].MTC_Role__c = 'Read-Only';
    update con.AccountContactRelations;
    Test.stopTest();

    memberships = [
      SELECT Id, Contact__c, Contact_Group__c, Contact_Group__r.Account__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];
    System.assertEquals(1, memberships.size());
    System.assertEquals(
      name2Id.get('Account A'),
      memberships[0].Contact_Group__r.Account__c
    );

    List<AccountContactRelation> newRelations = new List<AccountContactRelation>();
    newRelations.add(
      new AccountContactRelation(
        AccountId = name2Id.get('Account B'),
        ContactId = con.Id,
        MTC_Role__c = 'Read-Only'
      )
    );
    newRelations.add(
      new AccountContactRelation(
        AccountId = name2Id.get('Account C'),
        ContactId = con.Id,
        MTC_Role__c = 'Admin'
      )
    );
    insert newRelations;

    memberships = [
      SELECT
        Id,
        Contact__c,
        Contact_Group__c,
        Contact_Group__r.Account__c,
        Contact_Group__r.Is_Default_Group__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];
    System.assertEquals(2, memberships.size());
    for (Group_Membership__c m : memberships) {
      System.assertNotEquals(
        name2Id.get('Account C'),
        m.Contact_Group__r.Account__c
      );
      System.assertEquals(true, m.Contact_Group__r.Is_Default_Group__c);
    }
  }
  // when contact goes from read-only to admin or cga, membership should not be duplicated
  @isTest
  static void whenACRupdatedMembershipToDefaultGroupUnaffected() {
    List<Account> accounts = new List<Account>(
      [SELECT Name FROM Account ORDER BY Name]
    );
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts) {
      name2Id.put(acc.Name, acc.Id);
    }

    List<Contact> cons = TestDataFactory.createContacts(
      1,
      true,
      name2Id.get('Account A')
    );
    Contact con = [
      SELECT
        Id,
        (SELECT Id, accountId, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Id = :cons[0].Id
    ];
    con.AccountContactRelations[0].MTC_Role__c = 'Read-Only';
    update con.AccountContactRelations;

    List<Group_Membership__c> memberships = [
      SELECT Id, Contact__c, Contact_Group__c, Contact_Group__r.Account__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];

    Test.startTest();
    con.AccountContactRelations[0].MTC_Role__c = 'Admin';
    update con.AccountContactRelations;
    Test.stopTest();

    List<Group_Membership__c> membershipsAfter = [
      SELECT Id, Contact__c, Contact_Group__c, Contact_Group__r.Account__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];

    System.assertEquals(memberships.size(), membershipsAfter.size());
  }

  @isTest
  static void whenACRupdatedToNoAccessMembershipDeleted() {
    List<Account> accounts = new List<Account>(
      [SELECT Name FROM Account ORDER BY Name]
    );
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts) {
      name2Id.put(acc.Name, acc.Id);
    }

    List<Contact> cons = TestDataFactory.createContacts(
      1,
      true,
      name2Id.get('Account A')
    );
    Contact con = [
      SELECT
        Id,
        (SELECT Id, accountId, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Id = :cons[0].Id
    ];
    con.AccountContactRelations[0].MTC_Role__c = 'Read-Only';
    update con.AccountContactRelations;

    List<Group_Membership__c> memberships = [
      SELECT Id, Contact__c, Contact_Group__c, Contact_Group__r.Account__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];

    Test.startTest();
    con.AccountContactRelations[0].MTC_Role__c = 'No-Access';
    update con.AccountContactRelations;
    Test.stopTest();

    List<Group_Membership__c> membershipsAfter = [
      SELECT Id, Contact__c, Contact_Group__c, Contact_Group__r.Account__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];

    System.assertEquals(memberships.size() - 1, membershipsAfter.size());
  }

  @isTest
  static void whenACRDeletedMembershipsDeleted() {
    List<Account> accounts = new List<Account>(
      [SELECT Name FROM Account ORDER BY Name]
    );
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts) {
      name2Id.put(acc.Name, acc.Id);
    }

    List<Contact> cons = TestDataFactory.createContacts(
      1,
      true,
      name2Id.get('Account A')
    );
    Contact con = [
      SELECT
        Id,
        (SELECT Id, accountId, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Id = :cons[0].Id
    ];

    List<AccountContactRelation> newRelations = new List<AccountContactRelation>();
    newRelations.add(
      new AccountContactRelation(
        Id = con.AccountContactRelations[0].Id,
        MTC_Role__c = 'Read-Only'
      )
    );
    newRelations.add(
      new AccountContactRelation(
        AccountId = name2Id.get('Account B'),
        ContactId = con.Id,
        MTC_Role__c = 'Read-Only'
      )
    );
    upsert newRelations;

    List<Group_Membership__c> memberships = [
      SELECT
        Id,
        Contact__c,
        Contact_Group__c,
        Contact_Group__r.Account__c,
        Contact_Group__r.Is_Default_Group__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];
    System.assertEquals(2, memberships.size());

    delete newRelations[1];

    List<Group_Membership__c> membershipsAfter = [
      SELECT Id, Contact__c, Contact_Group__c, Contact_Group__r.Account__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];

    System.assertEquals(1, membershipsAfter.size());
    System.assertEquals(
      name2Id.get('Account A'),
      membershipsAfter[0].Contact_Group__r.Account__c
    );
  }

  // A contact with role restricted or pending approval should not be placed in the default group
  @isTest
  static void whenRestrictedUserNoMembershipToDefaultGroupCreated() {
    List<Account> accounts = new List<Account>(
      [SELECT Name FROM Account ORDER BY Name]
    );
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts) {
      name2Id.put(acc.Name, acc.Id);
    }

    List<Contact> cons = TestDataFactory.createContacts(
      1,
      true,
      name2Id.get('Account A')
    );
    Contact con = [
      SELECT
        Id,
        (SELECT Id, accountId, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Id = :cons[0].Id
    ];

    Test.startTest();

    List<AccountContactRelation> newRelations = new List<AccountContactRelation>();
    newRelations.add(
      new AccountContactRelation(
        Id = con.AccountContactRelations[0].Id,
        MTC_Role__c = 'Restricted'
      )
    );
    newRelations.add(
      new AccountContactRelation(
        AccountId = name2Id.get('Account B'),
        ContactId = con.Id,
        MTC_Role__c = 'Pending Approval'
      )
    );
    upsert newRelations;

    Test.stopTest();

    List<Group_Membership__c> memberships = [
      SELECT
        Id,
        Contact__c,
        Contact_Group__c,
        Contact_Group__r.Account__c,
        Contact_Group__r.Is_Default_Group__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];
    System.assertEquals(0, memberships.size());
  }

  @isTest
  static void whenReportCreatedAddedToDefaultGroup() {
    List<Account> accounts = new List<Account>(
      [SELECT Name FROM Account ORDER BY Name]
    );
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts) {
      name2Id.put(acc.Name, acc.Id);
    }
    Test.startTest();
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      true
    );
    Test.stopTest();

    List<Access__c> accesses = [
      SELECT
        Id,
        Contact_Group__c,
        Contact_Group__r.Is_Default_Group__c,
        Contact_Group__r.Account__c
      FROM Access__c
    ];
    System.assertEquals(2, accesses.size());

    for (Access__c access : accesses) {
      System.assertEquals(true, access.Contact_Group__r.Is_Default_Group__c);
      System.assertNotEquals(
        name2Id.get('Account C'),
        access.Contact_Group__r.Account__c
      );
    }
  }

  @isTest
  static void whenReportTransferredToAnotherAccount() {
    List<Account> accounts = new List<Account>(
      [SELECT Name FROM Account ORDER BY Name]
    );
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts) {
      name2Id.put(acc.Name, acc.Id);
    }
    Asset report = TestDataFactory.createReportForAccount(
      name2Id.get('Account A'),
      true,
      1
    );

    List<Access__c> accesses = [
      SELECT
        Id,
        Contact_Group__c,
        Contact_Group__r.Is_Default_Group__c,
        Contact_Group__r.Account__c
      FROM Access__c
      WHERE Report_Asset__c = :report.Id
    ];
    System.assertEquals(1, accesses.size());

    Test.startTest();

    report.AccountId = name2Id.get('Account B');
    update report;

    Test.stopTest();

    accesses = [
      SELECT
        Id,
        Contact_Group__c,
        Contact_Group__r.Is_Default_Group__c,
        Contact_Group__r.Account__c
      FROM Access__c
      WHERE Report_Asset__c = :report.Id
    ];
    System.assertEquals(1, accesses.size());
    System.assertEquals(
      name2Id.get('Account B'),
      accesses[0].Contact_Group__r.Account__c
    );
  }

  @isTest
  static void restrictedUserBecomesReadOnlyShouldGainDefaultGroup() {
    List<Account> accounts = new List<Account>(
      [SELECT Name FROM Account ORDER BY Name]
    );
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : accounts) {
      name2Id.put(acc.Name, acc.Id);
    }
    List<Contact> cons = TestDataFactory.createContacts(
      1,
      true,
      name2Id.get('Account A')
    );
    Asset report = TestDataFactory.createReportForAccount(
      name2Id.get('Account A'),
      false,
      1
    );
    report.ContactId = cons[0].Id;
    insert report;

    Contact con = [
      SELECT
        Id,
        (SELECT Id, accountId, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Id = :cons[0].Id
    ];
    System.assertEquals(
      'Restricted',
      con.AccountContactRelations[0].MTC_Role__c
    );

    Test.startTest();

    con.AccountContactRelations[0].MTC_Role__c = 'Read-Only';
    update con.AccountContactRelations;

    Test.stopTest();

    List<Group_Membership__c> memberships = [
      SELECT Id, Contact__c, Contact_Group__c, Contact_Group__r.Account__c
      FROM Group_Membership__c
      WHERE Contact__c = :con.Id
    ];
    System.assertEquals(1, memberships.size());
    System.assertEquals(
      name2Id.get('Account A'),
      memberships[0].Contact_Group__r.Account__c
    );
  }
}