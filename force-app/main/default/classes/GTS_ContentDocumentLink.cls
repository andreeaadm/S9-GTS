public with sharing class GTS_ContentDocumentLink {
  List<ContentDocumentLink> contentDocumentLinks;
  List<ContentVersion> ContentVersionList;
  Set<Id> contentDocumentIDs;
  Set<Id> linkedEntitiesID;
  GTS_Inspection inspection;
  GTS_Certificate certificate;
  GTS_Job job;
  GTS_ContentVersion GTScontentVersion;

  public GTS_ContentDocumentLink(
    List<ContentDocumentLink> contentDocumentLinks
  ) {
    this.contentDocumentLinks = contentDocumentLinks;
    this.linkedEntities();
    contentDocumentIDs = new Set<Id>();
    for (ContentDocumentLink content : this.contentDocumentLinks) {
      contentDocumentIDs.add(content.ContentDocumentId);
    }
    this.GTScontentVersion = new GTS_ContentVersion(contentDocumentIDs);
    this.ContentVersionList = this.GTScontentVersion.getSObjectListById();
    this.setDocumentsByJob();
    if (
      this.documetsSuperTypeByJobToString() != null &&
      this.documetsSuperTypeByJobToString().size() > 0
    ) {
      System.enqueueJob(
        new GTS_DocumentNotificationQueueable(
          this.documetsSuperTypeByJobToString()
        )
      );
    }
  }

  public GTS_ContentDocumentLink(List<ContentVersion> contentVersionList) {
    contentDocumentIDs = new Set<Id>();
    this.ContentVersionList = contentVersionList;
    for (ContentVersion content : contentVersionList) {
      contentDocumentIDs.add(content.ContentDocumentId);
    }
    contentDocumentLinks = [
      SELECT
        Id,
        LinkedEntityId,
        ContentDocumentId,
        IsDeleted,
        SystemModstamp,
        ShareType,
        Visibility
      FROM ContentDocumentLink
      WHERE ContentDocumentId IN :contentDocumentIDs
      WITH SECURITY_ENFORCED
    ];

    this.linkedEntities();
  }

  private void linkedEntities() {
    linkedEntitiesID = new Set<Id>();
    for (ContentDocumentLink contentLink : this.contentDocumentLinks) {
      linkedEntitiesID.add(contentLink.LinkedEntityId);
    }
    this.setRelatedEntities();
  }

  private void setRelatedEntities() {
    if (linkedEntitiesID != null && linkedEntitiesID.size() > 0) {
      this.inspection = new GTS_Inspection(
        linkedEntitiesID,
        Schema.GTS_Inspection__c.SObjectType
      );
      this.certificate = new GTS_Certificate(
        linkedEntitiesID,
        Schema.GTS_Certificate__c.SObjectType
      );
    }
  }

  private void setJobs() {
    this.job = new GTS_Job();
    if (this.certificate.getsObjectListID() != null) {
      this.job.addAll(this.certificate.getRelatedJobsID());
    }
    if (this.inspection.getsObjectListID() != null) {
      this.job.addAll(this.inspection.getRelatedJobsID());
    }
    this.job.GetGtsJobsByID();
  }

  public Map<Id, list<Id>> getDocumentsByJob() {
    return this.job.getDocumentsByJob();
  }

  public Map<Id, list<String>> getDocumentsSuperTypeByJob() {
    return this.job.getDocumentsSuperTypeByJob();
  }

  public List<String> documetsSuperTypeByJobToString() {
    List<String> outputList = new List<String>();
    Map<Id, list<String>> documentsSuperTypeByJob = this.job.getDocumentsSuperTypeByJob();
    for (Id key : documentsSuperTypeByJob.keySet()) {
      List<String> values = documentsSuperTypeByJob.get(key);
      String entry = key + ',' + String.join(values, ',');
      outputList.add(entry);
    }
    return outputList;
  }

  public void setDocumentsByJob() {
    this.setJobs();
    this.job.setDocumentsByJob(
      this.contentDocumentLinks,
      this.certificate,
      this.inspection,
      this.GTScontentVersion
    );
  }
}