public with sharing class BrandSupplierConnectionTrgHandler extends TriggerHandler {
  public override void afterInsert() {
    List<Brand_Supplier_Connection__c> newConnections = (List<Brand_Supplier_Connection__c>) Trigger.new;

    TC_TriggeredSharing.processNewOrUpdatedConnections(newConnections);
  }

  public override void afterUpdate() {
    List<Brand_Supplier_Connection__c> newConnections = (List<Brand_Supplier_Connection__c>) Trigger.new;

    TC_TriggeredSharing.processNewOrUpdatedConnections(newConnections);
  }
}