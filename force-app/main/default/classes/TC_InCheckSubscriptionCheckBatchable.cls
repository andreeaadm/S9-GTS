public with sharing class TC_InCheckSubscriptionCheckBatchable implements Database.Batchable<sObject>,Database.AllowsCallouts{
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Get Facility Accounts to loop over
        String accountType = 'Facility';
        return Database.getQueryLocator(
            'SELECT Id, Is_ToxClear_Account__c, ToxClear_Account_Type__c, ZDHC_Organisation_GUID__c, InCheck_Subscription_Expiration_Date__c, InCheck_Subscription_Start_Date__c, Facility_Manager__c, InCheck_Status__c FROM Account WHERE Is_ToxClear_Account__c = true AND ToxClear_Account_Type__c =:accountType AND ZDHC_Organisation_GUID__c != null AND Facility_Manager__c != null'
        );
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> facilitiesToBeUpdated = new List<Account>();
        List<ZDHC_Error_Log__c> calloutLogEntries = new List<ZDHC_Error_Log__c>();
        
        for(Account acc : scope) {
            ZDHCGetInCheckSubscriptionCheck ZDHCGetInCheckSubscriptionCheck = new ZDHCGetInCheckSubscriptionCheck(
                calloutLogEntries,
                acc.Facility_Manager__c, 
                new Map<String, Object>{ 'organizationGUID' => acc.ZDHC_Organisation_GUID__c }
            );
            
            if(ZDHCGetInCheckSubscriptionCheck.call()) {
                if(ZDHCGetInCheckSubscriptionCheck.response.InCheckStatus == 'Active' && acc.InCheck_Status__c == 'Active') {
                    acc.InCheck_Status__c = 'Active';
                    acc.InCheck_Subscription_Start_Date__c = ZDHCGetInCheckSubscriptionCheck.response.InCheckStartDate;
                    acc.InCheck_Subscription_Expiration_Date__c = ZDHCGetInCheckSubscriptionCheck.response.InCheckExpirationDate;
                    facilitiesToBeUpdated.add(acc);
                }
                else if(ZDHCGetInCheckSubscriptionCheck.response.InCheckStatus == 'Active' && acc.InCheck_Status__c != 'Active') {
                    acc.InCheck_Status__c = 'Active';
                    acc.InCheck_Subscription_Start_Date__c = ZDHCGetInCheckSubscriptionCheck.response.InCheckStartDate;
                    acc.InCheck_Subscription_Expiration_Date__c = ZDHCGetInCheckSubscriptionCheck.response.InCheckExpirationDate;
                    facilitiesToBeUpdated.add(acc);
                }
                else if(ZDHCGetInCheckSubscriptionCheck.response.InCheckStatus != 'Active' && acc.InCheck_Status__c != 'Active') {
                    acc.InCheck_Status__c = ZDHCGetInCheckSubscriptionCheck.response.InCheckStatus;
                    acc.InCheck_Subscription_Start_Date__c = null;
                    acc.InCheck_Subscription_Expiration_Date__c = null;
                    facilitiesToBeUpdated.add(acc);
                }
                else {
                    continue;
                }
            }
            else {
                continue;
            }
        }
        update facilitiesToBeUpdated;
        if (!calloutLogEntries.isEmpty()) {
            insert calloutLogEntries;
            calloutLogEntries.clear();
        } 
    }
    
    public void finish(Database.BatchableContext bc) {
    }
}