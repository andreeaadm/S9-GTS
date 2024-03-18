/*******************************************************************************************
 * @name         GTSJobSharingEngineQueueable
 * @author       Michael Thomas
 * @description  This acts as a queueable class to handle job Apex sharing records
 * @date         8-March-2024
 *******************************************************************************************/
public without sharing class GTSJobSharingEngineQueueable implements Queueable {
  public enum OPERATION_TYPE {
    JOB_INSERT,
    EXPORTER_NEW_PARENT,
    EXPORTER_UPDATED_PARENT,
    USER_INSERT,
    ACCOUNT_RELATIONSHIP_HISTORY_INSERT,
    ACCOUNT_RELATIONSHIP_HISTORY_UPDATE,
    ACCOUNT_RELATIONSHIP_HISTORY_DELETE
  }
  private OPERATION_TYPE operationType;

  private List<Id> jobsToProcessIds = new List<Id>();
  private List<Account> newAccounts = new List<Account>();
  private List<Account> oldAccounts = new List<Account>();
  private List<GTS_Account_Relationship_History__c> newAccountRelationshipHistoryToProcess = new List<GTS_Account_Relationship_History__c>();
  private List<GTS_Account_Relationship_History__c> oldAccountRelationshipHistoryToProcess = new List<GTS_Account_Relationship_History__c>();
  private List<String> permissionSetGroupDeveloperNames = new List<String>{
    'GTS_Portal_Manager',
    'GTS_Portal_Group_Manager'
  };

  /**
   * @description Constructor for GTSJobSharingEngineQueueable
   * @param jobListIds
   * @param operation
   */
  public GTSJobSharingEngineQueueable(
    List<Id> jobListIds,
    OPERATION_TYPE operation
  ) {
    this.jobsToProcessIds = jobListIds;
    this.operationType = operation;
  }
  /**
   * @description Constructor for GTSJobSharingEngineQueueable
   * @param newAccounts
   * @param oldAccounts
   * @param operation
   */
  public GTSJobSharingEngineQueueable(
    List<Account> newAccounts,
    List<Account> oldAccounts,
    OPERATION_TYPE operation
  ) {
    this.newAccounts = newAccounts;
    this.oldAccounts = oldAccounts;
    this.operationType = operation;
  }

  /**
   * @description Constructor for GTSJobSharingEngineQueueable
   * @param newAccountRelationshipHistoryList
   * @param oldAccountRelationshipHistoryList
   * @param operation
   */
  public GTSJobSharingEngineQueueable(
    List<GTS_Account_Relationship_History__c> newAccountRelationshipHistoryList,
    List<GTS_Account_Relationship_History__c> oldAccountRelationshipHistoryList,
    OPERATION_TYPE operation
  ) {
    this.newAccountRelationshipHistoryToProcess = newAccountRelationshipHistoryList;
    this.oldAccountRelationshipHistoryToProcess = oldAccountRelationshipHistoryList;
    this.operationType = operation;
  }

  /**
   * @description Execute method for Queueable
   * @param context
   */
  public void execute(QueueableContext context) {
    Id portalManagerPSGId;
    Id portalGroupManagerPSGId;

    for (PermissionSetGroup psg : [
      SELECT Id, DeveloperName
      FROM PermissionSetGroup
      WHERE DeveloperName IN :permissionSetGroupDeveloperNames
    ]) {
      if (psg.DeveloperName == permissionSetGroupDeveloperNames[0]) {
        portalManagerPSGId = psg.Id;
      } else if (psg.DeveloperName == permissionSetGroupDeveloperNames[1]) {
        portalGroupManagerPSGId = psg.Id;
      }
    }

    //Assumption - passed in jobs have related suppliers (accounts)
    if (!jobsToProcessIds.isEmpty()) {
      switch on operationType {
        when JOB_INSERT {
          GTSJobSharingHelper.createJobShareRecords(
            jobsToProcessIds,
            portalManagerPSGId,
            portalGroupManagerPSGId
          );
        }
      }
    } else if (!newAccounts.isEmpty() || !oldAccounts.isEmpty()) {
      switch on operationType {
        when EXPORTER_NEW_PARENT {
          GTSAccountJobSharingHelper.shareJobRecordsWithNewExporterParent(
            newAccounts,
            portalGroupManagerPSGId
          );
        }
        when EXPORTER_UPDATED_PARENT {
          GTSAccountJobSharingHelper.recalculateUpdatedExporterParent(
            newAccounts,
            oldAccounts,
            portalGroupManagerPSGId
          );
        }
      }
    }
  }
}