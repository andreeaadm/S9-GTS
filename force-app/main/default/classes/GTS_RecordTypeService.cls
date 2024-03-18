public with sharing virtual class GTS_RecordTypeService {
  public Map<String, iCare_JobId_Interface> getContextMapFromMetadataGrouped() {
    Map<String, iCare_JobId_Interface> result = new Map<String, iCare_JobId_Interface>();
    for (
      iCareRecordTypeToService__mdt recordTypeToServiceMapping : iCareRecordTypeToService__mdt.getAll()
        .values()
    ) {
      String key = recordTypeToServiceMapping.iCare_Record_Type_Group__c;
      if (!result.containsKey(key)) {
        iCare_JobId_Interface value = (iCare_JobId_Interface) (Type.forName(
            recordTypeToServiceMapping.iCare_Apex_Class_Name__c
          )
          .newInstance());
        result.put(key, value);
      }
    }
    return result;
  }

  public Map<String, Queueable> getContextMapFromMetadataGroupedQueable(
    String process
  ) {
    Map<String, Queueable> result = new Map<String, Queueable>();
    for (
      iCareRecordTypeToService__mdt recordTypeToServiceMapping : iCareRecordTypeToService__mdt.getAll()
        .values()
    ) {
      if (recordTypeToServiceMapping.GTS_Process__c == process) {
        String key = recordTypeToServiceMapping.iCare_Record_Type_Group__c;
        if (!result.containsKey(key)) {
          try {
            Queueable value = (Queueable) (Type.forName(
                recordTypeToServiceMapping.iCare_Queable_Apex_Class_Name__c
              )
              .newInstance());
            result.put(key, value);
          } catch (Exception e) {
            result.put(key, null);
          }
        }
      }
    }
    return result;
  }

  public Map<String, String> getGTSrfcType() {
    Map<String, String> result = new Map<String, String>();
    for (
      iCareRecordTypeToService__mdt recordTypeToServiceMapping : iCareRecordTypeToService__mdt.getAll()
        .values()
    ) {
      String key = recordTypeToServiceMapping.iCare_Record_Type_Developer_Name__c;
      String value = recordTypeToServiceMapping.GTS_rfcType__c;
      result.put(key, value);
    }
    return result;
  }

  public List<String> groupsByProcess(String process) {
    Set<String> groups = new Set<String>();
    for (
      iCareRecordTypeToService__mdt recordTypeToServiceMapping : iCareRecordTypeToService__mdt.getAll()
        .values()
    ) {
      if (recordTypeToServiceMapping.GTS_Process__c == process) {
        groups.add(recordTypeToServiceMapping.iCare_Record_Type_Group__c);
      }
    }
    return new List<String>(groups);
  }
}