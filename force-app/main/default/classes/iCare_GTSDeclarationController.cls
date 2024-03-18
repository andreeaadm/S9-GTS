/********************************************************************************************
* @Name         iCare_GTSDeclarationController
* @Author       Michael Thomas
* @Description  Controller class for the GTS Declaration LWC to handle database operations
*				
*********************************************************************************************/
public with sharing class iCare_GTSDeclarationController {
    
    @AuraEnabled(cacheable=true)
	public static List<iCare_Country_specific_information__mdt> getTermsAndConditions(String userId)
	{
        User loggedInUser = [SELECT Account.BillingCountryCode FROM User WHERE Id = :userId];
        String countryCode = loggedInUser?.Account?.BillingCountryCode; 
		return [SELECT GTS_T_Cs_required__c
                FROM iCare_Country_specific_information__mdt
                WHERE DeveloperName = :countryCode LIMIT 1];
	}
}