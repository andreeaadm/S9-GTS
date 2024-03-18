@isTest
public class GMAEL_AccessPassportPortalControllerTest {
    @isTest
    static void testGetCountriesListView() {
        
        GMAEL_Region__c region = GMAEL_TestDataFactory.createGmaelRegion(1,true).get(0);
		List<GMAEL_Country__c> countries = new List<GMAEL_Country__c>();

		for (Integer i = 0; i < 5; i++) {
			GMAEL_Country__c country
				= new GMAEL_Country__c(
					Name = 'Country ' + i,
					GMAEL_ISO_Code__c = 'I' + i,
					GMAEL_Region__c = region.Id,
					GMAEL_National_Deviation_Supply_Voltage__c = 'National Deviation Supply Voltage',
					GMAEL_Country_Status__c = 'Approved',
                    GMAEL_Continent__c = 'Asia'
				);
			countries.add(country);
		}
        insert countries;
        // Call the method being tested
        Test.startTest();
            Map<String, Object> result = GMAEL_AccessPassportPortalController.getCountriesListView();
        Test.stopTest();

        // Perform assertions
        System.assert(result != null, 'Result should not be null');
        // Add more specific assertions based on your actual implementation and expected data
    }

    @isTest
    static void testGetCountriesListView_Negative() {

        GMAEL_Country__c country = new GMAEL_Country__c(
            Name = 'Country ',
            GMAEL_ISO_Code__c = 'I',
            GMAEL_National_Deviation_Supply_Voltage__c = 'National Deviation Supply Voltage',
            GMAEL_Country_Status__c = 'Approved',
            GMAEL_Continent__c = 'Asia01'
        );

        String errorMsg;
        // Call the method being tested
        Test.startTest();
            try {

                insert country;
                Map<String, Object> result = GMAEL_AccessPassportPortalController.getCountriesListView();
            } catch (Exception ex) {

                errorMsg = ex.getMessage();
            }
        Test.stopTest();

        // Perform assertions
        System.assert(errorMsg != null, 'Result should not be null');
    }

    @isTest
    static void testGetReportData() {

        GMAEL_Region__c region = GMAEL_TestDataFactory.createGmaelRegion(1,true).get(0);
		List<GMAEL_Country__c> countries = GMAEL_TestDataFactory.createGmaelCounties(5, region.Id, true);

        // Call the method being tested
        Test.startTest();
            List<String> countryNames = new List<String>{'Country1', 'Country2'};
            GMAEL_AccessReportUtilityLite.AccessReportWrapper result = GMAEL_AccessPassportPortalController.getReportData(countryNames);
        Test.stopTest();

        // Perform assertions
        System.assert(result != null, 'Result should not be null');
        // Add more specific assertions based on your actual implementation and expected data
    }
}