public with sharing class GTSJobHistoryController {
  public static final String REGISTRATION_LICENSE_JOB_RECORD_TYPE_DEVELOPER_NAME = 'GTS_Registration_License_Product_Certificate';
  @AuraEnabled(cacheable=true)
  public static String getJobTimeStampsOnly(String jobId) {
    List<TimeStampWrapper> timeStampWrappers = new List<GTSJobHistoryController.TimeStampWrapper>();
    List<TimeStampWrapper> jobTimeStampWrappers = getJobTimeStamps(
      jobId,
      REGISTRATION_LICENSE_JOB_RECORD_TYPE_DEVELOPER_NAME
    );
    if (!jobTimeStampWrappers.isEmpty()) {
      timeStampWrappers.addAll(jobTimeStampWrappers);
    }
    return JSON.serialize(timeStampWrappers);
  }
  @AuraEnabled(cacheable=true)
  public static Boolean isRegistrationJob(String jobId) {
    iCare_Job__c job = [SELECT RecordType.DeveloperName FROM iCare_Job__c WHERE Id= :jobId ];
    return job.RecordType.DeveloperName == REGISTRATION_LICENSE_JOB_RECORD_TYPE_DEVELOPER_NAME;
  }
  @AuraEnabled(cacheable=true)
  public static Boolean isJobCompleted(String jobId) {
    icare_Job_Timestamp__c lastTimeStamp = [
      SELECT Id, iCare_Job_Status__c, iCare_Job_Timestamp__c
      FROM icare_Job_Timestamp__c
      WHERE iCare_Job__c = :jobId
      ORDER BY iCare_Job_Timestamp__c DESC
      LIMIT 1
    ];
    return lastTimeStamp.iCare_Job_Status__c == System.Label.GTS_Complete;
  }


  @AuraEnabled(cacheable=true)
  public static String getJobExistingNumber(String jobId) {
    iCare_Job__c jobRecord = [
      SELECT Id, GTS_Request_for_Inspection_Number__c
      FROM iCare_Job__c
      WHERE Id = :jobId
      LIMIT 1
    ];

    return jobRecord.GTS_Request_for_Inspection_Number__c;
  }
  @AuraEnabled(cacheable=true)
  public static String getAssociatedJobRequest(String jobId) {
    List<GTS_Associated_Job_Request__c> associatedJobRequests = [
      SELECT Id, GTS_Job_Request__c
      FROM GTS_Associated_Job_Request__c
      WHERE GTS_Job__c = :jobId
      AND GTS_Job_Request__r.iCare_Draft_ETRF__c = TRUE
      ORDER BY GTS_Job_Request__r.CreatedDate DESC
      LIMIT 1
    ];
    String returnedValue = '';
    if(associatedJobRequests != null && !associatedJobRequests.isEmpty()) {
      returnedValue = associatedJobRequests[0].GTS_Job_Request__c;
    }
    return returnedValue;
  }
  @AuraEnabled(cacheable=true)
  public static String getTimeStamps(String jobId) {
    List<TimeStampWrapper> timeStampWrappers = new List<GTSJobHistoryController.TimeStampWrapper>();
    List<TimeStampWrapper> jobTimeStampWrappers = getJobTimeStamps(jobId, null);
    if (!jobTimeStampWrappers.isEmpty()) {
      timeStampWrappers.addAll(jobTimeStampWrappers);
    }
    List<TimeStampWrapper> inspectionTimeStampWrappers = getInspectionTimeStamps(
      jobId
    );
    if (!inspectionTimeStampWrappers.isEmpty()) {
      timeStampWrappers.addAll(inspectionTimeStampWrappers);
    }
    List<TimeStampWrapper> shipmentTimeStampWrappers = getShipmentTimeStamps(
      jobId
    );
    if (!shipmentTimeStampWrappers.isEmpty()) {
      timeStampWrappers.addAll(shipmentTimeStampWrappers);
    }

    timeStampWrappers.sort();
    return JSON.serialize(timeStampWrappers);
  }

  public static List<TimeStampWrapper> getJobTimeStamps(
    String jobId,
    String jobRecordTypeDeveloperName
  ) {
    List<icare_Job_Timestamp__c> timestamps = new List<icare_Job_Timestamp__c>();
    if (
      jobRecordTypeDeveloperName !=
      REGISTRATION_LICENSE_JOB_RECORD_TYPE_DEVELOPER_NAME
    ) {
      System.debug('IF');
      timestamps = [
        SELECT Id, iCare_Job_Status__c, iCare_Job_Timestamp__c
        FROM icare_Job_Timestamp__c
        WHERE iCare_Job__c = :jobId
        WITH SYSTEM_MODE
        ORDER BY iCare_Job_Timestamp__c DESC
      ];
      System.debug(timestamps.size());
    } else if (
      jobRecordTypeDeveloperName ==
      REGISTRATION_LICENSE_JOB_RECORD_TYPE_DEVELOPER_NAME
    ) {
      timestamps = [
        SELECT Id, iCare_Job_Status__c, iCare_Job_Timestamp__c
        FROM icare_Job_Timestamp__c
        WHERE
          iCare_Job__c = :jobId
          AND iCare_Job__r.RecordType.DeveloperName = :REGISTRATION_LICENSE_JOB_RECORD_TYPE_DEVELOPER_NAME
        ORDER BY iCare_Job_Timestamp__c DESC
      ];
    }
    List<TimeStampWrapper> timeStampWrappers = new List<GTSJobHistoryController.TimeStampWrapper>();
    for (icare_Job_Timestamp__c jobTimestamp : timestamps) {
      timeStampWrappers.add(new TimeStampWrapper(jobTimestamp));
    }
    return timeStampWrappers;
  }
  public static List<TimeStampWrapper> getInspectionTimeStamps(String jobId) {
    List<GTS_Inspection_Timestamp__c> timestamps = [
      SELECT
        Id,
        GTS_Inspection_Status__c,
        GTS_Inspection_Timestamp__c,
        GTS_Inspection__r.GTS_IRN__c
      FROM GTS_Inspection_Timestamp__c
      WHERE GTS_Inspection__r.GTS_Job__c = :jobId
      ORDER BY GTS_Inspection_Timestamp__c DESC
    ];

    List<TimeStampWrapper> timeStampWrappers = new List<GTSJobHistoryController.TimeStampWrapper>();
    for (GTS_Inspection_Timestamp__c inspectionTimestamp : timestamps) {
      timeStampWrappers.add(new TimeStampWrapper(inspectionTimestamp));
    }
    return timeStampWrappers;
  }
  public static List<TimeStampWrapper> getShipmentTimeStamps(String jobId) {
    List<GTS_Certificate_Timestamp__c> timestamps = [
      SELECT
        Id,
        GTS_Certificate_Status__c,
        GTS_Certificate_Timestamp__c,
        GTS_Certificate__r.GTS_External_Id__c
      FROM GTS_Certificate_Timestamp__c
      WHERE GTS_Certificate__r.GTS_Job__c = :jobId
      ORDER BY GTS_Certificate_Timestamp__c DESC
    ];

    List<TimeStampWrapper> timeStampWrappers = new List<GTSJobHistoryController.TimeStampWrapper>();
    for (GTS_Certificate_Timestamp__c certificateTimestamp : timestamps) {
      timeStampWrappers.add(new TimeStampWrapper(certificateTimestamp));
    }
    return timeStampWrappers;
  }

  @TestVisible
  public class TimeStampWrapper implements Comparable {
    public String id;
    public String status;
    public Datetime timeStampDate;
    public String entryName;
    public String irnNr;
    public String shipmentNr;

    public TimeStampWrapper(icare_Job_Timestamp__c jobTimestamp) {
      id = jobTimestamp.Id;
      status = jobTimestamp.iCare_Job_Status__c;
      timeStampDate = jobTimestamp.iCare_Job_Timestamp__c;
      entryName = 'Job';
      irnNr = '-';
      shipmentNr = '-';
    }
    public TimeStampWrapper(GTS_Inspection_Timestamp__c inspectionTimestamp) {
      id = inspectionTimestamp.Id;
      status = inspectionTimestamp.GTS_Inspection_Status__c;
      timeStampDate = Datetime.valueOf(
        inspectionTimestamp.GTS_Inspection_Timestamp__c
      );
      entryName = 'Inspection';
      irnNr = inspectionTimestamp.GTS_Inspection__r.GTS_IRN__c;
      shipmentNr = '-';
    }

    public TimeStampWrapper(GTS_Certificate_Timestamp__c certificateTimestamp) {
      id = certificateTimestamp.Id;
      status = certificateTimestamp.GTS_Certificate_Status__c;
      timeStampDate = Datetime.valueOf(
        certificateTimestamp.GTS_Certificate_Timestamp__c
      );
      entryName = 'Shipment';
      irnNr = '-';
      shipmentNr = certificateTimestamp.GTS_Certificate__r.GTS_External_Id__c;
    }

    public Integer compareTo(Object compareTo) {
      TimeStampWrapper compareToTSWrapper = (TimeStampWrapper) compareTo;
      Integer returnValue = 0;
      if (timeStampDate <= compareToTSWrapper.timeStampDate) {
        // both wrappers have null Amounts
        returnValue = 1;
      } else if (timeStampDate > compareToTSWrapper.timeStampDate) {
        returnValue = -1;
      }
      return returnValue;
    }
  }
}