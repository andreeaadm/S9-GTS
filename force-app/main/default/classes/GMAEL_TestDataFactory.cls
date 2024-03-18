@IsTest
public class GMAEL_TestDataFactory {
	public static GMAEL_Category_Type_Relationship__c createGmaelCategoryTypeRelationships(Id productCategoryId, Id productTypeId, Boolean doInsert) {

		GMAEL_Category_Type_Relationship__c categoryTypeRelationship = new GMAEL_Category_Type_Relationship__c(
			GMAEL_Category_Type_Relationship_Status__c = 'Approved',
			GMAEL_Product_Category__c = productCategoryId,
			GMAEL_Product_Type__c = productTypeId
		);

		if (doInsert) {
			insert categoryTypeRelationship;
		}
		return categoryTypeRelationship;
	}
	public static List<GMAEL_Country__c> createGmaelCounties(Integer nrOfRecords, Id regionId, Boolean doInsert) {
		List<GMAEL_Country__c> countries = new List<GMAEL_Country__c>();
		for (Integer i = 0; i < nrOfRecords; i++) {
			GMAEL_Country__c country
				= new GMAEL_Country__c(
					Name = 'Country ' + i,
					GMAEL_ISO_Code__c = 'I' + i,
					GMAEL_Region__c = regionId,
					GMAEL_National_Deviation_Supply_Voltage__c = 'National Deviation Supply Voltage',
					GMAEL_Country_Status__c = 'Approved'
				);
			countries.add(country);
		}
		if (doInsert) {
			insert countries;
		}
		return countries;
	}
	public static GMAEL_Country_Body_Relationship__c countryBodyRelationship(Id governingBodyId, Id countryId, Boolean doInsert) {

		GMAEL_Country_Body_Relationship__c countryBodyRelationship = new GMAEL_Country_Body_Relationship__c(
			GMAEL_Country__c = countryId,
			GMAEL_Issuing_Governing_Body__c = governingBodyId
		);

		if (doInsert) {
			insert countryBodyRelationship;
		}
		return countryBodyRelationship;
	}

	public static GMAEL_Plug_Type__c createPlugType(String plugTypeName, Boolean doInsert) {

		GMAEL_Plug_Type__c plugType = new GMAEL_Plug_Type__c(
			Name = plugTypeName,
			GMAEL_Plug_Type_Description__c = plugTypeName,
			GMAEL_Plug_Type_Status__c = 'Approved',
			GMAEL_Logo_File_URL__c = 'https://plugimage.com'
		);

		if (doInsert) {
			insert plugType;
		}
		return plugType;
	}

	public static GMAEL_Country_Plug_Type_Relationship__c createPlugTypeRelationship(String plugTypeId, String countryId, Boolean doInsert) {

		GMAEL_Country_Plug_Type_Relationship__c plugTypeRelationship = new GMAEL_Country_Plug_Type_Relationship__c(
			GMAEL_Plug_Type__c = plugTypeId,
			GMAEL_Country__c = countryId,
			GMAEL_CPTR_Status__c = 'Approved'
		);

		if (doInsert) {
			insert plugTypeRelationship;
		}
		return plugTypeRelationship;
	}


