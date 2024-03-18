@IsTest
public with sharing class TC_TriggeredSharing_Test {
  @IsTest
  static void test_processNewOrUpdatedUsers_connectionShares() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    // insert a connection between the brand and supplier
    Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
      testData.brand.Id,
      testData.supplier.Id,
      testData.brandContacts[0].Id,
      'Requested'
    );
    insert conn;

    List<Id> userIds = new List<Id>{
      testData.brandUsers[0].Id,
      testData.brandUsers[1].Id,
      testData.supplierUsers[0].Id,
      testData.supplierUsers[1].Id,
      testData.facilityUsers[0].Id,
      testData.facilityUsers[1].Id
    };

    test.startTest();
    TC_TriggeredSharing.processNewOrUpdatedUsers(userIds);
    test.stopTest();

    // check what sharing records exist
    List<Brand_Supplier_Connection__Share> sharing = [
      SELECT UserOrGroupId, ParentId, AccessLevel
      FROM Brand_Supplier_Connection__Share
      WHERE RowCause = 'Manual'
    ];

    System.assertEquals(4, sharing.size());

    for (Brand_Supplier_Connection__Share bscs : sharing) {
      System.assert(userIds.contains(bscs.UserOrGroupId));
      System.assertEquals('Edit', bscs.AccessLevel);
      System.assertEquals(conn.Id, bscs.ParentId);
    }
  }

  @IsTest
  static void test_processNewOrUpdatedUsers_accountShares() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    // insert an approved connection between the brand and supplier
    insert TC_TestDataFactory_Connections.create(
      testData.brand.Id,
      testData.supplier.Id,
      testData.brandContacts[0].Id,
      'Approved'
    );

    List<Id> userIds = new List<Id>{
      testData.brandUsers[0].Id,
      testData.brandUsers[1].Id,
      testData.supplierUsers[0].Id,
      testData.supplierUsers[1].Id,
      testData.facilityUsers[0].Id,
      testData.facilityUsers[1].Id
    };

    test.startTest();
    TC_TriggeredSharing.processNewOrUpdatedUsers(userIds);
    test.stopTest();

    // check what sharing records exist
    List<AccountShare> sharing = [
      SELECT UserOrGroupId, AccountId, AccountAccessLevel
      FROM AccountShare
      WHERE RowCause = 'Manual' AND Account.Is_ToxClear_Account__c = TRUE
    ];

    System.assertEquals(14, sharing.size());

    for (AccountShare sh : sharing) {
      if (sh.AccountAccessLevel == 'Edit') {
        if (sh.UserOrGroupId == testData.supplierUsers[0].Id) {
          System.assert(
            sh.AccountId == testData.supplier.Id ||
            sh.AccountId == testData.facility.Id ||
            sh.AccountId == testData.facility2.Id
          );
        } else if (sh.UserOrGroupId == testData.brandUsers[0].Id) {
          System.assert(sh.AccountId == testData.brand.Id);
        } else {
          System.assert(false);
        }
      } else if (sh.AccountAccessLevel == 'Read') {
        if (
          sh.UserOrGroupId == testData.brandUsers[0].Id ||
          sh.UserOrGroupId == testData.brandUsers[1].Id
        ) {
          System.assert(
            sh.AccountId == testData.supplier.Id ||
            sh.AccountId == testData.facility.Id ||
            sh.AccountId == testData.facility2.Id
          );
        } else if (
          sh.UserOrGroupId == testData.supplierUsers[0].Id ||
          sh.UserOrGroupId == testData.supplierUsers[1].Id
        ) {
          System.assert(
            sh.AccountId == testData.facility.Id ||
            sh.AccountId == testData.facility2.Id ||
            sh.AccountId == testData.brand.Id
          );
        } else if (
          sh.UserOrGroupId == testData.facilityUsers[0].Id ||
          sh.UserOrGroupId == testData.facilityUsers[1].Id
        ) {
          System.assert(false);
        }
      } else {
        System.assert(false);
      }
    }
  }

  @IsTest
  static void test_processNewOrUpdatedConnections_connectionShares() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    // insert a connection between the brand and the supplier
    Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
      testData.brand,
      testData.supplier,
      testData.brandContacts[0],
      'Approved'
    );
    insert conn;

    test.startTest();
    TC_TriggeredSharing.processNewOrUpdatedConnections(
      new List<Brand_Supplier_Connection__c>{ conn }
    );
    test.stopTest();

    // check what sharing records exist
    List<Brand_Supplier_Connection__Share> sharing = [
      SELECT UserOrGroupId, ParentId
      FROM Brand_Supplier_Connection__Share
      WHERE RowCause = 'Manual'
    ];

    System.assertEquals(6, sharing.size());

    for (Brand_Supplier_Connection__Share bscs : sharing) {
      System.assertEquals(conn.Id, bscs.ParentId);
      System.assert(
        bscs.USerOrGroupId == testData.brandUsers[0].Id ||
        bscs.USerOrGroupId == testData.brandUsers[1].Id ||
        bscs.USerOrGroupId == testData.supplierUsers[0].Id ||
        bscs.USerOrGroupId == testData.supplierUsers[1].Id ||
        bscs.USerOrGroupId == testData.facilityUsers[0].Id ||
        bscs.USerOrGroupId == testData.facilityUsers[1].Id
      );
    }
  }

  @IsTest
  static void test_processNewOrUpdatedConnections_accountShares() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    // insert a connection between the brand and the supplier
    Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
      testData.brand,
      testData.supplier,
      testData.brandContacts[0],
      'Approved'
    );
    insert conn;

    test.startTest();
    TC_TriggeredSharing.processNewOrUpdatedConnections(
      new List<Brand_Supplier_Connection__c>{ conn }
    );
    test.stopTest();

    // check what sharing records exist
    List<AccountShare> sharing = [
      SELECT UserOrGroupId, AccountId, AccountAccessLevel
      FROM AccountShare
      WHERE RowCause = 'Manual' AND Account.Is_ToxClear_Account__c = TRUE
    ];

    System.assertEquals(14, sharing.size());

    for (AccountShare sh : sharing) {
      if (sh.AccountAccessLevel == 'Edit') {
        if (sh.UserOrGroupId == testData.supplierUsers[0].Id) {
          System.assert(
            sh.AccountId == testData.supplier.Id ||
            sh.AccountId == testData.facility.Id ||
            sh.AccountId == testData.facility2.Id
          );
        } else if (sh.UserOrGroupId == testData.brandUsers[0].Id) {
          System.assert(sh.AccountId == testData.brand.Id);
        } else {
          System.assert(false);
        }
      } else if (sh.AccountAccessLevel == 'Read') {
        if (
          sh.UserOrGroupId == testData.brandUsers[0].Id ||
          sh.UserOrGroupId == testData.brandUsers[1].Id
        ) {
          System.assert(
            sh.AccountId == testData.supplier.Id ||
            sh.AccountId == testData.facility.Id ||
            sh.AccountId == testData.facility2.Id
          );
        } else if (
          sh.UserOrGroupId == testData.supplierUsers[0].Id ||
          sh.UserOrGroupId == testData.supplierUsers[1].Id
        ) {
          System.assert(
            sh.AccountId == testData.facility.Id ||
            sh.AccountId == testData.facility2.Id ||
            sh.AccountId == testData.brand.Id
          );
        } else if (
          sh.UserOrGroupId == testData.facilityUsers[0].Id ||
          sh.UserOrGroupId == testData.facilityUsers[1].Id
        ) {
          System.assert(false);
        }
      } else {
        System.assert(false);
      }
    }
  }

  @isTest
  static void test_processNewOrUpdatedAccounts_removeAccountShares() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    // async process to insert proper shares may not run first so
    // insert these incorrect shares synchronously to test with
    insert new List<AccountShare>{
      new AccountShare(
        AccountId = testData.brand.Id,
        UserOrGroupId = testData.supplierUsers[0].Id,
        AccountAccessLevel = 'Read',
        RowCause = 'Manual',
        OpportunityAccessLevel = 'None'
      ),
      new AccountShare(
        AccountId = testData.brand.Id,
        UserOrGroupId = testData.supplierUsers[1].Id,
        AccountAccessLevel = 'Edit',
        RowCause = 'Manual',
        OpportunityAccessLevel = 'None'
      )
    };

    test.startTest();
    testData.supplier.ToxClear_Subscription_Status__c = 'Inactive';
    update testData.supplier;
    test.stopTest();

    List<AccountShare> sharing = [
      SELECT AccountId, UserOrGroupId, AccountAccessLevel, RowCause
      FROM AccountShare
      WHERE RowCause = 'Manual'
    ];

    for (AccountShare sh : sharing) {
      System.assertNotEquals(testData.brand.Id, sh.AccountId);
    }
  }

  @isTest
  static void test_processNewOrUpdatedAccounts_addAccountShares() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    test.startTest();
    TC_TriggeredSharing.processNewOrUpdatedAccounts(
      new List<Account>{
        testData.supplier,
        testData.brand,
        testData.facility,
        testData.facility2
      }
    );
    test.stopTest();

    List<AccountShare> sharing = [
      SELECT AccountId, UserOrGroupId, AccountAccessLevel, RowCause
      FROM AccountShare
      WHERE RowCause = 'Manual'
    ];

    System.assertEquals(6, sharing.size());

    for (AccountShare sh : sharing) {
      if (sh.AccountAccessLevel == 'Read') {
        System.assertEquals(testData.supplierUsers[1].Id, sh.UserOrGroupId);
        System.assert(
          sh.AccountId == testData.facility.Id ||
          sh.AccountId == testData.facility2.Id
        );
      } else if (sh.AccountAccessLevel == 'Edit') {
        if (sh.UserOrGroupId == testData.supplierUsers[0].Id) {
          System.assert(
            sh.AccountId == testData.supplier.Id ||
            sh.AccountId == testData.facility.Id ||
            sh.AccountId == testData.facility2.Id
          );
        } else if (sh.UserOrGroupId == testData.brandUsers[0].Id) {
          System.assertEquals(testData.brand.Id, sh.AccountId);
        } else {
          System.assert(false);
        }
      }
    }
  }

  @isTest
  static void test_processUpdatedContacts_recalcAccountShares() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    List<Contact> allContacts = new List<Contact>(testData.supplierContacts);
    allContacts.addAll(testData.brandContacts);
    allContacts.addAll(testData.facilityContacts);

    for (Contact c : allContacts) {
      c.ToxClear_User_Type__c = c.ToxClear_User_Type__c ==
        'ToxClear Administrator'
        ? 'ToxClear Standard User'
        : 'ToxClear Administrator';
    }
    update allContacts;

    test.startTest();
    TC_TriggeredSharing.processUpdatedContacts(allContacts);
    test.stopTest();

    List<AccountShare> sharing = [
      SELECT AccountId, UserOrGroupId, AccountAccessLevel, RowCause
      FROM AccountShare
      WHERE RowCause = 'Manual' AND AccountAccessLevel = 'Edit'
    ];

    System.assertEquals(4, sharing.size());

    for (AccountShare sh : sharing) {
      if (sh.UserOrGroupId == testData.supplierUsers[1].Id) {
        System.assert(
          sh.AccountId == testData.supplier.Id ||
          sh.AccountId == testData.facility.Id ||
          sh.AccountId == testData.facility2.Id
        );
      } else if (sh.UserOrGroupId == testData.brandUsers[1].Id) {
        System.assertEquals(testData.brand.Id, sh.AccountId);
      } else {
        System.assert(false);
      }
    }
  }

  @IsTest
  static void test_nullHandling() {
    test.startTest();
    TC_TriggeredSharing.processNewOrUpdatedUsers(new List<Id>());
    TC_TriggeredSharing.processNewOrUpdatedConnections(
      new List<Brand_Supplier_Connection__c>()
    );
    TC_TriggeredSharing.processNewOrUpdatedAccounts(new List<Account>());
    TC_TriggeredSharing.processUpdatedContacts(new List<Contact>());
    test.stopTest();

    List<AccountShare> acctSharing = [
      SELECT Id
      FROM AccountShare
      WHERE RowCause = 'Manual'
    ];

    List<Brand_Supplier_Connection__Share> connSharing = [
      SELECT Id
      FROM Brand_Supplier_Connection__Share
      WHERE RowCause = 'Manual'
    ];

    System.assertEquals(0, acctSharing.size());
    System.assertEquals(0, connSharing.size());
  }
}