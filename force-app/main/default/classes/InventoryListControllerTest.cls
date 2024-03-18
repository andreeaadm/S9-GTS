@isTest
public with sharing class InventoryListControllerTest {
  static Map<String, Id> setup() {
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
      2,
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
  static void test_getInventoriesListTableData_incorrectFacility() {
    Map<String, Id> idMap = setup();

    ListResponse returnData = InventoryListController.getInventoriesListTableData(
      idMap.get('supplier')
    );

    System.assertEquals(0, returnData.totalRows);
    System.assertEquals(5, returnData.table.columns.size());
    System.assertEquals(0, returnData.Table.rows.size());
  }

  @isTest
  static void test_getInventoriesListTableData_correctFacility() {
    Map<String, Id> idMap = setup();

    ListResponse returnData = InventoryListController.getInventoriesListTableData(
      idMap.get('facility')
    );

    System.assertEquals(24, returnData.totalRows);
    System.assertEquals(5, returnData.table.columns.size());
    System.assertEquals(24, returnData.table.rows.size());
  }

  @isTest
  static void test_createNewInventory_happyPath() {
    Map<String, Id> idMap = setup();
    Id facId = idMap.get('facility');
    Date today = Date.today();

    String returnVal = InventoryListController.createNewInventory(
      facId,
      'Delivery',
      today,
      Label.None
    );

    System.assertEquals('Success', returnVal);

    List<Inventory__c> inventoryList = [
      SELECT Facility__c, Type__c, Inventory_Date__c, Status__c
      FROM Inventory__c
      WHERE
        Facility__c = :facId
        AND Inventory_Date__c = :today
        AND Type__c = 'Delivery'
    ];

    System.assertEquals(1, inventoryList.size());

    for (
      Inventory_Line_Item__c ili : inventoryList[0].Inventory_Line_Items__r
    ) {
      System.assertEquals('kg', ili.Unit__c);
      System.assertEquals(null, ili.Stock_Take_Month_Begin__c);
    }
  }

  @isTest
  static void test_createNewInventory_invalidFacility() {
    Map<String, Id> idMap = setup();
    Id suppId = idMap.get('supplier');
    Date today = Date.today();

    Boolean threwException = false;

    try {
      InventoryListController.createNewInventory(
        suppId,
        'Delivery',
        today,
        null
      );
    } catch (Exception e) {
      threwException = true;
    }

    List<Inventory__c> inventoryList = [
      SELECT
        Facility__c,
        Type__c,
        Inventory_Date__c,
        Status__c,
        (SELECT Stock_Take_Month_Begin__c, Unit__c FROM Inventory_Line_Items__r)
      FROM Inventory__c
      WHERE
        Facility__c = :suppId
        AND Inventory_Date__c = :today
        AND Type__c = 'Delivery'
    ];

    System.assertEquals(0, inventoryList.size());
    System.assert(threwException);
  }

  @isTest
  static void test_createNewInventory_cloneDeactivatedProducts() {
    Map<String, Id> idMap = setup();
    Id facId = idMap.get('facility');
    Date today = Date.today();

    Inventory__c invToClone = [
      SELECT Inventory_Name__c
      FROM Inventory__c
      ORDER BY Inventory_Date__c DESC
      LIMIT 1
    ];

    String returnVal = InventoryListController.createNewInventory(
      facId,
      'Delivery',
      today,
      invToClone.Inventory_Name__c
    );

    System.assertEquals('MissingLineItems', returnVal);

    List<Inventory__c> inventoryList = [
      SELECT
        Facility__c,
        Type__c,
        Inventory_Date__c,
        Status__c,
        (SELECT Stock_Take_Month_Begin__c, Unit__c FROM Inventory_Line_Items__r)
      FROM Inventory__c
      WHERE
        Facility__c = :facId
        AND Inventory_Date__c = :today
        AND Type__c = 'Delivery'
    ];

    System.assertEquals(1, inventoryList.size());
    System.assertEquals(2, inventoryList[0].Inventory_Line_Items__r.size());
  }
}