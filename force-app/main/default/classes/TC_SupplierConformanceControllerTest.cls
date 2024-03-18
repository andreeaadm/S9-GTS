@isTest
public with sharing class TC_SupplierConformanceControllerTest {
  @TestSetup
  static void makeData() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    // insert a Pending inventory for each facility
    List<Inventory__c> allInventories = new List<Inventory__c>();
    allInventories.addAll(
      TC_TestDataFactory_Inventories.insertInventoriesForFacility(
        testData.facility.Id,
        1,
        Date.today(),
        'Delivery',
        3,
        3,
        null,
        null,
        null,
        null
      )
    );
    allInventories.addAll(
      TC_TestDataFactory_Inventories.insertInventoriesForFacility(
        testData.facility2.Id,
        1,
        Date.today(),
        'Delivery',
        3,
        3,
        null,
        null,
        null,
        null
      )
    );

    insert TC_TestDataFactory_Connections.create(
      testData.brand.Id,
      testdata.supplier.Id,
      testData.brandContacts[0].Id,
      'Approved'
    );
  }

  // Get conformance for current month by not providing a month as argument, with fully conformant line items
  @isTest
  private static void test_getSupplierConformanceByMonth_current() {
    User brandUser = [
      SELECT Id
      FROM User
      WHERE
        Profile.Name = 'Experience Cloud Site Admin - Member'
        AND Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND isActive = TRUE
      LIMIT 1
    ];
    Test.startTest();
    Map<String, Object> response;
    System.runAs(brandUser) {
      response = TC_SupplierConformanceController.getSupplierConformanceByMonth(
        null
      );
    }
    Test.stopTest();
    DataTable.Table table = (DataTable.Table) response.get('table');
    System.assertEquals(1, table.rows.size());
    System.assertEquals(
      Decimal.valueOf(100),
      Decimal.valueOf(table.rows[0].rowCells[2].value.substringBefore('%'))
    );
  }

  // Get conformance for previous month, which should have no results
  @isTest
  private static void test_getSupplierConformanceByMonth_previous() {
    User brandUser = [
      SELECT Id
      FROM User
      WHERE
        Profile.Name = 'Experience Cloud Site Admin - Member'
        AND Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND isActive = TRUE
      LIMIT 1
    ];
    String lastMonth =
      TC_SupplierConformanceController.getMonthString(
        Date.today().addMonths(-1).month(),
        false
      ) +
      ' ' +
      String.valueOf(Date.today().addMonths(-1).year());
    Test.startTest();
    Map<String, Object> response;
    System.runAs(brandUser) {
      response = TC_SupplierConformanceController.getSupplierConformanceByMonth(
        lastMonth
      );
    }
    Test.stopTest();
    DataTable.Table table = (DataTable.Table) response.get('table');
    System.assertEquals(0, table.rows.size());
  }
}