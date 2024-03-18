/*******************************************************************************************
 * @author       Globant
 * @description  This acts as a helper class to handle job Apex sharing records
 * @date         8-March-2024
 *******************************************************************************************/
public with sharing class GTSJobSharingHelper {
  /**
   * @description Create JobShare records for new Jobs
   * @param jobsToProcessIds
   * @param portalManagerPSGId
   * @param portalGroupManagerPSGId
   */
  public static void createJobShareRecords(
    List<Id> jobsToProcessIds,
    Id portalManagerPSGId,
    Id portalGroupManagerPSGId
  ) {
    List<iCare_Job__c> jobsToProcess = [
      SELECT Id, iCare_Supplier__c, iCare_Supplier__r.ParentId, OwnerId
      FROM iCare_Job__c
      WHERE Id IN :jobsToProcessIds
      WITH SECURITY_ENFORCED
    ];
    Set<Id> jobAccountIds = new Set<Id>();
    Set<Id> jobGrandparentAccountIds = new Set<Id>();
    List<Id> jobOwnerIds = new List<Id>();

    for (iCare_Job__c jobRecord : jobsToProcess) {
      if (jobRecord.iCare_Supplier__c != null) {
        jobAccountIds.add(jobRecord.iCare_Supplier__c);
        if (jobRecord.iCare_Supplier__r.ParentId != null) {
          jobGrandparentAccountIds.add(jobRecord.iCare_Supplier__r.ParentId);
        }
      }
      jobOwnerIds.add(jobRecord.OwnerId);
    }

    //Fetch users with Permission Set Groups
    List<User> managersToShareWith = [
      SELECT Id, AccountId, Name
      FROM User
      WHERE
        Id NOT IN :jobOwnerIds
        AND AccountId IN :jobAccountIds
        AND Id IN (
          SELECT AssigneeId
          FROM PermissionSetAssignment
          WHERE PermissionSetGroupId = :portalManagerPSGId
        )
      WITH SECURITY_ENFORCED
    ];
    List<User> groupManagersToShareWith = [
      SELECT Id, AccountId, Name
      FROM User
      WHERE
        Id NOT IN :jobOwnerIds
        AND (AccountId IN :jobAccountIds
        OR AccountId IN :jobGrandparentAccountIds)
        AND Id IN (
          SELECT AssigneeId
          FROM PermissionSetAssignment
          WHERE PermissionSetGroupId = :portalGroupManagerPSGId
        )
      WITH SECURITY_ENFORCED
    ];
    //Group account IDs with Users for matching
    Map<Id, List<User>> accountIdsWithManagers = getUsersByAccountId(
      managersToShareWith
    );
    Map<Id, List<User>> accountIdsWithGroupManagers = getUsersByAccountId(
      groupManagersToShareWith
    );

    //Create new share records
    List<iCare_Job__Share> newJobShareRecords = new List<iCare_Job__Share>();
    for (iCare_Job__c jobRecord : jobsToProcess) {
      if (accountIdsWithManagers.get(jobRecord.iCare_Supplier__c) != null) {
        List<User> managerUsers = accountIdsWithManagers.get(
          jobRecord.iCare_Supplier__c
        );
        for (User managerUser : managerUsers) {
          iCare_Job__Share shareRecord = constructShareRecord(
            jobRecord.Id,
            managerUser.Id
          );
          newJobShareRecords.add(shareRecord);
        }
      }
      if (
        accountIdsWithGroupManagers.get(jobRecord.iCare_Supplier__c) != null
      ) {
        List<User> groupMmanagerUsers = accountIdsWithGroupManagers.get(
          jobRecord.iCare_Supplier__c
        );
        for (User groupManagerUser : groupMmanagerUsers) {
          iCare_Job__Share shareRecord = constructShareRecord(
            jobRecord.Id,
            groupManagerUser.Id
          );
          newJobShareRecords.add(shareRecord);
        }
      }
      if (
        accountIdsWithGroupManagers.get(jobRecord.iCare_Supplier__r.ParentId) !=
        null
      ) {
        List<User> groupMmanagerUsers = accountIdsWithGroupManagers.get(
          jobRecord.iCare_Supplier__r.ParentId
        );
        for (User groupManagerUser : groupMmanagerUsers) {
          iCare_Job__Share shareRecord = constructShareRecord(
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
   * @description Create new iCare_Job__Share records
   * @param jobId
   * @param userId
   *
   * @return
   */
  public static iCare_Job__Share constructShareRecord(Id jobId, Id userId) {
    iCare_Job__Share sharerecord = new iCare_Job__Share();
    shareRecord.AccessLevel = 'Read';
    shareRecord.ParentID = jobId;
    shareRecord.UserOrGroupId = userId;
    shareRecord.RowCause = Schema.iCare_Job__Share.RowCause.Manual;

    return shareRecord;
  }
  /**
   * @description  Map users by Parent Account
   * @param users
   *
   * @return
   */
  public static Map<Id, List<User>> getUsersByAccountId(List<User> users) {
    Map<Id, List<User>> usersByAccountId = new Map<Id, List<User>>();
    for (User user : users) {
      if (usersByAccountId.containsKey(user.AccountId)) {
        usersByAccountId.get(user.AccountId).add(user);
      } else {
        usersByAccountId.put(user.AccountId, new List<User>{ user });
      }
    }
    return usersByAccountId;
  }
}