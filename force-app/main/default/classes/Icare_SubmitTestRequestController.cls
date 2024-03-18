public with sharing class Icare_SubmitTestRequestController {

    @AuraEnabled
    public static List<icare_Job_Request__c> getJobRequests(){
        try {
            List<icare_Job_Request__c> jobRequestList = new List<icare_Job_Request__c>();
            Id favouriteRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get('Favourite_Job_Request').getRecordTypeId();
            Id draftRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get('iCare_Job_Request').getRecordTypeId();
            
            List<icare_Job_Request__c> favouriteJobRecords = new List<icare_Job_Request__c> ();
            List<icare_Job_Request__c> draftJobRecords = new List<icare_Job_Request__c> ();
            
            for(icare_Job_Request__c objFavouriteJob : [SELECT Id, Name,createdDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name 
                                                        FROM icare_Job_Request__c 
                                                        WHERE RecordTypeId =: favouriteRecTypeId 
                                                        AND OwnerId =:userinfo.getUserId()
                                                        Order By CreatedDate desc LIMIT 5]){
                favouriteJobRecords.add(objFavouriteJob);
            }

            for(icare_Job_Request__c objDraftJob : [SELECT Id, Name,createdDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name 
                                                    FROM icare_Job_Request__c 
                                                    WHERE RecordTypeId =: draftRecTypeId
                                                    AND iCare_Draft_ETRF__c = true
                                                    AND OwnerId =:userinfo.getUserId()
                                                    Order By CreatedDate desc LIMIT 5]){
                draftJobRecords.add(objDraftJob);
            }
            
            if(!favouriteJobRecords.isEmpty()){
                jobRequestList.addAll(favouriteJobRecords);
            }

            if(!draftJobRecords.isEmpty()){
                jobRequestList.addAll(draftJobRecords);
            }
            return jobRequestList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<icare_Job_Request__c> getAllJobRequests(String recTypeName){
        try {
            Id selectedRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get(recTypeName).getRecordTypeId();
            List<icare_Job_Request__c> jobRequestList = new List<icare_Job_Request__c>();
            for(icare_Job_Request__c objJobRequest : [SELECT Id, Name,createdDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name 
                                                        FROM icare_Job_Request__c 
                                                        WHERE RecordTypeId =: selectedRecTypeId
                                                        AND iCare_Draft_ETRF__c = true
                                                        AND OwnerId =:userinfo.getUserId()
                                                        Order By CreatedDate desc]){
                jobRequestList.add(objJobRequest);
            }
            //System.debug('in all jobRequestList ** '+jobRequestList);
            //SubmitTestRequestController.totalRecords(jobRequestList);
            return jobRequestList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteJobRequest(Id jobReqId){
        try{
            delete [SELECT Id FROM icare_Job_Request__c WHERE Id = :jobReqId];
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Integer totalRecords(String selectedRecordTypeName){
        return Icare_SubmitTestRequestController.getAllJobRequests(selectedRecordTypeName).size();
    }

    @AuraEnabled(cacheable=true)
    public static List<icare_Job_Request__c> getJobRequestList(Integer v_Offset, Integer v_pagesize, String recTypeName){ 
        Id selectedRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get(recTypeName).getRecordTypeId();

        if(selectedRecTypeId == Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get('iCare_Job_Request').getRecordTypeId()){
            return [SELECT Id, Name,createdDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name 
                    FROM icare_Job_Request__c 
                    WHERE RecordTypeId =: selectedRecTypeId
                    AND iCare_Draft_ETRF__c = true
                    AND OwnerId =:userinfo.getUserId()
                    Order By CreatedDate desc limit :v_pagesize OFFSET :v_Offset ];
        } else {
            return [SELECT Id, Name,createdDate, iCare_Sample_Description__c, iCare_Favourite_Name__c, RecordType.Name 
                    FROM icare_Job_Request__c 
                    WHERE RecordTypeId =: selectedRecTypeId
                    AND OwnerId =:userinfo.getUserId()
                    Order By CreatedDate desc limit :v_pagesize OFFSET :v_Offset ];
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getNext(Integer v_Offset, Integer v_pagesize){
        v_Offset += v_pagesize;
        return v_Offset;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getPrevious(Integer v_Offset, Integer v_pagesize){
        v_Offset -= v_pagesize;
        return v_Offset;
    }
}