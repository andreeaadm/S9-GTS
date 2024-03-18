/*******************************************************************************************
 * @author       Globant
 * @description  Batch class to execute the recalculation of record sharing for new GTS Users
 * @date         8-March-2024
 *******************************************************************************************/
public with sharing class GTS_RecalcSharingOnUserCreationBatch implements Database.Batchable<sObject> {
  /**
   * @description Batch start method
   * @param batchableContext
   *
   * @return
   */
  public Database.QueryLocator start(
    Database.BatchableContext batchableContext
  ) {
    List<String> permissionSetGroupDeveloperNames = new List<String>{
      'GTS_Portal_Manager',
      'GTS_Portal_Group_Manager',
      'GTS_Standard_User'
    };

    return Database.getQueryLocator(
      [
        SELECT
          Id,
          AssigneeId,
          Assignee.AccountId,
          PermissionSetGroup.DeveloperName
        FROM PermissionSetAssignment
        WHERE
          Assignee.GTS_Recalculated_Sharing__c = FALSE
          AND PermissionSet.Name IN :permissionSetGroupDeveloperNames
      ]
    );
  }
  /**
   * @description Batch execute method
   * @param batchableContext
   * @param scope
   */
  public void execute(
    Database.BatchableContext batchableContext,
    List<PermissionSetAssignment> scope
  ) {
    List<Id> managerUserIds = new List<Id>();
    List<Id> managerGroupUserIds = new List<Id>();
    List<Id> usersIds = new List<Id>();
    for (PermissionSetAssignment permissionSetAssignment : scope) {
      if (
        permissionSetAssignment.PermissionSetGroup.DeveloperName ==
        'GTS_Portal_Manager'
      ) {
        managerUserIds.add(permissionSetAssignment.AssigneeId);
      } else if (
        permissionSetAssignment.PermissionSetGroup.DeveloperName ==
        'GTS_Portal_Group_Manager'
      ) {
        managerGroupUserIds.add(permissionSetAssignment.AssigneeId);
      }
      usersIds.add(permissionSetAssignment.AssigneeId);
    }

    if (!managerUserIds.isEmpty()) {
      GTSUserJobSharingHelper.shareJobRecordsWithManagers(managerUserIds);
    }
    if (!managerGroupUserIds.isEmpty()) {
      GTSUserJobSharingHelper.shareJobRecordsWithManagersGroup(
        managerGroupUserIds
      );
    }
    if (!usersIds.isEmpty()) {
      GTSAccountHistorySharingHelper.shareWithNewUsers(new List<Id>(usersIds));
    }

    List<User> users = new List<User>();
    for (Id userId : usersIds) {
      users.add(new User(Id = userId, GTS_Recalculated_Sharing__c = true));
    }

    if (!Test.isRunningTest()) {
      update users;
    } else {
      User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      System.runAs(currentUser) {
        update users;
      }
    }
  }
  /**
   * @description Batch finish method
   * @param batchableContext
   */
  public void finish(Database.BatchableContext batchableContext) {
  }
}