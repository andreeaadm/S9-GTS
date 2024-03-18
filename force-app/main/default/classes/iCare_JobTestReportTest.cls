/*******************************************************************************************
* @Name         iCare_JobTestReportTest 
* @Author       Praveen Kumar R
* @Description  This acts as the test class to iCare_JobTestReport.
*******************************************************************************************/
@isTest
public class iCare_JobTestReportTest {

    @TestSetup
    static void createData() {
        List<iCare_Job__c> jobList = new List<iCare_Job__c>();
        iCare_Job__c job = new iCare_Job__c(iCare_Job_ID__c='TUR-IST-23000000001',
                                            iCare_Job_Status__c = 'Job Submitted',
                                            iCare_Document_URL__c = '/report/sample/docurl');
        jobList.add(job);
        
        insert jobList;
    }
    
    
    @isTest
    static void getJobTestReportTest() {
        Test.startTest();
        List<iCare_Job__c> jobList = [SELECT Id,iCare_Job_ID__c,iCare_Job_Status__c,iCare_Document_URL__c FROM iCare_Job__c];
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new iCare_MockHttpResponseGenerator());        
        String filePath = iCare_JobTestReport.getJobTestReport(jobList[0].Id);
        System.assertEquals(filePath, 'https://www.intertek.com/files/sampleReport.pdf');

        Test.stopTest();
    }
}