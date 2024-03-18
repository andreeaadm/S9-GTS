/*
* @author       Globant
* @created      9-Nov-2023
* @description  Controller class to determine Phone Number based on mappings.
*/
global class GMAEL_GelocationPhoneNumber{

    private static final String GMAEL_SITE_NAME = 'GMA_EL';

    @RemoteAction
    global static Object getData(String countryName){ 

        Site mySite = [SELECT Id FROM Site WHERE Name = :GMAEL_SITE_NAME LIMIT 1];
        SiteDetail mySiteDetail = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :mySite.Id LIMIT 1];
        
        Map<String, String> dataMap = new Map<String, String>{
            'phoneNumber' => determinePhoneNumber(countryName),
            'lexOrigin' => mySiteDetail.SecureURL
        };

        return dataMap;
    }

    @RemoteAction
    global static String determinePhoneNumber(String countryName){

        List<GMAEL_Country_Phone_Mapping__mdt> countryPhoneMappings = GMAEL_Country_Phone_Mapping__mdt.getAll().values();
        String phoneNumber = GMAEL_Country_Phone_Mapping__mdt.getInstance('Default')?.Phone__c;
        
        if (countryPhoneMappings!=null) {

            for (Integer i=0; i<countryPhoneMappings.size(); i++) {

                if (countryName == countryPhoneMappings[i].Country__c) {
                    
                    phoneNumber = countryPhoneMappings[i].Phone__c;
                }
            }
        }

        return phoneNumber;
    }
}