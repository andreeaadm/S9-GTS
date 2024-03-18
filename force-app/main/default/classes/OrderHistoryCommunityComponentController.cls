/*******************************************************************************************
* @Name         OrderHistoryCommunityComponentController 
* @Author       Anay Karkhanis
* @Date         05/04/2022
* @Description  The controller class for the OrderHistoryCommunityComponent component.
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0             Anay K             05/04/2022         Initial Development for GSH-159                                                      
*******************************************************************************************/
public without sharing class OrderHistoryCommunityComponentController {

    @testVisible private static final String ORDER_DOCUMENT_FILE_EXTENSION = 'pdf';
    @testVisible private static final String ORDER_COMPLETED_STATUS = 'Completed';
    private static final String METADATA_NAME_FOR_CONTENT_URL = 'URL_Portal_ContentDownload';

    public class ResultWrapper{
        @AuraEnabled
        public Id recordId;
        
        @AuraEnabled
        public String timeStamp;

        @AuraEnabled
        public String solution;

        @AuraEnabled
        public Decimal token;

        @AuraEnabled
        public String generatedBy;

        @AuraEnabled
        public String downloadLabel;

        @AuraEnabled
        public String product;
        
        @AuraEnabled
        public String market;  
        
        @AuraEnabled
        public Boolean isDownloadLabel;

    }

/**************************************************************************************
* @Description  Method to get the Order History of the logged in Community User.
* @Param		N/A
* @Return       List<ResultWrapper> - List of Order Data.
**************************************************************************************/
    @AuraEnabled
    public static List<ResultWrapper> getOrderHistory(){
        List<ResultWrapper> result = new List<ResultWrapper>();
        try {
            Id accountId = [SELECT Id,AccountId FROM User WHERE Id = :UserInfo.getUserId()].AccountId;
            if(accountId!=null){
                List<Order__c> resultList = [SELECT Id, Report_ID__c, Order_DateTime__c, 
                                                EService__c, Token_Cost_Count__c, 
                                                CreatedBy.Name, Stage__c, Product__c, Market__c 
                                            FROM Order__c WHERE Account__c = :accountId ORDER BY CreatedDate DESC];
                if(!resultList.isEmpty()){
                    for(Order__c record : resultList){
                        ResultWrapper wrapper = new ResultWrapper();
                        wrapper.recordId = record.Id;
                        wrapper.timeStamp = record.Order_DateTime__c;
                        wrapper.solution = record.EService__c + ' (' + record.Report_ID__c + ')';
                        wrapper.token = record.Token_Cost_Count__c;
                        wrapper.generatedBy = record.CreatedBy.Name;
                        wrapper.product = convertMultiselectPicklistValue(record.Product__c);
                        wrapper.market = convertMultiselectPicklistValue(record.Market__c);
                        wrapper.downloadLabel = record.Stage__c == ORDER_COMPLETED_STATUS ? Label.GMA_Download : 'N/A';
                        wrapper.isDownloadLabel = record.Stage__c == ORDER_COMPLETED_STATUS ? True : False;
                        result.add(wrapper);
                    }
                }                
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

/**************************************************************************************
* @Description  To convert the multiselect picklist value to comma separated values
* @Param		String - Multiselect picklist field value.
* @Return       String - Comma separated multiselect picklist value
**************************************************************************************/    
private static String convertMultiselectPicklistValue(String multiselectValue){
    String result = '';
    if(String.isNotBlank(multiselectValue)){
        for(String val : multiselectValue.split(';'))result = result + val + ', ';
        result = result.removeEnd(', ');
    }
    return result;
}

/**************************************************************************************
* @Description  Method to get the downlink for the file attached to the record.
* @Param		Id - The record id of the record to which the file is attached.
* @Return       String - The Download link of the file.
**************************************************************************************/    
    @AuraEnabled
    public static String getDownloadLink(Id recordId){
        String result;
        try{
            ContentDocumentLink cdl = [SELECT ContentDocument.LatestPublishedVersionId 
                                    FROM ContentDocumentLink 
                                        WHERE LinkedEntityId =:recordId
                                        AND ContentDocument.FileExtension =:ORDER_DOCUMENT_FILE_EXTENSION
                                    ORDER BY ContentDocument.CreatedDate DESC LIMIT 1]; 
            String baseUrl = GmaPortalHelper.getGmaPortalBaseUrl();
            GMA_Variable__mdt contentUrlSetting = GMA_Variable__mdt.getAll().get(METADATA_NAME_FOR_CONTENT_URL);
            baseUrl += contentUrlSetting.Variable_Value__c;
            result = baseUrl + cdl.ContentDocument.LatestPublishedVersionId;
        }catch(Exception exp){
            throw new AuraHandledException(exp.getMessage());            
        }  
        return result;
    }
}