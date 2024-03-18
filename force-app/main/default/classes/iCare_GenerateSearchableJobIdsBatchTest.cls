@IsTest
public class iCare_GenerateSearchableJobIdsBatchTest {
    @TestSetup
    static void createData() {
        iCare_Job__c job1 = new iCare_Job__c(
        iCare_Job_ID__c = 'TUR-IST-23000000000',
        iCare_Job_Description__c = 'Enso Subject',
        iCare_Job_Status__c = 'Job Submitted (iCare)'
        );
        insert job1;
    }

    @IsTest
    public static void testBatch(){
        Test.startTest();
        Database.executeBatch(new iCare_GenerateSearchableJobIdsBatch());
        Test.stopTest();
        System.assertEquals([SELECT iCare_Job_ID_TF__c FROM iCare_Job__c LIMIT 1]?.iCare_Job_ID_TF__c != null, true);
    }
}