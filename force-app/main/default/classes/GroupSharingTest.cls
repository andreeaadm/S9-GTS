@isTest
public with sharing class GroupSharingTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;

    List<Account> accounts = TestDataFactory.createAccounts(2, true);

    TestDataFactory.createAccountsWithContacts(accounts, 5);
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      true
    );
    List<Asset> deliverables = TestDataFactory.createDeliverableForReports(
      new List<Asset>{ reports[1] },
      true
    );
    ReportAccessUtil.enableSharingProcessing();
  }

  // Helper method to set mtc role to Read-Only
  static void updateACRsToReadOnly(Set<Id> contactIds) {
    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId IN :contactIds
    ];

    for (AccountContactRelation acr : acrs) {
      acr.MTC_Role__c = 'Read-Only';
    }
    update acrs;
  }

  @isTest
  static void adminHaveAccessToUnassignedReports() {
    ReportAccessUtil.enableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;

    Contact con = [
      SELECT
        AccountId,
        Email,
        (SELECT Id, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Account.Name = 'Account 1'
      LIMIT 1
    ];
    User adminUser = TestDataFactory.createCommunityUser(
      'MTC Admin Login',
      con.AccountId,
      con.Id
    );
    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = con.AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;

    Test.startTest();

    // Lets make this contact an admin
    con.AccountContactRelations[0].MTC_Role__c = 'admin';
    update con.AccountContactRelations;

    Test.stopTest();

    System.runAs(adminUser) {
      List<Asset> reports = [
        SELECT Id, Name
        FROM Asset
        WHERE AccountId = :con.AccountId
      ];
      System.assertEquals(false, reports.isEmpty());
    }

  }

  @isTest
  static void given_GroupAndReport_as_MTCStandard_GainAccess_when_ContactAddedToGroup() {
    ReportAccessUtil.disableSharingProcessing();

    Contact con = [
      SELECT AccountId, Email
      FROM Contact
      WHERE Account.Name = 'Account 1'
      LIMIT 1
    ];
    TestDataFactory.createCommunityUser(
      'MTC Standard Login',
      con.AccountId,
      con.Id
    );

    updateACRsToReadOnly(new Set<Id>{ con.Id });

    SchemaUtil.RecordType reportRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Report'
    );
    SchemaUtil.RecordType deliverableRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Deliverable'
    );

    List<Asset> reportsWithDeliverables = [
      SELECT
        Id,
        AccountId,
        RecordTypeId,
        Name,
        Type__c,
        (
          SELECT Id, AccountId, RecordTypeId, Name, Type__c
          FROM ChildAssets
          WHERE RecordTypeId = :deliverableRT.recordId
        )
      FROM Asset
      WHERE accountId = :con.AccountId AND RecordTypeId = :reportRT.recordId
    ];
    // System.debug(JSON.serializePretty(reportsWithDeliverables));

    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = con.AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;

    ReportAccessUtil.enableSharingProcessing();

    ContactGroupUtil.linkGroupToReport(
      groupG,
      reportsWithDeliverables[0],
      true
    );

    Integer shareCountBeforeLink = [
        SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
        FROM AssetShare
      ]
      .size();

    Test.startTest();

    ContactGroupUtil.linkContactToGroup(con, groupG, true);

    Test.stopTest();

    List<AssetShare> assetShares = [
      SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
      FROM AssetShare
    ];
    // System.debug(JSON.serializePretty(assetShares));
    System.assertEquals(shareCountBeforeLink + 1, assetShares.size());
  }

  @isTest
  static void given_GroupAndReport_as_MTCStandard_GainAccess_when_ReportAddedToGroup() {
    List<Contact> cons = [
      SELECT Id, Firstname, Lastname, Email, AccountId, Account.Name
      FROM Contact
      WHERE Account.Name = 'Account 1'
      LIMIT 2
    ];

    Contact con = cons[0], con2 = cons[1];
    TestDataFactory.createCommunityUsers('MTC Standard Login', cons);

    updateACRsToReadOnly(new Set<Id>{ con.Id, con2.Id });

    SchemaUtil.RecordType reportRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Report'
    );
    SchemaUtil.RecordType deliverableRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Deliverable'
    );

    List<Asset> reportsWithDeliverables = [
      SELECT
        Id,
        AccountId,
        RecordTypeId,
        Name,
        Type__c,
        (
          SELECT Id, AccountId, RecordTypeId, Name, Type__c
          FROM ChildAssets
          WHERE RecordTypeId = :deliverableRT.recordId
        )
      FROM Asset
      WHERE accountId = :con.AccountId AND RecordTypeId = :reportRT.recordId
    ];

    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = con.AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;

    ContactGroupUtil.linkContactToGroup(con, groupG, true);
    ContactGroupUtil.linkContactToGroup(con2, groupG, true);

    Integer shareCountBeforeLink = [
        SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
        FROM AssetShare
      ]
      .size();

    Test.startTest();

    ContactGroupUtil.linkGroupToReport(
      groupG,
      reportsWithDeliverables[0],
      true
    );

    Test.stopTest();

    List<AssetShare> assetShares = [
      SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
      FROM AssetShare
    ];
    System.assertEquals(shareCountBeforeLink + 2, assetShares.size());
    // System.debug(JSON.serializePretty(assetShares));

    Set<Id> contactIds = new Set<Id>{ con.Id, con2.Id };
    Map<Id, User> usersForContacts = new Map<Id, User>(
      [SELECT Id, username, contactid FROM user WHERE contactid IN :contactIds]
    );

    Integer shareCount = 0;
    for (AssetShare share : assetShares) {
      if (usersForContacts.containsKey(share.UserOrGroupId)) {
        shareCount = shareCount + 1;
      }
    }
    System.assertEquals(
      2,
      shareCount,
      'Two AssetShare records should have been created.'
    );
  }
  // Relates to story [MTC-254]
  @isTest
  static void as_MTCStandard_IHave_AccessToDeliverable_when_AccessToReport() {
    ReportAccessUtil.disableSharingProcessing();
    Contact con = [
      SELECT
        AccountId,
        Email,
        (SELECT Id, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Account.Name = 'Account 2'
      LIMIT 1
    ];

    User mtcStandardUser = TestDataFactory.createCommunityUser(
      'MTC Standard Login',
      con.AccountId,
      con.Id
    );

    updateACRsToReadOnly(new Set<Id>{ con.Id });

    con.AccountContactRelations[0].MTC_Role__c = 'Read-Only';
    update con.AccountContactRelations;

    SchemaUtil.RecordType reportRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Report'
    );
    SchemaUtil.RecordType deliverableRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Deliverable'
    );

    List<Asset> reportsWithDeliverables = [
      SELECT
        Id,
        AccountId,
        RecordTypeId,
        Name,
        Type__c,
        (
          SELECT Id, AccountId, RecordTypeId, Name, Type__c
          FROM ChildAssets
          WHERE RecordTypeId = :deliverableRT.recordId
        )
      FROM Asset
      WHERE accountId = :con.AccountId AND RecordTypeId = :reportRT.recordId
    ];
    System.assertEquals(1, reportsWithDeliverables[0].ChildAssets.size());
    Id deliverableId = reportsWithDeliverables[0].ChildAssets[0].Id;

    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = con.AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;

    ReportAccessUtil.enableSharingProcessing();

    ContactGroupUtil.linkGroupToReport(
      groupG,
      reportsWithDeliverables[0],
      true
    );

    Integer shareCountBeforeLink = [
        SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
        FROM AssetShare
        WHERE UserOrGroupId = :mtcStandardUser.Id AND AssetId = :deliverableId
      ]
      .size();

    Test.startTest();

    ContactGroupUtil.linkContactToGroup(con, groupG, true);

    Test.stopTest();

    List<AssetShare> assetShares = [
      SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
      FROM AssetShare
      WHERE UserOrGroupId = :mtcStandardUser.Id AND AssetId = :deliverableId
    ];
    // System.debug(JSON.serializePretty(assetShares));
    System.assertEquals(shareCountBeforeLink + 1, assetShares.size());
  }

  @isTest
  static void user_keeps_access_when_in_any_group_having_access() {
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;

    Contact con = [
      SELECT AccountId, Email
      FROM Contact
      WHERE Account.Name = 'Account 2'
      LIMIT 1
    ];
    User mtcStandardUser = TestDataFactory.createCommunityUser(
      'MTC Standard Login',
      con.AccountId,
      con.Id
    );

    SchemaUtil.RecordType reportRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Report'
    );
    SchemaUtil.RecordType deliverableRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Deliverable'
    );

    List<Asset> reportsWithDeliverables = [
      SELECT
        Id,
        AccountId,
        RecordTypeId,
        Name,
        Type__c,
        (
          SELECT Id, AccountId, RecordTypeId, Name, Type__c
          FROM ChildAssets
          WHERE RecordTypeId = :deliverableRT.recordId
        )
      FROM Asset
      WHERE accountId = :con.AccountId AND RecordTypeId = :reportRT.recordId
    ];

    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = con.AccountId,
      Group_Name__c = 'group-g'
    );
    Contact_Group__c groupG2 = new Contact_Group__c(
      Account__c = con.AccountId,
      Group_Name__c = 'group-g2'
    );
    insert new List<Contact_Group__c>{ groupG, groupG2 };

    Access__c access4groupG = ContactGroupUtil.linkGroupToReport(
      groupG,
      reportsWithDeliverables[0],
      false
    );
    Access__c access4groupG2 = ContactGroupUtil.linkGroupToReport(
      groupG2,
      reportsWithDeliverables[0],
      false
    );
    insert new List<Access__c>{ access4groupG, access4groupG2 };

    Group_Membership__c conInGroupG = ContactGroupUtil.linkContactToGroup(
      con,
      groupG,
      false
    );
    Group_Membership__c conInGroupG2 = ContactGroupUtil.linkContactToGroup(
      con,
      groupG2,
      false
    );

    ReportAccessUtil.enableSharingProcessing();

    insert new List<Group_Membership__c>{ conInGroupG, conInGroupG2 };

    Integer shareCountBeforeUnlink = [
        SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
        FROM AssetShare
        WHERE UserOrGroupId = :mtcStandardUser.Id
      ]
      .size();

    Test.startTest();
    ContactGroupUtil.unlinkContactsFromGroup(new List<Contact>{ con }, groupG);
    Test.stopTest();

    List<AssetShare> assetShares = [
      SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
      FROM AssetShare
      WHERE UserOrGroupId = :mtcStandardUser.Id
    ];
    // System.debug(JSON.serializePretty(assetShares));
    System.assertEquals(shareCountBeforeUnlink, assetShares.size());
  }

  @isTest
  static void user_loses_access_when_removed_from_group() {
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;

    Contact con = [
      SELECT
        AccountId,
        Email,
        (SELECT Id, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Account.Name = 'Account 2'
      LIMIT 1
    ];
    // Must be done before the role is set so the Contact is not added to Default Group
    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = con.AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;

    User mtcStandardUser = TestDataFactory.createCommunityUser(
      'MTC Standard Login',
      con.AccountId,
      con.Id
    );
    con.AccountContactRelations[0].MTC_Role__c = 'Read-Only';
    update con.AccountContactRelations;

    List<Asset> reportsWithDeliverables = [
      SELECT
        Id,
        AccountId,
        RecordTypeId,
        Name,
        Type__c,
        (
          SELECT Id, AccountId, RecordTypeId, Name, Type__c
          FROM ChildAssets
          WHERE RecordTypeId = :AssetUtil.deliverableRT.recordId
        )
      FROM Asset
      WHERE
        accountId = :con.AccountId
        AND RecordTypeId = :AssetUtil.reportRT.recordId
    ];
    // Need to remove Report from Default Group
    Access__c defaultGroupAccessToDelete = [
      SELECT Id
      FROM Access__c
      WHERE
        Contact_Group__r.Is_Default_Group__c = TRUE
        AND Report_Asset__c = :reportsWithDeliverables[0].Id
    ];
    delete defaultGroupAccessToDelete;

    ContactGroupUtil.linkGroupToReport(
      groupG,
      reportsWithDeliverables[0],
      true
    );
    ReportAccessUtil.enableSharingProcessing();
    ContactGroupUtil.linkContactToGroup(con, groupG, true);

    Integer shareCountBeforeUnlink = [
        SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
        FROM AssetShare
        WHERE UserOrGroupId = :mtcStandardUser.Id
      ]
      .size();
    System.assertEquals(
      2,
      shareCountBeforeUnlink,
      'Expecting an AssetShare record for each of Report, Deliverable'
    );

    Test.startTest();
    ContactGroupUtil.unlinkContactsFromGroup(new List<Contact>{ con }, groupG);
    Test.stopTest();

    List<AssetShare> assetShares = [
      SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
      FROM AssetShare
      WHERE UserOrGroupId = :mtcStandardUser.Id
    ];
    // System.debug(JSON.serializePretty(assetShares));
    System.assertEquals(0, assetShares.size());
  }

  // when an access record is deleted, report unlinked from group
  @isTest
  static void members_lose_access_when_access_record_deleted() {
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;

    List<Contact> cons = [
      SELECT
        Id,
        Firstname,
        Lastname,
        Email,
        AccountId,
        Account.Name,
        (SELECT Id, MTC_Role__c FROM AccountContactRelations)
      FROM Contact
      WHERE Account.Name = 'Account 2'
      LIMIT 2
    ];
    // Must be done before the role is set so the Contact is not added to Default Group
    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = cons[0].AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;

    Contact con = cons[0], con2 = cons[1];
    TestDataFactory.createCommunityUsers('MTC Standard Login', cons);

    Set<Id> contactIds = new Set<Id>{ con.Id, con2.Id };

    updateACRsToReadOnly(contactIds);

    Map<Id, User> usersForContacts = new Map<Id, User>(
      [SELECT Id, username, contactid FROM user WHERE contactid IN :contactIds]
    );

    List<Asset> reportsWithDeliverables = [
      SELECT
        Id,
        AccountId,
        Name,
        RecordTypeId,
        Type__c,
        (
          SELECT Id, AccountId, RecordTypeId, Name, Type__c
          FROM ChildAssets
          WHERE RecordTypeId = :AssetUtil.deliverableRT.recordId
        )
      FROM Asset
      WHERE
        accountId = :con.AccountId
        AND RecordTypeId = :AssetUtil.reportRT.recordId
    ];
    Set<Id> assetIds = new Set<Id>{
      reportsWithDeliverables[0].Id,
      reportsWithDeliverables[0].ChildAssets[0].Id
    };

    // Need to remove Report from Default Group
    Access__c defaultGroupAccessToDelete = [
      SELECT Id
      FROM Access__c
      WHERE
        Contact_Group__r.Is_Default_Group__c = TRUE
        AND Report_Asset__c = :reportsWithDeliverables[0].Id
    ];
    delete defaultGroupAccessToDelete;

    Group_Membership__c conInGroupG = ContactGroupUtil.linkContactToGroup(
      con,
      groupG,
      false
    );
    Group_Membership__c con2InGroupG = ContactGroupUtil.linkContactToGroup(
      con2,
      groupG,
      false
    );
    insert new List<Group_Membership__c>{ conInGroupG, con2InGroupG };

    ReportAccessUtil.enableSharingProcessing();

    ContactGroupUtil.linkGroupToReport(
      groupG,
      reportsWithDeliverables[0],
      true
    );

    Integer shareCountBeforeLink = [
        SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
        FROM AssetShare
        WHERE
          AssetId IN :assetIds
          AND UserOrGroupId IN :usersForContacts.keySet()
      ]
      .size();
    System.assertNotEquals(0, shareCountBeforeLink);

    Test.startTest();
    ContactGroupUtil.unlinkGroupsFromReport(
      new List<Contact_Group__c>{ groupG },
      reportsWithDeliverables[0].Id
    );
    Test.stopTest();

    List<AssetShare> assetShares = [
      SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
      FROM AssetShare
      WHERE AssetId IN :assetIds AND UserOrGroupId IN :usersForContacts.keySet()
    ];
    System.assertEquals(0, assetShares.size());
  }

  @isTest
  static void adminWithAccessToReportCanEditClientReference() {
    ReportAccessUtil.disableSharingProcessing();

    Contact con = [
      SELECT
        AccountId,
        Email,
        (SELECT MTC_Role__c, AccountId FROM AccountContactRelations)
      FROM Contact
      WHERE Account.Name = 'Account 1'
      LIMIT 1
    ];
    TestDataFactory.createCommunityUser(
      'MTC Admin Login',
      con.AccountId,
      con.Id
    );
    AccountContactRelation acr = con.AccountContactRelations[0];
    acr.MTC_Role__c = 'Admin';
    update acr;

    User conUser = [SELECT Id FROM User WHERE ContactId = :con.Id];

    SchemaUtil.RecordType reportRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Report'
    );
    SchemaUtil.RecordType deliverableRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Deliverable'
    );

    List<Asset> reportsWithDeliverables = [
      SELECT
        Id,
        AccountId,
        RecordTypeId,
        Name,
        Type__c,
        (
          SELECT Id, AccountId, RecordTypeId, Name, Type__c
          FROM ChildAssets
          WHERE RecordTypeId = :deliverableRT.recordId
        )
      FROM Asset
      WHERE accountId = :con.AccountId AND RecordTypeId = :reportRT.recordId
    ];
    // System.debug(JSON.serializePretty(reportsWithDeliverables));

    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = con.AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;

    ReportAccessUtil.enableSharingProcessing();

    ContactGroupUtil.linkGroupToReport(
      groupG,
      reportsWithDeliverables[0],
      true
    );

    Integer shareCountBeforeLink = [
        SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
        FROM AssetShare
        WHERE UserOrGroupId = :conUser.Id
      ]
      .size();

    Test.startTest();

    ContactGroupUtil.linkContactToGroup(con, groupG, true);

    Test.stopTest();

    List<AssetShare> assetShares = [
      SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
      FROM AssetShare
      WHERE UserOrGroupId = :conUser.Id
    ];
    // System.debug(JSON.serializePretty(assetShares));
    System.assertEquals(shareCountBeforeLink + 1, assetShares.size());
    System.assertEquals('Edit', assetShares[0].AssetAccessLevel);
  }

  @isTest
  static void readOnlyBecomingAdmin_CanEditClientReference() {
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;

    Contact con = [
      SELECT
        AccountId,
        Email,
        (SELECT MTC_Role__c, AccountId FROM AccountContactRelations)
      FROM Contact
      WHERE Account.Name = 'Account 1'
      LIMIT 1
    ];
    TestDataFactory.createCommunityUser(
      'MTC Standard Login',
      con.AccountId,
      con.Id
    );
    AccountContactRelation acr = con.AccountContactRelations[0];
    acr.MTC_Role__c = 'Read-Only';
    update acr;

    User conUser = [SELECT Id FROM User WHERE ContactId = :con.Id];

    SchemaUtil.RecordType reportRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Report'
    );
    SchemaUtil.RecordType deliverableRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Deliverable'
    );

    List<Asset> reportsWithDeliverables = [
      SELECT
        Id,
        AccountId,
        RecordTypeId,
        Name,
        Type__c,
        (
          SELECT Id, AccountId, RecordTypeId, Name, Type__c
          FROM ChildAssets
          WHERE RecordTypeId = :deliverableRT.recordId
        )
      FROM Asset
      WHERE accountId = :con.AccountId AND RecordTypeId = :reportRT.recordId
    ];
    // System.debug(JSON.serializePretty(reportsWithDeliverables));

    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = con.AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;

    ContactGroupUtil.linkGroupToReport(
      groupG,
      reportsWithDeliverables[0],
      true
    );

    ReportAccessUtil.enableSharingProcessing();

    Test.startTest();

    ContactGroupUtil.linkContactToGroup(con, groupG, true);

    acr.MTC_Role__c = 'Admin';
    update acr;

    Test.stopTest();

    List<AssetShare> assetShares = [
      SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
      FROM AssetShare
      WHERE UserOrGroupId = :conUser.Id
    ];
    // System.debug(JSON.serializePretty(assetShares));

    System.assertEquals('Edit', assetShares[0].AssetAccessLevel);
  }

  @isTest
  static void goingToNoAccessOrRestricted_should_loseAnyAccess() {
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;

    Contact con = [
      SELECT
        AccountId,
        Email,
        (SELECT MTC_Role__c, AccountId FROM AccountContactRelations)
      FROM Contact
      WHERE Account.Name = 'Account 1'
      LIMIT 1
    ];
    TestDataFactory.createCommunityUser(
      'MTC Standard Login',
      con.AccountId,
      con.Id
    );
    AccountContactRelation acr = con.AccountContactRelations[0];
    acr.MTC_Role__c = 'Read-Only';
    update acr;

    User conUser = [SELECT Id FROM User WHERE ContactId = :con.Id];

    SchemaUtil.RecordType reportRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Report'
    );
    SchemaUtil.RecordType deliverableRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Deliverable'
    );

    List<Asset> reportsWithDeliverables = [
      SELECT
        Id,
        AccountId,
        RecordTypeId,
        Name,
        Type__c,
        (
          SELECT Id, AccountId, RecordTypeId, Name, Type__c
          FROM ChildAssets
          WHERE RecordTypeId = :deliverableRT.recordId
        )
      FROM Asset
      WHERE accountId = :con.AccountId AND RecordTypeId = :reportRT.recordId
    ];
    // System.debug(JSON.serializePretty(reportsWithDeliverables));

    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = con.AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;

    ContactGroupUtil.linkGroupToReport(
      groupG,
      reportsWithDeliverables[0],
      true
    );

    ReportAccessUtil.enableSharingProcessing();
    ContactGroupUtil.linkContactToGroup(con, groupG, true);

    Test.startTest();

    acr.MTC_Role__c = 'No-Access';
    update acr;

    Test.stopTest();

    List<AssetShare> assetShares = [
      SELECT AssetAccessLevel, AssetId, RowCause, UserOrGroupId
      FROM AssetShare
      WHERE UserOrGroupId = :conUser.Id
    ];

    System.assertEquals(0, assetShares.size());
  }
}