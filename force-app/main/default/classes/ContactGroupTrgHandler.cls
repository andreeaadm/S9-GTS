public with sharing class ContactGroupTrgHandler extends TriggerHandler {
  public override void beforeInsert() {
    List<Contact_Group__c> newCGs = (List<Contact_Group__c>) Trigger.new;

    ContactGroupUtil.setCGDupCheckFieldNoDML(newCGs);
    ContactGroupUtil.updateHasExpiredFieldOnUpdateNoDML(newCGs);
  }
  public override void afterInsert() {
    List<Contact_Group__c> newCGs = (List<Contact_Group__c>) Trigger.new;

    GroupAccessUtil.newContactGroup((Map<Id, Contact_Group__c>) Trigger.newMap);
  }
  public override void beforeUpdate() {
    List<Contact_Group__c> newCGs = (List<Contact_Group__c>) Trigger.new;
    Map<Id, Contact_Group__c> oldCGs = (Map<Id, Contact_Group__c>) Trigger.oldMap;

    ContactGroupUtil.updateHasExpiredFieldOnUpdateNoDML(newCGs);

    // Prevents a community user from changing a default group name
    for (Contact_Group__c cg : newCGs) {
      Contact_Group__c oldCG = oldCGs.get(cg.Id);
      if (
        cg.Is_Default_Group__c &&
        UserInfo.getUserType().containsIgnoreCase('CustomerSuccess') &&
        oldCG.Group_Name__c != cg.Group_Name__c
      ) {
        cg.addError(Label.MTC_Cannot_Update_Group_warning);
      }
    }
  }

  public override void beforeDelete() {
    List<Contact_Group__c> oldCGs = (List<Contact_Group__c>) Trigger.old;
    for (Contact_Group__c cg : oldCGs) {
      if (cg.Is_Default_Group__c) {
        cg.addError(Label.MTC_Cannot_Delete_Group_warning);
      }
    }
  }
}