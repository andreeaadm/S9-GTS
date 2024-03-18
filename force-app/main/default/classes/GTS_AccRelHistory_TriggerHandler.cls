/*******************************************************************************************
 * @author       Globant
 * @description  Handler class for AccountRelationshipHistory trigger
 * @date         8-March-2024
 *******************************************************************************************/
public with sharing class GTS_AccRelHistory_TriggerHandler {
  /**
   * @description Handler for After Insert
   * @param newList
   */
  public static void onAfterInsert(
    List<GTS_Account_Relationship_History__c> newList
  ) {
    GTSAccountSharingEngineQueueable accountSharingEngineQueueable = new GTSAccountSharingEngineQueueable(
      newList,
      null,
      GTSAccountSharingEngineQueueable.OPERATION_TYPE.ACCOUNT_RELATIONSHIP_HISTORY_INSERT
    );
    System.enqueueJob(accountSharingEngineQueueable);
  }
  /**
   * @description Handler for After Update
   * @param newList
   * @param oldMap
   */
  public static void onAfterUpdate(
    List<GTS_Account_Relationship_History__c> newList,
    Map<Id, GTS_Account_Relationship_History__c> oldMap
  ) {
    List<GTS_Account_Relationship_History__c> newAccountRelationshipHistoryToProcess = new List<GTS_Account_Relationship_History__c>();
    List<GTS_Account_Relationship_History__c> oldAccountRelationshipHistoryToProcess = new List<GTS_Account_Relationship_History__c>();

    for (
      GTS_Account_Relationship_History__c accountRelationshipHistory : newList
    ) {
      GTS_Account_Relationship_History__c oldAccountRelationshipHistory = oldMap.get(
        accountRelationshipHistory.Id
      );
      if (oldAccountRelationshipHistory != null) {
        if (
          accountRelationshipHistory.GTS_Account__c !=
          oldAccountRelationshipHistory.GTS_Account__c ||
          accountRelationshipHistory.GTS_Associated_Account__c !=
          oldAccountRelationshipHistory.GTS_Associated_Account__c
        ) {
          newAccountRelationshipHistoryToProcess.add(
            accountRelationshipHistory
          );
          oldAccountRelationshipHistoryToProcess.add(
            oldAccountRelationshipHistory
          );
        }
      }
    }

    if (
      !newAccountRelationshipHistoryToProcess.isEmpty() &&
      !oldAccountRelationshipHistoryToProcess.isEmpty()
    ) {
      GTSAccountSharingEngineQueueable accountSharingEngineQueueable = new GTSAccountSharingEngineQueueable(
        newAccountRelationshipHistoryToProcess,
        oldAccountRelationshipHistoryToProcess,
        GTSAccountSharingEngineQueueable.OPERATION_TYPE.ACCOUNT_RELATIONSHIP_HISTORY_UPDATE
      );
      System.enqueueJob(accountSharingEngineQueueable);
    }
  }
  /**
   * @description Handler for After Delete
   * @param oldList
   */
  public static void onAfterDelete(
    List<GTS_Account_Relationship_History__c> oldList
  ) {
    GTSAccountSharingEngineQueueable accountSharingEngineQueueable = new GTSAccountSharingEngineQueueable(
      null,
      oldList,
      GTSAccountSharingEngineQueueable.OPERATION_TYPE.ACCOUNT_RELATIONSHIP_HISTORY_DELETE
    );
    System.enqueueJob(accountSharingEngineQueueable);
  }
}