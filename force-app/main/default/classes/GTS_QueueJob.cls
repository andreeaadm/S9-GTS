public with sharing class GTS_QueueJob extends GTS_RecordTypeService {
  private Queueable queueableService;

  public GTS_QueueJob() {
  }

  public GTS_QueueJob(Queueable queueable) {
    this.queueableService = queueable;
  }

  public void enqueueExpertQuery(List<iCare_Expert_Query__c> expQueryList) {
    if (!expQueryList.isEmpty()) {
      ((icare_QueueableVirtual) queueableService)
        .setLists(
          expQueryList,
          new List<iCare_Expert_Query__c>(),
          new List<iCare_Integration_Audit_Log__c>()
        );
      System.enqueueJob(queueableService);
    } else {
      this.insertAuditLogError(expQueryList);
    }
  }

  public void enqueueJob(List<iCare_Job__c> jobProcessList) {
    Queueable serviceQueueable = null;
    if (!jobProcessList.isEmpty()) {
      GTS_Job gtsJob = new GTS_Job(jobProcessList[0]);
      String recordGr = gtsJob.getRecordGroup('iCare_Job__c');
      if (gtsJob != null && recordGr != null && recordGr != '') {
        serviceQueueable = this.getContextMapFromMetadataGroupedQueable(
            'iCare_Job__c'
          )
          .get(recordGr);
        if (serviceQueueable != null) {
          ((icare_QueueableVirtual) serviceQueueable)
            .setLists(
              jobProcessList,
              new List<iCare_Job__c>(),
              new List<iCare_Integration_Audit_Log__c>()
            );
          System.enqueueJob(serviceQueueable);
        }
      } else {
        this.insertAuditLogError(jobProcessList);
      }
    }
  }

  public void enqueueJobRequest(List<iCare_Job_Request__c> jobProcessList) {
    Queueable serviceQueueable = null;
    if (!jobProcessList.isEmpty()) {
      GTS_Job_Request gtsJob = new GTS_Job_Request(jobProcessList[0]);
      String recordGr = gtsJob.getRecordGroup('iCare_Job_Request__c');
      System.debug('gtsJob.getRecordGroup()****' + recordGr);
      if (gtsJob != null && recordGr != null && recordGr != '') {
        serviceQueueable = this.getContextMapFromMetadataGroupedQueable(
            'iCare_Job_Request__c'
          )
          .get(recordGr);
        System.debug('serviceQueueable****' + serviceQueueable);
        if (serviceQueueable != null) {
          ((icare_QueueableVirtual) serviceQueueable)
            .setLists(
              jobProcessList,
              new List<iCare_Job_Request__c>(),
              new List<iCare_Integration_Audit_Log__c>()
            );
          System.enqueueJob(serviceQueueable);
        }
      } else {
        this.insertAuditLogError(jobProcessList);
      }
    }
  }

  public void excuteClass(
    List<iCare_Expert_Query__c> expQueryList,
    List<iCare_Integration_Audit_Log__c> integrationAuditLogList,
    List<iCare_Expert_Query__c> expQueryUpdateList,
    QueueableContext context
  ) {
    if (!expQueryList.isEmpty()) {
      ((icare_QueueableVirtual) queueableService)
        .setLists(expQueryList, expQueryUpdateList, integrationAuditLogList);
      queueableService.execute(context);
    } else {
      this.insertAuditLogError(expQueryList);
    }
  }

  public void excuteClass(
    List<iCare_Job__c> jobProcessList,
    List<iCare_Integration_Audit_Log__c> integrationAuditLogList,
    QueueableContext context
  ) {
    Queueable serviceQueueable = null;
    if (!jobProcessList.isEmpty()) {
      GTS_Job gtsJob = new GTS_Job(jobProcessList[0]);
      String recordGr = gtsJob.getRecordGroup('iCare_Job__c');
      if (gtsJob != null && recordGr != null && recordGr != '') {
        serviceQueueable = this.getContextMapFromMetadataGroupedQueable(
            'iCare_Job__c'
          )
          .get(recordGr);
        if (serviceQueueable != null) {
          ((icare_QueueableVirtual) serviceQueueable)
            .setLists(
              jobProcessList,
              new List<iCare_Job__c>(),
              integrationAuditLogList
            );
          serviceQueueable.execute(context);
        }
      } else {
        this.insertAuditLogError(jobProcessList);
      }
    }
  }

  public void excuteClass(
    List<iCare_Job_Request__c> jobProcessList,
    List<iCare_Integration_Audit_Log__c> integrationAuditLogList,
    QueueableContext context
  ) {
    Queueable serviceQueueable = null;
    if (!jobProcessList.isEmpty()) {
      GTS_Job_Request gtsJob = new GTS_Job_Request(jobProcessList[0]);
      String recordGr = gtsJob.getRecordGroup('iCare_Job_Request__c');
      if (gtsJob != null && recordGr != null && recordGr != '') {
        serviceQueueable = this.getContextMapFromMetadataGroupedQueable(
            'iCare_Job_Request__c'
          )
          .get(recordGr);
        if (serviceQueueable != null) {
          ((icare_QueueableVirtual) serviceQueueable)
            .setLists(
              jobProcessList,
              new List<iCare_Job_Request__c>(),
              integrationAuditLogList
            );
          serviceQueueable.execute(context);
        }
      } else {
        this.insertAuditLogError(jobProcessList);
      }
    }
  }

  private void insertAuditLogError(List<iCare_Job__c> jobProcessList) {
    insert new iCare_Integration_Audit_Log__c(
      iCare_Response_Payload__c = 'Error Strategy Definition Groups',
      iCare_Integration_Reference__c = Label.iCare_Job_Request_IntegRef,
      iCare_Job__c = jobProcessList[0].Id,
      iCare_Sync_Status__c = 'Failure'
    );
  }

  private void insertAuditLogError(List<iCare_Expert_Query__c> expQueryList) {
    insert new iCare_Integration_Audit_Log__c(
      iCare_Response_Payload__c = 'Error Strategy Expert Query',
      iCare_Integration_Reference__c = Label.iCare_Job_Request_IntegRef,
      iCare_Expert_Query__c = expQueryList[0].Id,
      iCare_Sync_Status__c = 'Failure'
    );
  }

  private void insertAuditLogError(List<iCare_Job_Request__c> jobProcessList) {
    insert new iCare_Integration_Audit_Log__c(
      iCare_Response_Payload__c = 'Error Strategy Expert Query',
      iCare_Integration_Reference__c = Label.iCare_Job_Request_IntegRef,
      GTS_Job_Request__c = jobProcessList[0].Id,
      iCare_Sync_Status__c = 'Failure'
    );
  }
}