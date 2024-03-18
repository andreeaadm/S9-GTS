@IsTest
public with sharing class TC_DeleteInventoryController_Test {
  static TC_TestDataFactory_SupplierFacilityBrand setup() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      accounts.facility.Id,
      1,
      Date.today().addMonths(-1),
      'Delivery',
      2,
      0,
      'kg',
      5.00,
      30.00,
      6.00
    );

    return accounts;
  }
  @IsTest
  static void test_deleteInventory_happyPath() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();
    List<Inventory__c> inventories = [SELECT Id FROM Inventory__c];

    Boolean wasSuccessful = TC_DeleteInventoryController.deleteInventory(
      inventories[0].Id
    );

    System.assert(wasSuccessful);

    List<Inventory__c> remainingInventories = [SELECT Id FROM Inventory__c];

    System.assertEquals(0, remainingInventories.size());
  }

  @IsTest
  static void test_deleteInventory_insufficientAccess() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();
    List<Inventory__c> inventories = [SELECT Id FROM Inventory__c];

    System.runAs(accounts.brandUsers[0]) {
      Boolean wasSuccessful = TC_DeleteInventoryController.deleteInventory(
        inventories[0].Id
      );
      System.assert(!wasSuccessful);
    }

    List<Inventory__c> remainingInventories = [SELECT Id FROM Inventory__c];

    System.assertEquals(1, remainingInventories.size());
    System.assertEquals(inventories[0].Id, remainingInventories[0].Id);
  }

  @IsTest
  static void test_deleteInventory_incorrectId() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();
    List<Inventory__c> inventories = [SELECT Id FROM Inventory__c];

    Boolean threwException = false;

    try {
      TC_DeleteInventoryController.deleteInventory(accounts.facility.Id);
    } catch (Exception e) {
      threwException = true;
    }

    System.assert(threwException);

    List<Inventory__c> remainingInventories = [SELECT Id FROM Inventory__c];

    System.assertEquals(1, remainingInventories.size());
    System.assertEquals(inventories[0].Id, remainingInventories[0].Id);
  }
}