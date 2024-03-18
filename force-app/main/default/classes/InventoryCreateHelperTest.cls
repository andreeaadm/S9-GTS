@isTest
public with sharing class InventoryCreateHelperTest {
  static Map<String, Id> setup(Integer deactivatedProducts) {
    TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      accounts.facility.Id,
      30,
      Date.today().addMonths(-1),
      'Delivery',
      2,
      deactivatedProducts,
      'kg',
      5.00,
      30.00,
      6.00
    );

    return new Map<String, Id>{
      'facility' => accounts.facility.Id,
      'supplier' => accounts.supplier.Id
    };
  }

  @isTest
  static void test_createInventory_happyPath() {
    Map<String, Id> idMap = setup(0);
    Id facId = idMap.get('facility');
    Date today = Date.today();

    Id invId = InventoryCreateHelper.createInventory(facId, 'Delivery', today);

    System.assertNotEquals(null, invId);

    List<Inventory__c> invList = [
      SELECT Facility__c, Type__c, Inventory_Date__c, Status__c
      FROM Inventory__c
      WHERE Id = :invId
    ];

    System.assertEquals(1, invList.size());
    System.assertEquals(facId, invList[0].Facility__c);
    System.assertEquals('Delivery', invList[0].Type__c);
    System.assertEquals(today, invList[0].Inventory_Date__c);
    System.assertEquals('Pending', invList[0].Status__c);
  }

  @isTest
  static void test_createInventory_duplicate() {
    Map<String, Id> idMap = setup(0);
    Id facId = idMap.get('facility');
    Date invDate = Date.today().addMonths(-1);

    Boolean threwException = false;

    try {
      Id invId = InventoryCreateHelper.createInventory(
        facId,
        'Delivery',
        invDate
      );
    } catch (InventoryCreateHelper.DuplicateInventoryException e) {
      threwException = true;
    }

    System.assert(threwException);

    List<Inventory__c> invList = [SELECT Id FROM Inventory__c];
    System.assertEquals(30, invList.size());
  }

  @isTest
  static void test_createInventory_invalidFacility() {
    Map<String, Id> idMap = setup(0);
    Id suppId = idMap.get('supplier');
    Date today = Date.today();

    Boolean threwException = false;

    try {
      Id invId = InventoryCreateHelper.createInventory(
        suppId,
        'Delivery',
        today
      );
    } catch (Exception e) {
      threwException = true;
    }

    System.assert(threwException);

    List<Inventory__c> invList = [SELECT Id FROM Inventory__c];
    System.assertEquals(30, invList.size());
  }

  @isTest
  static void test_cloneLineItems_happyPathUsage() {
    Map<String, Id> idMap = setup(0);
    Id facId = idMap.get('facility');
    Date today = Date.today();

    Inventory__c invToClone = [
      SELECT Inventory_Name__c
      FROM Inventory__c
      ORDER BY Inventory_Date__c DESC
      LIMIT 1
    ];

    List<Inventory__c> inventory = TC_TestDataFactory_Inventories.newInventories(
      1,
      today,
      facId,
      'Usage'
    );
    insert inventory;

    System.assert(
      InventoryCreateHelper.cloneLineItems(
        facId,
        'Usage',
        today,
        inventory[0].Id,
        invToClone.Inventory_Name__c
      )
    );

    List<Inventory_Line_Item__c> lineItems = [
      SELECT
        Unit__c,
        Stock_Take_Month_Begin__c,
        Chemical_Product__c,
        RecordTypeId
      FROM Inventory_Line_Item__c
      WHERE Inventory__c = :inventory[0].Id
    ];

    System.assertEquals(2, lineItems.size());

    Id usageTypeId = Schema.SObjectType.Inventory_Line_Item__c.getRecordTypeInfosByDeveloperName()
      .get('Usage_Inventory_Line_Item')
      .getRecordTypeId();

    for (Inventory_Line_Item__c ili : lineItems) {
      System.assertEquals(usageTypeId, ili.RecordTypeId);
      System.assertEquals('kg', ili.Unit__c);
      System.assertNotEquals(null, ili.Chemical_Product__c);
    }
  }

  @isTest
  static void test_cloneLineItems_happyPathDelivery() {
    Map<String, Id> idMap = setup(0);
    Id facId = idMap.get('facility');
    Date today = Date.today();

    Inventory__c invToClone = [
      SELECT Inventory_Name__c
      FROM Inventory__c
      ORDER BY Inventory_Date__c DESC
      LIMIT 1
    ];

    List<Inventory__c> inventory = TC_TestDataFactory_Inventories.newInventories(
      1,
      today,
      facId,
      'Delivery'
    );
    insert inventory;

    System.assert(
      InventoryCreateHelper.cloneLineItems(
        facId,
        'Delivery',
        today,
        inventory[0].Id,
        invToClone.Inventory_Name__c
      )
    );

    List<Inventory_Line_Item__c> lineItems = [
      SELECT
        Unit__c,
        Stock_Take_Month_Begin__c,
        Chemical_Product__c,
        RecordTypeId
      FROM Inventory_Line_Item__c
      WHERE Inventory__c = :inventory[0].Id
    ];

    System.assertEquals(2, lineItems.size());

    Id deliveryTypeId = Schema.SObjectType.Inventory_Line_Item__c.getRecordTypeInfosByDeveloperName()
      .get('Delivery_Inventory_Line_Item')
      .getRecordTypeId();

    for (Inventory_Line_Item__c ili : lineItems) {
      System.assertEquals(deliveryTypeId, ili.RecordTypeId);
      System.assertEquals('kg', ili.Unit__c);
      System.assertEquals(null, ili.Stock_Take_Month_Begin__c);
      System.assertNotEquals(null, ili.Chemical_Product__c);
    }
  }

  @isTest
  static void test_cloneLineItems_deactivatedProducts() {
    Map<String, Id> idMap = setup(2);
    Id facId = idMap.get('facility');
    Date today = Date.today();

    Inventory__c invToClone = [
      SELECT Inventory_Name__c
      FROM Inventory__c
      ORDER BY Inventory_Date__c DESC
      LIMIT 1
    ];

    List<Inventory__c> inventory = TC_TestDataFactory_Inventories.newInventories(
      1,
      today,
      facId,
      'Delivery'
    );
    insert inventory;

    System.assert(
      !InventoryCreateHelper.cloneLineItems(
        facId,
        'Delivery',
        today,
        inventory[0].Id,
        invToClone.Inventory_Name__c
      )
    );

    List<Inventory_Line_Item__c> lineItems = [
      SELECT
        Unit__c,
        Stock_Take_Month_Begin__c,
        Chemical_Product__c,
        RecordTypeId
      FROM Inventory_Line_Item__c
      WHERE Inventory__c = :inventory[0].Id
    ];

    System.assertEquals(2, lineItems.size());

    Id deliveryTypeId = Schema.SObjectType.Inventory_Line_Item__c.getRecordTypeInfosByDeveloperName()
      .get('Delivery_Inventory_Line_Item')
      .getRecordTypeId();

    for (Inventory_Line_Item__c ili : lineItems) {
      System.assertEquals(deliveryTypeId, ili.RecordTypeId);
      System.assertEquals('kg', ili.Unit__c);
      System.assertEquals(null, ili.Stock_Take_Month_Begin__c);
      System.assertNotEquals(null, ili.Chemical_Product__c);
    }
  }

  @isTest
  static void test_cloneLineItems_nothingToClone() {
    Map<String, Id> idMap = setup(0);
    Id facId = idMap.get('facility');
    Date invDate = Date.today();

    Inventory__c invToClone = [
      SELECT Inventory_Name__c
      FROM Inventory__c
      ORDER BY Inventory_Date__c DESC
      LIMIT 1
    ];
    String lastInvName = invToClone.Inventory_Name__c;
    delete invToClone;

    List<Inventory__c> inventory = TC_TestDataFactory_Inventories.newInventories(
      1,
      invDate,
      facId,
      'Delivery'
    );
    insert inventory;

    System.assert(
      InventoryCreateHelper.cloneLineItems(
        facId,
        'Delivery',
        invDate,
        inventory[0].Id,
        lastInvName
      )
    );

    List<Inventory_Line_Item__c> lineItems = [
      SELECT Unit__c, Stock_Take_Month_Begin__c, Chemical_Product__c
      FROM Inventory_Line_Item__c
      WHERE Inventory__c = :inventory[0].Id
    ];

    System.assertEquals(0, lineItems.size());
  }

  @isTest
  static void test_rollbackCreation() {
    setup(0);

    Inventory__c inv = [SELECT Id FROM Inventory__c LIMIT 1];

    InventoryCreateHelper.rollbackCreation(inv.Id);

    List<Inventory__c> inventoryList = [
      SELECT Id, (SELECT Id FROM Inventory_Line_Items__r)
      FROM Inventory__c
      WHERE Id = :inv.Id
    ];

    System.assertEquals(0, inventoryList.size());
  }
}