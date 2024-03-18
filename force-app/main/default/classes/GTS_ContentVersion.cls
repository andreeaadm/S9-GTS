public with sharing class GTS_ContentVersion extends GTS_Object {
  private Map<Id, ContentVersion> GTS_ContentVersionByContentDocumentID;
  public GTS_ContentVersion(
    Set<Id> fullSobjectList,
    Schema.SObjectType objectType
  ) {
    super(fullSobjectList, objectType);
  }

  public GTS_ContentVersion(Set<Id> fullSobjectList) {
    super(fullSobjectList, Schema.ContentVersion.SObjectType);
  }

  public Map<Id, ContentVersion> getGTS_ContentVersionByContentDocumentID() {
    return this.GTS_ContentVersionByContentDocumentID;
  }

  public override List<sObject> getSObjectListById() {
    this.sObjectMap = new Map<Id, ContentVersion>(
      [
        SELECT
          Id,
          ContentDocumentId,
          GTS_Name__c,
          GTS_Path__c,
          Title,
          PathOnClient,
          VersionData,
          GTS_Is_Visible__c,
          GTS_Document_Type__c,
          GTS_Document_Type_Versioning_Behaviour__c,
          GTS_Document_Super_Type__c,
          GTS_CreatedTimeStamp__c,
          GTS_Timestamp__c,
          GTS_External_Id__c
        FROM ContentVersion
        WHERE ContentDocumentId IN :fullSobjectList
        WITH SECURITY_ENFORCED
      ]
    );
    this.GTS_ContentVersionByContentDocumentID = new Map<Id, ContentVersion>();
    for (Id recordId : sObjectMap.keySet()) {
      ContentVersion contentVersion = (ContentVersion) sObjectMap.get(recordId);
      this.GTS_ContentVersionByContentDocumentID.put(
        contentVersion.ContentDocumentId,
        contentVersion
      );
    }
    this.sObjectList = this.sObjectMap.values();
    return this.sObjectList;
  }

  public override Set<Id> getRelatedJobsID() {
    return null;
  }

  public override Map<String, List<sObject>> getByRecordTypeGroup(
    List<sObject> recordList
  ) {
    return null;
  }
}