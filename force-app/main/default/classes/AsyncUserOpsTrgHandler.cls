public with sharing class AsyncUserOpsTrgHandler extends TriggerHandler {
  public override void afterInsert() {
    Set<Id> contactIds = new Set<Id>();
    for (Async_User_Ops__e event : (List<Async_User_Ops__e>) Trigger.new) {
      contactIds.add(event.Contact_Id__c);
    }
    MTCUserUtil.createUpdateUsersForContacts(contactIds);
    UserAccessUtil.createMissingUserShares(contactIds);
  }
}