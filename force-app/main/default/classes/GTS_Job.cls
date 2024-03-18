public with sharing class GTS_Job extends GTS_Object {
  private Set<Id> jobsId;
  private Map<Id, iCare_Job__c> gtsJobs { get; set; }
  private Map<Id, list<Id>> documentsByJob;
  private Map<Id, list<String>> documentsSuperTypeByJob;
  private iCare_Job__c jobRecord;

  public GTS_Job() {
    this.jobsId = new Set<Id>();
    this.gtsJobs = new Map<Id, iCare_Job__c>();
    this.documentsByJob = new Map<Id, list<Id>>();
    this.documentsSuperTypeByJob = new Map<Id, list<String>>();
  }

  public GTS_Job(iCare_Job__c jobRecordParam) {
    super(jobRecordParam);
    this.recordTypeId = ((iCare_Job__c) this.record).RecordTypeId;
  }

  public GTS_job(Map<Id, iCare_Job__c> jobs) {
    this.gtsJobs = jobs;
  }

  public Map<Id, iCare_Job__c> GetGtsJobsByID(Set<Id> jobsID) {
    this.gtsJobs = new Map<ID, iCare_Job__c>(
      [
        SELECT Id, Name, CurrencyIsoCode, RecordTypeId
        FROM iCare_Job__c
        WHERE id IN :jobsID
        WITH SECURITY_ENFORCED
      ]
    );
    return this.gtsJobs;
  }

  public Map<Id, iCare_Job__c> GetGtsJobsByID() {
    return this.GetGtsJobsByID(this.jobsId);
  }

  public void addAll(Set<Id> jobsID) {
    this.jobsId.addAll(jobsID);
  }

  public void add(Id jobID) {
    this.jobsId.add(jobID);
  }

  public Map<Id, list<Id>> getDocumentsByJob() {
    return this.documentsByJob;
  }

  public Map<Id, list<String>> getDocumentsSuperTypeByJob() {
    return this.documentsSuperTypeByJob;
  }

  public void setDocumentsByJob(
    List<ContentDocumentLink> contentDocumentLinks,
    GTS_Certificate certificate,
    GTS_Inspection inspection,
    GTS_ContentVersion GTScontentVersion
  ) {
    Set<Id> jobsId = gtsJobs.keySet();
    List<Id> contentDocumentsId = null;
    List<String> contentDocumentSuperType = null;
    for (Id jobId : jobsId) {
      contentDocumentsId = new List<Id>();
      contentDocumentSuperType = new List<String>();
      for (ContentDocumentLink contentLink : contentDocumentLinks) {
        if (
          (certificate != null &&
          certificate.getSObjectMap() != null &&
          certificate.getSObjectMap().get(contentLink.LinkedEntityId) != null &&
          jobId ==
          ((GTS_Certificate__c) certificate.getSObjectMap()
              .get(contentLink.LinkedEntityId))
            .GTS_Job__c) ||
          (inspection != null &&
          inspection.getSObjectMap() != null &&
          inspection.getSObjectMap().get(contentLink.LinkedEntityId) != null &&
          jobId ==
          ((GTS_Inspection__c) inspection.getSObjectMap()
              .get(contentLink.LinkedEntityId))
            .GTS_Job__c)
        ) {
          contentDocumentsId.add(contentLink.ContentDocumentId);
          contentDocumentSuperType.add(
            GTScontentVersion.getGTS_ContentVersionByContentDocumentID()
              .get(contentLink.ContentDocumentId)
              .GTS_Document_Super_Type__c
          );
        }
      }
      documentsByJob.put(jobId, contentDocumentsId);
      documentsSuperTypeByJob.put(jobId, contentDocumentSuperType);
    }
  }

  public override Map<String, List<sObject>> getByRecordTypeGroup(
    List<sObject> recordList
  ) {
    Map<String, List<sObject>> recordTypeMap = new Map<String, List<sObject>>();
    Map<Id, String> recordTypeIdsToDeveloperNames = new Map<Id, String>();

    for (RecordType rt : [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE SObjectType = 'iCare_Job__c'
      WITH SECURITY_ENFORCED
    ]) {
      if (rt.DeveloperName.contains(GTS_GROUP)) {
        recordTypeIdsToDeveloperNames.put(rt.Id, GTS_GROUP);
      } else {
        recordTypeIdsToDeveloperNames.put(rt.Id, ICARE_GROUP);
      }
    }

    for (sObject jobRec : recordList) {
      Id recordTypeId = ((iCare_Job__c) jobRec).RecordTypeId;

      if (
        !recordTypeMap.containsKey(
          recordTypeIdsToDeveloperNames.get(recordTypeId)
        )
      ) {
        recordTypeMap.put(
          recordTypeIdsToDeveloperNames.get(recordTypeId),
          new List<iCare_Job__c>()
        );
      }

      recordTypeMap.get(recordTypeIdsToDeveloperNames.get(recordTypeId))
        .add(jobRec);
    }

    return recordTypeMap;
  }

  public override Set<Id> getRelatedJobsID() {
    return null;
  }

  public override List<sObject> getSObjectListById() {
    return null;
  }
}