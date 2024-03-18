@IsTest
private class iCare_ReportsTableControllerTest {
	@TestSetup
	static void setUp() {
        Account account = iCare_TestDataFactory.createICareCustomerAccount(true);

		icare_Job_Request__c jobRequest = iCare_TestDataFactory.createJobRequest(account.Id,true);

		List<iCare_Job__c> jobList = iCare_TestDataFactory.createJobs(5, account.Id, jobRequest.Id, true);

		List<icare_Job_Timestamp__c> timestamps = new List<icare_Job_Timestamp__c>();
		for(iCare_Job__c job : jobList){
			timestamps.add(iCare_TestDataFactory.createTimeStamp(job.Id, false));
		}

		insert timestamps;
	}

	@IsTest
	static void getReportsTest() {
		Test.startTest();
		String result = iCare_ReportsTableController.getReports();
		Test.stopTest();

		System.assert(result != null);
		List<iCare_ReportsTableController.ReportWrappers> reports =(List<iCare_ReportsTableController.ReportWrappers>) JSON.deserializeStrict(result,List<iCare_ReportsTableController.ReportWrappers>.class);

		System.assert(reports.size() == 5);
	}
}