/*******************************************************************************************
 * @Name         iCare_ExpertQueryTriggerHandler
 * @Test Class :  iCare_ExpertQueryTriggerHandlerTest
 * @Author       Praveen Kumar R
 * @Description  This acts as the handler class to ExpertQueryTrigger trigger.
 *******************************************************************************************/
public with sharing class iCare_ExpertQueryTriggerHandler {
  public void onAfterInsert(List<iCare_Expert_Query__c> expQueryList) {
    // queuable job to generate leads in iConnect
    Queueable queueClass = new iCare_ExpertQueryQueuable();
    GTS_QueueJob queue = new GTS_QueueJob(queueClass);
    queue.enqueueExpertQuery(expQueryList);
  }

  public void onAfterUpdate(
    List<iCare_Expert_Query__c> expQueryList,
    Map<Id, iCare_Expert_Query__c> oldExpQueryMap
  ) {
    List<iCare_Expert_Query__c> expQueryProcessList = new List<iCare_Expert_Query__c>();
    for (iCare_Expert_Query__c expQuery : expQueryList) {
      if (
        expQuery.iCare_Retry_Sync__c !=
        oldExpQueryMap.get(expQuery.Id).iCare_Retry_Sync__c &&
        expQuery.iCare_iConnect_Sync_Status__c != 'Success'
      ) {
        expQueryProcessList.add(expQuery);
      }
    }

    // queuable job to generate leads in iConnect
    if (!expQueryProcessList.isEmpty()) {
      Queueable queueClass = new iCare_ExpertQueryQueuable();
      GTS_QueueJob queue = new GTS_QueueJob(queueClass);
      queue.enqueueExpertQuery(expQueryProcessList);
    }
  }
}