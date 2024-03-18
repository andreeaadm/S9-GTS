/*******************************************************************************************
 * @Name         iCare_JobTriggerHandler
 * @Test Class :  iCare_JobTriggerHandlerTest
 * @Author       Praveen Kumar R
 * @Description  This acts as the handler class to iCare_JobTrigger trigger.
 *******************************************************************************************/
public with sharing class iCare_JobTriggerHandler extends GTS_RecordTypeService {
  public static final String JOB_SUBMITTED = 'Job Submitted (iCare)';
  public static final String JOB_SUBMITTED_GTS = 'Submitted';
  private Map<String, iCare_JobId_Interface> strategyServices = this.getContextMapFromMetadataGrouped();

  //Inner class used to deserialize external contacts JSON
  @TestVisible
  private class ContactInfo {
    @TestVisible
    private String FirstName;
    @TestVisible
    private String LastName;
    @TestVisible
    private String Email;
  }

  public void onBeforeInsert(List<iCare_Job__c> jobRecList) {
    Map<String, List<sObject>> jobsByRecordTypeGroup = new GTS_Job()
      .getByRecordTypeGroup(jobRecList);
    iCare_JobId_Interface service = null;

    for (String recordTypeDeveloperName : jobsByRecordTypeGroup.keySet()) {
      service = strategyServices.get(recordTypeDeveloperName);
      if (service != null) {
        service.setJobIds(
          (List<iCare_Job__c>) jobsByRecordTypeGroup.get(
            recordTypeDeveloperName
          )
        );
        service.setiCarePortalURL(
          (List<iCare_Job__c>) jobsByRecordTypeGroup.get(
            recordTypeDeveloperName
          )
        );
        service.updatePortalStatusValues(jobRecList, null);
      }
    }

    Map<Id, List<ContactInfo>> accountIdsWithContactInfo = new Map<Id, List<ContactInfo>>();
    List<iCare_Job__c> jobsWithExternalContacts = new List<iCare_Job__c>();

    for (iCare_Job__c jobSO : jobRecList) {
      if (String.isNotBlank(jobSO.iCare_External_Contacts__c)) {
        List<ContactInfo> contactInfo = (List<ContactInfo>) JSON.deserializeStrict(
          jobSO.iCare_External_Contacts__c,
          List<ContactInfo>.class
        );
        List<ContactInfo> allContacts = new List<ContactInfo>();
        for (Integer i = 0; i < contactInfo.size(); i++) {
          allContacts.add(contactInfo[i]);
        }
        accountIdsWithContactInfo.put(jobSO.iCare_Supplier__c, allContacts);
        jobsWithExternalContacts.add(jobSO);
      }
    }

    //Set the owner to the first Contact's user in the Job Request 'External Contacts' field
    if (!accountIdsWithContactInfo.isEmpty()) {
      List<User> newOwners = matchContacts(
        accountIdsWithContactInfo,
        jobsWithExternalContacts
      );

      for (iCare_Job__c jobRecord : jobsWithExternalContacts) {
        for (User newOwner : newOwners) {
          if (jobRecord.iCare_Supplier__c == newOwner.AccountId) {
            jobRecord.OwnerId = newOwner.Id;
            break;
          }
        }
      }
    }
  }

  public void onAfterInsert(List<iCare_Job__c> jobRecList) {
    List<iCare_Job__c> jobRecProcessList = new List<iCare_Job__c>();
    Map<Id, List<ContactInfo>> accountIdsWithContactInfo = new Map<Id, List<ContactInfo>>();
    List<iCare_Job__c> jobsWithExternalContacts = new List<iCare_Job__c>();

    for (iCare_Job__c jobRec : jobRecList) {
      if (
        (jobRec.iCare_Job_Status__c == JOB_SUBMITTED &&
        jobRec.iCare_ETRF__c != null) ||
        jobRec.iCare_Job_Status__c == JOB_SUBMITTED_GTS
      ) {
        jobRecProcessList.add(jobRec);
      }
      if (String.isNotBlank(jobRec.iCare_External_Contacts__c)) {
        List<ContactInfo> allContacts = (List<ContactInfo>) JSON.deserializeStrict(
          jobRec.iCare_External_Contacts__c,
          List<ContactInfo>.class
        );
        //If there is more than one associated contact, share records need to be created for all users but the first (they will be the owner)
        if (allContacts.size() > 1) {
          List<ContactInfo> allContactsExcludingOwner = new List<ContactInfo>();
          for (Integer i = 0; i < allContacts.size(); i++) {
            allContactsExcludingOwner.add(allContacts[i]);
          }
          accountIdsWithContactInfo.put(
            jobRec.iCare_Supplier__c,
            allContactsExcludingOwner
          );
          jobsWithExternalContacts.add(jobRec);
        }
      }
    }
    //Changes for IB-22
    iCare_JobUtil.generateSearchableJobIdsFuture(Trigger.newMap.keySet());

    if (!accountIdsWithContactInfo.isEmpty()) {
      List<User> usersToShareWith = matchContacts(
        accountIdsWithContactInfo,
        jobsWithExternalContacts
      );
      List<iCare_Job__Share> newShareRecords = new List<iCare_Job__Share>();
      for (User userToShareWith : usersToShareWith) {
        for (iCare_Job__c jobRecord : jobsWithExternalContacts) {
          if (
            jobRecord.iCare_Supplier__c == userToShareWith.AccountId &&
            jobRecord.OwnerId != userToShareWith.Id
          ) {
            iCare_Job__Share newShareRecord = new iCare_Job__Share();
            newShareRecord.ParentId = jobRecord.Id;
            newShareRecord.UserOrGroupId = userToShareWith.Id;
            newShareRecord.AccessLevel = 'Read';
            newShareRecords.add(newShareRecord);
          }
        }
      }
      if (newShareRecords.size() > 0) {
        insert newShareRecords;
      }
    }
    System.debug('Trigger****' + jobRecProcessList);
    GTS_QueueJob queue = new GTS_QueueJob();
    System.debug('GTS_QueueJob****' + queue);
    queue.enqueueJob(jobRecProcessList);

    gtsProcessSharingLogic(jobRecList);
  }

  public void onBeforeUpdate(
    List<iCare_Job__c> jobList,
    Map<Id, iCare_Job__c> oldJobMap
  ) {
  }

  public void onAfterUpdate(
    List<iCare_Job__c> jobList,
    Map<Id, iCare_Job__c> oldJobMap
  ) {
    Map<String, List<iCare_Job__c>> jobsByRecordType = new GTS_Job()
      .getByRecordTypeGroup(jobList);
    iCare_JobId_Interface service = null;

    for (String recordTypeDeveloperName : jobsByRecordType.keySet()) {
      service = strategyServices.get(recordTypeDeveloperName);
      if (service != null) {
        service.updatePortalStatusValues(
          (List<iCare_Job__c>) jobsByRecordType.get(recordTypeDeveloperName),
          oldJobMap
        );
      }
    }
    //updatePortalStatusValues(jobList, oldJobMap);

    List<iCare_Job__c> jobProcessList = new List<iCare_Job__c>();
    for (iCare_Job__c job : jobList) {
      if (
        job.iCare_Retry_Sync__c != oldJobMap.get(job.Id).iCare_Retry_Sync__c
      ) {
        jobProcessList.add(job);
      }
    }
    GTS_QueueJob queue = new GTS_QueueJob();
    queue.enqueueJob(jobProcessList);
  }

  // match contactonly by email, if multiple contacts exist with the same email, then match by first and lastname
  private List<User> matchContacts(
    Map<Id, List<iCare_JobTriggerHandler.ContactInfo>> accountIdsWithContactInfo,
    List<iCare_Job__c> jobsWithExternalContacts
  ) {
    //Construct share records for contacts on external jobs

    List<Id> accountIds = new List<Id>();
    List<Contact> relatedContacts = new List<Contact>();
    List<Id> contactIds = new List<Id>();
    MAP<ID, MAP<String, List<Contact>>> accountEmailContactMap = new Map<ID, MAP<String, List<Contact>>>();
    String dynamicSOQL = 'SELECT Id,Email, firstname, lastname, AccountId FROM Contact WHERE ';

    for (iCare_Job__c jobRecord : jobsWithExternalContacts) {
      List<ContactInfo> contactInformation = accountIdsWithContactInfo.get(
        jobRecord.iCare_Supplier__c
      );
      for (ContactInfo contactInfo : contactInformation) {
        dynamicSOQL +=
          '(Email = \'' +
          String.escapeSingleQuotes(contactInfo.Email) +
          '\' AND AccountId = \'' +
          String.escapeSingleQuotes(jobRecord.iCare_Supplier__c) +
          '\') OR ';
      }
      accountIds.add(jobRecord.iCare_Supplier__c);
    }
    //Remove final 'OR' statement
    dynamicSOQL = dynamicSOQL.substring(0, dynamicSOQL.length() - 3);
    try {
      relatedContacts = Database.query(dynamicSOQL);
    } catch (QueryException qe) {
      // Handle inaccessible fields
      relatedContacts = new List<Contact>();
    }

    for (Contact c : relatedContacts) {
      if (!accountEmailContactMap.containsKey(c.AccountId)) {
        accountEmailContactMap.put(
          c.accountID,
          new Map<String, List<contact>>()
        );
        accountEmailContactMap.get(c.accountID)
          .put(c.email, new List<Contact>{ c });
      } else {
        if (accountEmailContactMap.get(c.accountID).containsKey(c.email)) {
          accountEmailContactMap.get(c.accountID).get(c.email).add(c);
        } else {
          accountEmailContactMap.get(c.accountID)
            .put(c.email, new List<Contact>{ c });
        }
      }
    }

    for (Id key : accountEmailContactMap.keySet()) {
      MAP<String, List<Contact>> emailContactMap = accountEmailContactMap.get(
        key
      );
      for (String emailKey : emailContactMap.keySet()) {
        if (emailContactMap.get(emailKey).size() == 1) {
          contactIds.add(emailContactMap.get(emailKey)[0].id);
        } else {
          List<ContactInfo> contactInformation = accountIdsWithContactInfo.get(
            key
          );
          for (ContactInfo contactWithName : contactInformation) {
            List<Contact> contactRecords = emailContactMap.get(emailKey);
            for (Contact contactRecord : contactRecords) {
              if (
                (contactRecord.FirstName == contactWithName.FirstName ||
                contactRecord.FirstName == null &&
                contactWithName.FirstName == null) &&
                contactRecord.LastName.equals(contactWithName.LastName) &&
                contactRecord.Email.equals(contactWithName.Email)
              ) {
                contactIds.add(contactRecord.Id);
              }
            }
          }
        }
      }
    }
    List<User> usersToShareWith = [
      SELECT Id, AccountId
      FROM User
      WHERE
        ContactId IN :contactIds
        AND IsActive = TRUE
        AND IsPortalEnabled = TRUE
        AND AccountId IN :accountIds
    ];

    return usersToShareWith;
  }

  private static void gtsProcessSharingLogic(List<iCare_Job__c> jobRecList){
    List<String> gtsJobRecordTypes = new List<String> {'GTS_Certificate_of_Conformity', 'GTS_Commercial_Service', 'GTS_Registration_License_Product_Certificate'};

    Map<Id, RecordType> recordTypes = new Map<Id,RecordType>([SELECT Id FROM RecordType WHERE DeveloperName IN :gtsJobRecordTypes]);
    List<Id> jobsToProcessIds = new List<Id>();
    for(iCare_Job__c job : jobRecList){
      if(recordTypes.keySet().contains(job.RecordTypeId) && String.isNotBlank(job.iCare_Supplier__c)){
        jobsToProcessIds.add(job.Id);
      }
    }
    if(!jobsToProcessIds.isEmpty()){
      GTSJobSharingEngineQueueable jobSharingEngineQueueable = new GTSJobSharingEngineQueueable(jobsToProcessIds, GTSJobSharingEngineQueueable.OPERATION_TYPE.JOB_INSERT);
      System.enqueueJob(jobSharingEngineQueueable);
    }
  }
}