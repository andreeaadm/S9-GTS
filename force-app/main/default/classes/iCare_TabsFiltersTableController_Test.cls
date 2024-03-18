/*
 * ________________________________________________________________________________________________
 * Class to test the iCare_FileDownloadController Class
 * ________________________________________________________________________________________________
 * @author       Andres Morales
 * @created      2023-05-08
 * ________________________________________________________________________________________________
 * @changes
 * 2023-06-30    Remove getJobsByStatus calls, functionality mada a client level
 * ________________________________________________________________________________________________
 */
@isTest
private class iCare_TabsFiltersTableController_Test {
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
          //testJob.iCare_Job_Status_Portal__c = 'Sample Received';
          testJob.iCare_Job_Pending__c = true;
        }
        when 5, 6 {
          testJob.iCare_Job_Status__c = 'Test in Progress';
          //testJob.iCare_Job_Status_Portal__c = 'Test in Progress';
          testJob.iCare_Job_Pending__c = true;
        }
        when 7, 8 {
          testJob.iCare_Job_Status__c = 'Test Report Issued';
          //testJob.iCare_Job_Status_Portal__c = 'Test Report Issued';
        }
        when 9 {
          testJob.iCare_Job_Status__c = 'Cancelled';
          //testJob.iCare_Job_Status_Portal__c = 'Cancelled';
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
      SELECT Id, iCare_Job_ID__c, CreatedDate
      FROM iCare_Job__c
    ]) {
      icare_Job_Timestamp__c jobTimestamp = new icare_Job_Timestamp__c();
      jobTimestamp.iCare_Job_Status__c = 'Job Submitted';
      jobTimestamp.iCare_Job__c = job.Id;
      jobTimestamp.iCare_Job_Timestamp__c = job.CreatedDate;
      jobTimestamp.iCare_External_Id__c = job.iCare_Job_ID__c;
      jobTimestamp.iCare_Is_Current_State__c = true;

      listJobsTimestamp.add(jobTimestamp);
    }
    insert listJobsTimestamp;
  }

  @isTest
  static void test_GetJobsAll() {
    Test.startTest();
    List<iCare_Job__c> listJobs = iCare_TabsFiltersTableController.getJobs(
      0,
      null,
      null
    );
    Test.stopTest();

    // Verify the expected results
    System.assertEquals(
      10,
      listJobs.size(),
      'The number of records shoul be 10'
    );
  }

  @isTest
  static void test_GetJobsByDays() {
    Test.startTest();
    List<iCare_Job__c> listJobs = iCare_TabsFiltersTableController.getJobs(
      10,
      null,
      null
    );
    Test.stopTest();

    // Verify the expected results
    /*System.assertEquals(
      10,
      listJobs.size(),
      'The number of records shoul be 10'
    );*/
  }

  @isTest
  static void test_GetJobsByDates() {
    Test.startTest();
    List<iCare_Job__c> listJobs = iCare_TabsFiltersTableController.getJobs(
      0,
      System.today() - 1,
      System.today() + 1
    );
    Test.stopTest();

    // Verify the expected results
    /*System.assertEquals(
      10,
      listJobs.size(),
      'The number of records shoul be 10'
    );*/
  }
}