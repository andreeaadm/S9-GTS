@IsTest
public with sharing class GMAEL_GelocationPhoneNumber_Test {
    @TestSetup
	static void setUp() {
        List<GMAEL_Country_Phone_Mapping__mdt> countryPhoneMappings = new List<GMAEL_Country_Phone_Mapping__mdt>();
        GMAEL_Country_Phone_Mapping__mdt testCountryPhoneMapping = new GMAEL_Country_Phone_Mapping__mdt();
        testCountryPhoneMapping.DeveloperName ='Test Country';
        testCountryPhoneMapping.MasterLabel ='Test Country';
        testCountryPhoneMapping.Country__c ='Test Country';
        testCountryPhoneMapping.Phone__c ='+1111111';
        countryPhoneMappings.add(testCountryPhoneMapping);

        GMAEL_Country_Phone_Mapping__mdt testCountryPhoneMapping_Default = new GMAEL_Country_Phone_Mapping__mdt();
        testCountryPhoneMapping_Default.DeveloperName ='Default';
        testCountryPhoneMapping_Default.MasterLabel ='Default';
        testCountryPhoneMapping_Default.Country__c ='Default';
        testCountryPhoneMapping_Default.Phone__c ='+000000';
        countryPhoneMappings.add(testCountryPhoneMapping_Default);

        //insert countryPhoneMappings;
    }

    @IsTest
	static void testGMAEL_GelocationPhoneNumber() {

        //Intializing Controller
        GMAEL_GelocationPhoneNumber ctlObj = new GMAEL_GelocationPhoneNumber();

        String phone = GMAEL_GelocationPhoneNumber.determinePhoneNumber('');
        System.assert(phone!=null && phone.length()>0);


        GMAEL_GelocationPhoneNumber.getData('');
    }
}