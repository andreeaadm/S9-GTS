@isTest
public with sharing class iCare_TrackJobsControllerTest {
  @testSetup
  static void setup() {
    // Create a test jobs
    List<iCare_Job__c> listInsertJobs = new List<iCare_Job__c>();

    for (Integer x = 0; x < 10; x++) {
      iCare_Job__c testJob = new iCare_Job__c();
      testJob.iCare_Job_ID__c = 'TUR-IST-2400000' + x;
      testJob.iCare_Job_Description__c = 'Job description test ' + x;

      switch on x {
        when 2, 3, 4 {
          testJob.iCare_Job_Status__c = 'Sample Received';
          testJob.iCare_Job_Status_Portal__c = 'Sample Received';
          testJob.iCare_Job_Pending__c = true;
        }
        when 5, 6 {
          testJob.iCare_Job_Status__c = 'Test in Progress';
          testJob.iCare_Job_Status_Portal__c = 'Test in Progress';
          testJob.iCare_Job_Pending__c = true;
        }
        when 7, 8 {
          testJob.iCare_Job_Status__c = 'Test Report Issued';
          testJob.iCare_Job_Status_Portal__c = 'Test Report Issued';
        }
        when 9 {
          testJob.iCare_Job_Status__c = 'Cancelled';
          testJob.iCare_Job_Status_Portal__c = 'Cancelled';
        }
        when else {
          testJob.iCare_Job_Status__c = 'Job Submitted (iCare)';
          testJob.iCare_Job_Status_Portal__c = 'Job Submitted';
        }
      }

      listInsertJobs.add(testJob);
    }

    insert listInsertJobs;

    //Create Jobs Timestamps
    List<icare_Job_Timestamp__c> listJobsTimestamp = new List<icare_Job_Timestamp__c>();
    for (iCare_Job__c job : [
      SELECT Id, iCare_Job_Status__c, iCare_Job_ID__c, CreatedDate
      FROM iCare_Job__c
    ]) {
      icare_Job_Timestamp__c jobTimestamp = new icare_Job_Timestamp__c();
      jobTimestamp.iCare_Job_Status__c = job.iCare_Job_Status__c;
      jobTimestamp.iCare_Job__c = job.Id;
      jobTimestamp.iCare_Job_Timestamp__c = job.CreatedDate;
      jobTimestamp.iCare_External_Id__c = job.iCare_Job_ID__c;
      jobTimestamp.iCare_Is_Current_State__c = true;
      listJobsTimestamp.add(jobTimestamp);
    }
    insert listJobsTimestamp;
  }
  public static iCare_TrackJobsController.Request createRequest() {
    iCare_TrackJobsController.Request request = new iCare_TrackJobsController.Request();

    request.tableName = 'Track Jobs';
    request.recordLimit = 5000;
    request.isReport = true;
    request.daysToSearch = 30;

    return request;
  }

  @isTest
  static void test_GetJobsAll() {
    iCare_TrackJobsController.Request request = createRequest();
    request.startDate = Date.today().addDays(-1);
    request.endDate = Date.today().addDays(1);
    Test.startTest();
    iCare_TrackJobsController.DataTableResponse getJobsResponse = iCare_TrackJobsController.getTableData(
      request
    );
    Test.stopTest();

    // Verify the expected results
    /*System.assertEquals(
      10,
      getJobsResponse.lstJobRecords.size(),
      'The number of records should be 10'
    );
    System.assert(
      getJobsResponse.lstDataTableColumns.size() > 0,
      'Colums should be returned'
    );*/
  }

  @isTest
  static void test_GetJobsRecordLimit() {
    iCare_TrackJobsController.Request request = createRequest();
    request.recordLimit = 4;
    Test.startTest();
    iCare_TrackJobsController.DataTableResponse getJobsResponse = iCare_TrackJobsController.getTableData(
      request
    );
    Test.stopTest();

    // Verify the expected results
    System.assertEquals(
      4,
      getJobsResponse.lstJobRecords.size(),
      'The number of records should be 4'
    );
  }

  @isTest
  static void test_GetTotalJobs() {
    iCare_TrackJobsController.Request request = createRequest();
    Test.startTest();
    Integer totalRecords = iCare_TrackJobsController.totalRecords(request);
    Test.stopTest();

    // Verify the expected results
    //System.assertEquals(10, totalRecords, 'The number of records should be 10');
  }

  @isTest
  static void test_GetTotalReports() {
    iCare_TrackJobsController.Request request = createRequest();
    request.tableName = 'View Reports';
    Test.startTest();
    Integer totalRecords = iCare_TrackJobsController.totalRecords(request);
    Test.stopTest();

    // Verify the expected results
    System.assertEquals(3, totalRecords, 'The number of records should be 3');
  }

  @isTest
  static void test_JobsOffset() {
    iCare_TrackJobsController.Request request = createRequest();
    request.vOffset = 6;
    request.vPagesize = 5;
    request.pagination = true;
    Test.startTest();
    iCare_TrackJobsController.DataTableResponse getJobsResponse = iCare_TrackJobsController.getTableData(
      request
    );
    Test.stopTest();

    // Verify the expected results
    /*System.assertEquals(
      4,
      getJobsResponse.lstJobRecords.size(),
      'The number of records should be 4'
    );*/
  }

  @isTest
  static void test_GetNext() {
    iCare_TrackJobsController.Request request = createRequest();

    Test.startTest();
    Integer offset = iCare_TrackJobsController.getNext(5, 5);
    Test.stopTest();

    // Verify the expected results
    System.assertEquals(10, offset, 'The offset should be 10');
  }

  @isTest
  static void test_GetPrevious() {
    iCare_TrackJobsController.Request request = createRequest();

    Test.startTest();
    Integer offset = iCare_TrackJobsController.getPrevious(10, 5);
    Test.stopTest();

    // Verify the expected results
    System.assertEquals(5, offset, 'The offset should be 5');
  }

  @isTest
  static void test_GetJobsTabs() {
    iCare_TrackJobsController.Request request = createRequest();
    Test.startTest();
    iCare_TrackJobsController.DataTableResponse getJobsResponse = iCare_TrackJobsController.getTabData(
      request.tableName
    );
    Test.stopTest();

    // Verify the expected results
    System.assert(
      getJobsResponse.lstContainerTabs.size() > 0,
      'Should return Tabs'
    );
  }

  @isTest
  static void test_GetReportTabs() {
    iCare_TrackJobsController.Request request = createRequest();
    request.tableName = 'View Reports';
    Test.startTest();
    iCare_TrackJobsController.DataTableResponse getJobsResponse = iCare_TrackJobsController.getTabData(
      request.tableName
    );
    Test.stopTest();

    // Verify the expected results
    System.assert(
      getJobsResponse.lstContainerTabs.size() > 0,
      'Should return Tabs'
    );
  }
}