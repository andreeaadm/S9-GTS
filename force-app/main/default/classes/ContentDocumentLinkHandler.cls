/*
 * Class Description: This class should execute whenever a new ContentDocumentLink is inserted,
 * It is referred to by the ContentDocumentLinkTrigger, it then should loop through all new ContentDocumentLinks and create a CDL for the related Job record if the linkedEntity type is icare_Job_Request__c.
 *
 * @author Laura Fretter
 * @version 1.0
 * @created date 26/June/2023
 */
public with sharing class ContentDocumentLinkHandler {
  public void checkContentJobRequest(List<ContentDocumentLink> cdlList) {
    checkContentJob(cdlList);

    Set<Id> jobRequestIds = new Set<Id>();
    List<ContentDocumentLink> cdlJobRequest = new List<ContentDocumentLink>();
    if (cdlList.size() != null) {
      for (ContentDocumentLink cdl : cdlList) {
        if (
          cdl.linkedEntityId.getSObjectType().getDescribe().getName() ==
          'icare_Job_Request__c'
        ) {
          jobRequestIds.add(cdl.linkedEntityId);
          cdlJobRequest.add(cdl);
        }
      }
    }

    List<iCare_Job__c> jobs = [
      SELECT id, iCare_ETRF__c
      FROM iCare_Job__c
      WHERE iCare_ETRF__c IN :jobRequestIds
    ];
    Map<String, String> jobMap = new Map<String, String>();
    for (iCare_Job__c j : jobs) {
      jobMap.put(j.iCare_ETRF__c, j.Id);
    }
    Map<String, String> parentJobMap = new Map<String, String>();

    for (ContentDocumentLink cdl : cdlJobRequest) {
      if (jobMap.get(cdl.LinkedEntityId) != null) {
        parentJobMap.put(cdl.ContentDocumentID, jobMap.get(cdl.LinkedEntityId));
      }
    }

    List<ContentDocumentLink> cdl_List = new List<ContentDocumentLink>();
    for (String str : parentJobMap.keySet()) {
      ContentDocumentLink cdl = new ContentDocumentLink(); // Content Document Link to share the file with Job record
      cdl.LinkedEntityId = parentJobMap.get(str); // Job ID
      cdl.ContentDocumentId = str; //Content Dcoument ID
      cdl.ShareType = 'V';
      cdl.Visibility = 'AllUsers';
      cdl_List.add(cdl);
    }
    if (cdl_List.size() > 0) {
      insert cdl_List;
    }
  }

  public void checkContentJob(List<ContentDocumentLink> cdlList) {
    //Change sharing model to ETRF files added to Jobs
    List<ContentDocumentLink> cdlJobRequestNewList = new List<ContentDocumentLink>();
    Set<Id> cdIds = new Set<Id>();
    if (cdlList.size() != null) {
      for (ContentDocumentLink cdl : cdlList) {
        if (cdl.Visibility != 'AllUsers') {
          if (
            cdl.linkedEntityId.getSObjectType().getDescribe().getName() ==
            'icare_Job__c'
          ) {
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
          } else if (
            cdl.linkedEntityId.getSObjectType().getDescribe().getName() ==
            'icare_Job_Request__c'
          ) {
            cdlJobRequestNewList.add(cdl);
            cdIds.add(cdl.ContentDocumentId);
          }
        }
      }
    }
    if (!cdIds.isEmpty()) {
      Map<Id, ContentDocument> contentDocumentsByIds = new Map<Id, ContentDocument>(
        [SELECT Id, Title FROM ContentDocument WHERE Id IN :cdIds]
      );
      for (ContentDocumentLink cdl : cdlJobRequestNewList) {
        if (
          contentDocumentsByIds.get(cdl.ContentDocumentId)
            .Title.startsWith(System.Label.GTS_Conga_File_Name)
        ) {
          cdl.ShareType = 'V';
          cdl.Visibility = 'AllUsers';
        }
      }
    }
  }
}