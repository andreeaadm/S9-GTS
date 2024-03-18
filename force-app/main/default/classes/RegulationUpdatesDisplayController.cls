/*******************************************************************************************
* @Name         RegulationUpdatesDisplayController 
* @Author       Anay Karkhanis
* @Date         16/05/2022
* @Description  The controller class for the RegulationUpdatesDisplay component.
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0             Anay K             16/05/2022         Initial Development for GSH-55                                                      
*******************************************************************************************/
public without sharing class RegulationUpdatesDisplayController {

    private static final String METADATA_VARIABLE_NAME = 'Portal_Regulation_Update_Display_Range';
    private static final String COMPLETED_STATUS = 'Completed';

    public class ResultWrapper{
        @AuraEnabled
        public Id recordId;

        @AuraEnabled
        public String name;
        
        @AuraEnabled
        public String timeStamp;

    }    

/**************************************************************************************
* @Description  Method to get the Regulation Update data of the logged in Community User.
* @Param		N/A
* @Return       List<ResultWrapper> - List of Order Data.
**************************************************************************************/
    @AuraEnabled
    public static List<ResultWrapper> getRegulationUpdateData(){
        List<ResultWrapper> result = new List<ResultWrapper>();
        GMA_Variable__mdt variableMetadata = GMA_Variable__mdt.getInstance(METADATA_VARIABLE_NAME);
        Integer dateRange = (variableMetadata!=null && String.isNotBlank(variableMetadata.Variable_Value__c)) ? Integer.valueOf(variableMetadata.Variable_Value__c) : 30;
        String queryString = 'Select Id,Regulation__r.Legal_Regulation_Name__c,CreatedDate from Regulation_Update__c where Regulation__c IN :regulationIds AND CreatedDate = LAST_N_DAYS:'+dateRange+ ' Order By CreatedDate desc';
        try{
            Id accountId = [SELECT Id,AccountId FROM User WHERE Id = :UserInfo.getUserId()].AccountId;
            if(accountId!=null){
                List<Order_Line_Item__c> orderLineItemList = [Select Regulation__c from Order_Line_Item__c where Order__c IN (Select Id from Order__c where Account__c = :accountId and Stage__c=:COMPLETED_STATUS)
                                                      			AND Regulation__c!=null];  
                if(!orderLineItemList.isEmpty()){
                	Set<Id> regulationIds = new Set<Id>();
                    for(Order_Line_Item__c lineItem : orderLineItemList){regulationIds.add(lineItem.Regulation__c);}
                    List<Regulation_Update__c> resultList = Database.query(queryString);
                    for(Regulation_Update__c record : resultList){
                        ResultWrapper wrapper = new ResultWrapper();
                        wrapper.recordId = record.Id;
                        wrapper.name = record.Regulation__r.Legal_Regulation_Name__c;
                        wrapper.timeStamp = String.Valueof(record.CreatedDate.Date());
                        result.add(wrapper);
                    }
                }                
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }
}