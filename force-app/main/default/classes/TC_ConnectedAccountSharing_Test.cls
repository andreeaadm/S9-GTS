@IsTest
public with sharing class TC_ConnectedAccountSharing_Test {
  @IsTest
  static void test_createAccountShares() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    Map<Id, List<Id>> userIdsByAccountId = new Map<Id, List<Id>>{
      testData.brand.Id => new List<Id>{
        testData.brandUsers[0].Id,
        testData.brandUsers[1].Id
      },
      testData.supplier.Id => new List<Id>{
        testData.supplierUsers[0].Id,
        testData.supplierUsers[1].Id
      }
    };

    List<Brand_Supplier_Connection__c> connections = new List<Brand_Supplier_Connection__c>{
      TC_TestDataFactory_Connections.create(
        testData.brand,
        testData.supplier,
        testData.brandContacts[0],
        'Requested'
      ),
      TC_TestDataFactory_Connections.create(
        testData.brand,
        testData.supplier,
        testData.brandContacts[0],
        'Approved'
      )
    };

    insert connections;

    TC_ConnectedAccountSharing sharing = new TC_ConnectedAccountSharing(
      connections,
      userIdsByAccountId
    );

    System.assertEquals(8, sharing.accountSharesToInsert.size());

    for (AccountShare sh : sharing.accountSharesToInsert) {
      System.assertEquals('Read', sh.AccountAccessLevel);
      System.assertEquals('Manual', sh.RowCause);

      if (
        sh.AccountId == testData.facility.Id ||
        sh.AccountId == testData.facility2.Id
      ) {
        System.assert(
          sh.UserOrGroupId == testData.brandUsers[0].Id ||
          sh.UserOrGroupId == testData.brandUsers[1].Id
        );
      } else {
        System.assert(
          sh.AccountId == testData.brand.Id ||
          sh.AccountId == testData.supplier.Id
        );
        System.assert(
          sh.UserOrGroupId == testData.brandUsers[0].Id ||
          sh.UserOrGroupId == testData.brandUsers[1].Id ||
          sh.UserOrGroupId == testData.supplierUsers[0].Id ||
          sh.UserOrGroupId == testData.supplierUsers[1].Id
        );
      }
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

    List<Brand_Supplier_Connection__c> connections = new List<Brand_Supplier_Connection__c>{
      TC_TestDataFactory_Connections.create(
        testData.brand,
        testData.supplier,
        testData.brandContacts[0],
        'Requested'
      )
    };

    insert connections;

    TC_ConnectedAccountSharing sharing = new TC_ConnectedAccountSharing(
      connections,
      userIdsByAccountId
    );

    System.assertEquals(0, sharing.accountSharesToInsert.size());
  }
}