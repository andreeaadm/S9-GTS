public with sharing class AccountContactRelationTrgHandler extends TriggerHandler {
  public override void afterInsert() {
    List<AccountContactRelation> newACRs = (List<AccountContactRelation>) Trigger.new;

    List<AccountContactRelation> acrsWithValidMTCRole = new List<AccountContactRelation>();
    for (AccountContactRelation acr : newACRs) {
      if (
        !String.isEmpty(acr.MTC_Role__c) &&
        MTCUserUtil.isValidMTCRole(acr.MTC_Role__c)
      ) {
        acrsWithValidMTCRole.add(acr);
      }
    }

    if (!acrsWithValidMTCRole.isEmpty()) {
      AccountUtil.replaceCGA(
        acrsWithValidMTCRole,
        new Map<Id, AccountContactRelation>()
      );

      DefaultGroupUtil.newRelationshipAddToDefaultGroup(
        acrsWithValidMTCRole,
        new Map<Id, AccountContactRelation>()
      );

      MTCUserUtil.updatedRelationship(
        acrsWithValidMTCRole,
        new Map<Id, AccountContactRelation>()
      );

      List<AccountContactRelation> acrsWithUser = AccountRelationUtil.filterWithUserRecord(
        acrsWithValidMTCRole
      );
      ReportAccessUtil.newAccountRelation(acrsWithUser);

      GroupAccessUtil.newAccountRelation(
        acrsWithUser,
        new Map<Id, AccountContactRelation>()
      );
      UserAccessUtil.createMissingUserShares(acrsWithUser);
        
        //Prateek
      set<Id> contactIdset = new set<Id>();
      set<Id> contactIdsetRes = new set<Id>();
      List<Asset_Contact_Relationship__c> reportUpdate = new List<Asset_Contact_Relationship__c>();
      for(AccountContactRelation acr : newACRs){
          if(acr.MTC_Role__c == 'Restricted'  ){
              contactIdsetRes.add(acr.ContactId);
          }
      } 
      for(Asset_Contact_Relationship__c aacrR : [select id , Restricted_Role__c from Asset_Contact_Relationship__c where Contact__c IN: contactIdsetRes  ]){
          aacrR.Restricted_Role__c = true;
          reportUpdate.add(aacrR);
      }
      if(reportUpdate != null && !reportUpdate.isEmpty()){
          update reportUpdate;
      }
      //Prateek
    }
  }
  public override void afterUpdate() {
    List<AccountContactRelation> newACRs = (List<AccountContactRelation>) Trigger.new;
    Map<Id, AccountContactRelation> oldACRs = (Map<Id, AccountContactRelation>) Trigger.oldMap;

    List<AccountContactRelation> acrsWithMTCRoleChange = AccountRelationUtil.filterMTCRoleChange(
      newACRs,
      oldACRs
    );
    List<AccountContactRelation> acrsWithMTCRoleChangeAndUser = AccountRelationUtil.filterWithUserRecord(
      acrsWithMTCRoleChange
    );

    if (!acrsWithMTCRoleChange.isEmpty()) {
      AccountUtil.replaceCGA(acrsWithMTCRoleChange, oldACRs);
      DefaultGroupUtil.newRelationshipAddToDefaultGroup(
        acrsWithMTCRoleChange,
        oldACRs
      );
      DefaultGroupUtil.relationshipsMovingToNoAccess(
        acrsWithMTCRoleChange,
        oldACRs
      );
      ReportAccessUtil.newAccountRelation(acrsWithMTCRoleChangeAndUser);
      GroupAccessUtil.newAccountRelation(acrsWithMTCRoleChangeAndUser, oldACRs);

      UserAccessUtil.createMissingUserShares(acrsWithMTCRoleChangeAndUser);
    }
    MTCUserUtil.updatedRelationship(acrsWithMTCRoleChange, oldACRs);
      //Prateek
      set<Id> contactIdset = new set<Id>();
      set<Id> contactIdsetRes = new set<Id>();
      List<Asset_Contact_Relationship__c> reportUpdate = new List<Asset_Contact_Relationship__c>();
      for(AccountContactRelation acr : newACRs){
          if(acr.MTC_Role__c != 'Restricted'  && oldACRs.get(acr.Id).MTC_Role__c == 'Restricted'){ 
              contactIdset.add(acr.ContactId);
          }else if(acr.MTC_Role__c == 'Restricted'  && oldACRs.get(acr.Id).MTC_Role__c == 'No-Access'){
              contactIdsetRes.add(acr.ContactId);
          }
      } 
      if(!contactIdset.isEmpty() && contactIdset != null){
          for(Asset_Contact_Relationship__c aacr : [select id , Restricted_Role__c from Asset_Contact_Relationship__c where Restricted_Role__c = true and Contact__c IN: contactIdset  ]){
              aacr.Restricted_Role__c = false;
              reportUpdate.add(aacr);
      		}
      }
       if(!contactIdsetRes.isEmpty() && contactIdsetRes != null){
          for(Asset_Contact_Relationship__c aacrR : [select id , Restricted_Role__c from Asset_Contact_Relationship__c where Contact__c IN: contactIdsetRes  ]){
              aacrR.Restricted_Role__c = true;
              reportUpdate.add(aacrR); 
          }
       }
      if(reportUpdate != null && !reportUpdate.isEmpty()){
          update reportUpdate;
      }
      //Prateek
  }

  public override void afterDelete() {
    List<AccountContactRelation> oldACRs = (List<AccountContactRelation>) Trigger.old;
    DefaultGroupUtil.relationshipsDeleted(oldACRs);
  }
}