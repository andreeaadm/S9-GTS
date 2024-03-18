/*
* Class to test the iCare_FileDownloadController Class
* @author       Globant
* @created      29-Aug-2023
* @description  Class contains logic to create ContentDistribution record with public link for Country Mark Uploaded.
*/
public with sharing class GMAEL_CountryMarkLogoHelper {
	 public static void generateCountryMarkPublicLink(Set<Id> linkedEntityIds){
        String countryMarkKeyPrefix = GMAEL_Country_Mark__c.sObjectType.getDescribe().getKeyPrefix();
        String plugTypeKeyPrefix = GMAEL_Plug_Type__c.sObjectType.getDescribe().getKeyPrefix();
        String countryPrefix = GMAEL_Country__c.sObjectType.getDescribe().getKeyPrefix();
        String regionPrefix = GMAEL_Region__c.sObjectType.getDescribe().getKeyPrefix();

        System.debug('----------------linkedEntityIds='+linkedEntityIds);
        ContentDocumentLink[] contentDocLinks = [SELECT ContentDocumentId, LinkedEntityId  
                                                FROM ContentDocumentLink where Id in: linkedEntityIds];
        
        Map<String, String> keyPrefix_ObjectMap = new Map<String, String>();
        keyPrefix_ObjectMap.put(countryMarkKeyPrefix,'GMAEL_Country_Mark__c');
        keyPrefix_ObjectMap.put(plugTypeKeyPrefix,'GMAEL_Plug_Type__c');
        keyPrefix_ObjectMap.put(countryPrefix,'GMAEL_Country__c');
        keyPrefix_ObjectMap.put(regionPrefix,'GMAEL_Region__c');

        Map<String,String> countryMark_ContentDocIdsMap = new Map<String,String>();
        
        //Filtering Content Versions for Country Mark
        for(Integer i=0; i<contentDocLinks.size(); i++){
            if(String.valueOf(contentDocLinks[i].LinkedEntityId).startsWith(countryMarkKeyPrefix) ||
            String.valueOf(contentDocLinks[i].LinkedEntityId).startsWith(plugTypeKeyPrefix) ||
            String.valueOf(contentDocLinks[i].LinkedEntityId).startsWith(countryPrefix) ||
            String.valueOf(contentDocLinks[i].LinkedEntityId).startsWith(regionPrefix)) { 
                countryMark_ContentDocIdsMap.put(contentDocLinks[i].ContentDocumentId,contentDocLinks[i].LinkedEntityId);
            }
        }         
        
        //Retrieving Content Versions for Country Mark
        if(countryMark_ContentDocIdsMap.size()>0){
            System.debug('-------------countryMark_ContentDocIdsMap='+countryMark_ContentDocIdsMap);
            Map<String,ContentDistribution> countryMark_ContentDistributionMap = new Map<String,ContentDistribution>();
            ContentVersion[] contentVersions = [SELECT Id, Title, ContentDocumentId
                                                FROM ContentVersion 
                                                WHERE ContentDocumentId in:countryMark_ContentDocIdsMap.keySet()];
            
            for(Integer i=0; i<contentVersions.size(); i++){
                ContentDistribution conDisObj = new ContentDistribution();
                conDisObj.Name = contentVersions[i].Title;
                conDisObj.ContentVersionId = contentVersions[i].Id;
                conDisObj.PreferencesAllowViewInBrowser= true;
                conDisObj.PreferencesNotifyOnVisit = false;
                conDisObj.PreferencesNotifyRndtnComplete = false;
                countryMark_ContentDistributionMap.put(countryMark_ContentDocIdsMap.get(contentVersions[i].ContentDocumentId),conDisObj);
            }             
            
            if(countryMark_ContentDistributionMap.size()>0){
                insert countryMark_ContentDistributionMap.values();
                Set<Id> contentDistributionIds = new Set<Id>();
                
                for(Integer i=0; i<countryMark_ContentDistributionMap.values().size(); i++){
                    contentDistributionIds.add(countryMark_ContentDistributionMap.values()[i].Id);
                }
                
                Map<Id,ContentDistribution> contentDistributionMap = new Map<Id,ContentDistribution>([Select Id,ContentDownloadUrl 
                                                                                                    from ContentDistribution
                                                                                                    where Id in:contentDistributionIds]);

                List<SObject> countryMarksForUpdate = new List<SObject>();
                    
                for(String countryMarkId : countryMark_ContentDistributionMap.keySet()){
                    SObject countryMarkObj = Schema.getGlobalDescribe().get(keyPrefix_ObjectMap.get(countryMarkId.substring(0,3))).newSObject();
                    countryMarkObj.put('Id',countryMarkId);
                    countryMarkObj.put('GMAEL_Logo_File_URL__c',contentDistributionMap.get(countryMark_ContentDistributionMap.get(countryMarkId).Id).ContentDownloadUrl);
                    countryMarksForUpdate.add(countryMarkObj);
                }
                
                update countryMarksForUpdate;
            }
        }
    }
}