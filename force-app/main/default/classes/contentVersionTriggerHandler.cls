public class contentVersionTriggerHandler {
	public static void checkRecallOrRegulation(List<ContentVersion> ContentVersionList){
        Set<Id> linkedEntityRegulationSet = new Set<Id>();
        Set<Id> linkedEntityRecallSet = new Set<Id>();

        System.debug('ContentVersionList is: ' + ContentVersionList);
           
        //For Regulation Prefix
        String regulation = System.Label.Regulation;
        String RegulationPrefix = getObjectPrefix(regulation);
           
        //For Recall Prefix
        String recall = System.Label.Recall;
        String RecallPrefix = getObjectPrefix(recall);
           
        for(ContentVersion a:ContentVersionList){
            System.debug('id is: ' + a.Id);
            String relatedRegulation;
            if(a.FirstPublishLocationId != null){
                relatedRegulation = Id.valueOf(a.FirstPublishLocationId);
                if(relatedRegulation.startsWith(RegulationPrefix)){
                    linkedEntityRegulationSet.add(a.FirstPublishLocationId);
                }
                if(relatedRegulation.startsWith(RecallPrefix)){
                    linkedEntityRecallSet.add(a.FirstPublishLocationId);
                } 
            }
        } 
           
        System.debug('linkedEntityRegulationSet id is: ' + linkedEntityRegulationSet);  
        System.debug('linkedEntityRecallSet id is: ' + linkedEntityRecallSet);
          
        if(!linkedEntityRegulationSet.isEmpty()){
            List<ContentDistribution> insertedContentDist = createContentDistribution(linkedEntityRegulationSet, ContentVersionList);
            if(!insertedContentDist.isEmpty()){
                updateRegulation(linkedEntityRegulationSet, insertedContentDist);
            }
        } 
        if(!linkedEntityRecallSet.isEmpty()){
            List<ContentDistribution> insertedContentDist =createContentDistribution(linkedEntityRecallSet, ContentVersionList);
            if(!insertedContentDist.isEmpty()){
                updateRecall(linkedEntityRecallSet, insertedContentDist);
            }
        }    
               
    }

    //Method to check the object prefix
    public static String getObjectPrefix(String objName){
        Map<String, Schema.SObjectType> m  = Schema.getGlobalDescribe() ;
        system.debug('==>m is==>'+m);
        Schema.SObjectType obj = m.get(objName) ;
        system.debug('==>Sobject Type is ==>'+obj);
        Schema.DescribeSObjectResult objResult = obj.getDescribe() ;
        String objPrefix = objResult.getKeyPrefix();
        system.debug('==>objPrefix keyPrefix ==>'+objPrefix);
        return objPrefix;
    }

    //Method to create ContentDistribution.
    public static List<ContentDistribution> createContentDistribution(Set<Id> relatedRecordId, List<ContentVersion> ContentVersionList){
        List<ContentDistribution> contDisbToCreate = new List<ContentDistribution>();
        
        List<ContentVersion> conVersionList = [SELECT id,Title FROM ContentVersion WHERE FirstPublishLocationId IN :relatedRecordId AND id IN :ContentVersionList];
        
        for(ContentVersion conVersion:conVersionList){
            System.debug('ContentVersion ==== ' + conVersion);
        
            ContentDistribution conDist = new ContentDistribution();
            conDist.ContentVersionId = conVersion.Id;
            conDist.Name = conVersion.Title;
            conDist.PreferencesAllowPDFDownload = false;
            conDist.PreferencesAllowViewInBrowser = true;
            contDisbToCreate.add(conDist);
        }
        insert contDisbToCreate;
        System.debug('contDisbToCreate id is: ' + contDisbToCreate);

        return contDisbToCreate;
    }
    
    //To update Regulation
    public static void updateRegulation(Set<Id> linkedEntityRegulationSet,List<ContentDistribution> insertedContentDist){
        Set<Regulation__c> regulationSet = new Set<Regulation__c>(); 
        List<Regulation__c> finalRegulationList = new List<Regulation__c>(); 
        List<Regulation__c> regulationList = new List<Regulation__c>();//Can't Make this as set here ,its throwing error when doing update in line 138 as duplicate ids.
        Map<Id,Regulation__c> regulationMap = new Map<Id,Regulation__c>([SELECT Id,Technical_Details__c FROM Regulation__c WHERE Id = :linkedEntityRegulationSet]);

        List<ContentDistribution> contentDistributionList = [SELECT Id,ContentDownloadUrl,Name,ContentVersion.FirstPublishLocationId FROM ContentDistribution WHERE Id IN :insertedContentDist];
        System.debug('contentDistributionList id is: ' + contentDistributionList);
        System.debug('contentDistributionList size is: ' + contentDistributionList.size());
        
        for(ContentDistribution conDistribution:contentDistributionList){
            System.debug('conDistribution for loop: ' + conDistribution);
            Regulation__c reg = regulationMap.get(conDistribution.ContentVersion.FirstPublishLocationId);
            if(reg != null && reg.Technical_Details__c.containsIgnoreCase('['+conDistribution.Name+']')){
               System.debug('entered if');
               String updatedTechDetails =  reg.Technical_Details__c.replace('['+conDistribution.Name+']', '<img src='+conDistribution.ContentDownloadUrl+' alt='+conDistribution.Name+'></img>');
               System.debug('updatedTechDetails'+updatedTechDetails);
               reg.Technical_Details__c = updatedTechDetails;
               regulationList.add(reg);
        	}
        }
           
        System.debug('regulationList ' + regulationList); 
      
        regulationSet.addAll(regulationList); //to remove duplicate records
        finalRegulationList.addAll(regulationSet);   //coz we cant use set for DML

        update finalRegulationList;
    }

    
    //To update Recall
    public static void updateRecall(Set<Id> linkedEntityRecallSet, List<ContentDistribution> insertedContentDist){
        Set<Recall__c> recallSet = new Set<Recall__c>(); 
        List<Recall__c> finalRecallList = new List<Recall__c>(); 
        List<Recall__c> recallList = new List<Recall__c>();
        Map<String,Recall__c> recallMap = new Map<String,Recall__c>([SELECT Id,Images__c FROM Recall__c  WHERE Id = :linkedEntityRecallSet]);

        System.debug('recallMap is: ' + recallMap);

        List<ContentDistribution> contentDistributionList = [SELECT Id,ContentDownloadUrl,Name,ContentVersion.FirstPublishLocationId FROM ContentDistribution WHERE Id IN :insertedContentDist];
        System.debug('contentDistributionList id is: ' + contentDistributionList);
        System.debug('contentDistributionList size is: ' + contentDistributionList.size());

        for(ContentDistribution conDistribution:contentDistributionList){
            System.debug('conDistribution for loop: ' + conDistribution);
            Recall__c recall = recallMap.get(conDistribution.ContentVersion.FirstPublishLocationId);
            if(recall != null && recall.Images__c.containsIgnoreCase('['+conDistribution.Name+']')){
               String updatedImages =  recall.Images__c.replace('['+conDistribution.Name+']', '<img src='+conDistribution.ContentDownloadUrl+'></img>');
               recall.Images__c = updatedImages;
               recallList.add(recall);
        	}
        }
           
        System.debug('recallList ' + recallList); 
      
        recallSet.addAll(recallList); //to remove duplicate records
        finalRecallList.addAll(recallSet);   //coz we cant use set for DML

        update finalRecallList;
    }
}