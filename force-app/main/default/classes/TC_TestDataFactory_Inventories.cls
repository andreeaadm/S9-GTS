/*
 * Test data factory for Inventory__c and Inventory_Line_Item__c objects
 */
@IsTest
public with sharing class TC_TestDataFactory_Inventories {
  /*
   * Inserts a complete set of inventories with line items linked to chemical products for the specified facility
   * Each inventory has identical line items, the number of line items = activeProds + inactiveProds
   * Each inserted chemical product is related to the same formulator
   *
   * @param facilityId
   * @param inventoryCount
   * @param latestDate - monthly inventories will be created with the latest one having Inventory_Date__c = latestDate
   * @param invType - either Delivery or Usage
   * @param activeProds - active chemical products to insert
   * @param inactiveProds - inactive chemical products to insert
   * @param lineItemUnit - Unit__c for all line items
   * @param lineItemMonthBegin - Stock_Take_Month_Begin__c for all line items
   * @param lineItemMonthEnd - Stock_Take_Month_End__c for all line items
   *
   * @return the inserted inventories
   */
  public static List<Inventory__c> insertInventoriesForFacility(
    Id facilityId,
    Integer inventoryCount,
    Date latestDate,
    String invType,
    Integer activeProds,
    Integer inactiveProds,
    String lineItemUnit,
    Decimal lineItemMonthBegin,
    Decimal lineItemMonthEnd,
    Decimal lineItemDelivered
  ) {
    List<Chemical_Product__c> productList = TC_TestDataFactory_Chemicals.createInsertedWithFormulators(
      facilityId,
      1,
      activeProds,
      inactiveProds,
      0
    );

    return insertInventoriesForFacility(
      facilityId,
      inventoryCount,
      latestDate,
      invType,
      productList,
      lineItemUnit,
      lineItemMonthBegin,
      lineItemMonthEnd,
      lineItemDelivered
    );
  }

  /*
   * Inserts a complete set of inventories with line items linked to chemical products for the specified facility
   * Each inventory has identical line items, one for each chemical product
   *
   * @param facilityId
   * @param inventoryCount
   * @param latestDate - monthly inventories will be created with the latest one having Inventory_Date__c = latestDate
   * @param invType - either Delivery or Usage
   * @param chemProds - chemical product records to use
   * @param lineItemUnit - Unit__c for all line items
   * @param lineItemMonthBegin - Stock_Take_Month_Begin__c for all line items
   * @param lineItemMonthEnd - Stock_Take_Month_End__c for all line items
   *
   * @return the inserted inventories
   */
  public static List<Inventory__c> insertInventoriesForFacility(
    Id facilityId,
    Integer inventoryCount,
    Date latestDate,
    String invType,
    List<Chemical_Product__c> chemProds,
    String lineItemUnit,
    Decimal lineItemMonthBegin,
    Decimal lineItemMonthEnd,
    Decimal lineItemDelivered
  ) {
    List<Inventory__c> inventoryList = newInventories(
      inventoryCount,
      latestDate,
      facilityId,
      invType
    );
    insert inventoryList;

    List<Inventory_Line_Item__c> totalLineItems = new List<Inventory_Line_Item__c>();
    for (Inventory__c inv : inventoryList) {
      List<Inventory_Line_Item__c> lineItemList = newLineItems(
        inv.Id,
        invType,  
        lineItemUnit,
        lineItemMonthBegin,
        lineItemMonthEnd,
        lineItemDelivered,
        chemProds
      );

      totalLineItems.addAll(lineItemList);
    }
    insert totalLineItems;

    return inventoryList;
  }

  /*
   * Returns line items for the specified inventory with the specified field values, one for each Chemical_Product__c
   */
  public static List<Inventory_Line_Item__c> newLineItems(
    Id inventoryId,
    String invType, 
    String unit,
    Decimal monthBegin,
    Decimal monthEnd,
    Decimal delivered,
    List<Chemical_Product__c> products
  ) {
    Id deliveryTypeId = Schema.SObjectType.Inventory_Line_Item__c.getRecordTypeInfosByDeveloperName()
      .get('Delivery_Inventory_Line_Item')
      .getRecordTypeId();
    Id usageTypeId = Schema.SObjectType.Inventory_Line_Item__c.getRecordTypeInfosByDeveloperName()
      .get('Usage_Inventory_Line_Item')
      .getRecordTypeId();

    List<Inventory_Line_Item__c> toReturn = new List<Inventory_Line_Item__c>();

    for (Chemical_Product__c ch : products) {
      Inventory_Line_Item__c ili = new Inventory_Line_Item__c();
      ili.Inventory__c = inventoryId;
      ili.Chemical_Product__c = ch.Id;
      ili.ZDHC_MRSL_v2_0__c = ch.ZDHC_MRSL_v2_0__c;
      ili.ZDHC_Product_Id__c = ch.ZDHC_Product_Id__c;
      ili.ZDHC_Product_GUID__c = ch.ZDHC_Product_GUID__c;
      ili.Unit__c = unit;
      ili.Stock_Take_Month_Begin__c = invType == 'Usage' ? monthBegin : null;
      ili.Stock_Take_Month_End__c = invType == 'Usage' ? monthEnd : null;
      ili.Delivered_Stock_This_Month__c = delivered;
      ili.RecordTypeId = invType == 'Usage' ? usageTypeId : deliveryTypeId;
      ili.Inditex_Classification_for_Babies__c = 'A';
      ili.Inditex_Classification_for_Child_Adult__c = 'A';

      toReturn.add(ili);
    }
    return toReturn;
  }

  /*
   * Returns a list of monthly inventories of a specified type with the latest one specified by latestDate
   */
  public static List<Inventory__c> newInventories(
    Integer count,
    Date latestDate,
    Id facilityId,
    String type
  ) {
    List<Inventory__c> toReturn = new List<Inventory__c>();

    for (Integer i = 0; i < count; i++) {
      Inventory__c inv = new Inventory__c();
      inv.Inventory_Date__c = latestDate.addMonths(-1 * i);
      inv.Facility__c = facilityId;
      inv.Type__c = type;

      toReturn.add(inv);
    }
    return toReturn;
  }

  public List<Inventory__c> records = new List<Inventory__c>();
  public List<Inventory_Line_Item__c> lineItems = new List<Inventory_Line_Item__c>();

  public TC_TestDataFactory_Inventories() {
    records = [
      SELECT
        Completed_Date__c,
        CreatedById,
        CreatedDate,
        CurrencyIsoCode,
        Facility__c,
        Id,
        InCheck_Report_Error_Message__c,
        InCheck_Report_Status__c,
        InCheck_Report_Verification_Id__c,
        Inventory_Date__c,
        Inventory_Name__c,
        IsDeleted,
        LastActivityDate,
        LastModifiedById,
        LastModifiedDate,
        LastReferencedDate,
        LastViewedDate,
        Name,
        Status__c,
        Submitted_Date__c,
        SystemModstamp,
        Type__c
      FROM Inventory__c
      ORDER BY Id ASC
      LIMIT 200
    ];
    lineItems = [
      SELECT
        Calculated_Usage__c,
        Calculated_Weight_kg__c,
        Chemical_Product_Name__c,
        Chemical_Product__c,
        Conformant__c,
        CreatedById,
        CreatedDate,
        CurrencyIsoCode,
        Delivered_Stock_History__c,
        Delivered_Stock_This_Month__c,
        Expiry_Date__c,
        Formulator_Name__c,
        Id,
        Inventory__c,
        IsDeleted,
        LastActivityDate,
        LastModifiedById,
        LastModifiedDate,
        Lot_Number__c,
        Name,
        Origin__c,
        Other_Certifications__c,
        Product_Trade_Name_Other_Name__c,
        RecordTypeId,
        Stock_Take_Month_Begin__c,
        Stock_Take_Month_End__c,
        Stock_for_Calculated_Weight__c,
        Storage_Location__c,
        Substrate__c,
        SystemModstamp,
        Unit__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_Product_GUID__c,
        ZDHC_Product_Id__c
      FROM Inventory_Line_Item__c
      ORDER BY Id ASC
      LIMIT 1000
    ];
  }

  public TC_TestDataFactory_Inventories(
    List<Account> facilities,
    List<Integer> count,
    Date latestDate
  ) {
    List<String> unit = new List<String>{ 'kg', 'lb', 'Metric Ton' };
    List<Decimal> monthBegin = new List<Decimal>{
      100.0,
      50.0,
      25.0,
      200.0,
      1000.0
    };
    List<Decimal> monthEnd = new List<Decimal>{
      77.7,
      45.89,
      23.67,
      3.55,
      4.999,
      109.5778,
      512.54
    };
    List<Decimal> delivered = new List<Decimal>{ 23.7, 34.8, 89.8, 101.9, 5.5 };
    List<List<String>> mrsl = new List<List<String>>{
      new List<String>{
        'Registered',
        'Level 0',
        'Level 1',
        'Level 2',
        'Level 3'
      },
      new List<String>{ 'Registered', 'Level 0' }, // none will be conformant
      new List<String>{ 'Level 1', 'Level 2', 'Level 3' },
      new List<String>{ 'Level 0', 'Level 1', 'Level 2' },
      new List<String>{ 'Level 0' }
    };
    TC_TestDataFactory_Chemicals chemical = new TC_TestDataFactory_Chemicals();

    List<String> type = new List<String>{ 'Usage', 'Delivery' };
    for (Integer i = 0; i < facilities.size() && i < count.size(); i++) {
      List<Inventory__c> inv = newInventories(
        count[Math.mod(i, count.size())],
        latestDate,
        facilities[i].Id,
        type[Math.mod(i, type.size())]
      );
      records.addAll(inv);
    }
    insert records;
    for (Integer i = 0; i < records.size(); i++) {
      lineItems.addAll(
        newLineItems(
          records[i].Id,
          records[i].Type__c,
          unit[Math.mod(i, unit.size())],
          monthBegin[Math.mod(i, monthBegin.size())],
          monthEnd[Math.mod(i, monthEnd.size())],
          delivered[Math.mod(i, delivered.size())],
          chemical.productUpdates(
            records[i].Facility__c,
            mrsl[Math.mod(i, mrsl.size())]
          )
        )
      );
    }
    insert lineItems;
  }

  /**
   * TC_TestDataFactory_Inventories Old constructor kept for existing unit tests.
   */
  public TC_TestDataFactory_Inventories(
    List<Account> facilities,
    List<Integer> count,
    Date latestDate,
    TC_TestDataFactory_Formulators chemical
  ) {
    List<String> type = new List<String>{ 'Usage', 'Delivery' };
    for (Integer i = 0; i < facilities.size() && i < count.size(); i++) {
      records.addAll(
        newInventories(
          count[Math.mod(i, count.size())],
          latestDate,
          facilities[i].Id,
          type[Math.mod(i, type.size())]
        )
      );
    }
    insert records;

    List<String> unit = new List<String>{ 'kg', 'lb', 'Metric Ton' };
    List<Decimal> monthBegin = new List<Decimal>{
      100.0,
      50.0,
      25.0,
      200.0,
      1000.0
    };
    List<Decimal> monthEnd = new List<Decimal>{
      77.7,
      45.89,
      23.67,
      3.55,
      4.999,
      109.5778,
      512.54
    };
    List<Decimal> delivered = new List<Decimal>{ 23.7, 34.8, 89.8, 101.9, 5.5 };
    List<List<String>> mrsl = new List<List<String>>{
      new List<String>{
        'Registered',
        'Level 0',
        'Level 1',
        'Level 2',
        'Level 3'
      },
      new List<String>{ 'Registered', 'Level 0' }, // none will be conformant
      new List<String>{ 'Level 1', 'Level 2', 'Level 3' },
      new List<String>{ 'Level 0', 'Level 1', 'Level 2' },
      new List<String>{ 'Level 0' }
    };

    for (Integer i = 0; i < records.size(); i++) {
      if (lineItems.size() < 7500) {
        lineItems.addAll(
          newLineItems(
            records[i].Id,
            records[i].Type__c,
            unit[Math.mod(i, unit.size())],
            monthBegin[Math.mod(i, monthBegin.size())],
            monthEnd[Math.mod(i, monthEnd.size())],
            delivered[Math.mod(i, delivered.size())],
            chemical.productUpdates(
              records[i].Facility__c,
              mrsl[Math.mod(i, mrsl.size())]
            )
          )
        );
      }
    }
    insert lineItems;
  }
}