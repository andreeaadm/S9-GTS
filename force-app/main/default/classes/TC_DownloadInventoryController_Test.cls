@IsTest
public with sharing class TC_DownloadInventoryController_Test {
  static TC_TestDataFactory_SupplierFacilityBrand setup(Boolean withLineItems) {
    TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      accounts.facility.Id,
      3,
      Date.today(),
      'Delivery',
      withLineItems ? 2 : 0,
      0,
      'kg',
      2.5,
      5.0,
      3.0
    );

    insert new Brand_Supplier_Connection__c(
      Brand_Account__c = accounts.brand.Id,
      Supplier_Account__c = accounts.supplier.Id,
      Requestor_Contact__c = accounts.supplierUsers[0].ContactId,
      Status__c = 'Approved',
      Active__c = true
    );

    return accounts;
  }

  @isTest
  static void test_getDataForDownload_WInventories() {
    // need to start and stop test because sharing of inventories to suppliers occurs asynchronously
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup(true);
    List<Inventory__c> inventories = [SELECT Id FROM Inventory__c];

    test.startTest();
    TC_TriggeredSharing.processNewOrUpdatedAccounts(
      new List<Account>{ accounts.supplier }
    );
    test.stopTest();

    TC_DownloadInventoryWrapper resultAsFacilityUser;
    TC_DownloadInventoryWrapper resultAsSupplierUser;
    TC_DownloadInventoryWrapper resultAsBrandUser;
    System.runAs(accounts.facilityUsers[0]) {
      resultAsFacilityUser = TC_DownloadInventoryController.getDataForDownload(
        inventories[0].Id
      );
    }
    System.runAs(accounts.supplierUsers[0]) {
      resultAsSupplierUser = TC_DownloadInventoryController.getDataForDownload(
        inventories[0].Id
      );
    }
    System.runAs(accounts.brandUsers[0]) {
      resultAsBrandUser = TC_DownloadInventoryController.getDataForDownload(
        inventories[0].Id
      );
    }
    System.assertEquals(2, resultAsFacilityUser.lineItems.size());
    System.assertEquals(
      accounts.facility.Name,
      resultAsFacilityUser.facilityName
    );
    System.assertEquals(
      accounts.supplier.Name,
      resultAsFacilityUser.supplierName
    );

    System.assertEquals(2, resultAsSupplierUser.lineItems.size());
    System.assertEquals(
      accounts.facility.Name,
      resultAsSupplierUser.facilityName
    );
    System.assertEquals(
      accounts.supplier.Name,
      resultAsSupplierUser.supplierName
    );
  }

  @isTest
  static void test_getDataForDownload_noLineItems() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup(false);

    TC_DownloadInventoryWrapper resultAsSupplierUser;
    TC_DownloadInventoryWrapper resultAsBrandUser;
    System.runAs(accounts.supplierUsers[0]) {
      resultAsSupplierUser = TC_DownloadInventoryController.getDataForDownload(
        accounts.facility.Id
      );
    }
    System.runAs(accounts.brandUsers[0]) {
      resultAsBrandUser = TC_DownloadInventoryController.getDataForDownload(
        accounts.facility.Id
      );
    }

    System.assertEquals(0, resultAsSupplierUser.lineItems.size());
    System.assertEquals(null, resultAsSupplierUser.facilityName);
    System.assertEquals(null, resultAsSupplierUser.supplierName);
    System.assertEquals(null, resultAsSupplierUser.inventoryName);

    System.assertEquals(0, resultAsBrandUser.lineItems.size());
    System.assertEquals(null, resultAsBrandUser.facilityName);
    System.assertEquals(null, resultAsBrandUser.supplierName);
    System.assertEquals(null, resultAsBrandUser.inventoryName);
  }
}