@isTest
private with sharing class GMAEL_SendARequestFormController_Test {
    
    @isTest
    static void testGetData() {

        // Call the method
        Test.startTest();
            Map<String, Object> result = GMAEL_SendARequestFormController.getData();
        Test.stopTest();

        // Add your assertions here based on the expected result
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testCreateIConnectLead() {

        // Add your test data setup here, if needed
        IConnect_Lead__c lead = new IConnect_Lead__c();

        lead.INTK_Address__City__s = '686';
        lead.INTK_Address__CountryCode__s = 'GB';
        lead.INTK_Address__GeocodeAccuracy__s = null;
        lead.INTK_Address__Latitude__s = null;
        lead.INTK_Address__Longitude__s = null;
        lead.INTK_Address__PostalCode__s = null;
        lead.INTK_Address__StateCode__s = null;
        lead.INTK_Address__Street__s = null;

        lead.INTK_Business_Phone__c = '+09890786543';
        lead.INTK_Campaign_Id__c = 'CMP-16042-R1L7Z3';
        lead.INTK_Company_Name__c = 'test';
        lead.INTK_Description__c = 'Countries - China\nServices - Marketing brief\nAdditional Information - NA';
        lead.INTK_Email__c = 'sa@setest1.com';
        lead.INTK_First_Name__c = 'Test1';
        lead.INTK_iConnect_Sync_Status__c = 'Success';
        lead.INTK_Job_Title__c = 'Test Job';
        lead.INTK_Last_Name__c = '12';
        lead.INTK_Retry_Sync_Counter__c = null; // Blank
        lead.INTK_Source__c = 'Web';
        lead.INTK_Source_Application_Name__c = 'GMA EL';
        lead.INTK_Subject__c = 'Intertek Access Services';

        // Call the method
        Test.startTest();
            GMAEL_SendARequestFormController.createIConnectLead(lead);
        Test.stopTest();

        // Add your assertions here based on the expected result
        System.assertNotEquals(null, lead.Id);
    }

    @isTest
    static void testRetrievePicklist() {

        // Call the method
        Test.startTest();
            List<Map<String, String>> picklist = GMAEL_SendARequestFormController.retrievePicklist('IConnect_Lead__c', 'INTK_Address__CountryCode__s');
        Test.stopTest();

        // Add your assertions here based on the expected result
        System.assertNotEquals(null, picklist);
    }

    @isTest
    static void testGetDependentPicklistValues() {

        // Call the method
        Test.startTest();
            Map<String,List<Map<String,String>>> dependentPicklist = GMAEL_SendARequestFormController.getDependentPicklistValues();
        Test.stopTest();

        // Add your assertions here based on the expected result
        System.assertNotEquals(null, dependentPicklist);
    }
}