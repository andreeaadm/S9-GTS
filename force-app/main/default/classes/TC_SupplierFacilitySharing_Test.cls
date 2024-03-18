@isTest
public with sharing class TC_SupplierFacilitySharing_Test {
  @IsTest
  static void test_createAccountShares() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    Map<Id, List<Id>> userIdsByAccountId = new Map<Id, List<Id>>{
      testData.supplier.Id => new List<Id>{
        testData.supplierUsers[0].Id,
        testData.supplierUsers[1].Id
      }
    };

    Map<Id, List<Id>> adminUserIdsByAccountId = new Map<Id, List<Id>>{
      testData.supplier.Id => new List<Id>{ testData.supplierUsers[0].Id },
      testData.brand.Id => new List<Id>{ testData.brandUsers[0].Id }
    };

    TC_SupplierFacilitySharing sharing = new TC_SupplierFacilitySharing(
      userIdsByAccountId,
      adminUserIdsByAccountId
    );

    System.assertEquals(4, sharing.accountSharesToInsert.size());

    for (AccountShare sh : sharing.accountSharesToInsert) {
      System.assertEquals('Manual', sh.RowCause);
      if (sh.UserOrGroupId == testData.supplierUsers[0].Id) {
        System.assertEquals('Edit', sh.AccountAccessLevel);
      } else if (sh.UserOrGroupId == testData.supplierUsers[1].Id) {
        System.assertEquals('Read', sh.AccountAccessLevel);
      } else {
        System.assert(false);
      }

      System.assert(
        sh.AccountId == testData.facility.Id ||
        sh.AccountId == testData.facility2.Id
      );
    }
  }

  @IsTest
  static void test_createAccountShares_noneToCreate() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    Map<Id, List<Id>> userIdsByAccountId = new Map<Id, List<Id>>{
      testData.facility.Id => new List<Id>{
        testData.facilityUsers[0].Id,
        testData.facilityUsers[1].Id
      }
    };

    TC_SupplierFacilitySharing sharing = new TC_SupplierFacilitySharing(
      userIdsByAccountId,
      new Map<Id, List<Id>>()
    );

    System.assertEquals(0, sharing.accountSharesToInsert.size());
  }
}