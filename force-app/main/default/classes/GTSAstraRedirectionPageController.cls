/*
* @author       Globant
* @created      16-Jan-2024
* @description  Controller class to redirect users to track job detail page based on Astra ID
*/
public with sharing class GTSAstraRedirectionPageController {

    @RemoteAction
    public static PageReference trackJobRedirection(String astraID) {
        //Construct track job page URL
        String redirectURL = Url.getOrgDomainUrl().toExternalForm().replace('salesforce', 'site');
        redirectURL += '/iCareGTS/s/detail/';

        List<iCare_Job__c> jobRecord = [SELECT Id FROM iCare_Job__c WHERE iCare_Ops_System_Job_Number__c = :astraID];
        redirectURL += jobRecord[0]?.Id;

        PageReference returnURL = new PageReference(redirectURL);
        returnURL.setRedirect(true);
        return returnURL;
    }
}