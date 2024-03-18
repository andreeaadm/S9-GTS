public without sharing class GTS_AssociatedJobRequest_TriggerHandler {
  public static void onAfterInsert(
    List<GTS_Associated_Job_Request__c> lstAssJobRequestes
  ) {
    Map<Id, Id> mapJobRequestJob = new Map<Id, Id>();

    try {
      for (GTS_Associated_Job_Request__c ajr : lstAssJobRequestes) {
        mapJobRequestJob.put(ajr.GTS_Job_Request__c, ajr.GTS_Job__c);
      }

      String jobRequestAndJobMap = JSON.serialize(mapJobRequestJob);

      createContentDocumentLink(jobRequestAndJobMap);
    } catch (Exception e) {
      System.debug('Error : ' + e);
    }
  }

  @future
  public static void createContentDocumentLink(String jobRequestAndJobMap) {
    List<ContentDocumentLink> newDocumentLinks = new List<ContentDocumentLink>();
    Map<Id, Id> mapJobRequestJob = (Map<Id, Id>) JSON.deserialize(
      jobRequestAndJobMap,
      Map<Id, Id>.class
    );

    if (mapJobRequestJob.size() > 0) {
      List<ContentDocumentLink> documentLinks = [
        SELECT Id, ContentDocumentId, LinkedEntityId
        FROM ContentDocumentLink
        WHERE LinkedEntityId IN :mapJobRequestJob.keySet()
      ];

      if (documentLinks.size() > 0) {
        for (ContentDocumentLink cdl : documentLinks) {
          ContentDocumentLink newCDL = new ContentDocumentLink();
          newCDL.ContentDocumentId = cdl.ContentDocumentId;
          newCDL.LinkedEntityId = mapJobRequestJob.get(cdl.LinkedEntityId);
          newCDL.ShareType = 'V';
          newDocumentLinks.add(newCDL);
        }
      }
    }

    if (newDocumentLinks.size() > 0) {
      insert newDocumentLinks;
    }
  }
}