public with sharing class InventoryListController {
  @AuraEnabled
  public static ListResponse getInventoriesListTableData(Id facilityId) {
    try {
      return InventoryListTableHelper.buildTable(facilityId);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }

  @AuraEnabled
  public static String createNewInventory(
    Id facilityId,
    String invType,
    Date invDate,
    String cloneName
  ) {
    Id newInvId = null;
    try {
      newInvId = InventoryCreateHelper.createInventory(
        facilityId,
        invType,
        invDate
      );

      if (!String.isBlank(cloneName) && cloneName != Label.None) {
        if (
          !InventoryCreateHelper.cloneLineItems(
            facilityId,
            invType,
            invDate,
            newInvId,
            cloneName
          )
        ) {
          return 'MissingLineItems';
        }
      }
      return 'Success';
    } catch (Exception e) {
      if (newInvId != null) {
        InventoryCreateHelper.rollbackCreation(newInvId);
      }
      throw new AuraHandledException(e.getMessage());
    }
  }
}