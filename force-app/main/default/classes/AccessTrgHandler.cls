public with sharing class AccessTrgHandler extends TriggerHandler {
  public override void beforeInsert() {
    ContactGroupUtil.setAccessDupCheckFieldNoDML((List<Access__c>) Trigger.new);
  }
  public override void afterInsert() {
    List<Access__c> newAccesses = (List<Access__c>) Trigger.new;
    ReportAccessUtil.newReports(newAccesses);
  }
  public override void afterDelete() {
    List<Access__c> oldAccesses = (List<Access__c>) Trigger.old;
    ReportAccessUtil.removedReports(oldAccesses);
  }
}