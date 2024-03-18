/*******************************************************************************************
 * @author       Globant
 * @description  Helper class to handle sharing logic between Users and Jobs
 * @date         8-March-2024
 *******************************************************************************************/
public with sharing class GTSAccountJobSharingHelper {
  /**
   * @description Logic to share the new Job records with existing users
   * @param accountsToProcess
   * @param portalGroupManagerPSGId
   */
  public static void shareJobRecordsWithNewExporterParent(
    List<Account> accountsToProcess,
    Id portalGroupManagerPSGId
  ) {
    Set<Id> parentAccountsToProcess = new Set<Id>();

    for (Account accountRecord : accountsToProcess) {
      parentAccountsToProcess.add(accountRecord.ParentId);
    }

    List<User> groupManagersToShareWith = [
      SELECT Id, AccountId
      FROM User
      WHERE
        AccountId IN :parentAccountsToProcess
        AND Id IN (
          SELECT AssigneeId
          FROM PermissionSetAssignment
          WHERE PermissionSetGroupId = :portalGroupManagerPSGId
        )
      WITH SECURITY_ENFORCED
    ];
    Map<Id, List<User>> accountIdsWithGroupManagers = GTSJobSharingHelper.getUsersByAccountId(
      groupManagersToShareWith
    );

    List<iCare_Job__c> jobs = [
      SELECT Id, iCare_Supplier__r.ParentId
      FROM iCare_Job__c
      WHERE iCare_Supplier__r.ParentId IN :parentAccountsToProcess
      WITH SECURITY_ENFORCED
    ];

    List<iCare_Job__Share> newJobShareRecords = new List<iCare_Job__Share>();
    for (iCare_Job__c jobRecord : jobs) {
      List<User> groupManagerUsersFromParentAccount = accountIdsWithGroupManagers.get(
        jobRecord.iCare_Supplier__r.ParentId
      );
      if (groupManagerUsersFromParentAccount != null) {
        for (User groupManagerUser : groupManagerUsersFromParentAccount) {
          iCare_Job__Share shareRecord = GTSJobSharingHelper.constructShareRecord(
            jobRecord.Id,
            groupManagerUser.Id
          );
          newJobShareRecords.add(shareRecord);
        }
      }
    }

    List<Database.SaveResult> saveResults = Database.insert(
      newJobShareRecords,
      false
    );

    GTSLogErrors.logDatabaseOperationErrors(saveResults);
  }

  /**
   * @description Recalculate JobSharing
   * @param newAccounts
   * @param oldAccounts
   * @param portalGroupManagerPSGId
   */
  public static void recalculateUpdatedExporterParent(
    List<Account> newAccounts,
    List<Account> oldAccounts,
    Id portalGroupManagerPSGId
  ) {
    if (!newAccounts.isEmpty()) {
      shareJobRecordsWithNewExporterParent(
        newAccounts,
        portalGroupManagerPSGId
      );
    }
    if (!oldAccounts.isEmpty()) {
      deleteForUpdatedExporterParent(oldAccounts, portalGroupManagerPSGId);
    }
  }
  /**
   * @description Delete JobSharing records
   * @param accountsToProcess
   * @param portalGroupManagerPSGId
   */
  public static void deleteForUpdatedExporterParent(
    List<Account> accountsToProcess,
    Id portalGroupManagerPSGId
  ) {
    Set<Id> parentAccountsToProcess = new Set<Id>();
    Map<Id, Account> accountsByIds = new Map<Id, Account>(accountsToProcess);

    for (Account accountRecord : accountsToProcess) {
      parentAccountsToProcess.add(accountRecord.ParentId);
    }

    List<User> groupManagersToShareWith = [
      SELECT Id, AccountId
      FROM User
      WHERE
        AccountId IN :parentAccountsToProcess
        AND Id IN (
          SELECT AssigneeId
          FROM PermissionSetAssignment
          WHERE PermissionSetGroupId = :portalGroupManagerPSGId
        )
      WITH SECURITY_ENFORCED
    ];
    Map<Id, List<User>> managerUsersByAccountId = GTSJobSharingHelper.getUsersByAccountId(
      groupManagersToShareWith
    );

    List<iCare_Job__Share> sharedRecords = [
      SELECT Id, UserOrGroupId, Parent.iCare_Supplier__r.ParentId
      FROM iCare_Job__Share
      WHERE
        UserOrGroupId IN :groupManagersToShareWith
        AND Parent.iCare_Supplier__c IN :accountsToProcess
      WITH SECURITY_ENFORCED
    ];

    List<iCare_Job__Share> sharedRecordsToDelete = new List<iCare_Job__Share>();
    for (iCare_Job__Share sharedRecord : sharedRecords) {
      Id relatedAccountId = sharedRecord.Parent.iCare_Supplier__c;
      Id parentAccountId = accountsByIds.get(relatedAccountId).ParentId;

      if (managerUsersByAccountId.containsKey(parentAccountId)) {
        Set<Id> relatedUsers = (new Map<Id, User>(
            managerUsersByAccountId.get(parentAccountId)
          ))
          .keySet();
        if (relatedUsers.contains(sharedRecord.UserOrGroupId)) {
          sharedRecordsToDelete.add(sharedRecord);
        }
      }
    }
    if (!sharedRecordsToDelete.isEmpty()) {
      if (iCare_Job__Share.sObjectType.getDescribe().isDeletable()) {
        delete sharedRecordsToDelete;
      }
    }
  }
}