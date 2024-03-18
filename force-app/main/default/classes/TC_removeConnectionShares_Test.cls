@isTest
public with sharing class TC_removeConnectionShares_Test {
  @IsTest
  static void test_getConnectionSharesToDelete() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    List<Brand_Supplier_Connection__c> connections = new List<Brand_Supplier_Connection__c>{
      TC_TestDataFactory_Connections.create(
        testData.brand,
        testData.supplier,
        testData.brandContacts[0],
        'Requested'
      )
    };

    insert connections;

    Brand_Supplier_Connection__Share share = new Brand_Supplier_Connection__Share(
      ParentId = connections[0].Id,
      AccessLevel = 'Edit',
      RowCause = 'Manual',
      UserOrGroupId = testData.facilityUsers[0].Id
    );

    insert share;

    TC_removeConnectionShares sharing = new TC_removeConnectionShares(
      new List<Id>{ testData.facilityUsers[0].Id }
    );

    System.assertEquals(1, sharing.connectionSharesToDelete.size());
  }

  @IsTest
  static void test_getConnectionSharesToDelete_noUsers() {
    TC_removeConnectionShares sharing = new TC_removeConnectionShares(
      new List<Id>()
    );

    System.assertEquals(0, sharing.connectionSharesToDelete.size());
  }

  @IsTest
  static void test_getConnectionSharesToDelete_noneToDelete() {
    TC_removeConnectionShares sharing = new TC_removeConnectionShares(
      new List<Id>{ UserInfo.getUserId() }
    );

    System.assertEquals(0, sharing.connectionSharesToDelete.size());
  }
}