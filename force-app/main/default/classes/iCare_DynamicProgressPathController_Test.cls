/*
 * ________________________________________________________________________________________________
 * Class to test the iCare_DynamicProgressPathController Class
 * ________________________________________________________________________________________________
 * @author       Andres Morales
 * @created      2023-05-08
 * ________________________________________________________________________________________________
 * @changes
 *
 * ________________________________________________________________________________________________
 */
@isTest
private class iCare_DynamicProgressPathController_Test {
  @TestSetup
  static void makeData() {
    Account objAccount = iCare_TestDataFactory.createICareCustomerAccount(true);

    Testing_Location__c testLocation = iCare_TestDataFactory.createTestLocation(
      objAccount.Id,
      true
    );
  }

  @isTest
  static void test_JobSubmitted() {
    Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('iCare_Customer')
      .getRecordTypeId();

    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE Name = 'iCare Account Inc'
    ];
    List<Testing_Location__c> testLocations = [
      SELECT Id
      FROM Testing_Location__c
      WHERE iCare_Account__c = :accounts[0].Id
    ];

    // Create a test job
    iCare_Job__c testJob = new iCare_Job__c();
    testJob.iCare_Job_ID__c = 'TUR-IST-24000008';
    testJob.iCare_Job_Description__c = 'Job description test';
    testJob.iCare_Job_Status__c = 'Job Submitted (iCare)';
    testJob.iCare_Testing_Location__c = testLocations[0].id;
    testJob.iCare_Supplier__c = accounts[0].id;
    testJob.iCare_Job_Status_Portal__c = 'Job Submitted';

    insert testJob;

    // Create a test job timestamp
    iCare_Job_Timestamp__c testJobTimestamp = new iCare_Job_Timestamp__c();
    testJobTimestamp.iCare_Job__c = testJob.Id;
    testJobTimestamp.iCare_Is_Current_State__c = false;
    testJobTimestamp.iCare_Job_Pending__c = false;
    testJobTimestamp.iCare_Job_Status__c = 'Job Submitted';
    testJobTimestamp.iCare_Job_Timestamp__c = Date.newInstance(2020, 12, 5);
    testJobTimestamp.iCare_External_Id__c = 'TUR-IST-24000005';
    insert testJobTimestamp;

    Test.startTest();
    List<iCare_DynamicProgressPathController.JobTimestampWrapper> results = iCare_DynamicProgressPathController.getJobTimestampWithImages(
      testJob.Id
    );
    Test.stopTest();

    // Verify the expected results
    System.assertEquals(4, results.size());
    System.assertEquals('Job Submitted', results[0].progressLabel);
    System.assertEquals('JobSubmittedYellow.svg', results[0].progressImage);
    System.assertEquals('TrackCenterOk.svg', results[0].progressTrackImage);

    System.assertEquals('Job Submitted', results[0].currentStatus);

    System.assertEquals('Sample Received', results[1].progressLabel);
    System.assertEquals('SamplesReceivedWhite.svg', results[1].progressImage);
    System.assertEquals('TrackCenterBlank.svg', results[1].progressTrackImage);

    System.assertEquals('Test in Progress', results[2].progressLabel);
    System.assertEquals('TestingProgresWhite.svg', results[2].progressImage);
    System.assertEquals('TrackCenterBlank.svg', results[2].progressTrackImage);

