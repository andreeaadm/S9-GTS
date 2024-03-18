@isTest
public with sharing class InventoryListTableHelperTest {
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
  static void test_buildTable_incorrectFacility() {
    Map<String, Id> idMap = setup();

    ListResponse returnData = InventoryListTableHelper.buildTable(
      idMap.get('supplier')
    );

    System.assertEquals(0, returnData.totalRows);
    System.assertEquals(5, returnData.table.columns.size());
    System.assertEquals(0, returnData.Table.rows.size());
  }

  @isTest
  static void test_buildTable_correctFacility() {
    Map<String, Id> idMap = setup();

    ListResponse returnData = InventoryListTableHelper.buildTable(
      idMap.get('facility')
    );

    System.assertEquals(24, returnData.totalRows);
    System.assertEquals(5, returnData.table.columns.size());
    System.assertEquals(24, returnData.table.rows.size());
  }

  @IsTest
  static void test_getInventoriesByFacility_returns0() {
    Map<String, Id> idMap = setup();

    List<Inventory__c> returnData = InventoryListTableHelper.getInventoriesByFacility(
      idMap.get('supplier')
    );

    System.assertEquals(0, returnData.size());
  }

  @IsTest
  static void test_getInventoriesByFacility_returnsCorrect() {
    Map<String, Id> idMap = setup();

    List<Inventory__c> returnData = InventoryListTableHelper.getInventoriesByFacility(
      idMap.get('facility')
    );

    System.assertEquals(24, returnData.size());

    for (Inventory__c i : returnData) {
      System.assert(i.Inventory_Date__c <= Date.today().addMonths(-1));
    }
  }

  @IsTest
  static void test_getColumns_returnsColumns() {
    List<DataTable.Column> returnData = InventoryListTableHelper.getColumns();

    System.assertEquals(5, returnData.size());
    System.assertEquals(Label.TC_Inventory_Column, returnData[0].label);
    System.assertEquals(Label.TC_Date_Created_Column, returnData[1].label);
    System.assertEquals(Label.TC_Date_Completed, returnData[2].label);
    System.assertEquals(Label.TC_Date_Submitted_Column, returnData[3].label);
    System.assertEquals(Label.TC_Status_Column, returnData[4].label);
  }

  @IsTest
  static void test_getRows_returns0() {
    List<DataTable.Row> returnData = InventoryListTableHelper.getRows(
      new List<Inventory__c>()
    );

    System.assertEquals(0, returnData.size());
  }

  @IsTest
  static void test_getRows_returnsRows() {
    setup();

    List<Inventory__c> invList = [
      SELECT
        Inventory_Name__c,
        Inventory_Date__c,
        Completed_Date__c,
        Submitted_Date__c,
        Status__c
      FROM Inventory__c
    ];

    System.assertEquals(30, invList.size());

    List<DataTable.Row> returnData = InventoryListTableHelper.getRows(invList);

    System.assertEquals(30, returnData.size());
    System.assertEquals(invList[0].Id, returnData[0].rowId);
    System.assertEquals(
      invList[0].Inventory_Name__c,
      returnData[0].rowCells[0].value
    );
  }
}