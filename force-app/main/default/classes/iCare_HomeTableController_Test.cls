/*
* ________________________________________________________________________________________________
* Class to test the iCare_HomeTableController Class
* ________________________________________________________________________________________________
* @author       Andres Morales
* @created      2023-07-10
* ________________________________________________________________________________________________
* @changes
* 
* ________________________________________________________________________________________________
*/
@isTest
private class iCare_HomeTableController_Test {
    @testSetup static void setup() {
        // Create a test jobs
        List<iCare_Job__c> listInsertJobs = new List<iCare_Job__c>();

        for (Integer x = 0; x < 10; x++){
            iCare_Job__c testJob = new iCare_Job__c();
            testJob.iCare_Job_ID__c = 'TUR-IST-2405000' + x;
            testJob.iCare_Job_Description__c = 'Job description test ' + x;
            listInsertJobs.add(testJob);
        }

        insert listInsertJobs;

        //Create Jobs Timestamps
        List<icare_Job_Timestamp__c> listJobsTimestamp = new List<icare_Job_Timestamp__c>();
        Integer x = 1;
        for(iCare_Job__c job : [SELECT Id, iCare_Job_ID__c, CreatedDate FROM iCare_Job__c]){
            icare_Job_Timestamp__c jobTimestamp = new icare_Job_Timestamp__c();
            jobTimestamp.iCare_Job__c = job.Id;
            jobTimestamp.iCare_Job_Timestamp__c = job.CreatedDate;
            jobTimestamp.iCare_External_Id__c = job.iCare_Job_ID__c;

            switch on x {
                when 1, 2, 3, 4 {
                    jobTimestamp.iCare_Job_Status__c = 'Job Submitted';
                    jobTimestamp.iCare_Is_Current_State__c = true;
                }	
                when 5, 6, 7 {
                    jobTimestamp.iCare_Job_Status__c = 'Sample Received';
                    jobTimestamp.iCare_Is_Current_State__c = true;
                }
                when 8, 9, 10 {
                    jobTimestamp.iCare_Job_Status__c = 'Test Report Issued';
                    jobTimestamp.iCare_Is_Current_State__c = true;
                }
            }

            listJobsTimestamp.add(jobTimestamp);
            x++;
        }
        insert listJobsTimestamp;
    }

    @isTest static void test_getJobs_TestReportIssued() {
        Test.startTest();
        List<iCare_Job__c> listJobs = iCare_HomeTableController.getJobs(100, true);
        Test.stopTest();

        // Verify the expected results
        System.assertEquals(3, listJobs.size(), 'The number of records shoul be 3');
    }

    @isTest static void test_getJobs_No_TestReportIssued() {
        Test.startTest();
        List<iCare_Job__c> listJobs = iCare_HomeTableController.getJobs(100, false);
        Test.stopTest();

        // Verify the expected results
        System.assertEquals(7, listJobs.size(), 'The number of records shoul be 7');
    }

    /*@isTest static void test_getJobList_TestReportIssued() {
        Test.startTest();
        List<iCare_Job__c> listJobs = iCare_HomeTableController.getJobList(1, 5, true);
        Test.stopTest();

        // Verify the expected results
        System.assertEquals(3, listJobs.size(), 'The number of records shoul be 3');
    }*/

    @isTest static void test_getJobList_No_TestReportIssued() {
        Test.startTest();
        List<iCare_Job__c> listJobs = iCare_HomeTableController.getJobList(1, 5, false);
        Test.stopTest();

        // Verify the expected results
        System.assertEquals(5, listJobs.size(), 'The number of records shoul be 5');
    }
    @isTest static void test_totalRecords() {
        Test.startTest();
        Integer cntJobs = iCare_HomeTableController.totalRecords(false);
        Test.stopTest();

        // Verify the expected results
        System.assertEquals(7, cntJobs, 'The number of Jobs shoul be 7');
    }

    @isTest static void test_getNext() {
        Test.startTest();
        Integer offset = iCare_HomeTableController.getNext(10, 5);
        Test.stopTest();

        // Verify the expected results
        System.assertEquals(15, offset, 'The value shoul be 15');
    }

    @isTest static void test_getPrevious() {
        Test.startTest();
        Integer offset = iCare_HomeTableController.getPrevious(10, 5);
        Test.stopTest();

        // Verify the expected results
        System.assertEquals(5, offset, 'The value shoul be 5');
    }
}