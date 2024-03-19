/*******************************************************************************************
 * @name         GTSJobLifecycle
 * @author       Globant
 * @description  LWC Controller to get the path for Job Lifecycle
 * @date         12-March-2024
 *******************************************************************************************/
public with sharing class GTSJobLifecycle {
  /**
   * @description Method to query the job and return the Request for inspection number
   * @param jobId
   *
   * @return
   */
  @AuraEnabled(cacheable=true)
  public static String getJobInspectionNumber(Id jobId) {
    iCare_Job__c job = [
      SELECT Id, GTS_Request_for_Inspection_Number__c
      FROM iCare_Job__c
      WHERE Id = :jobId
      WITH SECURITY_ENFORCED
    ];
    return String.isNotBlank(job.GTS_Request_for_Inspection_Number__c)
      ? job.GTS_Request_for_Inspection_Number__c
      : '';
  }
  /**
   * @description Method to get the Status Path of the job
   * @param jobId
   *
   * @return
   */
  @AuraEnabled(cacheable=true)
  public static String getJobStatusPath(Id jobId) {
    List<GTS_Associated_Job_Request__c> associatedJobRequests = [
      SELECT Id, GTS_Job_Request__r.CreatedDate
      FROM GTS_Associated_Job_Request__c
      WHERE
        GTS_Job__c = :jobId
        AND GTS_Job_Request__r.iCare_Draft_ETRF__c = FALSE
        AND GTS_Job_Request__r.GTS_Renewal_Revision__c != NULL
      WITH SECURITY_ENFORCED
      ORDER BY GTS_Job_Request__r.CreatedDate DESC
    ];
    iCare_Job__c job;
    if (associatedJobRequests != null && !associatedJobRequests.isEmpty()) {
      job = [
        SELECT
          Id,
          RecordType.DeveloperName,
          iCare_Job_Status__c,
          GTS_Inspection_Required__c,
          CreatedDate,
          (
            SELECT
              Id,
              iCare_Job_Status__c,
              iCare_Job_Timestamp__c,
              iCare_Is_Current_State__c
            FROM Job_Timestamps__r
            WHERE
              iCare_Job_Timestamp__c > :associatedJobRequests[0]
                .GTS_Job_Request__r.CreatedDate
            ORDER BY iCare_Job_Timestamp__c ASC
          )
        FROM iCare_Job__c
        WHERE Id = :jobId
        WITH SECURITY_ENFORCED
      ];
    } else {
      job = [
        SELECT
          Id,
          RecordType.DeveloperName,
          iCare_Job_Status__c,
          GTS_Inspection_Required__c,
          CreatedDate,
          (
            SELECT
              Id,
              iCare_Job_Status__c,
              iCare_Job_Timestamp__c,
              iCare_Is_Current_State__c
            FROM Job_Timestamps__r
            ORDER BY iCare_Job_Timestamp__c ASC
          )
        FROM iCare_Job__c
        WHERE Id = :jobId
        WITH SECURITY_ENFORCED
      ];
    }
    Map<String, icare_Job_Timestamp__c> timeStampByStatus = getTimeStampByStatus(
      job.Job_Timestamps__r
    );
    Boolean cancelledPath = timeStampByStatus.containsKey(
      System.Label.GTS_Cancelled
    );

    GTS_Job_Lifecycle__mdt jobLifecycleRecord = [
      SELECT
        Label,
        (
          SELECT
            GTS_Status__c,
            toLabel(GTS_Status__c) translatedStatus,
            GTS_Step_Pozition__c
          FROM Job_Lifecycle_Step__r
          ORDER BY GTS_Step_Pozition__c ASC
        )
      FROM GTS_Job_Lifecycle__mdt
      WHERE
        GTS_Job_Record_Type__c = :job.RecordType.DeveloperName
        AND GTS_Is_Cancelled__c = :cancelledPath
        AND GTS_Path_with_inspection__c = :job.GTS_Inspection_Required__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    List<StepWrapper> statusPath = new List<StepWrapper>();
    Integer stepNr = 0;
    Boolean isAfterCurrentStep = false;

    for (
      GTS_Job_Lifecycle_Step__mdt step : jobLifecycleRecord.Job_Lifecycle_Step__r
    ) {
      Boolean isLastStep = (stepNr ==
      (jobLifecycleRecord.Job_Lifecycle_Step__r.size() - 1));
      icare_Job_Timestamp__c timestamp;

      if (timeStampByStatus.containsKey(step.GTS_Status__c)) {
        timestamp = timeStampByStatus.get(step.GTS_Status__c);
      }

      if (cancelledPath) {
        if (timestamp != null) {
          statusPath.add(
            new StepWrapper(
              String.valueOf(step.get('translatedStatus')),
              '100',
              isLastStep,
              timestamp.iCare_Job_Timestamp__c
            )
          );
        }
      } else {
        if (timestamp != null) {
          if (timestamp.iCare_Is_Current_State__c) {
            isAfterCurrentStep = true;
          }
          statusPath.add(
            new StepWrapper(
              String.valueOf(step.get('translatedStatus')),
              '100',
              isLastStep,
              timestamp.iCare_Job_Timestamp__c
            )
          );
        } else {
          if (isAfterCurrentStep) {
            statusPath.add(
              new StepWrapper(
                String.valueOf(step.get('translatedStatus')),
                '0',
                isLastStep
              )
            );
          }
        }
      }

      stepNr++;
    }

    return Json.serialize(statusPath);
  }
  /**
   * @description Method to Map the Timestamps by JobStatus
   * @param timestamps
   *
   * @return
   */
  public static Map<String, icare_Job_Timestamp__c> getTimeStampByStatus(
    List<icare_Job_Timestamp__c> timestamps
  ) {
    Map<String, icare_Job_Timestamp__c> timestampByStatus = new Map<String, icare_Job_Timestamp__c>();
    for (icare_Job_Timestamp__c timestamp : timestamps) {
      timestampByStatus.put(timestamp.iCare_Job_Status__c, timestamp);
    }
    return timestampByStatus;
  }

  class StepWrapper {
    String name;
    String ringVariant;
    String ringValue;
    Boolean isLastStep;
    String timestamp;
    /**
     * @description Constructor for StepWrapper
     * @param name
     * @param ringValue
     * @param isLastStep
     * @param timestamp
     */
    StepWrapper(
      String name,
      String ringValue,
      Boolean isLastStep,
      Datetime timestamp
    ) {
      this.name = name;
      this.ringVariant = 'base-autocomplete';
      this.ringValue = ringValue;
      this.isLastStep = isLastStep;
      this.timestamp = timestamp.format('yyyy-MM-dd HH:mm:ss');
    }
    /**
     * @description Constructor for StepWrapper
     * @param name
     * @param ringValue
     * @param isLastStep
     */
    StepWrapper(String name, String ringValue, Boolean isLastStep) {
      this.name = name;
      this.ringVariant = 'base-autocomplete';
      this.ringValue = ringValue;
      this.isLastStep = isLastStep;
    }
  }
}