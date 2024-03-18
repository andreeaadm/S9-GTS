public with sharing class GroupMembershipTrgHandler extends TriggerHandler {
  public override void beforeInsert() {
    ContactGroupUtil.setGMbshipDupCheckFieldNoDML(
      (List<Group_Membership__c>) Trigger.new
    );
  }
  public override void afterInsert() {
    List<Group_Membership__c> newMembers = (List<Group_Membership__c>) Trigger.new;
    ReportAccessUtil.newMembers(newMembers);
    //Trigger execution Unit tested in AccountRelationUtilTest
    AccountRelationUtil.createACRsForContactsAddedToGroupsInAccountsDifferentThanParent(newMembers,'Read-Only');
  }
  public override void afterDelete() {
    List<Group_Membership__c> deletedMembers = (List<Group_Membership__c>) Trigger.old;
    ReportAccessUtil.removedMembers(deletedMembers);
  }
}