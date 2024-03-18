@isTest
private class GTSShipmentTableController_Test {
    private static final Integer NR_OF_CERTIFICATES = 10;

    @testSetup static void setup() {
        RecordType cocRecordType = [
          SELECT Id
          FROM RecordType
          WHERE
            DeveloperName = 'GTS_Certificate_of_Conformity'
            AND SobjectType = 'iCare_Job__c'
        ];

        // Create a test job
        iCare_Job__c jobCOC = new iCare_Job__c(
          RecordTypeId = cocRecordType.Id,
          iCare_Sample_Description__c = 'Certificate of Conformity'
        );
        insert jobCOC;

        List<GTS_Certificate__c> certificates = new List<GTS_Certificate__c>();
        for(Integer i=0;i<NR_OF_CERTIFICATES;i++){
            certificates.add(new GTS_Certificate__c(GTS_Job__c = jobCOC.Id));
        }
        insert certificates;
    }

    @isTest static void getRelatedFilesByRecordId_test() {
        Id jobId = [SELECT Id FROM iCare_Job__c LIMIT 1].Id;

        Test.startTest();
        String result = GTSShipmentTableController.getShipments(jobId);
        Test.stopTest();

        System.assert(result != null,'No response received');

        List<GTS_Certificate__c> certificates = (List<GTS_Certificate__c>) JSON.deserialize(result, List<GTS_Certificate__c>.class);

        // Verify the expected results
        System.assertEquals(NR_OF_CERTIFICATES, certificates.size(), 'The number of records should be 10');
    }
}