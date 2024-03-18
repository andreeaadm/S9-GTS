@IsTest
public with sharing class TC_ConnectionSharing_Test {
  @IsTest
  static void test_createConnectionShares() {
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

    Map<Id, List<Id>> facilityUserIdsByAccountId = new Map<Id, List<Id>>{
      testData.supplier.Id => new List<Id>{
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

    TC_ConnectionSharing sharing = new TC_ConnectionSharing(
      connections,
      userIdsByAccountId,
      facilityUserIdsByAccountId
    );

    System.assertEquals(4, sharing.connectionSharesToInsert.size());

    for (
      Brand_Supplier_Connection__Share sh : sharing.connectionSharesToInsert
    ) {
      System.assertEquals(connections[0].Id, sh.ParentId);
      System.assertEquals('Edit', sh.AccessLevel);
      System.assertEquals('Manual', sh.RowCause);
    }
  }

  @IsTest
  static void test_createConnectionShares_noneToCreate() {
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

    TC_ConnectionSharing sharing = new TC_ConnectionSharing(
      connections,
      userIdsByAccountId,
      userIdsByAccountId
    );

    System.assertEquals(0, sharing.connectionSharesToInsert.size());
  }
}