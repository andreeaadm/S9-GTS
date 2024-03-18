public without sharing class InventoryCreateHelper {
  public static Id createInventory(
    Id facilityId,
    String invType,
    Date invDate
  ) {
    Inventory__c newInventory = new Inventory__c();
    newInventory.Facility__c = facilityId;
    newInventory.Type__c = invType;
    newInventory.Inventory_Date__c = invDate;
    newInventory.Status__c = 'Pending';

    if (inventoryUniqueForDateAndFacility(facilityId, invDate)) {
      insert newInventory;
      return newInventory.Id;
    } else {
      throw new DuplicateInventoryException();
    }
  }

  public static Boolean cloneLineItems(
    Id facilityId,
    String invType,
    Date invDate,
    Id inventoryId,
    String cloneName
  ) {
    Boolean cloneSuccessful = true;

    List<Inventory_Line_Item__c> prevLineItems = getLineItemsToClone(
      facilityId,
      invDate,
      cloneName
    );

    if (prevLineItems.size() > 0) {
      Id deliveryTypeId = Schema.SObjectType.Inventory_Line_Item__c.getRecordTypeInfosByDeveloperName()
        .get('Delivery_Inventory_Line_Item')
        .getRecordTypeId();
      Id usageTypeId = Schema.SObjectType.Inventory_Line_Item__c.getRecordTypeInfosByDeveloperName()
        .get('Usage_Inventory_Line_Item')
        .getRecordTypeId();
      List<Inventory_Line_Item__c> toInsert = new List<Inventory_Line_Item__c>();

      for (Inventory_Line_Item__c ili : prevLineItems) {
        if (ili.Chemical_Product__r.Product_Status__c == 'Active') {
          Inventory_Line_Item__c newItem = new Inventory_Line_Item__c();

          newItem.Inventory__c = inventoryId;
          newItem.Chemical_Product__c = ili.Chemical_Product__c;
          newItem.Unit__c = ili.Unit__c;
          newItem.Stock_Take_Month_Begin__c = invType == 'Usage'
            ? ili.Stock_Take_Month_End__c
            : null;
          newItem.RecordTypeId = invType == 'Usage'
            ? usageTypeId
            : deliveryTypeId;
          newItem.Other_Certifications__c = ili.Chemical_Product__r.Other_Certifications__c;
          newItem.ZDHC_MRSL_v2_0__c = ili.Chemical_Product__r.ZDHC_MRSL_v2_0__c;
          newItem.ZDHC_MRSL_Version__c = ili.Chemical_Product__r.ZDHC_MRSL_Version__c;
          newItem.ZDHC_Product_GUID__c = ili.Chemical_Product__r.ZDHC_Product_GUID__c;
          newItem.ZDHC_Product_Id__c = ili.Chemical_Product__r.ZDHC_Product_Id__c;
          newItem.Expiry_Date__c = ili.Chemical_Product__r.Expiry_Date__c;
          newItem.Origin__c = ili.Chemical_Product__r.Origin__c;
          toInsert.add(newItem);
        } else {
          cloneSuccessful = false;
        }
      }
      insert toInsert;
    }
    return cloneSuccessful;
  }

  public static void rollbackCreation(Id invId) {
    delete [SELECT Id FROM Inventory__c WHERE Id = :invId];
  }

  private static Boolean inventoryUniqueForDateAndFacility(
    Id facilityId,
    Date invDate
  ) {
    date startDate = invDate.toStartOfMonth();
    date endDate = invDate.addMonths(1).toStartOfMonth();
    List<Inventory__c> matchingInventories = [
      SELECT Id
      FROM Inventory__c
      WHERE
        Facility__c = :facilityId
        AND Inventory_Date__c >= :startDate
        AND Inventory_Date__c < :endDate
    ];
    return matchingInventories.size() == 0;
  }

  private static List<Inventory_Line_Item__c> getLineItemsToClone(
    Id facilityId,
    Date invDate,
    String cloneName
  ) {
    return [
      SELECT
        Chemical_Product__c,
        Chemical_Product__r.ZDHC_Product_GUID__c,
        Chemical_Product__r.Other_Certifications__c,
        Chemical_Product__r.ZDHC_MRSL_v2_0__c,
        Chemical_Product__r.ZDHC_MRSL_Version__c,
        Chemical_Product__r.ZDHC_Product_Id__c,
        Chemical_Product__r.Expiry_Date__c,
        Chemical_Product__r.Origin__c,
        Chemical_Product__r.Product_Status__c,
        Unit__c,
        Stock_Take_Month_End__c
      FROM Inventory_Line_Item__c
      WHERE
        Inventory__r.Facility__c = :facilityId
        AND Inventory__r.Inventory_Name__c = :cloneName
    ];
  }

  public class DuplicateInventoryException extends Exception {
  }
}