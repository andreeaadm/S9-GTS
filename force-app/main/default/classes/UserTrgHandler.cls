public with sharing class UserTrgHandler extends TriggerHandler {
  public override void beforeInsert() {
    List<User> newUsers = (List<User>) Trigger.new;
    UserUtil.setEmailVisibilityNoDML(newUsers);
  }

  public override void afterInsert() {
    Eventbus.publish(
      new User_Upsert__e(
        Is_Insert__c = true,
        User_Ids__c = JSON.serialize(Trigger.newMap.keySet())
      )
    );
  }

  // After User update
  public override void afterUpdate() {
    if (!ContactTrgHandler.triggerHasRun) {
      Eventbus.publish(
        new User_Upsert__e(
          Is_Insert__c = false,
          User_Ids__c = JSON.serialize(Trigger.newMap.keySet())
        )
      );
    }
  }
    
    public override void beforeUpdate() {
        List<User> newUsers = (List<User>) Trigger.new;
        for(User usr: newUsers){
            if(usr.isactive == false && usr.SystemUser__c==true){
                usr.AddError('Do not deactivate this User as System Users supports the ORG');
            }
        }
    }
}