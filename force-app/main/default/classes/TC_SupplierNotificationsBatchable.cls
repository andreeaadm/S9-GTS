public with sharing class TC_SupplierNotificationsBatchable implements Database.Batchable<sObject> {
  public Database.QueryLocator start(Database.BatchableContext bc) {
    // Get Inventories to loop over
    Date today = Date.today();
    return Database.getQueryLocator(
      'SELECT Id FROM Inventory__c WHERE Supplier_Notification_Date__c = :today'
    );
  }

  public void execute(Database.BatchableContext bc, List<Inventory__c> scope) {
    // Process Inventories and get platform events to send to EmailRequestUtil
    // Filtered Inventories should be removed in start step, so just create platform events
    List<Email_Request__e> emailRequestsToInsert = new List<Email_Request__e>();
    for (Inventory__c i : scope) {
      emailRequestsToInsert.add(
        new Email_Request__e(
          Email_Template_Name__c = 'ToxClear_Facility_Inventory_Due',
          RecordId__c = i.Id,
          Organization_Wide_Address__c = Label.TC_System_Default_Org_Wide_Address
        )
      );
    }
    EmailRequestUtil.newEmailRequests(emailRequestsToInsert);
  }

  public void finish(Database.BatchableContext bc) {
  }
}