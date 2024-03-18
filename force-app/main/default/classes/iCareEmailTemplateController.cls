public with sharing class iCareEmailTemplateController {
  public String fieldsToQuery { get; set; }
  public String currentId { get; set; }
  public String customLabelValue { get; set; }
  public String currentRecordStatus { get; set; }
  public String cachePartitionKey { get; set; }
  public String cachePartitionValue { get; set; }
  public String cachePartitionName { get; set; }

  public String getMergedText() {
    currentRecordStatus = currentRecordStatus == null
      ? 'test'
      : currentRecordStatus;
    iCareEmailTemplate__mdt[] etList = [
      SELECT
        Id,
        MasterLabel,
        Custom_Label__c,
        Fields_Query__c,
        GTS_Cache_Partition_Key__c,
        GTS_Cache_Partition_Name__c
      FROM iCareEmailTemplate__mdt
      WHERE masterlabel = :currentRecordStatus
      WITH SECURITY_ENFORCED
    ];
    iCareEmailTemplate__mdt et = etList.size() > 0
      ? etList[0]
      : new iCareEmailTemplate__mdt();
    customLabelValue = System.Label.get('', et.Custom_Label__c);
    //Sobject objectRecord;
    fieldsToQuery = et.Fields_Query__c;
    cachePartitionKey = et.GTS_Cache_Partition_Key__c;
    cachePartitionName = et.GTS_Cache_Partition_Name__c;
    List<String> fieldsToMerge = new List<String>();
    if (cachePartitionKey != null) {
      cachePartitionValue = GTS_PlatformCacheController.getValueForKey(
        cachePartitionKey,
        cachePartitionName
      );
      if (cachePartitionValue != null) {
        fieldsToMerge.add(cachePartitionValue);
      }
    }
    List<String> fieldsToQueryList = fieldsToQuery.split(',');
    sObject objectRecord;
    String objectType = '';
    if (currentId != null) {
      ID objectId = Id.valueOf(currentId);
      objectType = objectId.getSObjectType().getDescribe().getName();
    } else {
      objectType = 'iCare_Job__c';
    }

    if (currentRecordStatus != 'test' && currentId != null) {
      Sobject[] objectRecords = Database.query(
        'SELECT ' +
        String.escapeSingleQuotes(fieldsToQuery) +
        ' FROM ' +
        String.escapeSingleQuotes(objectType) +
        ' WHERE Id = \'' +
        String.escapeSingleQuotes(currentId) +
        '\''
      );

      objectRecord = objectRecords.size() > 0
        ? objectRecords[0]
        : (sObject) Type.forName(objectType).newInstance();
    } else {
      objectRecord = (sObject) Type.forName(objectType).newInstance();
    }

    for (String fieldToQuery : fieldsToQueryList) {
      String mergeField;
      if (fieldToQuery.indexOf('__r') != -1) {
        List<String> relationObjects = fieldToQuery.split('\\.');
        sObject objectAux;
        for (String referencedField : relationObjects) {
          if (referencedField != relationObjects[relationObjects.size() - 1]) {
            if (referencedField == relationObjects[0]) {
              objectAux = objectRecord.getSObject(referencedField);
            } else {
              objectAux = objectAux.getSObject(referencedField);
            }
          } else {
            mergeField = objectAux.get(referencedField) == null
              ? ''
              : objectAux.get(referencedField) + '';
            fieldsToMerge.add(mergefield);
          }
        }
      } else {
        mergeField = objectRecord.get(fieldToQuery) == null
          ? ''
          : objectRecord.get(fieldToQuery) + '';
        fieldsToMerge.add(mergefield);
      }
    }
    return String.format(customLabelValue, fieldsToMerge);
  }
}