	public static List<GMAEL_Issuing_Governing_Body__c> createGmaelIssuingGoverningBodies(Integer nrOfRecords, Boolean doInsert) {
		List<GMAEL_Issuing_Governing_Body__c> issuingGoverningBodies = new List<GMAEL_Issuing_Governing_Body__c>();
		for (Integer i = 0; i < nrOfRecords; i++) {
			GMAEL_Issuing_Governing_Body__c issuingGoverningBody
				= new GMAEL_Issuing_Governing_Body__c(
					GMAEL_Type__c = 'Governing Body',
					GMAEL_Acronym__c = 'ACRO'+i,
					GMAEL_Standard_Governing_Body_Status__c='Approved'
				);
			issuingGoverningBodies.add(issuingGoverningBody);
		}
		if (doInsert) {
			insert issuingGoverningBodies;
		}
		return issuingGoverningBodies;
	}
	public static List<GMAEL_Legislation__c> createGmaelLegislations(Integer nrOfRecords, Boolean doInsert) {
		List<GMAEL_Legislation__c> legislations = new List<GMAEL_Legislation__c>();
		for (Integer i = 0; i < nrOfRecords; i++) {
			GMAEL_Legislation__c legislation
				= new GMAEL_Legislation__c(
					Name = 'Legislation' + i,
					GMAEL_Effective_Date__c = Date.today().addDays(-2),
					GMAEL_Legislation_Status__c = 'Approved'
				);
			legislations.add(legislation);
		}
		if (doInsert) {
			insert legislations;
		}
		return legislations;
	}
	public static GMAEL_Legislation_Country__c createGmaelLegislationCountry(Id legislationId, Id countryId, Id governingBodyId, Boolean doInsert) {

		GMAEL_Legislation_Country__c legislationCountry = new GMAEL_Legislation_Country__c(
			GMAEL_Jurisdiction__c = countryId,
			GMAEL_Legislation__c = legislationId,
			GMAEL_Country_Conformity_Requirement__c = 'Yes',
			GMAEL_Governance_URL__c = 'test.com',
			GMAEL_Governing_Body__c = governingBodyId,
			GMAEL_Pre_Shipment_Requirement__c = 'No',
			GMAEL_Engineering_Application__c = 'Chemical/RoHS',
			GMAEL_Country_Conformity_Types__c = 'Assessment Level - Type 1a (Testing & Certification (Identified Samples))',
			GMAEL_Scheme__c = 'Mandatory'
		);

		if (doInsert) {
			insert legislationCountry;
		}
		return legislationCountry;
	}
	public static GMAEL_Legislation_Standard__c createGmaelLegislationStandard(Id standardId, Id legislationCountry, Boolean doInsert) {

		GMAEL_Legislation_Standard__c legislationStandard = new GMAEL_Legislation_Standard__c(
			GMAEL_Standard__c = standardId,
			GMAEL_Legislation_Country__c = legislationCountry
		);

		if (doInsert) {
			insert legislationStandard;
		}
		return legislationStandard;
	}
	public static List<GMAEL_Product_Category__c> createGmaelProductCategories(Integer nrOfRecords, Boolean doInsert) {
		List<GMAEL_Product_Category__c> productCategories = new List<GMAEL_Product_Category__c>();
		for (Integer i = 0; i < nrOfRecords; i++) {
			GMAEL_Product_Category__c productCategory
				= new GMAEL_Product_Category__c(
					GMAEL_Product_Category_Name__c = 'TEST-PC-' + i,
					GMAEL_Migration_ID__c = 'TEST-PC-' + i,
					GMAEL_Product_Category_Status__c = 'Approved');
			productCategories.add(productCategory);
		}
		if (doInsert) {
			insert productCategories;
		}
		return productCategories;
	}
	public static List<GMAEL_Product_Type__c> createGmaelProductTypes(Integer nrOfRecords, Boolean doInsert) {
		List<GMAEL_Product_Type__c> productTypes = new List<GMAEL_Product_Type__c>();
		for (Integer i = 0; i < nrOfRecords; i++) {
			GMAEL_Product_Type__c productType
				= new GMAEL_Product_Type__c(
					GMAEL_Product_Type_Name__c = 'PT' + i,
					GMAEL_Migration_ID__c = 'ProductType' + i,
					GMAEL_Product_Type_Status__c = 'Approved'
				);
			productTypes.add(productType);
		}
		if (doInsert) {
			insert productTypes;
		}
		return productTypes;
	}
	public static List<GMAEL_Region__c> createGmaelRegion(Integer nrOfRecords, Boolean doInsert) {
		List<GMAEL_Region__c> regions = new List<GMAEL_Region__c>();
		for (Integer i = 0; i < nrOfRecords; i++) {
			GMAEL_Region__c region
				= new GMAEL_Region__c(
					Name = 'Region ' + i);
			regions.add(region);
		}
		if (doInsert) {
			insert regions;
		}
		return regions;
	}
	public static List<GMAEL_Report__c> createGmaelReport(Integer nrOfRecords, String accountId, String contactId, String status, Boolean doInsert) {
		List<GMAEL_Report__c> reports = new List<GMAEL_Report__c>();
		for (Integer i = 0; i < nrOfRecords; i++) {
			GMAEL_Report__c report
				= new GMAEL_Report__c(
					GMAEL_Account__c = accountId,
					GAMEL_Contact__c = contactId,
					GMAEL_Report_Number__c = 'G0000000' + i,
					GMAEL_GIN__c = 'G'+String.valueOf(10000000 + i),
					GMAEL_Report_Status__c = status);
			reports.add(report);
		}
		if (doInsert) {
			insert reports;
		}
		return reports;
	}
	public static List<GMAEL_Report_Country__c> createGmaelReportCountries(Integer nrOfRecords, Id reportId, Boolean doInsert) {
		List<GMAEL_Report_Country__c> reportCountries = new List<GMAEL_Report_Country__c>();
		for (Integer i = 0; i < nrOfRecords; i++) {
			GMAEL_Report_Country__c reportCountry
				= new GMAEL_Report_Country__c(
					GMAEL_Country_ISO_Code__c = 'I' + i,
					GMAEL_Report__c = reportId);
			reportCountries.add(reportCountry);
		}
		if (doInsert) {
			insert reportCountries;
		}
		return reportCountries;
	}
	public static List<GMAEL_Standard__c> createGmaelStandard(Integer nrOfRecords, Boolean doInsert) {
		List<GMAEL_Standard__c> standards = new List<GMAEL_Standard__c>();
		for (Integer i = 0; i < nrOfRecords; i++) {
			GMAEL_Standard__c standard
				= new GMAEL_Standard__c(
					Name = 'Standard' + i,
					GMAEL_Migration_ID__c = 'STANDARD-' + i,
					GMAEL_Standard_Status__c = 'Approved'
				);
			standards.add(standard);
		}
		if (doInsert) {
			insert standards;
		}
		return standards;
	}
	public static GMAEL_Standard_Category_Type__c createGmaelStandardCategoryType(GMAEL_Category_Type_Relationship__c categoryTypeRelationship, Id standardId, Boolean doInsert) {

		GMAEL_Standard_Category_Type__c standardCategoryType = new GMAEL_Standard_Category_Type__c(
			GMAEL_Product_Category__c = categoryTypeRelationship.GMAEL_Product_Category__c,
			GMAEL_Category_Type_Relationship__c = categoryTypeRelationship.Id,
			GMAEL_Standard__c = standardId
		);

		if (doInsert) {
			insert standardCategoryType;
		}
		return standardCategoryType;
	}
}