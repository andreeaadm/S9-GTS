/*******************************************************************************************
 * @name         GTSAccountSharingEngineQueueable
 * @author       Globant
 * @description  This acts as a queueable class to handle job Apex sharing records
 * @date         8-March-2024
 *******************************************************************************************/
public without sharing class GTSAccountSharingEngineQueueable implements Queueable {
  public enum OPERATION_TYPE {
    ACCOUNT_RELATIONSHIP_HISTORY_INSERT,
    ACCOUNT_RELATIONSHIP_HISTORY_UPDATE,
    ACCOUNT_RELATIONSHIP_HISTORY_DELETE
  }
  private OPERATION_TYPE operationType;

  private List<GTS_Account_Relationship_History__c> newAccountRelationshipHistoryToProcess = new List<GTS_Account_Relationship_History__c>();
  private List<GTS_Account_Relationship_History__c> oldAccountRelationshipHistoryToProcess = new List<GTS_Account_Relationship_History__c>();
  private List<String> permissionSetGroupDeveloperNames = new List<String>{
    'GTS_Portal_Manager',
    'GTS_Portal_Group_Manager',
    'GTS_Standard_User'
  };

  /**
   * @description Constructor for GTSAccountSharingEngineQueueable
   * @param newAccountRelationshipHistoryList
   * @param oldAccountRelationshipHistoryList
   * @param operation
   */
  public GTSAccountSharingEngineQueueable(
    List<GTS_Account_Relationship_History__c> newAccountRelationshipHistoryList,
    List<GTS_Account_Relationship_History__c> oldAccountRelationshipHistoryList,
    OPERATION_TYPE operation
  ) {
    this.newAccountRelationshipHistoryToProcess = newAccountRelationshipHistoryList;
    this.oldAccountRelationshipHistoryToProcess = oldAccountRelationshipHistoryList;
    this.operationType = operation;
  }
  /**
   * @description Execute method
   * @param context
   */
  public void execute(QueueableContext context) {
    List<PermissionSetGroup> permissionSetGroups = [
      SELECT Id, DeveloperName
      FROM PermissionSetGroup
      WHERE DeveloperName IN :permissionSetGroupDeveloperNames
    ];
    switch on operationType {
      when ACCOUNT_RELATIONSHIP_HISTORY_INSERT {
        GTSAccountHistorySharingHelper.shareAccounts(
          newAccountRelationshipHistoryToProcess,
          permissionSetGroups
        );
      }
      when ACCOUNT_RELATIONSHIP_HISTORY_UPDATE {
        GTSAccountHistorySharingHelper.updateAccountRecordsSharingWithUsers(
          newAccountRelationshipHistoryToProcess,
          oldAccountRelationshipHistoryToProcess,
          permissionSetGroups
        );
      }
      when ACCOUNT_RELATIONSHIP_HISTORY_DELETE {
        GTSAccountHistorySharingHelper.recalculateAccountRecordsSharingWithUsers(
          oldAccountRelationshipHistoryToProcess,
          permissionSetGroups
        );
      }
    }
  }
}