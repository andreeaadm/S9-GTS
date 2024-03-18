@isTest
private class INTK_IConnectLeadIntegrationTest {

    @TestSetup
	static void setUp() {
        IConnect_Lead__c testLeadObj = new IConnect_Lead__c();
        testLeadObj.INTK_Subject__c = 'Intertek Access Services';
        testLeadObj.INTK_Campaign_Id__c = 'Campaing123';
        testLeadObj.INTK_Source__c = 'Web';
        testLeadObj.INTK_Description__c = 'Countries - France,Germany\nServices - Marketing Brief, Custom Solution\nAddtional Information - Sample Additional Info';
        testLeadObj.INTK_Source_Application_Name__c  = 'GMA EL';
        testLeadObj.INTK_Job_Title__c =  'VP';
        testLeadObj.INTK_Company_Name__c =  'BOSH UK';
        testLeadObj.INTK_Address__CountryCode__s =  'GB';
        testLeadObj.INTK_Address__City__s =  'London';
        testLeadObj.INTK_Email__c =  'john@smith.com';
        testLeadObj.INTK_Business_Phone__c =  '+44 7557123213';
        testLeadObj.INTK_Last_Name__c =  'Smith';
        testLeadObj.INTK_First_Name__c =  'John';
        testLeadObj.RecordType = new RecordType(Name='GMA EL');
        insert testLeadObj;
    }

    @isTest
    static void testLeadIntegration() {
        Test.setMock(HttpCalloutMock.class, new iCare_MockHttpResponseGenerator());
    }
}