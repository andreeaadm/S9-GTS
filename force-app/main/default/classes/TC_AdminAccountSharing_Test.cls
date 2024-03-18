@IsTest
public with sharing class TC_AdminAccountSharing_Test {
  @IsTest
  static void test_createAccountShares() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      null
    );

    Map<Id, List<Id>> userIdsByAccountId = new Map<Id, List<Id>>{
      testData.supplier.Id => new List<Id>{
        testData.supplierUsers[0].Id,
        testData.supplierUsers[1].Id
      },
      testData.brand.Id => new List<Id>{
        testData.brandUsers[0].Id,
        testData.brandUsers[1].Id
      }
    };

    TC_AdminAccountSharing sharing = new TC_AdminAccountSharing(
      userIdsByAccountId
    );

    System.assertEquals(4, sharing.accountSharesToInsert.size());

    for (AccountShare sh : sharing.accountSharesToInsert) {
      System.assertEquals('Edit', sh.AccountAccessLevel);
      System.assertEquals('Manual', sh.RowCause);
      System.assert(
        (sh.AccountId == testData.supplier.Id &&
        (sh.UserOrGroupId == testData.supplierUsers[0].Id ||
        sh.UserOrGroupId == testData.supplierUsers[1].Id)) ||
        (sh.AccountId == testData.brand.Id &&
        (sh.UserOrGroupId == testData.brandUsers[0].Id ||
        sh.UserOrGroupId == testData.brandUsers[1].Id))
      );
    }
  }

  @IsTest
  static void test_createAccountShares_noneToCreate() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      null
    );

    TC_AdminAccountSharing sharing = new TC_AdminAccountSharing(
      new Map<Id, List<Id>>()
    );

    System.assertEquals(0, sharing.accountSharesToInsert.size());
  }
}