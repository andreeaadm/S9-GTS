/**
 * @author Kaspars Rezgalis <kaspars@cloudshiftgroup.com>
 * @date 2022-05-16
 * @group CloudShiftGroup
 * @description Class to provide supporting functionality when interacting with GMA customer portal
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 16/05/2022    Kaspars Rezgalis   Created Class
*/

public without sharing class GmaPortalHelper {
    private static final String METADATA_NAME_FOR_PORTAL_URL = 'Portal_URL';
    /**
     * Method to handle logging in from custom login modal in portal
     *
     * @param username username of person logging in
     * @param password user's password
     * @param retUrl return URL to set (appended as Url parameter), i.e. url to navigate to once login is completed
     *
     * @return String login url that user should follow to complete logging in 
    */
    @AuraEnabled
    public static String portalLogin(String username, String password, String retUrl){
        try {
            String siteUrl = getGmaPortalBaseUrl();
            ApexPages.PageReference pageRef = Site.login(username, password, siteUrl);
            pageRef.getParameters().put('retUrl', retUrl);
            if (pageRef != null) {
                return pageRef.getUrl();
            }

            throw new CalloutException();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method to retrieve current user details for use in portal
     *
     * @return User user SObject 
    */
    @AuraEnabled
    public static User getCurrentUser(){
        List<User> tmpList = new List<User>([SELECT Id, ContactId, Contact.AccountId, 
                                                Contact.Account.GMA_Available_Tokens__c, Is_GMA_Portal_User__c
                                            FROM User WHERE Id =:UserInfo.getUserId()]);
        return tmpList.get(0);
    }

    /**
     * Helper method to retrieve community base url as specified in custom metadata
     *
     * @return String base URL
    */
    public static String getGmaPortalBaseUrl() {
        GMA_VAriable__mdt siteUrlVariable = GMA_VAriable__mdt.getAll().get(METADATA_NAME_FOR_PORTAL_URL);
        return siteUrlVariable.Variable_Value__c;
    }

    /**
     * Helper method to make readable timestamp from datetime
     * @param Datetime to convert (time is assumed to be in the timezone of running user, therefore no offsets should be applied)
     * @return String converted timestamp
    */
    public static String prettifyTimestamp(Datetime dTime) {
        String offsetName = UserInfo.getTimeZone().getDisplayName();
        offsetName = offsetName.left(offsetName.indexOf(')') + 1);

        return String.Valueof(dTime) + ' ' + offsetName;
    }
}