@isTest
private class GMAELLegislationCountryActionHelperTest {

    @isTest
    static void testCreateGMAELLegislationCountriesPositiveCase() {
        
        // Test setup
        List<GMAEL_Country__c> testCRecords = new List<GMAEL_Country__c>();

        // Record 1 - GMAEL_Country__c
        GMAEL_Country__c recordC1 = new GMAEL_Country__c(
            CurrencyIsoCode = 'USD',
            GMAEL_Country_Status__c = 'Approved',
            GMAEL_ISO_Code__c = 'US',
            GMAEL_Migration_ID__c = 'MIG-001',
            GMAEL_National_Deviation_Supply_Freqncy__c = '50 Hz',
            GMAEL_National_Deviation_Supply_Voltage__c = '220 V',
            //GMAEL_Region__c = 'North America',
            GMAEL_Scheme_Document__c = 'Scheme Document 1',
            Name = 'United States'
        );

        GMAEL_Country__c recordC2 = new GMAEL_Country__c(
            CurrencyIsoCode = 'USD',
            GMAEL_Country_Status__c = 'Approved',
            GMAEL_ISO_Code__c = 'US',
            GMAEL_Migration_ID__c = 'MIG-002',
            GMAEL_National_Deviation_Supply_Freqncy__c = '50 Hz',
            GMAEL_National_Deviation_Supply_Voltage__c = '220 V',
            //GMAEL_Region__c = 'North America',
            GMAEL_Scheme_Document__c = 'Scheme Document 2',
            Name = 'United Kingdom'
        );

        testCRecords.add(recordC1);
        testCRecords.add(recordC2);
        insert testCRecords;

        List<GMAEL_Issuing_Governing_Body__c> testIGBRecords = new List<GMAEL_Issuing_Governing_Body__c>();

        // Record 1 - GMAEL_Issuing_Governing_Body__c
        GMAEL_Issuing_Governing_Body__c recordIGB1 = new GMAEL_Issuing_Governing_Body__c(
            CurrencyIsoCode = 'USD',
            GMAEL_Acronym__c = 'ABC',
            GMAEL_Migration_ID__c = 'MIG-001',
            GMAEL_Type__c = 'Governing Body',
            Name = 'United States',
            GMAEL_Standard_Governing_Body_Status__c='Approved'
        );

        // Record 2 - GMAEL_Issuing_Governing_Body__c
        GMAEL_Issuing_Governing_Body__c recordIGB2 = new GMAEL_Issuing_Governing_Body__c(
            CurrencyIsoCode = 'USD',
            GMAEL_Acronym__c = 'ABCD',
            GMAEL_Migration_ID__c = 'MIG-002',
            GMAEL_Type__c = 'Standard Body',
            Name = 'IEC',
            GMAEL_Standard_Governing_Body_Status__c='Approved'
        );

        testIGBRecords.add(recordIGB1);
        testIGBRecords.add(recordIGB2);
        insert testIGBRecords;

        List<GMAEL_Country_Body_Relationship__c> testRecordsCBR = new List<GMAEL_Country_Body_Relationship__c>();

        // Record 1 - GMAEL_Country_Body_Relationship__c
        GMAEL_Country_Body_Relationship__c recordCBR1 = new GMAEL_Country_Body_Relationship__c(
            GMAEL_Migration_ID__c = '',
            GMAEL_Unique_Key__c = '',
            GMAEL_Country__c = [SELECT Id FROM GMAEL_Country__c WHERE Name = 'United States'].Id,
            GMAEL_Issuing_Governing_Body__c = [SELECT Id FROM GMAEL_Issuing_Governing_Body__c WHERE GMAEL_Type__c = 'Governing Body' LIMIT 1].Id,//testIGBRecords.get(0).Id,            
            CurrencyIsoCode = 'USD'
        );

        GMAEL_Country_Body_Relationship__c recordCBR2 = new GMAEL_Country_Body_Relationship__c(
            GMAEL_Migration_ID__c = '008',
            GMAEL_Unique_Key__c = '007',
            GMAEL_Country__c = [SELECT Id FROM GMAEL_Country__c WHERE Name = 'United Kingdom'].Id,
            GMAEL_Issuing_Governing_Body__c = [SELECT Id FROM GMAEL_Issuing_Governing_Body__c WHERE GMAEL_Type__c = 'Governing Body' LIMIT 1].Id,//testIGBRecords.get(0).Id,            
            CurrencyIsoCode = 'USD'
        );

        testRecordsCBR.add(recordCBR1);
        testRecordsCBR.add(recordCBR2);
        insert testRecordsCBR;

        // Record 1 - GMAEL_Legislation__c
        GMAEL_Legislation__c recordLegislation1 = new GMAEL_Legislation__c(
            CurrencyIsoCode = 'USD',
            GMAEL_Effective_Date__c = null,
            GMAEL_Legislation_Status__c = 'Pending Approval',
            GMAEL_Migration_ID__c = null,
            Name = 'Washing Machine EU'
        );
        insert recordLegislation1;

        
        // Create a test Country Mark record
        GMAEL_Country_Mark__c countryMark = new GMAEL_Country_Mark__c(
            Name = 'CE',
            GMAEL_Country_Mark_Description__c = 'CE',
            //GMAEL_Country_Mark_Status__c = 'Active',
            GMAEL_Logo_File_URL__c = 'https://sample_logo_file_url.com',
            GMAEL_Migration_ID__c = 'SampleMigrationID',
            GMAEL_Country_Mark_Status__c='Approved'
        );
        insert countryMark;

        List<GMAEL_Country_Mark_Relationship__c> relationships = new List<GMAEL_Country_Mark_Relationship__c>();
        // Create a new GMAEL_Country_Mark_Relationship__c record
        GMAEL_Country_Mark_Relationship__c relationship = new GMAEL_Country_Mark_Relationship__c();

        // Set field values
        relationship.CurrencyIsoCode = 'USD';
        relationship.GMAEL_Country__c = testCRecords[0].Id;
        relationship.GMAEL_Country_Mark__c = countryMark.Id;
        relationship.GMAEL_Country_Mark_Description__c = 'CE-CE-Denmark';
        relationship.GMAEL_Country_Mark_Relationship_Status__c = 'Approved';
        relationship.GMAEL_Migration_ID__c = '007';
        relationship.GMAEL_Unique_Key__c = 'a1H8J0000009MjaUAE-a1G8J0000005Y6gUAE';

        // Create a new GMAEL_Country_Mark_Relationship__c record
        GMAEL_Country_Mark_Relationship__c relationship1 = new GMAEL_Country_Mark_Relationship__c();

        // Set field values
        relationship1.CurrencyIsoCode = 'USD';
        relationship1.GMAEL_Country__c = testCRecords[1].Id;
        relationship1.GMAEL_Country_Mark__c = countryMark.Id;
        relationship1.GMAEL_Country_Mark_Description__c = 'CE-CE-Denmark';
        relationship1.GMAEL_Country_Mark_Relationship_Status__c = 'Approved';
        relationship1.GMAEL_Migration_ID__c = null;
        relationship1.GMAEL_Unique_Key__c = 'a1H8J0000009MjaUAE-a1G8J0000005Y6g001';

        relationships.add(relationship);
        relationships.add(relationship1);
        insert relationships;

        GMAEL_Legislation_Country__c recordLC1 = new GMAEL_Legislation_Country__c(
            CurrencyIsoCode = 'USD',
            GMAEL_CAB_Accreditation__c = null,
            GMAEL_Country_Conformity_Requirement__c = 'Yes',
            GMAEL_Country_Mark__c = relationships[0].Id,
            GMAEL_Engineering_Application__c = null,
            GMAEL_Governance_Description__c = null,
            GMAEL_Governance_URL__c = 'test.com',
            GMAEL_Governing_Body__c = testRecordsCBR.get(0).Id,
            GMAEL_Jurisdiction__c = testCRecords[0].Id,
            GMAEL_Pre_Shipment_Requirement__c = 'Yes',
            GMAEL_Scheme__c = null,
            GMAEL_Scheme_Documents_Requirements__c = null,
            GMAEL_Legislation__c = recordLegislation1.Id,
            GMAEL_Country_Conformity_Types__c='Assessment Level - Type 1a (Testing & Certification (Identified Samples))'
        );

        insert recordLC1;

        // Record 1 - GMAEL_Standard__c
        GMAEL_Standard__c recordStandard1 = new GMAEL_Standard__c(
            CurrencyIsoCode = 'USD',
            GMAEL_Migration_ID__c = null,
            GMAEL_Standard_Body__c = [SELECT Id FROM GMAEL_Issuing_Governing_Body__c WHERE GMAEL_Type__c = 'Standard Body' LIMIT 1].Id,//testIGBRecords.get(0).Id,
            GMAEL_Standard_Prefix__c = 'IEC',
            GMAEL_Standard_Version__c = '2023',
            Name = '62061v1',
            GMAEL_Standard_Status__c='Approved'
            
        );
        insert recordStandard1;

        List<GMAEL_Legislation_Standard__c> testLSRecords = new List<GMAEL_Legislation_Standard__c>();
        // Record 1 - GMAEL_Legislation_Standard__c
        GMAEL_Legislation_Standard__c recordLS1 = new GMAEL_Legislation_Standard__c(
            CurrencyIsoCode = 'USD',
            GMAEL_Legislation_Country__c = recordLC1.Id,
            GMAEL_Standard__c = recordStandard1.Id,
            GMAEL_Unique_Key__c = recordLC1.Id
        );

        testLSRecords.add(recordLS1);
        insert testLSRecords;

        Test.startTest();        
            
            GMAELLegislationCountriesActionHelper.Input input = new GMAELLegislationCountriesActionHelper.Input();
            input.selectedCountries = [SELECT Id FROM GMAEL_Country__c WHERE Name = 'United Kingdom'].Id;        
            input.countryMarkId = countryMark.Id;
            input.governingBodyId = [SELECT Id FROM GMAEL_Issuing_Governing_Body__c WHERE GMAEL_Type__c = 'Governing Body' LIMIT 1].Id;    
            input.gMAELLegislationCountry = new GMAEL_Legislation_Country__c(
                CurrencyIsoCode = 'USD',
                GMAEL_CAB_Accreditation__c = null,
                GMAEL_Country_Conformity_Requirement__c = 'Yes',
                GMAEL_Country_Mark__c = relationships[0].Id,
                GMAEL_Governing_Body__c = testRecordsCBR.get(0).Id,
                GMAEL_Jurisdiction__c = testCRecords[0].Id,
                GMAEL_Engineering_Application__c = null,
                GMAEL_Governance_Description__c = null,
                GMAEL_Governance_URL__c = 'test.com',
                GMAEL_Pre_Shipment_Requirement__c = 'Yes',
                GMAEL_Scheme__c = null,
                GMAEL_Scheme_Documents_Requirements__c = null,
                GMAEL_Legislation__c = recordLegislation1.Id,
                GMAEL_Country_Conformity_Types__c='Assessment Level - Type 1a (Testing & Certification (Identified Samples))'
            );
            input.gMAELLegislationStandards = null;
                  
            List<GMAELLegislationCountriesActionHelper.Output> outputs = GMAELLegislationCountriesActionHelper.createGMAELLegislationCountries(new List<GMAELLegislationCountriesActionHelper.Input>{input});
        Test.stopTest();

        Assert.areEqual(1, outputs.size());
        Assert.areEqual(true, outputs[0].success);
    }

