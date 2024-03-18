/******************************************************************************
Created Date: May 2022
@description: To test TC_DownloadInventoryWrapper class 
@author: Intertek
Modification History:
Ver			Date			Author			Modification
1.0     Nov 2023  Akshay      Updated soql query to add Inditex classification fields(TBS-59)
2.0  		Jan 2024	Yash			  Added Commodity Chemical & Type of Chemical Fields(TBS-61)

******************************************************************************/

@IsTest
public with sharing class TC_DownloadInventoryWrapper_Test {
    
  @isTest
  static void test_constructWLineItems() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      accounts.facility.Id,
      3,
      Date.today(),
      'Usage',
      2,
      0,
      'kg',
      2.5,
      5.0,
      3.0
    );

    List<Inventory_Line_Item__c> lineItems = [
      SELECT
        Name,
        Inventory__r.Inventory_Name__c,
        Inventory__r.Inventory_Date__c,
        Inventory__r.Type__c,
        Inventory__r.Facility__r.Parent.Name,
        Inventory__r.Facility__r.Name,
        Chemical_Product__r.Name,
        Chemical_Product_Name__c,
        Formulator_Name__c,
        Product_Trade_Name_Other_Name__c,
        Substrate__c,
        Other_Certifications__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_MRSL_Version__c,
        Conformant__c,
        ZDHC_Product_Id__c,
        ZDHC_Product_GUID__c,
        Unit__c,
        Stock_Take_Month_Begin__c,
        Delivered_Stock_This_Month__c,
        Stock_Take_Month_End__c,
        Calculated_Usage__c,
        Calculated_Weight_kg__c,
        Delivered_Stock_History__c,
        Storage_Location__c,
        Lot_Number__c,
        Expiry_Date__c,
        Chemical_Product__r.CAS_Number__c,
        Supplier_Reference_Number__c, 
        Supplier_Reference_Name__c, 
        Product_Name_Local_Language__c, 
        Formulator_Name_Local_Language__c,
        Inditex_Classification_for_Babies__c,
        Inditex_Classification_for_Child_Adult__c,
        Commodity_Chemical_Standard_Name__c,
        Type_of_Chemicals__c
      FROM Inventory_Line_Item__c
      WHERE Inventory__c = :inventories[0].Id
    ];

    TC_DownloadInventoryWrapper wrapper = new TC_DownloadInventoryWrapper(
      lineItems
    );

    System.assertEquals(2, wrapper.lineItems.size());
    System.assertEquals(accounts.supplier.Name, wrapper.supplierName);
    System.assertEquals(accounts.facility.Name, wrapper.facilityName);
    System.assertEquals('Usage', wrapper.lineItems[0].type);
    System.assertNotEquals(null, wrapper.lineItems[0].chemicalProduct);
    System.assertEquals('Level 2', wrapper.lineItems[0].zdhcMRSL);
    System.assertNotEquals(null, wrapper.lineItems[0].productGUID);
    System.assertEquals('kg', wrapper.lineItems[0].unit);
    System.assertEquals('2.50', wrapper.lineItems[0].stockTakeMonthBegin);
    System.assertEquals('5.00', wrapper.lineItems[0].stockTakeMonthEnd);
    System.assertEquals('3.00', wrapper.lineItems[0].deliveredStock);
    System.assertEquals('0.50', wrapper.lineItems[0].calculatedUsage);
    System.assertEquals('0.50', wrapper.lineItems[0].calculatedWeight);
  }

  @isTest
  static void test_constructWEmptyList() {
    TC_DownloadInventoryWrapper wrapper = new TC_DownloadInventoryWrapper(
      new List<Inventory_Line_Item__c>()
    );

    System.assertEquals(null, wrapper.facilityName);
    System.assertEquals(null, wrapper.inventoryName);
    System.assertEquals(null, wrapper.supplierName);
    System.assertEquals(0, wrapper.lineItems.size());
  }
}