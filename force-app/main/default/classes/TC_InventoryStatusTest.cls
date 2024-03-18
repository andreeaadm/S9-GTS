/**
 * Unit tests for the TC_InventoryStatus apex class.
 * @author Alan West (oe:gen)
 * @date January 2022
 */
@isTest
public with sharing class TC_InventoryStatusTest {
  @testSetup
  static void setup() {
    // 4 Supplers (1 inactive), first supplier to have 10 facilities, second 3 facilities, third 1 facility, 7 brands (3 inactive)
    TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
      4,
      1, // inactive
      new List<Integer>{ 10, 3, 1 },
      new List<Integer>{ 1, 1, 1 }, // inactive
      7,
      3 // inactive
    );
    TC_TestDataFactory_Contacts tdfc = new TC_TestDataFactory_Contacts(
      tdfa,
      'unittest@example.com',
      null,
      null,
      null,
      null,
      null,
      null
    );
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(tdfc, true);
    List<PermissionSetAssignment> allPSA = new List<PermissionSetAssignment>(
      tdfu.permissionSetAssignments
    );
    allPSA.addAll(tdfu.accessPermissionSetAssignments);
    TC_TestDataFactory_Users.insertPermissionSetAssignments(allPSA);
    TC_TestDataFactory_Formulators tdff = new TC_TestDataFactory_Formulators(
      tdfa.facilities
    );
    TC_TestDataFactory_Chemicals chemical = new TC_TestDataFactory_Chemicals(
      tdff,
      null
    );
    TC_TestDataFactory_Inventories inventory = new TC_TestDataFactory_Inventories(
      tdfa.facilities,
      new List<Integer>{ 3 },
      Date.today()
    );
  }

  @isTest
  static void getRecords_fields_month_recordLimit_offset() {
    TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts();
    // Query the users connected with the first Accounts created; 1 Supplier and associated Facilities, 1 Brand.
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(
      new Map<Id, Account>(tdfa.first).keySet()
    );

    ListResponse resultAsSupplierAdminForToday;
    ListResponse resultAsSupplierStdForToday;
    ListResponse resultAsFacilityAdminForToday;
    ListResponse resultAsFacilityStdForToday;
    ListResponse resultAsBrandAdminForToday;
    ListResponse resultAsBrandStdForToday;
    ListResponse resultAsSupplierAdminForLastMonth;
    ListResponse resultAsSupplierStdForLastMonth;
    ListResponse resultAsFacilityAdminForLastMonth;
    ListResponse resultAsFacilityStdForLastMonth;
    ListResponse resultAsBrandAdminForLastMonth;
    ListResponse resultAsBrandStdForLastMonth;

    Test.startTest();
    ListResponse resultAsTestUser = TC_InventoryStatus.getRecords(
      null,
      null,
      null
    );
    System.runAs(tdfu.supplierAdminUsers[0]) {
      resultAsSupplierAdminForToday = TC_InventoryStatus.getRecords(
        null,
        null,
        null
      );
      resultAsSupplierAdminForLastMonth = TC_InventoryStatus.getRecords(
        Date.today().addMonths(-1),
        null,
        null
      );
    }
    System.runAs(tdfu.supplierStdUsers[0]) {
      resultAsSupplierStdForToday = TC_InventoryStatus.getRecords(
        null,
        null,
        null
      );
      resultAsSupplierStdForLastMonth = TC_InventoryStatus.getRecords(
        Date.today().addMonths(-1),
        null,
        null
      );
    }
    System.runAs(tdfu.facilityAdminUsers[0]) {
      resultAsFacilityAdminForToday = TC_InventoryStatus.getRecords(
        null,
        null,
        null
      );
      resultAsFacilityAdminForLastMonth = TC_InventoryStatus.getRecords(
        Date.today().addMonths(-1),
        null,
        null
      );
    }
    System.runAs(tdfu.facilityStdUsers[0]) {
      resultAsFacilityStdForToday = TC_InventoryStatus.getRecords(
        null,
        null,
        null
      );
      resultAsFacilityStdForLastMonth = TC_InventoryStatus.getRecords(
        Date.today().addMonths(-1),
        null,
        null
      );
    }
    System.runAs(tdfu.brandAdminUsers[0]) {
      resultAsBrandAdminForToday = TC_InventoryStatus.getRecords(
        null,
        null,
        null
      );
      resultAsBrandAdminForLastMonth = TC_InventoryStatus.getRecords(
        Date.today().addMonths(-1),
        null,
        null
      );
    }
    System.runAs(tdfu.brandStdUsers[0]) {
      resultAsBrandStdForToday = TC_InventoryStatus.getRecords(
        null,
        null,
        null
      );
      resultAsBrandStdForLastMonth = TC_InventoryStatus.getRecords(
        Date.today().addMonths(-1),
        null,
        null
      );
    }
    Test.stopTest();

    System.assertEquals(
      10,
      resultAsSupplierAdminForToday.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      0,
      resultAsSupplierStdForToday.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      0,
      resultAsFacilityAdminForToday.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      1,
      resultAsFacilityStdForToday.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      0,
      resultAsBrandAdminForToday.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      0,
      resultAsBrandStdForToday.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      10,
      resultAsSupplierAdminForLastMonth.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      0,
      resultAsSupplierStdForLastMonth.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      0,
      resultAsFacilityAdminForLastMonth.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      1,
      resultAsFacilityStdForLastMonth.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      0,
      resultAsBrandAdminForLastMonth.totalRows,
      'Unexpected totalRows'
    );
    System.assertEquals(
      0,
      resultAsBrandStdForLastMonth.totalRows,
      'Unexpected totalRows'
    );
  }
}