    @isTest
    static void testCreateGMAELLegislationCountriesNegativeCase() {

        // Test setup
        List<GMAEL_Country__c> testCRecords = new List<GMAEL_Country__c>();

        // Record 1 - GMAEL_Country__c
        GMAEL_Country__c recordC1 = new GMAEL_Country__c(
            CurrencyIsoCode = 'USD',
            GMAEL_Country_Status__c = 'Approved',
            GMAEL_ISO_Code__c = 'US',
            GMAEL_Migration_ID__c = 'MIG-001',
            GMAEL_National_Deviation_Supply_Freqncy__c = '50 Hz',
            GMAEL_National_Deviation_Supply_Voltage__c = '220 V',
            //GMAEL_Region__c = 'North America',
            GMAEL_Scheme_Document__c = 'Scheme Document 1',
            Name = 'United States'
        );

        testCRecords.add(recordC1);
        insert testCRecords;

        List<GMAEL_Issuing_Governing_Body__c> testIGBRecords = new List<GMAEL_Issuing_Governing_Body__c>();

        // Record 1 - GMAEL_Issuing_Governing_Body__c
        GMAEL_Issuing_Governing_Body__c recordIGB1 = new GMAEL_Issuing_Governing_Body__c(
            CurrencyIsoCode = 'USD',
            GMAEL_Acronym__c = 'ABC',
            GMAEL_Migration_ID__c = 'MIG-001',
            GMAEL_Type__c = 'Governing Body',
            Name = 'Governing Body 1',
            GMAEL_Standard_Governing_Body_Status__c='Approved'
        );

        testIGBRecords.add(recordIGB1);
        insert testIGBRecords;

        List<GMAEL_Country_Body_Relationship__c> testRecordsCBR = new List<GMAEL_Country_Body_Relationship__c>();

        // Record 1 - GMAEL_Country_Body_Relationship__c
        GMAEL_Country_Body_Relationship__c recordCBR1 = new GMAEL_Country_Body_Relationship__c(
            GMAEL_Migration_ID__c = '007',
            GMAEL_Unique_Key__c = 'GMAEL001',
            GMAEL_Country__c = testCRecords.get(0).Id,
            GMAEL_Issuing_Governing_Body__c = testIGBRecords.get(0).Id,
            CurrencyIsoCode = 'USD'
        );

        testRecordsCBR.add(recordCBR1);
        insert testRecordsCBR;

        GMAELLegislationCountriesActionHelper.Input input = new GMAELLegislationCountriesActionHelper.Input();
        input.selectedCountries = 'United States';
        input.gMAELLegislationCountry = new GMAEL_Legislation_Country__c(
            CurrencyIsoCode = 'USD',
            GMAEL_CAB_Accreditation__c = null,
            GMAEL_Country_Conformity_Requirement__c = 'Yes',
            GMAEL_Country_Mark__c = null,
            GMAEL_Engineering_Application__c = null,
            GMAEL_Governance_Description__c = null,
            GMAEL_Governance_URL__c = 'test.com',
            GMAEL_Governing_Body__c = testRecordsCBR.get(0).Id,
            GMAEL_Jurisdiction__c = testCRecords[0].Id,
            GMAEL_Pre_Shipment_Requirement__c = 'Yes',
            GMAEL_Scheme__c = null,
            GMAEL_Scheme_Documents_Requirements__c = null
        );

        Test.startTest();
            List<GMAELLegislationCountriesActionHelper.Output> outputs = GMAELLegislationCountriesActionHelper.createGMAELLegislationCountries(new List<GMAELLegislationCountriesActionHelper.Input>{input});
        Test.stopTest();

        Assert.areEqual(1, outputs.size());
        Assert.areEqual(false, outputs[0].success);
    }

    @isTest
    static void testCreateGMAELLegislationCountriesWithNoInput() {
        Test.startTest();
        List<GMAELLegislationCountriesActionHelper.Output> outputs = GMAELLegislationCountriesActionHelper.createGMAELLegislationCountries(new List<GMAELLegislationCountriesActionHelper.Input>());
        Test.stopTest();

        Assert.areEqual(1, outputs.size());
        Assert.areEqual(false, outputs[0].success);
        Assert.areEqual('No Input Provided, please contact to System Administrator.', outputs[0].message);
    }
}