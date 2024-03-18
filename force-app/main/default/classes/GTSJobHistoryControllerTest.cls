@isTest
public with sharing class GTSJobHistoryControllerTest {
  public static final String REGISTRATION_LICENSE_JOB_RECORD_TYPE_DEVELOPER_NAME = GTSJobHistoryController.REGISTRATION_LICENSE_JOB_RECORD_TYPE_DEVELOPER_NAME; // Originally 'GTS_Registration_License_Product_Certificate'

  @TestSetup
  public static void makeData() {
    // Get Job RecordTypes
    RecordType jobRecordTypeRL = [
      SELECT Id
      FROM RecordType
      WHERE
        DeveloperName = :REGISTRATION_LICENSE_JOB_RECORD_TYPE_DEVELOPER_NAME
        AND SobjectType = 'iCare_Job__c'
    ];

    RecordType jobRecordTypeCOC = [
      SELECT Id
      FROM RecordType
      WHERE
        DeveloperName = 'GTS_Certificate_of_Conformity'
        AND SobjectType = 'iCare_Job__c'
    ];

    // Create Jobs
    List<iCare_Job__c> listOfJobsToInsert = new List<iCare_Job__c>();

    iCare_Job__c jobRL = new iCare_Job__c(
      RecordTypeId = jobRecordTypeRL.Id,
      iCare_Sample_Description__c = 'Registration License'
    );

    iCare_Job__c jobCOC = new iCare_Job__c(
      RecordTypeId = jobRecordTypeCOC.Id,
      iCare_Sample_Description__c = 'Certificate of Conformity'
    );

    iCare_Job__c jobATS = new iCare_Job__c(
      RecordTypeId = jobRecordTypeRL.Id,
      iCare_Sample_Description__c = 'All TimeStamps'
    );

    listOfJobsToInsert.add(jobRL);
    listOfJobsToInsert.add(jobCOC);
    listOfJobsToInsert.add(jobATS);

    insert listOfJobsToInsert;

    // Create Job Timestamps
    List<icare_Job_Timestamp__c> listOfJobTimestampsToInsert = new List<icare_Job_Timestamp__c>();

    icare_Job_Timestamp__c jobTimestampRL = new icare_Job_Timestamp__c(
      iCare_Job__c = jobRL.Id,
      iCare_External_Id__c = '123',
      iCare_Job_Status__c = 'Accepted',
      iCare_Job_Timestamp__c = datetime.now()
    );

    icare_Job_Timestamp__c jobTimestampCOC = new icare_Job_Timestamp__c(
      iCare_Job__c = jobCOC.Id,
      iCare_External_Id__c = '456',
      iCare_Job_Status__c = 'Accepted',
      iCare_Job_Timestamp__c = datetime.now()
    );

    icare_Job_Timestamp__c jobTimestampATS = new icare_Job_Timestamp__c(
      iCare_Job__c = jobATS.Id,
      iCare_External_Id__c = '789',
      iCare_Job_Status__c = 'Accepted',
      iCare_Job_Timestamp__c = datetime.now()
    );

    listOfJobTimestampsToInsert.add(jobTimestampRL);
    listOfJobTimestampsToInsert.add(jobTimestampCOC);
    listOfJobTimestampsToInsert.add(jobTimestampATS);

    insert listOfJobTimestampsToInsert;

    // Create Inspection Timestamps
    GTS_Inspection__c inspectionRecordATS = new GTS_Inspection__c(
      GTS_Job__c = jobATS.Id
    );

    insert inspectionRecordATS;

    GTS_Inspection_Timestamp__c inspectionTimeStampATS = new GTS_Inspection_Timestamp__c(
      Name = 'New inspection Timestamp',
      GTS_Inspection__c = inspectionRecordATS.Id,
      GTS_Inspection_Timestamp__c = datetime.now(),
      GTS_Inspection_Status__c = 'Accepted'
    );

    insert inspectionTimeStampATS;

    // Create Shipment(Certificate) Timestamps
    GTS_Certificate__c certificateATS = new GTS_Certificate__c(
      Name = 'New Certificate',
      GTS_Job__c = jobATS.Id
    );

    insert CertificateATS;

    GTS_Certificate_Timestamp__c certificateTimestampATS = new GTS_Certificate_Timestamp__c(
      Name = 'New Certificate Timestamp',
      GTS_Certificate__c = certificateATS.Id,
      GTS_Certificate_Timestamp__c = datetime.now(),
      GTS_Certificate_Status__c = 'Accepted'
    );

    insert certificateTimestampATS;
  }

  @isTest
  public static void testGetJobTimeStampsOnlyPositive() {
    iCare_Job__c jobRecordToTest = [
      SELECT Id
      FROM iCare_Job__c
      WHERE iCare_Sample_Description__c = 'Registration License'
    ];

    String serialsedString = GTSJobHistoryController.getJobTimeStampsOnly(
      jobRecordToTest.Id
    );

    List<GTSJobHistoryController.TimeStampWrapper> dserialisedTimeStampWrappers = (List<GTSJobHistoryController.TimeStampWrapper>) JSON.deserialize(
      serialsedString,
      List<GTSJobHistoryController.TimeStampWrapper>.class
    );

    Assert.areEqual(
      1,
      dserialisedTimeStampWrappers.size(),
      'There should only be 1 item in the deserialised list of job timestamps'
    );
  }

  @isTest
  public static void testGetJobTimeStampsOnlyNegitive() {
    iCare_Job__c jobRecordToTest = [
      SELECT Id
      FROM iCare_Job__c
      WHERE iCare_Sample_Description__c = 'Certificate of Conformity'
    ];

    String serialsedString = GTSJobHistoryController.getJobTimeStampsOnly(
      jobRecordToTest.Id
    );

    List<GTSJobHistoryController.TimeStampWrapper> dserialisedTimeStampWrappers = (List<GTSJobHistoryController.TimeStampWrapper>) JSON.deserialize(
      serialsedString,
      List<GTSJobHistoryController.TimeStampWrapper>.class
    );

    Assert.areEqual(
      0,
      dserialisedTimeStampWrappers.size(),
      'There should not be any items in the deserialised list of job timestamps'
    );
  }

  @isTest
  public static void testGetTimeStamps() {
    iCare_Job__c jobRecordToTest = [
      SELECT Id
      FROM iCare_Job__c
      WHERE iCare_Sample_Description__c = 'All TimeStamps'
    ];

    String serialsedString = GTSJobHistoryController.getTimeStamps(
      jobRecordToTest.Id
    );

    List<GTSJobHistoryController.TimeStampWrapper> dserialisedTimeStampWrappers = (List<GTSJobHistoryController.TimeStampWrapper>) JSON.deserialize(
      serialsedString,
      List<GTSJobHistoryController.TimeStampWrapper>.class
    );

    Assert.areEqual(
      3,
      dserialisedTimeStampWrappers.size(),
      'There should be 3 items in the deserialised list of job timestamps'
    );
  }
}