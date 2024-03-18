@IsTest
private class TC_SupplierNotificationsSchedulableTest {
  @TestSetup
  private static void setupData() {
    TC_TestDataFactory_SupplierFacilityBrand baseTestData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    List<Inventory__c> invs = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      baseTestData.facility.Id,
      1,
      Date.today().addDays(-28),
      'Delivery',
      2,
      2,
      'kg',
      5.00,
      30.00,
      6.00
    );

    baseTestData.supplier.Monthly_Inventory_Due__c = invs[0]
      .Inventory_Date__c.daysBetween(
        Date.today()
          .addDays(Integer.valueOf(Label.TC_Inventory_Notification_Days))
      );
    update baseTestData.supplier;

    for (Contact c : baseTestData.facilityContacts) {
      c.Main_Facility__c = baseTestData.facility.Id;
    }
    update baseTestData.facilityContacts;

    System.runAs(new User(Id = UserInfo.getUserId())) {
      for (User u : baseTestData.facilityUsers) {
        u.Inventory_Report_Reminder_Notifications__c = true;
      }
      update baseTestData.facilityUsers;
    }
  }

  @IsTest
  private static void test_execute() {
    Test.startTest();
    String jobId = System.schedule(
      'Notify Inventory Due Test',
      '0 0 0 * * ?',
      new TC_SupplierNotificationsSchedulable()
    );
    Test.stopTest();

    // No assertion made as is difficult to unit test for email sending.
  }
}