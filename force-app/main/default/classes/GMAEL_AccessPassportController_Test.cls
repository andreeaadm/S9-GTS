@IsTest
private class GMAEL_AccessPassportController_Test {
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

		GMAEL_Region__c region = GMAEL_TestDataFactory.createGmaelRegion(1,true).get(0);
		List<GMAEL_Country__c> countries = GMAEL_TestDataFactory.createGmaelCounties(5, region.Id, true);
		GMAEL_Plug_Type__c plugTypeObj = GMAEL_TestDataFactory.createPlugType('Type A', true);
		GMAEL_Country_Plug_Type_Relationship__c plugTypeRelObj = GMAEL_TestDataFactory.createPlugTypeRelationship(plugTypeObj.Id, countries[0].Id,true);

		List<GMAEL_Product_Category__c> productCategories = GMAEL_TestDataFactory.createGmaelProductCategories(5, true);
		List<GMAEL_Product_Type__c> productTypes = GMAEL_TestDataFactory.createGmaelProductTypes(5, true);

		List<GMAEL_Category_Type_Relationship__c> categoryTypeRelationshipStatuses = new List<GMAEL_Category_Type_Relationship__c>();
		for(GMAEL_Product_Category__c productCategory : productCategories){
			for(GMAEL_Product_Type__c productType : productTypes) {
				categoryTypeRelationshipStatuses.add(GMAEL_TestDataFactory.createGmaelCategoryTypeRelationships(productCategory.Id, productType.Id, false));
			}
		}
		insert categoryTypeRelationshipStatuses;

		List<GMAEL_Report__c> reports = GMAEL_TestDataFactory.createGmaelReport(5,account.Id, contact.Id, 'Approved', true);

    }


	@IsTest
	static void getContacts(){
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

		Test.startTest();
		String response = GMAEL_AccessPassportController.getContacts(accountId);
		Test.stopTest();
		System.assert(response != null);
	}

	@IsTest
	static void retrieveCountriesByIsocode(){
		GMAEL_Country__c country = [SELECT Id,GMAEL_ISO_Code__c FROM GMAEL_Country__c LIMIT 1];

		Test.startTest();
		List<GMAEL_Country__c> countries = GMAEL_AccessPassportController.retrieveCountriesByIsocode(country.GMAEL_ISO_Code__c);
		Test.stopTest();
		System.assert(countries != null);
		System.assert(countries.size() == 5);
	}

	@IsTest
	static void retrieveISO2CountriesByIds(){
		Map<Id, GMAEL_Country__c> countryById = new Map<Id, GMAEL_Country__c>([SELECT Id,GMAEL_ISO_Code__c FROM GMAEL_Country__c]);

		List<Id> countryIds = new List<Id>();
		countryIds.addAll(countryById.keySet());
		Test.startTest();
		Map<String, Object> isoCountiesResult = GMAEL_AccessPassportController.retrieveISO2CountriesByIds(countryIds);
		Test.stopTest();
		System.assert(isoCountiesResult != null);
	}

	@IsTest
	static void retrieveCountries(){
		Test.startTest();
		List<GMAEL_Country__c> countries = GMAEL_AccessPassportController.retrieveCountries();
		Test.stopTest();
		System.assert(countries != null);
		System.assert(countries.size() == 5);
	}


	@IsTest
	static void retrieveProductCategories(){
		List<GMAEL_Product_Category__c> productCategories = [SELECT Id FROM GMAEL_Product_Category__c WHERE GMAEL_Product_Category_Status__c = 'Approved'];

		Test.startTest();
		List<GMAEL_Product_Category__c> productCategoriesResult = GMAEL_AccessPassportController.retrieveProductCategories();
		Test.stopTest();
		System.assert(productCategoriesResult != null);
		System.assert(productCategoriesResult.size() == productCategories.size());
	}


	@IsTest
	static void retrieveProductTypeByCategoryId(){
		GMAEL_Product_Category__c productCategory = [SELECT Id, (SELECT Id FROM GMAEL_Category_Description_Relationships__r WHERE GMAEL_Category_Type_Relationship_Status__c = 'Approved') FROM GMAEL_Product_Category__c LIMIT 1];

		Test.startTest();
		List<GMAEL_Category_Type_Relationship__c> productTypeRelationships = GMAEL_AccessPassportController.retrieveProductTypeByCategoryId(productCategory.Id);
		Test.stopTest();
		System.assert(productTypeRelationships != null);
		System.assert(productTypeRelationships.size() == productCategory.GMAEL_Category_Description_Relationships__r.size());

	}
	@IsTest
	static void submitForApproval(){
		Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
		GMAEL_Report__c report = GMAEL_TestDataFactory.createGmaelReport(1,contact.AccountId, contact.Id, 'Draft', true)[0];

		Test.startTest();
		//GMAEL_AccessPassportController.submitForApproval(report.Id);
		Test.stopTest();
		//GMAEL_Report__c updatedReport = [SELECT Id, GMAEL_Report_Status__c FROM GMAEL_Report__c WHERE Id = :report.Id];
		//System.assert(updatedReport.GMAEL_Report_Status__c == 'Pending Approval');
	}

	@IsTest
	static void getData(){
		GMAEL_Report__c report = [SELECT Id FROM GMAEL_Report__c LIMIT 1];

		Test.startTest();
		Map<String, Object> dataResult = GMAEL_AccessPassportController.getData(report.Id);
		Test.stopTest();

		System.assert(dataResult != null);
		System.assert(dataResult.get('approvedCountries') != null);
		System.assert(dataResult.get('countriesIso2') != null);
		System.assert(dataResult.get('approvedProductCategories') != null);
		System.assert(dataResult.get('reportRecordData') != null);
		System.assert(dataResult.get('countriesToBePrePopup') != null);
		System.assert(dataResult.get('isReportObject') == true);
		System.assert(dataResult.get('reportId') == report.Id);
	}

	@IsTest
	static void retrieveRegionsByCountries(){
		GMAEL_Country__c country = [SELECT Id, GMAEL_Region__c FROM GMAEL_Country__c LIMIT 1];

		Test.startTest();
		List<GMAEL_Region__c> regions = GMAEL_AccessPassportController.retrieveRegionsByCountries( new List<String>{country.Id});
		Test.stopTest();
		System.assert(regions != null && regions.size() == 1);
		System.assert(regions[0].Id == country.GMAEL_Region__c);
	}

	@IsTest
	static void retrieveReportData(){
		List<GMAEL_Country__c> counties = [SELECT Id FROM GMAEL_Country__c];
		List<String> countryIds = new List<String>();
		for(GMAEL_Country__c country : counties){
			countryIds.add(country.Id);
		}

		Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
		GMAEL_Report__c report = [SELECT Id, GMAEL_GIN__c FROM GMAEL_Report__c LIMIT 1];

		GMAEL_Category_Type_Relationship__c productTypes = [SELECT Id, GMAEL_Product_Category__c
		FROM GMAEL_Category_Type_Relationship__c
		WHERE GMAEL_Category_Type_Relationship_Status__c = 'Approved'
		LIMIT 1];


		Test.startTest();
		GMAEL_AccessReportUtility.AccessReportWrapper reportData = GMAEL_AccessPassportController.retrieveReportData(
			countryIds,
			contact.AccountId,
			contact.Id,
			report.GMAEL_GIN__c,
			productTypes.Id,
			productTypes.GMAEL_Product_Category__c,
			report.Id,
			false
		);
		Test.stopTest();
		System.assert(reportData.reportObj.GMAEL_GIN__c == report.GMAEL_GIN__c);
	}
}