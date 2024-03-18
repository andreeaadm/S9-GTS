/*
* @author       Globant
* @created      20-Sep-2023
* @description  Class contains logic to render Access Passport Report
*/
public with sharing class GMAEL_AccessPassportController {

	@AuraEnabled(cacheable=true)
	public static String getContacts(String accountId) {

		List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE AccountId = :accountId];
		return JSON.serialize(contacts);
	}

	@AuraEnabled
	public static List<GMAEL_Country__c> retrieveCountriesByIsocode(String countryIsoCode) {

		GMAEL_Country__c country = [SELECT Id, Name, GMAEL_Country_Status__c, GMAEL_ISO_Code__c, GMAEL_Migration_ID__c, GMAEL_National_Deviation_Supply_Freqncy__c,
											GMAEL_National_Deviation_Supply_Voltage__c, GMAEL_Region__c, GMAEL_Scheme_Document__c, GMAEL_Geolocation__latitude__s,
											GMAEL_Geolocation__longitude__s, GMAEL_Is_Small_Country__c
									FROM GMAEL_Country__c
									WHERE GMAEL_ISO_Code__c = :countryIsoCode];

		List<GMAEL_Country__c> countries = new List<GMAEL_Country__c>();
		if(String.isBlank(country.GMAEL_Region__c)){
			countries.add(country);
		}else {
			countries = [SELECT Id, Name, GMAEL_Country_Status__c, GMAEL_ISO_Code__c, GMAEL_Migration_ID__c, GMAEL_National_Deviation_Supply_Freqncy__c,
								GMAEL_National_Deviation_Supply_Voltage__c, GMAEL_Region__c, GMAEL_Scheme_Document__c, GMAEL_Geolocation__latitude__s,
								GMAEL_Geolocation__longitude__s, GMAEL_Is_Small_Country__c
						FROM GMAEL_Country__c
						WHERE GMAEL_Region__c = :country.GMAEL_Region__c AND GMAEL_Country_Status__c = 'Approved'];
		}

		return countries;
	}

	@AuraEnabled
	public static List<GMAEL_Country__c> retrieveCountries() {

		List<GMAEL_Country__c> countries = [SELECT Id, Name, GMAEL_Country_Status__c, 
													GMAEL_ISO_Code__c, GMAEL_Migration_ID__c, 
													GMAEL_National_Deviation_Supply_Freqncy__c, 
													GMAEL_National_Deviation_Supply_Voltage__c, 
													GMAEL_Region__c, GMAEL_Scheme_Document__c, 
													GMAEL_Sequence__c, GMAEL_Geolocation__latitude__s,
													GMAEL_Geolocation__longitude__s, GMAEL_Is_Small_Country__c
											FROM GMAEL_Country__c 
											WHERE GMAEL_Country_Status__c = 'Approved' 
											ORDER BY GMAEL_Sequence__c , Name];

		return countries;
	}

	@AuraEnabled
	public static Map<String, Object> retrieveISO2CountriesByIds(List<String> countryIds) {

		List<String> countriesISO2Regions = new List<String>();
		List<String> countriesISO2Markers = new List<String>();
		List<GMAEL_Country__c> countries = [SELECT Id, Name, GMAEL_Country_Status__c, 
													GMAEL_ISO_Code__c, GMAEL_Migration_ID__c, 
													GMAEL_National_Deviation_Supply_Freqncy__c, 
													GMAEL_National_Deviation_Supply_Voltage__c, 
													GMAEL_Region__c, GMAEL_Scheme_Document__c, 
													GMAEL_Sequence__c, GMAEL_Geolocation__latitude__s,
													GMAEL_Geolocation__longitude__s, GMAEL_Is_Small_Country__c 
											FROM GMAEL_Country__c 
											WHERE GMAEL_Country_Status__c = 'Approved' 
											AND Id IN:countryIds 
											ORDER BY GMAEL_Sequence__c , Name];

		for (GMAEL_Country__c c :countries) {
			
			if (c.GMAEL_Is_Small_Country__c) {
				
				countriesISO2Markers.add(c.GMAEL_ISO_Code__c);
			} else {
				
				countriesISO2Regions.add(c.GMAEL_ISO_Code__c);
			}
		}

		return new Map<String, Object>{
			'regions' => countriesISO2Regions,
			'markers' => countriesISO2Markers
		};
	}

	@AuraEnabled
	public static List<GMAEL_Product_Category__c> retrieveProductCategories() {

		List<GMAEL_Product_Category__c> productCategories = [SELECT Id, Name, GMAEL_Product_Category_Name__c 
															FROM GMAEL_Product_Category__c
															WHERE GMAEL_Product_Category_Status__c = 'Approved'];

		return productCategories;
	}

	@AuraEnabled
	public static Map<String, Object> getData(String recordId) {

		Map<String, Object> countriesISO2ToPrePopup = new Map<String, Object>();
		Map<String, Integer> countriesISO2MapForJVector = new Map<String, Integer>();
		Map<String, Object> smallCountries = new Map<String, Object>();
		Boolean isReportObject = retrieveCurrentObjectName(recordId) == 'GMAEL_Report__c';
		GMAEL_Report__c gMAELReport = getGMAELReport(recordId, isReportObject);
		List<GMAEL_Country__c> approvedCountries = retrieveCountries();

		if(String.isNotBlank(gMAELReport?.GAMEL_Filter_JSON__c)) {

			GMAEL_AccessReportUtility.AccessReportInput reportInput = (GMAEL_AccessReportUtility.AccessReportInput) JSON.deserialize(gMAELReport?.GAMEL_Filter_JSON__c, GMAEL_AccessReportUtility.AccessReportInput.class);
			countriesISO2ToPrePopup = retrieveISO2CountriesByIds(reportInput.countries);
		}

		for (GMAEL_Country__c c : approvedCountries) {
			
			countriesISO2MapForJVector.put(c.GMAEL_ISO_Code__c, 1);

			if (c.GMAEL_Is_Small_Country__c == true) {

				Map<String, Object> objLatLng = new Map<String, Object>();

				List<Decimal> latlng = new List<Decimal>{
					c.GMAEL_Geolocation__latitude__s,
					c.GMAEL_Geolocation__longitude__s
				};

				objLatLng.put('latLng', latlng);
				objLatLng.put('name', c.Name);
				
				smallCountries.put(c.GMAEL_ISO_Code__c, objLatLng);
			}
		}

		Map<String, Object> data = new Map<String, Object> {
			'approvedCountries' => approvedCountries,
			'smallCountries' => smallCountries,
			'countriesIso2' => countriesISO2MapForJVector,
			'approvedProductCategories' => retrieveProductCategories(),
			'reportRecordData' => gMAELReport,
			'countriesToBePrePopup' => countriesISO2ToPrePopup,
			'isReportObject' => isReportObject,
			'reportId' => (retrieveCurrentObjectName(recordId) == 'GMAEL_Report__c' ? recordId : '')
		};

		return data;
	}

	private static String retrieveCurrentObjectName(String recordId) {

		return String.isNotBlank(recordId) ? ((Id) recordId).getSObjectType().getDescribe().getName() : null;
	}

	private static GMAEL_Report__c getGMAELReport(String recordId, Boolean isReportObject) {
		
		if (!isReportObject) {
			
			return null;
		}

		return [SELECT Id, GMAEL_Account__c, GAMEL_Contact__c, GMAEL_GIN__c, GMAEL_Report_Number__c,
				GAMEL_Filter_JSON__c, GMAEL_Report_Status__c, GMAEL_System_Id__c, GMAEL_Type__c, Name, 
				(SELECT Id,GMAEL_Country_ISO_Code__c, GMAEL_Country_Name__c 
				FROM GMAEL_Report_Countries__r) 
				FROM GMAEL_Report__c WHERE Id =:recordId];
	}

	@AuraEnabled
	public static List<GMAEL_Category_Type_Relationship__c> retrieveProductTypeByCategoryId(String productCategoryId) {

		List<GMAEL_Category_Type_Relationship__c> productTypes = [SELECT Id, Name, GMAEL_Product_Type__c, Product_Type_Name__c 
																	FROM GMAEL_Category_Type_Relationship__c
																	WHERE GMAEL_Category_Type_Relationship_Status__c = 'Approved'
																	AND GMAEL_Product_Category__c = :productCategoryId];

		return productTypes;
	}

	@AuraEnabled
	public static List<GMAEL_Region__c> retrieveRegionsByCountries(List<String> countryIds) {

		List<GMAEL_Region__c> regions = [SELECT Id, Name, (SELECT Id, Name
											FROM GMAEL_Countries__r 
											WHERE GMAEL_Country_Status__c = 'Approved' 
											ORDER BY GMAEL_Sequence__c , Name)
										FROM GMAEL_Region__c 
										WHERE Id IN (SELECT GMAEL_Region__c
										 	FROM GMAEL_Country__c WHERE Id IN :countryIds) 
										];

		return regions;
	}

	@AuraEnabled
	public static GMAEL_AccessReportUtility.AccessReportWrapper retrieveReportData(
		List<String> countries, String accountId, String contactId, String ginNumber,
		String productDescriptionId, String productCategoryId, String reportId, Boolean isPreviewed 
	) {
		
		try {

			GMAEL_AccessReportUtility.AccessReportInput  inputObj = new GMAEL_AccessReportUtility.AccessReportInput();
			inputObj.countries = countries; 
			inputObj.accId = accountId;
			inputObj.contactId = contactId; 
			inputObj.ginNumber = ginNumber;
			inputObj.productDescriptionId = productDescriptionId;
			inputObj.productCategoryId = productCategoryId;
			inputObj.reportId = reportId;

			GMAEL_AccessReportUtility.AccessReportWrapper accessReportData = GMAEL_AccessReportUtility.generateAccessReport(inputObj);
			
			if (isPreviewed == true) {
				
				accessReportData = GMAEL_AccessReportUtility.saveAccessReportData(accessReportData);
			}

			return accessReportData;
		} catch (Exception e) {
			
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void submitForApproval(String reportId){
		
		try {
			
			GMAEL_Report__c report = new GMAEL_Report__c(
				Id = reportId,
				GMAEL_Report_Status__c = 'Pending Approval'
			);

			update report;
		} catch (Exception e) {

			throw new AuraHandledException(e.getMessage());
		}
	}
}