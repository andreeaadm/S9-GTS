/*******************************************************************************************
 * @author       Globant
 * @description  Helper class to handle sharing logic between Users and Job
 * @date         8-March-2024
 *******************************************************************************************/
public with sharing class GTSUserJobSharingHelper {
  /**
   * @description Logic to share existing Job records with new Manager Users
   * @param usersToProcessIds
   */
  public static void shareJobRecordsWithManagers(List<Id> usersToProcessIds) {
    List<User> managersToShareWith = [
      SELECT Id, AccountId
      FROM User
      WHERE Id IN :usersToProcessIds AND AccountId != NULL
      WITH SECURITY_ENFORCED
    ];
    Map<Id, List<User>> managerUsersByAccountId = GTSJobSharingHelper.getUsersByAccountId(
      managersToShareWith
    );

    List<iCare_Job__c> jobs = [
      SELECT Id, iCare_Supplier__c
      FROM iCare_Job__c
      WHERE iCare_Supplier__c IN :managerUsersByAccountId.keySet()
      WITH SECURITY_ENFORCED
    ];
    List<iCare_Job__Share> newJobShareRecords = new List<iCare_Job__Share>();
    for (iCare_Job__c jobRecord : jobs) {
      List<User> managerUsers = managerUsersByAccountId.get(
        jobRecord.iCare_Supplier__c
      );
      for (User managerUser : managerUsers) {
        iCare_Job__Share shareRecord = GTSJobSharingHelper.constructShareRecord(
          jobRecord.Id,
          managerUser.Id
        );
        newJobShareRecords.add(shareRecord);
      }
    }
    List<Database.SaveResult> saveResults = Database.insert(
      newJobShareRecords,
      false
    );

    GTSLogErrors.logDatabaseOperationErrors(saveResults);
  }
  /**
   * @description Logic to share existing Job records with new Group Manager Users
   *
   * @param usersToProcessIds
   */
  public static void shareJobRecordsWithManagersGroup(
    List<Id> usersToProcessIds
  ) {
    List<User> groupManagersToShareWith = [
      SELECT Id, AccountId
      FROM User
      WHERE Id IN :usersToProcessIds AND AccountId != NULL
      WITH SECURITY_ENFORCED
    ];

    Map<Id, List<User>> accountIdsWithGroupManagers = GTSJobSharingHelper.getUsersByAccountId(
      groupManagersToShareWith
    );

    List<iCare_Job__c> jobs = [
      SELECT Id, iCare_Supplier__c, iCare_Supplier__r.ParentId
      FROM iCare_Job__c
      WHERE
        iCare_Supplier__c IN :accountIdsWithGroupManagers.keySet()
        OR iCare_Supplier__r.ParentId IN :accountIdsWithGroupManagers.keySet()
      WITH SECURITY_ENFORCED
    ];

    List<iCare_Job__Share> newJobShareRecords = new List<iCare_Job__Share>();
    for (iCare_Job__c jobRecord : jobs) {
      List<User> groupManagerUsers = accountIdsWithGroupManagers.get(
        jobRecord.iCare_Supplier__c
      );
      if (groupManagerUsers != null) {
        for (User groupManagerUser : groupManagerUsers) {
          iCare_Job__Share shareRecord = GTSJobSharingHelper.constructShareRecord(
            jobRecord.Id,
            groupManagerUser.Id
          );
          newJobShareRecords.add(shareRecord);
        }
      }
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
}