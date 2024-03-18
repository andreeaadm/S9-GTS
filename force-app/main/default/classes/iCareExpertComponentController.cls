/********************************************************************************************
* @Name         iCareExpertComponentControllerTest
* @Author       Regan Smiith
* @Description  This class is used by the Expert Component LWC to query iCare_Expert records 
*				and return the correct ones based on user details
*********************************************************************************************/
public with sharing class iCareExpertComponentController {
    public static final Id GTS_EXPERT_RECORD_TYPE_ID = Schema.SObjectType.iCare_Expert__c.getRecordTypeInfosByDeveloperName().get('GTS_Expert').getRecordTypeId();
    @AuraEnabled(cacheable=true)
    public static List<iCare_Expert__c> getExpertsList(String selection){
        
        List<iCare_Expert__c> expertsRetrieved = new List<iCare_Expert__c>();
        
        User currentUser = [ SELECT Id, CountryCode, LanguageLocaleKey  FROM User 
                            WHERE Id =: UserInfo.getUserId() ];
        
        try {
            if(selection != null && selection == 'Global'){
                for(iCare_Expert__c expert :  [SELECT Id, Name, iCare_IsActive__c, ICare_Bio__c, ICare_Country__c, ICare_Profile_Picture__c,
                                               ICare_Role__c,GTS_Bio__c,GTS_Role__c, GTS_Country__c, GTS_Global_Expert__c
                                               FROM iCare_Expert__c
                                               WHERE iCare_IsActive__c = true
                                               AND RecordTypeId = :GTS_EXPERT_RECORD_TYPE_ID]){
                                                   if(expert.GTS_Global_Expert__c){
                                                       expertsRetrieved.add(expert); 
                                                   }
                                               }
            }else{
                expertsRetrieved = [SELECT Id, Name, iCare_IsActive__c, ICare_Bio__c, ICare_Country__c, ICare_Profile_Picture__c,
                                    ICare_Role__c,GTS_Bio__c,GTS_Role__c, GTS_Country__c
                                    FROM iCare_Expert__c
                                    WHERE iCare_IsActive__c = true 
                                    AND RecordTypeId = :GTS_EXPERT_RECORD_TYPE_ID
                                    AND GTS_Country__c INCLUDES (:currentUser.CountryCode) ];
            }
        } catch(QueryException qe){
            System.debug('An Error Has Occurred whilst retriving experts: '+ qe);
        }
        return expertsRetrieved;
    }
    @AuraEnabled(cacheable=true)
    public static GTS_Expert_Translation__c getGtsExpertTranslation(Id expertId){
        User currentUser = [ SELECT Id, CountryCode, LanguageLocaleKey  FROM User 
                            WHERE Id =: UserInfo.getUserId() ];
        GTS_Expert_Translation__c expertTranslationRec ;
        try {
            expertTranslationRec = [SELECT Id, GTS_Bio_Translation__c, GTS_Role_Translation__c
                                    FROM GTS_Expert_Translation__c 
                                    Where GTS_Language_ISO_Code__c = :currentUser.LanguageLocaleKey
                                    AND GTS_Associated_Expert__c =:expertId
                                    LIMIT 1];
        } catch(QueryException qe){
            System.debug('An Error Has Occurred whilst retriving expertTranslationRecord: '+ qe);
        }
        return expertTranslationRec;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getGtsExpertQueryRecordtypeId(){
        
        String recordTypeId ;
        try {
            recordTypeId = [SELECT Id, Name  FROM RecordType
                            WHERE DeveloperName = 'GTS_Expert_Query' LIMIT 1 ].Id;
        } catch(QueryException qe){
            System.debug('An Error Has Occurred whilst retriving recordTypeId: '+ qe);
        }
        return recordTypeId;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getGtsExpertQueryQueueId(){
        
        String queueId ;        
        try {
            queueId = [SELECT Id, Name  FROM Group
                       WHERE DeveloperName = 'GTS_Expert_Query_Queue' AND Type = 'Queue' LIMIT 1 ].Id;
        } catch(QueryException qe){
            System.debug('An Error Has Occurred whilst retriving Queue Id: '+ qe);
        }
        return queueId;
    }
}