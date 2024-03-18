@isTest
public with sharing class FacilityListControllerTest {
  @isTest
  static void test_getFacilitiesListTableData_noFacilities() {
    ListResponse tabledata = FacilityListController.getFacilitiesListTableData();

    System.assertEquals(0, tableData.totalRows);
    System.assertEquals(0, tableData.table.rows.size());
    System.assertEquals(10, tableData.table.columns.size());
  }

  @isTest
  static void test_getFacilitiesListTableData_someFacilities() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    test.startTest();
    TC_TriggeredSharing.processNewOrUpdatedAccounts(
      new List<Account>{ accounts.Supplier }
    );
    test.stopTest();

    System.runAs(accounts.supplierUsers[0]) {
      ListResponse tabledata = FacilityListController.getFacilitiesListTableData();

      System.assertEquals(2, tableData.totalRows);
      System.assertEquals(2, tableData.table.rows.size());
      System.assertEquals(10, tableData.table.columns.size());
    }
  }
}