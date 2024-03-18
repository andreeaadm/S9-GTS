public with sharing class GTS_Inspection extends GTS_Object {
  public GTS_Inspection(
    Set<Id> fullSobjectList,
    Schema.SObjectType objectType
  ) {
    super(fullSobjectList, objectType);
  }

  public override List<sObject> getSObjectListById() {
    this.sObjectMap = new Map<Id, GTS_Inspection__c>(
      [
        SELECT Id, GTS_Job__c
        FROM GTS_Inspection__c
        WHERE id IN :sObjectListID
        WITH SECURITY_ENFORCED
      ]
    );
    this.sObjectList = this.sObjectMap.values();
    return this.sObjectList;
  }

  public override Set<Id> getRelatedJobsID() {
    this.getSObjectListById();
    if (this.sObjectList != null && this.sObjectList.size() > 0) {
      this.relatedJobsID = new Set<Id>();
      for (sObject certificate : this.sObjectList) {
        this.relatedJobsID.add(((GTS_Inspection__c) certificate).GTS_Job__c);
      }
    }
    return this.relatedJobsID;
  }

  public override Map<String, List<sObject>> getByRecordTypeGroup(
    List<sObject> recordList
  ) {
    return null;
  }
}