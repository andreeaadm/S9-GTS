public with sharing class TC_DeleteInventoryController {
  @AuraEnabled
  public static Boolean deleteInventory(Id inventoryToDelete) {
    try {
      if (Schema.sObjectType.Inventory__c.isDeletable()) {
        Inventory__c toDelete = new Inventory__c(Id = inventoryToDelete);
        delete toDelete;
        return true;
      } else {
        return false;
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}