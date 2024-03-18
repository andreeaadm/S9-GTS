@isTest
public with sharing class TC_removeTCAccountShares_Test {
  @IsTest
  static void test_getAccountSharesToDelete_noneToDelete() {
    TC_removeTCAccountShares sharing = new TC_removeTCAccountShares(
      new List<Id>{ UserInfo.getUserId() },
      true,
      true
    );

    System.assertEquals(0, sharing.accountSharesToDelete.size());
  }

  @IsTest
  static void test_getAccountSharesToDelete_nullArg() {
    TC_removeTCAccountShares sharing = new TC_removeTCAccountShares(
      null,
      true,
      true
    );

    System.assertEquals(null, sharing.accountSharesToDelete);
  }

  @IsTest
  static void test_getAccountSharesToDelete() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    List<AccountShare> shares = new List<AccountShare>{
      new AccountShare(
        AccountId = testData.facility.Id,
        UserOrGroupId = testData.brandUsers[1].Id,
        AccountAccessLevel = 'Read',
        RowCause = 'Manual',
        OpportunityAccessLevel = 'None'
      ),
      new AccountShare(
        AccountId = testData.facility2.Id,
        UserOrGroupId = testData.brandUsers[0].Id,
        AccountAccessLevel = 'Edit',
        RowCause = 'Manual',
        OpportunityAccessLevel = 'None'
      )
    };

    insert shares;

    TC_removeTCAccountShares sharing = new TC_removeTCAccountShares(
      new List<Id>{ testData.brandUsers[1].Id, testData.brandUsers[0].Id },
      true,
      true
    );

    System.assertEquals(2, sharing.accountSharesToDelete.size());
  }

  @IsTest
  static void test_getAccountSharesToDelete_onlyEdit() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    List<AccountShare> shares = new List<AccountShare>{
      new AccountShare(
        AccountId = testData.facility.Id,
        UserOrGroupId = testData.brandUsers[1].Id,
        AccountAccessLevel = 'Read',
        RowCause = 'Manual',
        OpportunityAccessLevel = 'None'
      ),
      new AccountShare(
        AccountId = testData.facility2.Id,
        UserOrGroupId = testData.brandUsers[0].Id,
        AccountAccessLevel = 'Edit',
        RowCause = 'Manual',
        OpportunityAccessLevel = 'None'
      )
    };

    insert shares;

    TC_removeTCAccountShares sharing = new TC_removeTCAccountShares(
      new List<Id>{ testData.brandUsers[1].Id, testData.brandUsers[0].Id },
      false,
      true
    );

    System.assertEquals(1, sharing.accountSharesToDelete.size());
  }
}