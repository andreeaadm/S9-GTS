/**
 * unit tests for the TC_InventoryLineItems apex class
 * @author Kevin Reader
 * @date January 2022
 */
@isTest
private class TC_InventoryLineItemsTest {
  @TestSetup
  private static void setupData() {
    TC_TestDataFactory_SupplierFacilityBrand baseTestData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    Account facility = [
      SELECT Id
      FROM Account
      WHERE
        Is_ToxClear_Account__c = TRUE
        AND ToxClear_Account_Type__c = 'Facility'
      LIMIT 1
    ];
    TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      facility.Id,
      1,
      Date.today(),
      'Delivery',
      5,
      0,
      'kg',
      0.0,
      0.0,
      50034
    );
    TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      facility.Id,
      1,
      Date.today(),
      'Usage',
      2,
      0,
      'kg',
      12345.1,
      2342.0,
      5034
    );
  }

  @isTest
  private static void getLineItemRecordsWithRecordsTest() {
    Inventory__c inv = [
      SELECT Id
      FROM Inventory__c
      WHERE Type__c = 'Delivery'
      LIMIT 1
    ];

    Test.startTest();
    List<Inventory_Line_Item__c> result = TC_InventoryLineItems.getLineItemRecords(
      inv.Id,
      50,
      0
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(5, result.size());
  }

  @isTest
  private static void getLineItemRecordsNoRecordsTest() {
    Inventory__c inv = new Inventory__c(
      Type__c = 'Usage',
      Facility__c = [
        SELECT Id
        FROM Account
        WHERE ToxClear_Account_Type__c = 'Facility'
        LIMIT 1
      ]
      .Id
    );
    Database.insert(inv);
    Test.startTest();
    List<Inventory_Line_Item__c> result = TC_InventoryLineItems.getLineItemRecords(
      inv.Id,
      50,
      0
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assert(result.isEmpty());
  }

  @isTest
  private static void getLineItemRecordsNoOffsetTest() {
    Inventory__c inv = [
      SELECT Id
      FROM Inventory__c
      WHERE Type__c = 'Delivery'
      LIMIT 1
    ];

    Test.startTest();
    List<Inventory_Line_Item__c> result = TC_InventoryLineItems.getLineItemRecords(
      inv.Id,
      50,
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(5, result.size());
  }

  @isTest
  private static void buildColumnsUsageTest() {
    Test.startTest();
    List<DataTable.Column> result = TC_InventoryLineItems.buildColumns('Usage');
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(12, result.size());
    System.assertEquals(Label.Name, result[0].label);
    System.assertEquals('Name', result[0].id);
    System.assertEquals(Label.TC_Origin, result[1].label);
    System.assertEquals('Origin__c', result[1].id);
    System.assertEquals(Label.TC_Chemical_Product, result[2].label);
    System.assertEquals('Chemical_Product', result[2].id);
    System.assertEquals(Label.TC_Conformant, result[3].label);
    System.assertEquals('Conformant__c', result[3].id);
    System.assertEquals(Label.TC_Unit, result[4].label);
    System.assertEquals('Unit__c', result[4].id);
    System.assertEquals(Label.TC_Stock_Take_Month_Begin, result[5].label);
    System.assertEquals('Stock_Take_Month_Begin__c', result[5].id);
    System.assertEquals(Label.TC_Delivered_Stock_This_Month, result[6].label);
    System.assertEquals('Delivered_Stock_This_Month__c', result[6].id);
    System.assertEquals(Label.TC_Stock_Take_Month_End, result[7].label);
    System.assertEquals('Stock_Take_Month_End__c', result[7].id);
    System.assertEquals(Label.TC_Calculated_Usage, result[8].label);
    System.assertEquals('Calculated_Usage__c', result[8].id);
    System.assertEquals(Label.TC_Storage_Location, result[9].label);
    System.assertEquals('Storage_Location__c', result[9].id);
    System.assertEquals(Label.TC_Lot_Number, result[10].label);
    System.assertEquals('Lot_Number__c', result[10].id);
    System.assertEquals(Label.TC_Expiry_Date, result[11].label);
    System.assertEquals('Expiry_Date__c', result[11].id);
  }

  @isTest
  private static void buildColumnsDeliveryTest() {
    Test.startTest();
    List<DataTable.Column> result = TC_InventoryLineItems.buildColumns(
      'Delivery'
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(9, result.size());

    System.assertEquals(Label.Name, result[0].label);
    System.assertEquals('Name', result[0].id);
    System.assertEquals(Label.TC_Origin, result[1].label);
    System.assertEquals('Origin__c', result[1].id);
    System.assertEquals(Label.TC_Chemical_Product, result[2].label);
    System.assertEquals('Chemical_Product', result[2].id);
    System.assertEquals(Label.TC_Conformant, result[3].label);
    System.assertEquals('Conformant__c', result[3].id);
    System.assertEquals(Label.TC_Unit, result[4].label);
    System.assertEquals('Unit__c', result[4].id);
    System.assertEquals(Label.TC_Delivered_Stock_This_Month, result[5].label);
    System.assertEquals('Delivered_Stock_This_Month__c', result[5].id);
    System.assertEquals(Label.TC_Storage_Location, result[6].label);
    System.assertEquals('Storage_Location__c', result[6].id);
    System.assertEquals(Label.TC_Lot_Number, result[7].label);
    System.assertEquals('Lot_Number__c', result[7].id);
    System.assertEquals(Label.TC_Expiry_Date, result[8].label);
    System.assertEquals('Expiry_Date__c', result[8].id);
  }

  @isTest
  private static void buildColumnsNoTypeProvidedTest() {
    Test.startTest();
    try {
      List<DataTable.Column> result = TC_InventoryLineItems.buildColumns(null);
    } catch (System.Exception ex) {
      System.assertEquals('System.NullPointerException', ex.getTypeName());
    }
    Test.stopTest();
  }

  @isTest
  private static void getChemicalDetailsTest() {
    Inventory__c inv = [
      SELECT Id
      FROM Inventory__c
      WHERE Type__c = 'Usage'
      LIMIT 1
    ];
    List<Inventory_Line_Item__c> lineItems = TC_InventoryLineItems.getLineItemRecords(
      inv.Id,
      50,
      0
    );
    Test.startTest();
    String result = TC_InventoryLineItems.getChemicalDetails(lineItems[0]);
    Test.stopTest();

    System.assertNotEquals(null, result);

    String chemicalDetails = String.join(
      new List<String>{
        lineItems[0].Chemical_Product_Name__c,
        lineItems[0].Formulator_Name__c,
        lineItems[0].Product_Trade_Name_Other_Name__c,
        lineItems[0].Substrate__c,
        lineItems[0].ZDHC_MRSL_v2_0__c,
        lineItems[0].ZDHC_Product_Id__c,
        lineItems[0].ZDHC_Product_GUID__c
      },
      ' '
    );

    System.assertEquals(chemicalDetails, result);
  }

  @isTest
  private static void buildRowsUsageTest() {
    Inventory__c inv = [
      SELECT Id
      FROM Inventory__c
      WHERE Type__c = 'Usage'
      LIMIT 1
    ];
    List<Inventory_Line_Item__c> lineItems = TC_InventoryLineItems.getLineItemRecords(
      inv.Id,
      50,
      0
    );
    Test.startTest();
    List<DataTable.Row> result = TC_InventoryLineItems.buildRows(
      lineItems,
      'Usage'
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(lineItems.size(), result.size());

    for (Integer i = 0; i < lineItems.size(); i++) {
      Inventory_Line_Item__c lineItem = lineItems[i];
      DataTable.Row row = result[i];
      String convertedConformant = lineItem.Conformant__c ? 'Yes' : 'No';
      System.assertEquals(lineItem.Name, row.rowCells[0].value);
      System.assertEquals(lineItem.Origin__c, row.rowCells[1].value);
      System.assertEquals(
        TC_InventoryLineItems.getChemicalDetails(lineItem),
        row.rowCells[2].value
      );
      System.assertEquals(convertedConformant, row.rowCells[3].value);
      System.assertEquals(lineItem.Unit__c, row.rowCells[4].value);
      System.assertEquals(
        String.valueOf(lineItem.Stock_Take_Month_Begin__c),
        row.rowCells[5].value
      );
      System.assertEquals(
        String.valueOf(lineItem.Delivered_Stock_This_Month__c),
        row.rowCells[6].value
      );
      System.assertEquals(
        String.valueOf(lineItem.Stock_Take_Month_End__c),
        row.rowCells[7].value
      );
      System.assertEquals(
        String.valueOf(lineItem.Calculated_Usage__c),
        row.rowCells[8].value
      );
      System.assertEquals(lineItem.Storage_Location__c, row.rowCells[9].value);
      System.assertEquals(lineItem.Lot_Number__c, row.rowCells[10].value);
      System.assertEquals(
        lineItem.Expiry_Date__c == null
          ? ''
          : String.valueOf(lineItem.Expiry_Date__c),
        row.rowCells[11].value
      );
    }
  }

  @isTest
  private static void buildRowsDeliveryTest() {
    Inventory__c inv = [
      SELECT Id
      FROM Inventory__c
      WHERE Type__c = 'Delivery'
      LIMIT 1
    ];
    List<Inventory_Line_Item__c> lineItems = TC_InventoryLineItems.getLineItemRecords(
      inv.Id,
      50,
      0
    );
    Test.startTest();
    List<DataTable.Row> result = TC_InventoryLineItems.buildRows(
      lineItems,
      'Delivery'
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(lineItems.size(), result.size());

    for (Integer i = 0; i < lineItems.size(); i++) {
      Inventory_Line_Item__c lineItem = lineItems[i];
      DataTable.Row row = result[i];
      String convertedConformant = lineItem.Conformant__c ? 'Yes' : 'No';
      System.assertEquals(lineItem.Name, row.rowCells[0].value);
      System.assertEquals(lineItem.Origin__c, row.rowCells[1].value);
      System.assertEquals(
        TC_InventoryLineItems.getChemicalDetails(lineItem),
        row.rowCells[2].value
      );
      System.assertEquals(convertedConformant, row.rowCells[3].value);
      System.assertEquals(lineItem.Unit__c, row.rowCells[4].value);
      System.assertEquals(
        String.valueOf(lineItem.Delivered_Stock_This_Month__c),
        row.rowCells[5].value
      );
      System.assertEquals(lineItem.Storage_Location__c, row.rowCells[6].value);
      System.assertEquals(lineItem.Lot_Number__c, row.rowCells[7].value);
      System.assertEquals(
        lineItem.Expiry_Date__c == null
          ? ''
          : String.valueOf(lineItem.Expiry_Date__c),
        row.rowCells[8].value
      );
    }
  }

  @isTest
  private static void buildRowsNoTypeProvidedTest() {
    Inventory__c inv = [
      SELECT Id
      FROM Inventory__c
      WHERE Type__c = 'Delivery'
      LIMIT 1
    ];
    List<Inventory_Line_Item__c> lineItems = TC_InventoryLineItems.getLineItemRecords(
      inv.Id,
      50,
      0
    );
    Test.startTest();
    try {
      List<DataTable.Row> result = TC_InventoryLineItems.buildRows(
        lineItems,
        null
      );
    } catch (System.Exception ex) {
      System.assertEquals('System.NullPointerException', ex.getTypeName());
    }
    Test.stopTest();
  }

  @isTest
  private static void buildResponseTest() {
    Inventory__c inv = [
      SELECT Id
      FROM Inventory__c
      WHERE Type__c = 'Delivery'
      LIMIT 1
    ];
    List<Inventory_Line_Item__c> lineItems = TC_InventoryLineItems.getLineItemRecords(
      inv.Id,
      50,
      0
    );
    Test.startTest();
    ListResponse result = TC_InventoryLineItems.buildResponse(
      lineItems,
      'Delivery'
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertNotEquals(null, result.table);
    System.assertEquals(lineItems.size(), result.totalRows);
    System.assert(!result.table.columns.isEmpty()); //more detailed assertions in above tests
    System.assert(!result.table.rows.isEmpty()); //more detailed assertions in above tests
  }

  @isTest
  private static void getLineItemsForInventoryWithRecordsTest() {
    Inventory__c inv = [
      SELECT Id
      FROM Inventory__c
      WHERE Type__c = 'Delivery'
      LIMIT 1
    ];
    List<Inventory_Line_Item__c> lineItems = [
      SELECT Id
      FROM Inventory_Line_item__c
      WHERE Inventory__c = :inv.Id
    ];
    Test.startTest();
    ListResponse result = TC_InventoryLineItems.getLineItemsForInventory(
      inv.Id,
      50,
      0,
      'Delivery'
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertNotEquals(null, result.table);
    System.assertEquals(lineItems.size(), result.totalRows);
    System.assert(!result.table.columns.isEmpty()); //more detailed assertions in above tests
    System.assert(!result.table.rows.isEmpty()); //more detailed assertions in above tests
  }

  @isTest
  private static void getLineItemsForInventoryWithoutRecordsTest() {
    Inventory__c inv = new Inventory__c(
      Type__c = 'Usage',
      Facility__c = [
        SELECT Id
        FROM Account
        WHERE ToxClear_Account_Type__c = 'Facility'
        LIMIT 1
      ]
      .Id
    );
    Database.insert(inv);
    Test.startTest();
    ListResponse result = TC_InventoryLineItems.getLineItemsForInventory(
      inv.Id,
      50,
      0,
      'Usage'
    );
    Test.stopTest();

    System.assertEquals(null, result);
  }

  @isTest
  private static void getLineItemForProduct_WithRecordsTest() {
    Inventory__c inv = [
      SELECT Id
      FROM Inventory__c
      WHERE Type__c = 'Delivery'
      LIMIT 1
    ];
    List<Inventory_Line_Item__c> check = [
      SELECT Chemical_Product__c
      FROM Inventory_Line_Item__c
      WHERE Inventory__c = :inv.Id
    ];
    Id productId = check[0].Chemical_Product__c;

    Test.startTest();
    List<Inventory_Line_Item__c> result = TC_InventoryLineItems.getLineItemForProduct(
      inv.Id,
      productId
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(1, result.size());
    System.assertEquals(result[0].Chemical_Product__c, productId);
  }

  @isTest
  private static void getLineItemForProduct_NoRecordsTest() {
    Inventory__c inv = new Inventory__c(
      Type__c = 'Usage',
      Facility__c = [
        SELECT Id
        FROM Account
        WHERE ToxClear_Account_Type__c = 'Facility'
        LIMIT 1
      ]
      .Id
    );
    Database.insert(inv);

    Id productId = [SELECT Id FROM Chemical_Product__c LIMIT 1].Id;
    Test.startTest();
    List<Inventory_Line_Item__c> result = TC_InventoryLineItems.getLineItemForProduct(
      inv.Id,
      productId
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assert(result.isEmpty());
  }

  @isTest
  private static void getLineItemProductGUIDs_WithRecordsTest() {
    Inventory__c inv = [
      SELECT Id
      FROM Inventory__c
      WHERE Type__c = 'Delivery'
      LIMIT 1
    ];
    List<Inventory_Line_Item__c> check = [
      SELECT ZDHC_Product_GUID__c
      FROM Inventory_Line_Item__c
      WHERE Inventory__c = :inv.Id
    ];

    Test.startTest();
    List<String> result = TC_InventoryLineItems.getLineItemProductGUIDs(inv.Id);
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(check.size(), result.size());
  }

  @isTest
  private static void getLineItemProductGUIDs_NoRecordsTest() {
    Inventory__c inv = new Inventory__c(
      Type__c = 'Usage',
      Facility__c = [
        SELECT Id
        FROM Account
        WHERE ToxClear_Account_Type__c = 'Facility'
        LIMIT 1
      ]
      .Id
    );
    Database.insert(inv);

    Test.startTest();
    List<String> result = TC_InventoryLineItems.getLineItemProductGUIDs(inv.Id);
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assert(result.isEmpty());
  }
}