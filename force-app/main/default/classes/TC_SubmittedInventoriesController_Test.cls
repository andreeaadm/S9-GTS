@IsTest
public with sharing class TC_SubmittedInventoriesController_Test {
  @IsTest
  static void test_getPercentage() {
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
        0,
        0,
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
        0,
        0,
        null,
        null,
        null,
        null
      )
    );

    // connect the brand admin with the suppliers
    test.startTest();
    insert TC_TestDataFactory_Connections.create(
      testData.brand.Id,
      testdata.supplier.Id,
      testData.brandContacts[0].Id,
      'Approved'
    );
    test.stopTest();

    System.runAs(testData.brandUsers[0]) {
      String percentage = TC_SubmittedInventoriesController.getPercentageSubmittedInventories();

      // there are no Submitted inventories
      System.assertEquals('0', percentage);
    }

    // update status on first inventory
    allInventories[0].Status__c = 'Submitted';
    update allInventories;

    System.runAs(testData.brandUsers[0]) {
      String percentage = TC_SubmittedInventoriesController.getPercentageSubmittedInventories();

      // one inventory is Submitted
      System.assertEquals('50', percentage);
    }

    // update status on second inventory
    allInventories[1].Status__c = 'Submitted';
    update allInventories;

    System.runAs(testData.brandUsers[0]) {
      String percentage = TC_SubmittedInventoriesController.getPercentageSubmittedInventories();

      // all inventories are Submitted
      System.assertEquals('100', percentage);
    }
  }
}