    System.assertEquals('Test Report Issued', results[3].progressLabel);
    System.assertEquals('ReportIssuedWhite.svg', results[3].progressImage);
    System.assertEquals('TrackCenterBlank.svg', results[3].progressTrackImage);
  }

  @isTest
  static void test_SampleReceived() {
    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE Name = 'iCare Account Inc'
    ];
    List<Testing_Location__c> testLocations = [
      SELECT Id
      FROM Testing_Location__c
      WHERE iCare_Account__c = :accounts[0].Id
    ];
    // Create a test job
    iCare_Job__c testJob = new iCare_Job__c();
    testJob.iCare_Job_ID__c = 'TUR-IST-24000006';
    testJob.iCare_Job_Status__c = 'Job Submitted (iCare)';
    testJob.iCare_Job_Description__c = 'Job description test';
    testJob.iCare_Testing_Location__c = testLocations[0].id;
    testJob.iCare_Supplier__c = accounts[0].id;

    insert testJob;

    // Create a test job timestamp
    iCare_Job_Timestamp__c testJobTimestamp = new iCare_Job_Timestamp__c();
    testJobTimestamp.iCare_Job__c = testJob.Id;
    testJobTimestamp.iCare_Is_Current_State__c = false;
    testJobTimestamp.iCare_Job_Pending__c = false;
    testJobTimestamp.iCare_Job_Status__c = 'Job Submitted (iCare)';
    testJobTimestamp.iCare_Job_Timestamp__c = Date.newInstance(2020, 12, 5);
    testJobTimestamp.iCare_External_Id__c = 'Ext Id1';
    insert testJobTimestamp;

    System.debug(testJob.iCare_Job_Status_Portal__c);
    iCare_Job_Timestamp__c testJobTimestamp2 = new iCare_Job_Timestamp__c();
    testJobTimestamp2.iCare_Job__c = testJob.Id;
    testJobTimestamp2.iCare_Is_Current_State__c = true;
    testJobTimestamp2.iCare_Job_Pending__c = false;
    testJobTimestamp2.iCare_Job_Status__c = 'Sample Received';
    testJobTimestamp2.iCare_Job_Timestamp__c = Date.newInstance(2020, 12, 7);
    testJobTimestamp2.iCare_External_Id__c = 'Ext Id2';
    insert testJobTimestamp2;

    Test.startTest();
    List<iCare_DynamicProgressPathController.JobTimestampWrapper> results = iCare_DynamicProgressPathController.getJobTimestampWithImages(
      testJob.Id
    );
    Test.stopTest();

    // Verify the expected results
    System.assertEquals(4, results.size());
    System.assertEquals('Job Submitted', results[0].progressLabel);
    System.assertEquals('JobSubmittedYellow.svg', results[0].progressImage);
    System.assertEquals('TrackCenterOk.svg', results[0].progressTrackImage);
    //System.assertEquals('TUR-IST-24000006', results[0].iCareJobId);
    System.assertEquals('Sample Received', results[0].currentStatus);

    System.assertEquals('Sample Received', results[1].progressLabel);
    System.assertEquals('SamplesReceivedYellow.svg', results[1].progressImage);
    System.assertEquals('TrackCenterOk.svg', results[1].progressTrackImage);

    System.assertEquals('Test in Progress', results[2].progressLabel);
    System.assertEquals('TestingProgresWhite.svg', results[2].progressImage);
    System.assertEquals('TrackCenterBlank.svg', results[2].progressTrackImage);

    System.assertEquals('Test Report Issued', results[3].progressLabel);
    System.assertEquals('ReportIssuedWhite.svg', results[3].progressImage);
    System.assertEquals('TrackCenterBlank.svg', results[3].progressTrackImage);
  }

  @isTest
  static void test_InProgress() {
    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE Name = 'iCare Account Inc'
    ];
    List<Testing_Location__c> testLocations = [
      SELECT Id
      FROM Testing_Location__c
      WHERE iCare_Account__c = :accounts[0].Id
    ];
    // Create a test job
    iCare_Job__c testJob = new iCare_Job__c();
    testJob.iCare_Job_ID__c = 'TUR-IST-24000006';
    testJob.iCare_Job_Description__c = 'Job description test';
    testJob.iCare_Testing_Location__c = testLocations[0].id;
    testJob.iCare_Supplier__c = accounts[0].id;
    testJob.iCare_Job_Status__c = 'Job Submitted (iCare)';

    insert testJob;

    // Create a test job timestamp
    iCare_Job_Timestamp__c testJobTimestamp = new iCare_Job_Timestamp__c();
    testJobTimestamp.iCare_Job__c = testJob.Id;
    testJobTimestamp.iCare_Is_Current_State__c = false;
    testJobTimestamp.iCare_Job_Pending__c = false;
    testJobTimestamp.iCare_Job_Status__c = 'Job Submitted (iCare)';
    testJobTimestamp.iCare_Job_Timestamp__c = Date.newInstance(2020, 12, 5);
    testJobTimestamp.iCare_External_Id__c = 'Ext Id1';
    insert testJobTimestamp;
    iCare_Job_Timestamp__c testJobTimestamp2 = new iCare_Job_Timestamp__c();
    testJobTimestamp2.iCare_Job__c = testJob.Id;
    testJobTimestamp2.iCare_Is_Current_State__c = false;
    testJobTimestamp2.iCare_Job_Pending__c = false;
    testJobTimestamp2.iCare_Job_Status__c = 'Sample Received';
    testJobTimestamp2.iCare_Job_Timestamp__c = Date.newInstance(2020, 12, 7);
    testJobTimestamp2.iCare_External_Id__c = 'Ext Id2';
    insert testJobTimestamp2;
    iCare_Job_Timestamp__c testJobTimestamp3 = new iCare_Job_Timestamp__c();
    testJobTimestamp3.iCare_Job__c = testJob.Id;
    testJobTimestamp3.iCare_Is_Current_State__c = true;
    testJobTimestamp3.iCare_Job_Pending__c = false;
    testJobTimestamp3.iCare_Job_Status__c = 'Test in Progress';
    testJobTimestamp3.iCare_Job_Timestamp__c = Date.newInstance(2020, 12, 9);
    testJobTimestamp3.iCare_External_Id__c = 'Ext Id3';
    insert testJobTimestamp3;

    Test.startTest();
    List<iCare_DynamicProgressPathController.JobTimestampWrapper> results = iCare_DynamicProgressPathController.getJobTimestampWithImages(
      testJob.Id
    );
    Test.stopTest();

    // Verify the expected results
    System.assertEquals(4, results.size());
    System.assertEquals('Job Submitted', results[0].progressLabel);
    System.assertEquals('JobSubmittedYellow.svg', results[0].progressImage);
    System.assertEquals('TrackCenterOk.svg', results[0].progressTrackImage);
    //System.assertEquals('TUR-IST-24000006', results[0].iCareJobId);
    System.assertEquals('Test in Progress', results[0].currentStatus);

    System.assertEquals('Sample Received', results[1].progressLabel);
    System.assertEquals('SamplesReceivedYellow.svg', results[1].progressImage);
    System.assertEquals('TrackCenterOk.svg', results[1].progressTrackImage);

    System.assertEquals('Testing 0% Complete', results[2].progressLabel);
    System.assertEquals('TestingProgresYellow.svg', results[2].progressImage);
    System.assertEquals('TrackCenterOk.svg', results[2].progressTrackImage);

    System.assertEquals('Test Report Issued', results[3].progressLabel);
    System.assertEquals('ReportIssuedWhite.svg', results[3].progressImage);
    System.assertEquals('TrackCenterBlank.svg', results[3].progressTrackImage);
  }

  @isTest
  static void test_ReportIssued() {
    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE Name = 'iCare Account Inc'
    ];
    List<Testing_Location__c> testLocations = [
      SELECT Id
      FROM Testing_Location__c
      WHERE iCare_Account__c = :accounts[0].Id
    ];
    // Create a test job
    iCare_Job__c testJob = new iCare_Job__c();
    testJob.iCare_Job_ID__c = 'TUR-IST-24000006';
    testJob.iCare_Job_Description__c = 'Job description test';
    testJob.iCare_Testing_Location__c = testLocations[0].id;
    testJob.iCare_Supplier__c = accounts[0].id;
    testJob.iCare_Job_Status__c = 'Job Submitted (iCare)';

    insert testJob;

    // Create a test job timestamp
    iCare_Job_Timestamp__c testJobTimestamp = new iCare_Job_Timestamp__c();
    testJobTimestamp.iCare_Job__c = testJob.Id;
    testJobTimestamp.iCare_Is_Current_State__c = false;
    testJobTimestamp.iCare_Job_Pending__c = false;
    testJobTimestamp.iCare_Job_Status__c = 'Job Submitted (iCare)';
    testJobTimestamp.iCare_Job_Timestamp__c = Date.newInstance(2020, 12, 5);
    testJobTimestamp.iCare_External_Id__c = 'Ext Id1';
    insert testJobTimestamp;
    iCare_Job_Timestamp__c testJobTimestamp2 = new iCare_Job_Timestamp__c();
    testJobTimestamp2.iCare_Job__c = testJob.Id;
    testJobTimestamp2.iCare_Is_Current_State__c = false;
    testJobTimestamp2.iCare_Job_Pending__c = false;
    testJobTimestamp2.iCare_Job_Status__c = 'Sample Received';
    testJobTimestamp2.iCare_Job_Timestamp__c = Date.newInstance(2020, 12, 7);
    testJobTimestamp2.iCare_External_Id__c = 'Ext Id2';
    insert testJobTimestamp2;
    iCare_Job_Timestamp__c testJobTimestamp3 = new iCare_Job_Timestamp__c();
    testJobTimestamp3.iCare_Job__c = testJob.Id;
    testJobTimestamp3.iCare_Is_Current_State__c = false;
    testJobTimestamp3.iCare_Job_Pending__c = false;
    testJobTimestamp3.iCare_Job_Status__c = 'Test in Progress';
    testJobTimestamp3.iCare_Job_Timestamp__c = Date.newInstance(2020, 12, 9);
    testJobTimestamp3.iCare_External_Id__c = 'Ext Id3';
    insert testJobTimestamp3;
    iCare_Job_Timestamp__c testJobTimestamp4 = new iCare_Job_Timestamp__c();
    testJobTimestamp4.iCare_Job__c = testJob.Id;
    testJobTimestamp4.iCare_Is_Current_State__c = true;
    testJobTimestamp4.iCare_Job_Pending__c = false;
    testJobTimestamp4.iCare_Job_Status__c = 'Test Report Issued';
    testJobTimestamp4.iCare_Job_Timestamp__c = Date.newInstance(2020, 12, 11);
    testJobTimestamp4.iCare_External_Id__c = 'Ext Id4';
    insert testJobTimestamp4;

    Test.startTest();
    List<iCare_DynamicProgressPathController.JobTimestampWrapper> results = iCare_DynamicProgressPathController.getJobTimestampWithImages(
      testJob.Id
    );
    Test.stopTest();

    // Verify the expected results
    System.assertEquals(4, results.size());
    System.assertEquals('Job Submitted', results[0].progressLabel);
    System.assertEquals('JobSubmittedYellow.svg', results[0].progressImage);
    System.assertEquals('TrackCenterOk.svg', results[0].progressTrackImage);
    //System.assertEquals('TUR-IST-24000006', results[0].iCareJobId);
    System.assertEquals('Test Report Issued', results[0].currentStatus);

    System.assertEquals('Sample Received', results[1].progressLabel);
    System.assertEquals('SamplesReceivedYellow.svg', results[1].progressImage);
    System.assertEquals('TrackCenterOk.svg', results[1].progressTrackImage);

    System.assertEquals('Testing Complete', results[2].progressLabel);
    System.assertEquals('TestingProgresYellow.svg', results[2].progressImage);
    System.assertEquals('TrackCenterOk.svg', results[2].progressTrackImage);

    System.assertEquals('Test Report Issued', results[3].progressLabel);
    System.assertEquals('ReportIssuedYellow.svg', results[3].progressImage);
    System.assertEquals('TrackCenterOk.svg', results[3].progressTrackImage);
  }
}