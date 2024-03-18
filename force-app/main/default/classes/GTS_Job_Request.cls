public with sharing class GTS_Job_Request extends GTS_Object {
  private iCare_Job_Request__c jobRecord;

  public GTS_Job_Request() {
  }

  public GTS_Job_Request(
    Set<Id> fullSobjectList,
    Schema.SObjectType objectType
  ) {
    super(fullSobjectList, objectType);
  }

  public GTS_Job_Request(iCare_Job_Request__c jobRecordParam) {
    super(jobRecordParam);
    this.recordTypeId = ((iCare_Job_Request__c) this.record).RecordTypeId;
  }

  public override List<sObject> getSObjectListById() {
    this.sObjectMap = new Map<Id, GTS_Certificate__c>(
      [
        SELECT Id, GTS_Job__c
        FROM GTS_Certificate__c
        WHERE id IN :sObjectListID
        WITH SECURITY_ENFORCED
      ]
    );
    this.sObjectList = this.sObjectMap.values();
    return this.sObjectList;
  }

  public override Map<String, List<sObject>> getByRecordTypeGroup(
    List<sObject> recordList
  ) {
    Map<String, List<sObject>> recordTypeMap = new Map<String, List<sObject>>();
    Map<Id, String> recordTypeIdsToDeveloperNames = new Map<Id, String>();

    for (RecordType rt : [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE SObjectType = 'iCare_Job_Request__c'
      WITH SECURITY_ENFORCED
    ]) {
      if (rt.DeveloperName.contains(GTS_GROUP)) {
        recordTypeIdsToDeveloperNames.put(rt.Id, GTS_GROUP);
      } else {
        recordTypeIdsToDeveloperNames.put(rt.Id, ICARE_GROUP);
      }
    }

    for (SObject jobRec : recordList) {
      Id recordTypeId = ((iCare_Job_Request__c) jobRec).RecordTypeId;

      if (
        !recordTypeMap.containsKey(
          recordTypeIdsToDeveloperNames.get(recordTypeId)
        )
      ) {
        recordTypeMap.put(
          recordTypeIdsToDeveloperNames.get(recordTypeId),
          new List<iCare_Job_Request__c>()
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
}