/*
* @author       Globant
* @created      02-Oct-2023
* @description  Class contains logic to render Access Passport Report on portal/public page
*/

public with sharing class GMAEL_AccessPassportPortalController {
    
    @AuraEnabled
    public static Map<String, Object> getCountriesListView(){

        try {
            
            Map<String, List<GMAEL_Country__c>> countriesByContinent = new Map<String, List<GMAEL_Country__c>>();
            List<GMAEL_Country__c> countries = [SELECT Id, Name, GMAEL_Continent__c, GMAEL_Country_Status__c, 
													GMAEL_ISO_Code__c, GMAEL_Migration_ID__c, GMAEL_National_Deviation_Supply_Freqncy__c, 
													GMAEL_National_Deviation_Supply_Voltage__c,GMAEL_Region__c, GMAEL_Scheme_Document__c, 
													GMAEL_Sequence__c, GMAEL_Geolocation__latitude__s,
													GMAEL_Geolocation__longitude__s, GMAEL_Is_Small_Country__c
											    FROM GMAEL_Country__c  WHERE GMAEL_Country_Status__c = 'Approved' 
                                                ORDER BY GMAEL_Continent__c, Name];

            for (GMAEL_Country__c country : countries) {

                if (String.isNotBlank(country.GMAEL_Continent__c)) {

                    if (!countriesByContinent.containsKey(country.GMAEL_Continent__c)) {
                    
                        countriesByContinent.put(country.GMAEL_Continent__c, new List<GMAEL_Country__c>());
                    }
                    countriesByContinent.get(country.GMAEL_Continent__c).add(country);
                }
            }

            return countriesByContinent;
        } catch (Exception e) {

            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static GMAEL_AccessReportUtilityLite.AccessReportWrapper getReportData(List<String> countries){

        try {
            
            GMAEL_AccessReportUtilityLite.AccessReportInput reportInput = new GMAEL_AccessReportUtilityLite.AccessReportInput();
            reportInput.countries = countries;
            reportInput.reportId = null;
            return GMAEL_AccessReportUtilityLite.generateAccessReport(reportInput);
        } catch (Exception e) {
            System.debug('--------------'+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }    
}