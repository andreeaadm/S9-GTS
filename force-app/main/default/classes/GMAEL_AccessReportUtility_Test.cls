@IsTest
private class GMAEL_AccessReportUtility_Test {
	@TestSetup
	static void setUp() {
		Id gmaelAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('GMA_Electrical_Customer').getRecordTypeId();
		Id gmaelContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('GMA_Electrical_Contact').getRecordTypeId();

		Account account = new Account(Name = 'Account', RecordTypeId = gmaelAccountRecordTypeId,
			BillingStreet = '1409 Sok. No:34 D:19 Buca Koop Mah.',
			BillingCity = 'London',
			BillingCountry = 'United Kingdom',
			BillingPostalCode = '35390'
		);
		insert account;
		Contact contact = new Contact(AccountId = account.Id, FirstName = 'Test', LastName = 'Contact', Email = 'test@test.com', RecordTypeId = gmaelContactRecordTypeId);
		insert contact;

		GMAEL_Region__c region = GMAEL_TestDataFactory.createGmaelRegion(1, true).get(0);
		List<GMAEL_Country__c> countries = GMAEL_TestDataFactory.createGmaelCounties(5, region.Id, true);
		GMAEL_Plug_Type__c plugTypeObj = GMAEL_TestDataFactory.createPlugType('Type A', true);
		GMAEL_Country_Plug_Type_Relationship__c plugTypeRelObj = GMAEL_TestDataFactory.createPlugTypeRelationship(plugTypeObj.Id, countries[0].Id,true);

		List<GMAEL_Product_Category__c> productCategories = GMAEL_TestDataFactory.createGmaelProductCategories(5, true);
		List<GMAEL_Product_Type__c> productTypes = GMAEL_TestDataFactory.createGmaelProductTypes(5, true);
		List<GMAEL_Standard__c> standards = GMAEL_TestDataFactory.createGmaelStandard(5, true);
		List<GMAEL_Legislation__c> legislations = GMAEL_TestDataFactory.createGmaelLegislations(5, true);
		GMAEL_Issuing_Governing_Body__c governingBody = GMAEL_TestDataFactory.createGmaelIssuingGoverningBodies(1, true)[0];

		List<GMAEL_Category_Type_Relationship__c> categoryTypeRelationships = new List<GMAEL_Category_Type_Relationship__c>();
		for (GMAEL_Product_Category__c productCategory : productCategories) {
			for (GMAEL_Product_Type__c productType : productTypes) {
				categoryTypeRelationships.add(GMAEL_TestDataFactory.createGmaelCategoryTypeRelationships(productCategory.Id, productType.Id, false));
			}
		}
		insert categoryTypeRelationships;

		List<GMAEL_Legislation_Country__c> legislationCountries = new List<GMAEL_Legislation_Country__c>();
		List<GMAEL_Country_Body_Relationship__c> countryBodyRelationships = new List<GMAEL_Country_Body_Relationship__c>();
		for (GMAEL_Country__c country : countries) {
            countryBodyRelationships.add(GMAEL_TestDataFactory.countryBodyRelationship(governingBody.Id, country.Id, false));
		}
		insert countryBodyRelationships;

		Integer i =0;
		for (GMAEL_Country__c country : countries) {
			for (GMAEL_Legislation__c legislation : legislations) {
				legislationCountries.add(GMAEL_TestDataFactory.createGmaelLegislationCountry(legislation.Id, country.Id, countryBodyRelationships[i].Id, false));
			}
			i++;
		}
		insert legislationCountries;

		List<GMAEL_Standard_Category_Type__c> standardCategoryTypes = new List<GMAEL_Standard_Category_Type__c>();
		List<GMAEL_Legislation_Standard__c> legislationStandards = new List<GMAEL_Legislation_Standard__c>();
		for (GMAEL_Standard__c standard : standards) {
			for (GMAEL_Category_Type_Relationship__c categoryTypeRelationship : categoryTypeRelationships) {
				standardCategoryTypes.add(GMAEL_TestDataFactory.createGmaelStandardCategoryType(categoryTypeRelationship, standard.Id, false));
			}
			for (GMAEL_Legislation_Country__c legislationCountry : legislationCountries) {
				legislationStandards.add(GMAEL_TestDataFactory.createGmaelLegislationStandard(standard.Id, legislationCountry.Id, false));
			}
		}
		insert standardCategoryTypes;
		insert legislationStandards;

		List<GMAEL_Report__c> reports = GMAEL_TestDataFactory.createGmaelReport(5, account.Id, contact.Id, 'Approved', true);


	}
	@IsTest
	static void generateAccessReport() {
		List<String> countryIds = new List<String>();
		List<GMAEL_Country__c>countries = [Select Id FROM GMAEL_Country__c];
		for(GMAEL_Country__c country: countries){
			countryIds.add(country.Id);
		}
		Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
		GMAEL_Report__c report = [SELECT Id, GMAEL_GIN__c FROM GMAEL_Report__c LIMIT 1];

		GMAEL_Category_Type_Relationship__c productTypes = [
			SELECT Id, GMAEL_Product_Category__c
			FROM GMAEL_Category_Type_Relationship__c
			WHERE GMAEL_Category_Type_Relationship_Status__c = 'Approved'
			LIMIT 1
		];


		Test.startTest();
		GMAEL_AccessReportUtility.AccessReportWrapper reportData = GMAEL_AccessPassportController.retrieveReportData(
			countryIds,
			contact.AccountId,
			contact.Id,
			report.GMAEL_GIN__c,
			productTypes.Id,
			productTypes.GMAEL_Product_Category__c,
			report.Id,
			true
		);
		Test.stopTest();
		System.assert(reportData.reportObj.GMAEL_GIN__c == report.GMAEL_GIN__c);
		System.assert(reportData.reportCountries.size() == countryIds.size());
	}

	@IsTest
	static void generateAccessReportLite() {
		List<String> countryIds = new List<String>();
		List<GMAEL_Country__c>countries = [Select Id FROM GMAEL_Country__c];
		for(GMAEL_Country__c country: countries){
			countryIds.add(country.Id);
		}
		Test.startTest();
		GMAEL_AccessReportUtilityLite.AccessReportWrapper reportData = GMAEL_AccessPassportPortalController.getReportData(countryIds);
		Test.stopTest();
	}
}