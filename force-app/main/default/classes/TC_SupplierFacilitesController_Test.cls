@IsTest
public with sharing class TC_SupplierFacilitesController_Test {
  static TC_TestDataFactory_SupplierFacilityBrand setup() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
      accounts.brand,
      accounts.supplier,
      accounts.brandContacts[0],
      'Approved'
    );

    insert conn;

    return accounts;
  }

  @IsTest
  static void buildTable_happyPath() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();

    Id connectionId = [SELECT Id FROM Brand_Supplier_Connection__c LIMIT 1].Id;

    ListResponse returnVal = TC_SupplierFacilitiesController.buildTable(
      String.valueOf(connectionId)
    );

    System.assertEquals(2, returnVal.totalRows);
    System.assertEquals(8, returnVal.table.columns.size());
    System.assertEquals(2, returnVal.table.rows.size());
  }

  @IsTest
  static void buildTable_invalidConnectionId() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();

    Boolean threwException = false;

    try {
      ListResponse returnVal = TC_SupplierFacilitiesController.buildTable(null);
    } catch (AuraHandledException e) {
      threwException = true;
    }

    System.assert(threwException);
  }

  @IsTest
  static void getBrandSupplierConnection_happyPath() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();

    Id connectionId = [SELECT Id FROM Brand_Supplier_Connection__c LIMIT 1].Id;

    Brand_Supplier_Connection__c returnVal = TC_SupplierFacilitiesController.getBrandSupplierConnection(
      String.valueOf(connectionId)
    );

    System.assertNotEquals(null, returnVal);
    System.assertEquals(accounts.supplier.Id, returnVal.Supplier_Account__c);
  }

  @IsTest
  static void getBrandSupplierConnection_invalidConnection() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();

    Brand_Supplier_Connection__c connection = [
      SELECT Id
      FROM Brand_Supplier_Connection__c
      LIMIT 1
    ];
    connection.Status__c = 'Requested';
    update connection;

    Boolean threwException = false;

    try {
      Brand_Supplier_Connection__c returnVal = TC_SupplierFacilitiesController.getBrandSupplierConnection(
        String.valueOf(connection.Id)
      );
    } catch (QueryException e) {
      threwException = true;
    }

    System.assert(threwException);
  }

  @IsTest
  static void getFacilitiesForSupplier_happyPath() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();

    List<Account> returnVal = TC_SupplierFacilitiesController.getFacilitiesForSupplier(
      String.valueOf(accounts.supplier.Id)
    );

    System.assertEquals(2, returnVal.size());
    for (Account a : returnVal) {
      System.assert(
        a.Id == accounts.facility.Id ||
        a.Id == accounts.facility2.Id
      );
    }
  }

  @IsTest
  static void getFacilitiesForSupplier_invalidSupplier() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();

    List<Account> returnVal = TC_SupplierFacilitiesController.getFacilitiesForSupplier(
      String.valueOf(accounts.brand.Id)
    );

    System.assertEquals(0, returnVal.size());
  }

  @IsTest
  static void getColumns_returnsCorrect() {
    List<DataTable.Column> returnVal = TC_SupplierFacilitiesController.getColumns();

    System.assertEquals(8, returnVal.size());
    System.assertEquals(Label.TC_Facility_Name_Column, returnVal[0].label);
      System.assertEquals(Label.TC_HIGGID, returnVal[1].label);
      System.assertEquals(Label.TC_SupplierAID, returnVal[2].label);
    System.assertEquals(Label.TC_Street_Column, returnVal[3].label);
    System.assertEquals(Label.TC_CityTown_Column, returnVal[4].label);
    System.assertEquals(Label.TC_Country_Column, returnVal[5].label);
    System.assertEquals(Label.Postal_Code, returnVal[6].label);
    System.assertEquals(Label.TC_Facility_Manager_Column, returnVal[7].label);
  }

  @IsTest
  static void getRows_returnsCorrect() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();
    List<DataTable.Row> returnVal = TC_SupplierFacilitiesController.getRows(
      new List<Account>{ accounts.facility, accounts.facility2 }
    );

    System.assertEquals(2, returnVal.size());
    System.assertEquals(accounts.facility.Id, returnVal[0].rowId);
    System.assertEquals(accounts.facility2.Id, returnVal[1].rowId);
    System.assertEquals(accounts.facility.Name, returnVal[0].rowCells[0].value);
    System.assertNotEquals(null, returnVal[0].rowCells[0].navMixinPageRef);
    System.assertEquals(true, returnVal[0].rowCells[0].isAction);
    System.assertEquals(false, returnVal[0].rowCells[0].isButton);
    System.assertEquals(true, returnVal[0].rowCells[0].isLink);
    System.assertEquals(
      accounts.facility2.Name,
      returnVal[1].rowCells[0].value
    );
    System.assertNotEquals(null, returnVal[1].rowCells[0].navMixinPageRef);
    System.assertEquals(true, returnVal[1].rowCells[0].isAction);
    System.assertEquals(false, returnVal[1].rowCells[0].isButton);
    System.assertEquals(true, returnVal[1].rowCells[0].isLink);
  }
}