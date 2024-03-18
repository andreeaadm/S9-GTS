/***
History:
    11-07-2023  Kamlesh.kahar   Fixed the query condition and added custom label    https://intertek.atlassian.net/browse/MBS-294
***/

public class MTC_deleteACCRrecords implements Database.Batchable<sObject>,Database.AllowsCallouts {
	public final Integer DAYS_OLD = Integer.valueOf(System.Label.Delete_ACR_Records_Older_Than_N_Days);
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'Select Id,Expiry_Date__c From Asset_Contact_Relationship__c where Expiry_Date__c < LAST_N_DAYS:' + DAYS_OLD;
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Asset_Contact_Relationship__c> accrs){
        delete accrs;
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
}