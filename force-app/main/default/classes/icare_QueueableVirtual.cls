public with sharing virtual class icare_QueueableVirtual extends GTS_RecordTypeService {
  public List<iCare_Job__c> jobList = new List<iCare_Job__c>();
  public List<iCare_Expert_Query__c> expQueryList = new List<iCare_Expert_Query__c>();
  public List<iCare_Job__c> jobUpdateList = new List<iCare_Job__c>();
  public List<iCare_Expert_Query__c> expQueryUpdateList = new List<iCare_Expert_Query__c>();
  public List<iCare_Integration_Audit_Log__c> auditLogList = new List<iCare_Integration_Audit_Log__c>();
  public List<icare_Job_Request__c> jobRequestList = new List<icare_Job_Request__c>();
  public List<icare_Job_Request__c> jobRequestUpdateList = new List<icare_Job_Request__c>();
  private String client_Id;
  private String client_Secret;
  private String endpoint_service_url;
  private String method;
  private String namedCredentials;
  public Map<String, String> headersMap;
  public icare_Job_Request__c jobReq;
  public String origin;
  private String response;
  private Integer intStatusCode;
  public iCare_Integration_Details__mdt integrationDetails;

  public icare_QueueableVirtual() {
  }

  public icare_QueueableVirtual(
    List<iCare_Job__c> jobList,
    List<iCare_Job__c> jobUpdateList,
    List<iCare_Integration_Audit_Log__c> auditLogList
  ) {
    super();
    this.jobList.addAll(jobList);
    this.jobUpdateList.addAll(jobUpdateList);
    this.auditLogList.addAll(auditLogList);
  }

  public icare_QueueableVirtual(
    List<icare_Job_Request__c> jobRequestList,
    List<icare_Job_Request__c> jobRequestUpdateList,
    List<iCare_Integration_Audit_Log__c> auditLogList
  ) {
    super();
    this.jobRequestList.addAll(jobRequestList);
    this.jobRequestUpdateList.addAll(jobRequestUpdateList);
    this.auditLogList.addAll(auditLogList);
  }

  public void setLists(
    List<iCare_Job__c> jobList,
    List<iCare_Job__c> jobUpdateList,
    List<iCare_Integration_Audit_Log__c> auditLogList
  ) {
    this.jobList.addAll(jobList);
    this.jobUpdateList.addAll(jobUpdateList);
    this.auditLogList.addAll(auditLogList);
  }

  public void setLists(
    List<iCare_Expert_Query__c> expQueryList,
    List<iCare_Expert_Query__c> expQueryUpdateList,
    List<iCare_Integration_Audit_Log__c> auditLogList
  ) {
    this.expQueryList.addAll(expQueryList);
    this.expQueryUpdateList.addAll(expQueryUpdateList);
    this.auditLogList.addAll(auditLogList);
  }

  public void setLists(
    List<icare_Job_Request__c> jobRequestList,
    List<icare_Job_Request__c> jobRequestUpdateList,
    List<iCare_Integration_Audit_Log__c> auditLogList
  ) {
    this.jobRequestList.addAll(jobRequestList);
    this.jobRequestUpdateList.addAll(jobRequestUpdateList);
    this.auditLogList.addAll(auditLogList);
  }

  public void setHeaders(String jobOrigin) {
    this.origin = jobOrigin;
    headersMap = new Map<String, String>();
    this.integrationDetails = iCare_Integration_Details__mdt.getInstance(
      jobOrigin
    );
    this.client_Id = Test.isRunningTest()
      ? iCare_CallOutUtilityClass.CLIENT_ID
      : this.integrationDetails.Client_Id__c;
    this.client_Secret = Test.isRunningTest()
      ? iCare_CallOutUtilityClass.CLIENT_SECRET
      : this.integrationDetails.Client_Secret__c;
    this.endpoint_service_url = Test.isRunningTest()
      ? iCare_CallOutUtilityClass.ENDPOINT_SERVICE_URL_CREATE_JOB
      : this.integrationDetails.Endpoint_Service_Url__c;
    this.method = Test.isRunningTest()
      ? iCare_CallOutUtilityClass.POST_METHOD
      : this.integrationDetails.Http_Method__c;
    this.namedCredentials = Test.isRunningTest()
      ? iCare_CallOutUtilityClass.NAMED_CREDENTIALS
      : this.integrationDetails.Named_Credentials__c;

    headersMap.put('client_id', client_Id);
    headersMap.put('client_secret', client_Secret);
  }

  public virtual icare_Job_Request__c getJobRequest() {
    return new icare_Job_Request__c();
  }

  public String callOut(String payLoad) {
    this.response = iCare_CallOutUtilityClass.basicAuthCallout(
      endpoint_service_url,
      payLoad,
      method,
      headersMap,
      namedCredentials
    );
    return this.response;
  }

  public Integer statusCode() {
    this.intStatusCode = Integer.valueOf(
      response.substringBefore(':responseBody:')
    );
    return this.intStatusCode;
  }
}