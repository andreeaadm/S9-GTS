/**
 * @author Vikash <vikash.kumar@cloudshiftgroup.com>
 * @date 2022-06-05
 * @group CloudShiftGroup
 * @description Class to provide supporting functionality when interacting with GMA customer portal
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 06/05/2022    Vikash Kumar   Created Class
*/
public without sharing class GMAHLSLProductSearchController {
    @testVisible private static final String REGULATORY_REPORT_TYPE = 'Regulatory Sheet';
    private static final String RECALL_REPORT_TYPE = 'Recall Summary';
    private static final String GAPANALYSIS_REPORT_TYPE = 'Gap Analysis';
    private static final String EXISTING_OLI_TYPE = 'Existing';
    private static final String MATCHED_OLI_TYPE = 'Matched';
    private static final String GAP_OLI_TYPE = 'Gap';
    private static final String TESTPLAN_REPORT_TYPE = 'Test Plan';
    private static final String ORDER_RECORD_TYPE_DEVNAME = 'GMA_HL_SL_Order_RT';
    private static final String TOKENTRANSACTION_RECORD_TYPE_DEVNAME = 'GMA_DEBIT_TRANSACTION_RT';
    private static final String METADATA_NAME_FOR_DOWNLOAD_MAX_WAIT = 'Download_Max_Wait';
    private static final String ORDER_STATUS_IN_PROGRESS = 'In Progress';
    private static final String ORDER_STATUS_IN_PENDING = 'Pending Review';
    private static final String ORDER_STATUS_COMPLETED = 'Completed';
    private static final String SEARCH_ALL_VALUES_SELECTED = 'ALL';
    private static final String SEARCH_HISTORIES_COUNT_SETTING = 'Portal_Historical_Searches_View_Count';
    @testVisible private static final String MULTIPICKLIST_SPLIT_CHAR = ';';
    
    private static final Map<String, TokensAndPricingHelper.REPORT_TYPE> REPORT_TYPES_FOR_CALCULATION = new Map<String, TokensAndPricingHelper.REPORT_TYPE>{
                                        REGULATORY_REPORT_TYPE => TokensAndPricingHelper.REPORT_TYPE.REGULATORY,
                                        RECALL_REPORT_TYPE => TokensAndPricingHelper.REPORT_TYPE.RECALL,
                                        TESTPLAN_REPORT_TYPE => TokensAndPricingHelper.REPORT_TYPE.TEST_PLAN,
                                        GAPANALYSIS_REPORT_TYPE => TokensAndPricingHelper.REPORT_TYPE.GAP_ANALYSIS
                                    };

    public class searchResult {
        @AuraEnabled
        public Map<String, Integer> recordsMatched;
        @AuraEnabled
        public Map<String, Integer> existingRecords;
        @AuraEnabled
        public Map<String, Integer> gapRecords;
        @AuraEnabled
        public Integer tokenCost;
        @AuraEnabled
        public String searchId;
    }

    private class tokenCost {
        private Integer searchCost;
        private Integer reportCost;
    }

    public class searchHistory {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String searchDate;
        @AuraEnabled
        public List<String> productList;
        @AuraEnabled
        public List<String> marketList;
        @AuraEnabled
        public List<String> materialList;
        @AuraEnabled
        public List<String> ageRangeList;
        @AuraEnabled
        public List<String> riskTypeList;
        @AuraEnabled
        public String toDate;
        @AuraEnabled
        public String fromDate;
        @AuraEnabled
        public List<String> targetMarketList;
    }
    

    /**
     * Method to get token cost for gap analysis search
     * @param targetMarketValues List<String> : target market values
     * @return Inetger: search token cost
     *
    */
    @AuraEnabled(cacheable=false)
    public static Integer getSearchTokenCost(List<String> targetMarketValues){
        Integer searchTokenCost = getSearchCostInTokens(targetMarketValues);
        return searchTokenCost;
    }


    /**
     * Method to get user and account data
     * @param userId String : logged  in portal user id
     * @return user: user record
     *
    */
    @AuraEnabled(cacheable=false)
    public static User getUserData(String userId){
        User portalUser = [Select id, ContactId, Contact.Account.GMA_Available_Tokens__c FROM User WHERE Id =:userId LIMIT 1];
        return portalUser;
    }

    
    /**
     * Method to get past searches for given account and given order type
     * @param orderType String : type of order
     * @return List<searchHistory>: relevant past searches
     *
    */
    @AuraEnabled(cacheable=false)
    public static List<searchHistory> getPastSearches(String orderType){
        List<searchHistory> retValues = new List<searchHistory>();
        Integer searchHistoriesCount = Integer.valueOf(GMA_Variable__mdt.getInstance(SEARCH_HISTORIES_COUNT_SETTING).Variable_Value__c);
        User thisUser = GmaPortalHelper.getCurrentUser();
        
        if (String.isNotBlank(thisUser.ContactId) && String.isNotBlank(thisUser.Contact.AccountId)) {
            String accId = thisUser.Contact.AccountId;
            String soql = 'SELECT CreatedDate, Product__c, Risk_Type__c, Age_Range__c, Market__c, Material__c, From_Date__c, Target_Market__c, To_Date__c ';
            soql += ' FROM Search__c WHERE Type__c=:orderType AND Account__c=:accId ';
            soql += ' ORDER BY CreatedDate DESC LIMIT ' + searchHistoriesCount;
            
            for (Search__c s : Database.query(soql)) {
                searchHistory history = new searchHistory();
                history.key = s.Id;
                                    
                history.searchDate = GmaPortalHelper.prettifyTimestamp(s.CreatedDate);
                history.productList = (String.isNotBlank(s.Product__c) ? s.Product__c.split(MULTIPICKLIST_SPLIT_CHAR) : new List<String>());
                history.marketList = (String.isNotBlank(s.Market__c) ? s.Market__c.split(MULTIPICKLIST_SPLIT_CHAR) : new List<String>());
                history.materialList = (String.isNotBlank(s.Material__c) ? s.Material__c.split(MULTIPICKLIST_SPLIT_CHAR) : new List<String>());
                history.ageRangeList = (String.isNotBlank(s.Age_Range__c) ? s.Age_Range__c.split(MULTIPICKLIST_SPLIT_CHAR) : new List<String>());
                history.riskTypeList = (String.isNotBlank(s.Risk_Type__c) ? s.Risk_Type__c.split(MULTIPICKLIST_SPLIT_CHAR) : new List<String>());
                history.targetMarketList = (String.isNotBlank(s.Target_Market__c) ? s.Target_Market__c.split(MULTIPICKLIST_SPLIT_CHAR) : new List<String>());
                history.fromDate = String.valueOf(s.From_Date__c);
                history.toDate = String.valueOf(s.To_Date__c);

                history.riskTypeList = (history.riskTypeList.isEmpty() ? new List<String>{SEARCH_ALL_VALUES_SELECTED} : history.riskTypeList);
                history.materialList = (history.materialList.isEmpty() ? new List<String>{SEARCH_ALL_VALUES_SELECTED} : history.materialList);
               retValues.add(history);

            }
        }

        return retValues;
    }


    /**
     * Method for doing search for regulatory summary and test plan
     * @param productList List<String> - names of products selected
     * @param marketList List<String> - target markets selected in search
     * @param materialList List<String> - materials selected 
     * @param ageRangeList List<String> - age ranges selected
     * @param orderType String - type of search performed 
     * @return searchResult
    */
    @AuraEnabled(cacheable=false)
    public static searchResult productSearch(List<String> productList, List<String> marketList, List<String> materialList, List<String> ageRangeList, String orderType ) {
        String materialValue = null;
        String productValue = '(\'' + String.join(productList, '\',\'') + '\')';
        String marketValue = '(\'' + String.join(marketList, '\',\'') + '\')';
        if(!materialList.isEmpty()){
            if(materialList[0] != SEARCH_ALL_VALUES_SELECTED){
                materialValue = '(\'' + String.join(materialList, '\',\'') + '\')';
            }else{
                materialList.clear();
            }
        }
        String ageRangeValue = '(\'' + String.join(ageRangeList, '\',\'') + '\')';
        Integer testCount;
        String queryString;
        Map<String, Integer> recordsMatched = new Map<String, Integer>();
        if(orderType == REGULATORY_REPORT_TYPE){
            queryString = 'SELECT Id, Product__c, Age_Range__c, Market__c, Material__c, (SELECT Id FROM Test_Items__r) FROM Regulation__c ';
            queryString +=' WHERE (Product__c INCLUDES ' + productValue;
            queryString +=' OR Additional_Product__c INCLUDES ' + productValue;
            queryString +=' OR Auxiliary_Product__c INCLUDES ' + productValue;
            queryString +=' OR Ancillary_Product__c INCLUDES ' + productValue;
            queryString +=' OR Extra_Product__c INCLUDES ' + productValue + ')';
        }
        if(orderType == TESTPLAN_REPORT_TYPE){
            queryString = 'SELECT Id,Product__c, Age_Range__c, Market__c, Material__c FROM Test_Item__c ';
            queryString +=' WHERE (Product__c INCLUDES ' + productValue;
            queryString +=' OR Additional_Product__c INCLUDES ' + productValue;
            queryString +=' OR Auxiliary_Product__c INCLUDES ' + productValue;
            queryString +=' OR Ancillary_Product__c INCLUDES ' + productValue;
            queryString +=' OR Extra_Product__c INCLUDES ' + productValue + ')';
        } 
        queryString += ' AND Market__c INCLUDES ' + marketValue;
        if(materialValue != null){
            queryString += ' AND Material__c INCLUDES ' + materialValue;
        }   
        queryString += ' AND Age_Range__c INCLUDES ' + ageRangeValue; 
        List<sObject> recordList = Database.query(queryString);
        if(recordList!= null){
            for(sObject record:recordList){
                testCount = 0;
                if(orderType == REGULATORY_REPORT_TYPE){
                    if(record.getSObjects('Test_Items__r') != null){
                        testCount = record.getSObjects('Test_Items__r').size();                
                    }
                    recordsMatched.put(record.id, testCount);
                }
                if(orderType == TESTPLAN_REPORT_TYPE){
                    recordsMatched.put(record.id, testCount);
                }          
            }
        }

        Id searchId = createSearchHistoryRecord(productList, marketList, materialList, ageRangeList, null, null, null, recordsMatched.size(), orderType, null);

        searchResult result = new searchResult();
        result.recordsMatched = recordsMatched;
        result.tokenCost = null;
        if (!recordsMatched.isEmpty() && recordsMatched!=null) {
            result.tokenCost = getCostInTokens(orderType, marketList, ageRangeList, null, new List<String>(recordsMatched.keySet())).reportCost;
            if (result.tokenCost==null) {
                throw new AuraException(TokensAndPricingHelper.ERROR_CALCULATION_FAILED);
            }
        }

        result.searchId = searchId;
        return result;
    }

    
    /**
     * Method for doing search for recall search
     * @param productList List<String> - names of products selected
     * @param marketList List<String> - current markets selected in search
     * @param materialList List<String> - materials selected 
     * @param riskTypeList List<String> - risk type selected
     * @param toDate String -  selected todate
     * @param toDate fromDate -  selected fromDate
     * @return searchResult
    */
    @AuraEnabled(cacheable=false)
    public static searchResult recallSearch(List<String> productList, List<String> marketList, List<String> riskTypeList, String toDate, String fromDate) {
        String riskTypeValue = null;
        String productValue = '(\'' + String.join(productList, '\',\'') + '\')';
        String marketValue = '(\'' + String.join(marketList, '\',\'') + '\')';
        if(!riskTypeList.isEmpty()){
            if(riskTypeList[0] != SEARCH_ALL_VALUES_SELECTED){
                riskTypeValue = '(\'' + String.join(riskTypeList, '\',\'') + '\')';
            }else{
                riskTypeList.clear();
            }
        }
        Date periodToDate;
        Date periodFromDate;
        
        if(toDate != null && fromDate != null){
            periodToDate = Date.valueof(toDate);
            periodFromDate = Date.valueof(fromDate);
        }
        
        Integer testCount;
        Map<String, Integer> recordsMatched = new Map<String, Integer>();
        
        String queryString = 'SELECT Id, Product__c, Risk_Type__c, Recall_Date__c, Market__c, Material__c FROM Recall__c WHERE Product__c INCLUDES ' + productValue ;
        queryString += ' AND Market__c INCLUDES' + marketValue;
        if(riskTypeValue != null){
            queryString += ' AND Risk_Type__c INCLUDES' + riskTypeValue;
        }
        List<Recall__c> recallList = Database.query(queryString);

        if(recallList != null){
            for(Recall__c recall : recallList){
                if(recall.Recall_Date__c <= periodToDate && recall.Recall_Date__c >= periodFromDate ){
                    recordsMatched.put(recall.Id, 0);
                }
            }
        }

        Id searchId = createSearchHistoryRecord(productList, marketList, null, null, riskTypeList, fromDate, toDate, recordsMatched.size(), RECALL_REPORT_TYPE, null);
        
        searchResult result = new searchResult();
        result.recordsMatched = recordsMatched;
        result.tokenCost = null;

        if (!recordsMatched.isEmpty() && recordsMatched!=null) {
            result.tokenCost = getCostInTokens(RECALL_REPORT_TYPE, marketList, null, riskTypeList, new List<String>(recordsMatched.keySet())).reportCost;
            if (result.tokenCost==null) {
                throw new AuraException(TokensAndPricingHelper.ERROR_CALCULATION_FAILED);
            }
        }
        
        result.searchId = searchId;
        return result;
    }

    /**
     * Method for doing search for gap analysis 
     * @param productList List<String> - names of products selected
     * @param currentMarketList List<String> - current markets selected in search
     * @param targetMarketList List<String> - target markets selected in search
     * @param materialList List<String> - materials selected 
     * @param ageRangeList List<String> - age ranges selected
     * @param orderType String - type of search performed 
     * @return searchResult
    */
    @AuraEnabled(cacheable=false)
    public static searchResult gapSearch(List<String> productList, List<String> currentMarketList,List<String> targetMarketList, List<String> materialList, List<String> ageRangeList, String orderType) {
        String materialValue = null;
        String productValue = '(\'' + String.join(productList, '\',\'') + '\')';
        String currentmarketValue = '(\'' + String.join(currentMarketList, '\',\'') + '\')';
        String targetmarketValue = '(\'' + String.join(targetMarketList, '\',\'') + '\')';
        if(!materialList.isEmpty()){
            if(materialList[0] != SEARCH_ALL_VALUES_SELECTED){
                materialValue = '(\'' + String.join(materialList, '\',\'') + '\')';
            }else{
                materialList.clear();
            }
        }
        String ageRangeValue = '(\'' + String.join(ageRangeList, '\',\'') + '\')';
        Integer testCount;
        String queryString;
        Map<String, Integer> existingRecords = new Map<String, Integer>();
        Map<String, Integer> recordsMatched = new Map<String, Integer>();
        Map<String, Integer> gapRecords= new Map<String, Integer>();
        queryString = 'SELECT Id,Product__c, Age_Range__c, Market__c, Material__c,(SELECT Name, Test_Item_1__c FROM Test_Item_Equivalency__r) FROM Test_Item__c ';
        queryString +=' WHERE (Product__c INCLUDES ' + productValue;
        queryString +=' OR Additional_Product__c INCLUDES ' + productValue;
        queryString +=' OR Auxiliary_Product__c INCLUDES ' + productValue;
        queryString +=' OR Ancillary_Product__c INCLUDES ' + productValue;
        queryString +=' OR Extra_Product__c INCLUDES ' + productValue + ')'; 
        queryString += ' AND (Market__c INCLUDES ' + currentmarketValue;
        queryString += ' OR Market__c INCLUDES ' + targetmarketValue;
        if(materialValue != null){
            queryString += ' ) AND Material__c INCLUDES ' + materialValue;
        }else{
            queryString += ' )' ;
        }
        queryString += ' AND Age_Range__c INCLUDES ' + ageRangeValue; 
        List<Test_Item__c> recordList = Database.query(queryString);

        if(recordList!= null){
            for(Test_Item__c record : recordList){
                testCount = 0;

                Boolean matchedToCurrentMarket = false;
                Boolean matchedToTargetMarket = false;
                Set<String> recordMarkets = new Set<String>(record.Market__c.split(';'));
                for (String m : currentMarketList) {
                    if (recordMarkets.contains(m)) {
                        matchedToCurrentMarket = true;
                        break;
                    }
                }
                
                if (!matchedToCurrentMarket) {
                    for (String m : targetMarketList) {
                        if (recordMarkets.contains(m)) {
                            matchedToTargetMarket = true;
                            break;
                        }
                    }
                }

                if (matchedToCurrentMarket) {
                    existingRecords.put(record.id, testCount);
                } else if (matchedToTargetMarket) {
                    if (!record.Test_Item_Equivalency__r.isEmpty()) {
                        recordsMatched.put(record.id, testCount);
                    } else {
                        gapRecords.put(record.id, testCount);
                    }
                }        
            }
        }

        //create search record
        Integer recordsCount = recordsMatched.size() + gapRecords.size();
        Id searchId = createSearchHistoryRecord(productList, currentMarketList, materialList, ageRangeList, null, null, null, recordsCount, orderType, targetMarketList);
        
        //create token transaction for search cost
        User thisUser = GmaPortalHelper.getCurrentUser();
        String recTypeDevName = GMA_Variable__mdt.getInstance(TOKENTRANSACTION_RECORD_TYPE_DEVNAME).Variable_Value__c;
        Id devRecordTypeId = Schema.SObjectType.Token_Transaction__c.getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId();
        Token_Transaction__c token= new Token_Transaction__c();
        token.Amount__c = getSearchCostInTokens(targetMarketList);
        token.Account__c = thisUser.Contact.AccountId;
        token.recordtypeId = devRecordTypeId;
        token.Start_Date__c = System.today();
        insert token;

        searchResult result = new searchResult();
        result.recordsMatched = recordsMatched;
        result.existingRecords = existingRecords;
        result.gapRecords = gapRecords;
        result.tokenCost = null;

        List<String> allRecordsForTargetMarkets = new List<String>(recordsMatched.keySet());
        allRecordsForTargetMarkets.addAll(gapRecords.keySet());

        if (!allRecordsForTargetMarkets.isEmpty()) {
            result.tokenCost = getCostInTokens(orderType, targetMarketList, ageRangeList, null, allRecordsForTargetMarkets).reportCost;
            if (result.tokenCost==null) {
                throw new AuraException(TokensAndPricingHelper.ERROR_CALCULATION_FAILED);
            }
        }

        result.searchId = searchId;
        return result;
    }

     /**
      * Method for creating search record
     * @param parentRecordId List<String> - Ids of regulation 
     * @param orderType String - type of search performed 
     * @param selectedMarketValues List<String> -  markets selected in search
     * @param selectedProductValues List<String> - names of products selected
     * @param selectedMaterialValues List<String> - materials selected 
     * @param selectedAgeRangeValues List<String> - age ranges selected
     * @param riskTypeValues List<String> - risk types selected (e.g. for recall search)
     * @param fromDate String - from date selected in search (e.g. for recall search)
     * @param toDate String - to date selected in search (e.g. for recall search)
     * @return generated search record Id
     *
    */
    @AuraEnabled(cacheable=false)
    public static String createSearchRecord(List<String> parentRecordId, String orderType,
                                    List<String> selectedMarketValues, List<String> selectedProductValues, 
                                    List<String> selectedMaterialValues, List<String> selectedAgeRangeValues,
                                    List<String> riskTypeValues, String fromDate, String toDate){
        if(!selectedMaterialValues.isEmpty() && selectedMaterialValues.get(0) == SEARCH_ALL_VALUES_SELECTED){
            selectedMaterialValues.clear();
        }

        Id searchId = createSearchHistoryRecord(selectedProductValues, selectedMarketValues, selectedMaterialValues, selectedAgeRangeValues, riskTypeValues, fromDate, toDate, parentRecordId.size(), orderType, null);
        return searchId;
    }

     /**
      * Method for creating order of regulatory type based on search performed
     * @param parentRecordId List<String> - Ids of regulation 
     * @param orderType String - type of search performed 
     * @param selectedMarketValues List<String> -  markets selected in search
     * @param selectedProductValues List<String> - names of products selected
     * @param selectedMaterialValues List<String> - materials selected 
     * @param selectedAgeRangeValues List<String> - age ranges selected
     * @return generated order record Id
     *
    */
    @AuraEnabled(cacheable=false)
    public static Id createRegulatorySheetOrder(List<String> parentRecordId, String orderType,
                                    List<String> selectedMarketValues, List<String> selectedProductValues, 
                                    List<String> selectedMaterialValues, List<String> selectedAgeRangeValues){
        
        Map<Id, Test_Item__c> testItems;
        if (orderType==TESTPLAN_REPORT_TYPE) {
            testItems = new Map<Id, Test_Item__c>([SELECT Id, Regulation__c FROM Test_Item__c WHERE Id IN :parentRecordId]);
        }

        if(!selectedMaterialValues.isEmpty() && selectedMaterialValues.get(0) == SEARCH_ALL_VALUES_SELECTED){
            selectedMaterialValues.clear();
        }

        Order__c order;
        List<Order_Line_Item__c> orderLineItemList = new List<Order_Line_Item__c>();
        User userValue = GmaPortalHelper.getCurrentUser();
        String recTypeDevName = GMA_Variable__mdt.getInstance(ORDER_RECORD_TYPE_DEVNAME).Variable_Value__c;
        Id devRecordTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId();
        Integer tokenCost = getCostInTokens(orderType, selectedMarketValues, selectedAgeRangeValues, null, parentRecordId).reportCost;

        if(parentRecordId != null){
            order = new Order__c();
            order.Account__c = userValue.Contact.AccountId;
            order.Stage__c = ORDER_STATUS_IN_PROGRESS;
            order.EService__c = orderType;
            order.recordtypeID =devRecordTypeId ;
            order.Market__c = createMultipicklistValue(selectedMarketValues);
            order.Material__c = createMultipicklistValue(selectedMaterialValues);
            order.Product__c = createMultipicklistValue(selectedProductValues);
            order.Age_Range__c = createMultipicklistValue(selectedAgeRangeValues);
            order.Token_Cost_Count__c = tokenCost;
            order.Total_Cost__c = order.Token_Cost_Count__c;
            insert order;
            for(String recordId : parentRecordId){
                Order_Line_Item__c oli = new Order_Line_Item__c();
                oli.Order__c = order.id;
                if(order.EService__c == REGULATORY_REPORT_TYPE){
                    oli.Regulation__c = recordId;
                }
                if(order.EService__c == TESTPLAN_REPORT_TYPE){
                    oli.Test_Item__c = recordId;
                    oli.Regulation__c = testItems.get(recordId).Regulation__c;
                }
                orderLineItemList.add(oli);
            }
            insert orderLineItemList;
        }

        return order.Id;
    }

    /**
      * Method for creating order of gap analysis type based on search performed
     * @param existingRecordId List<String> - Ids of existing test items 
     * @param gapRecordId List<String> - Ids of gaps test items
     * @param matchedRecordId List<String> - Ids of matched test items 
     * @param orderType String - type of search performed 
     * @param selectedcurrentMarketValues List<String> - current markets selected in search
     * @param selectedTargetMarketValues List<String> - target markets selected in search
     * @param selectedProductValues List<String> - names of products selected
     * @param selectedMaterialValues List<String> - materials selected 
     * @param selectedAgeRangeValues List<String> - age ranges selected
     * @return generated order record Id
     *
    */
    @AuraEnabled(cacheable=false)
    public static Id createGapAnalysisOrder(List<String> existingRecordId, List<String> gapRecordId,
                                    List<String> matchedRecordId, String orderType,
                                    List<String> selectedcurrentMarketValues, List<String> selectedTargetMarketValues,
                                    List<String> selectedProductValues, List<String> selectedMaterialValues,
                                    List<String> selectedAgeRangeValues){
        
        Set<String> allTestItems = new Set<String>();
        allTestItems.addAll(existingRecordId);
        allTestItems.addAll(gapRecordId);
        allTestItems.addAll(matchedRecordId);
        Map<Id, Test_Item__c> testItems = new Map<Id, Test_Item__c>([SELECT Id, Regulation__c 
                                                                FROM Test_Item__c 
                                                                WHERE Id IN :allTestItems]);

        Order__c order;
        if(!selectedMaterialValues.isEmpty() && selectedMaterialValues.get(0) == SEARCH_ALL_VALUES_SELECTED){
            selectedMaterialValues.clear();
        }

        List<Order_Line_Item__c> orderLineItemList = new List<Order_Line_Item__c>();
        User userValue = GmaPortalHelper.getCurrentUser();
        String recTypeDevName = GMA_Variable__mdt.getInstance(ORDER_RECORD_TYPE_DEVNAME).Variable_Value__c;
        Id devRecordTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId();
        if(allTestItems != null && !allTestItems.isEmpty()){

            List<String> allRecordsForTargetMarkets = new List<String>(matchedRecordId);
            allRecordsForTargetMarkets.addAll(gapRecordId);
            tokenCost allCosts = getCostInTokens(orderType, selectedTargetMarketValues, selectedAgeRangeValues, null, allRecordsForTargetMarkets);
            Integer reportTokensCost = allCosts.reportCost;
            Integer searchTokensCost = allCosts.searchCost;

            order = new Order__c();
            order.Account__c = userValue.Contact.AccountId;
            order.Stage__c = ORDER_STATUS_IN_PROGRESS;
            order.EService__c = orderType;
            order.recordtypeID =devRecordTypeId ;
            order.Market__c = createMultipicklistValue(selectedcurrentMarketValues);
            order.Material__c = createMultipicklistValue(selectedMaterialValues);
            order.Product__c = createMultipicklistValue(selectedProductValues);
            order.Age_Range__c = createMultipicklistValue(selectedAgeRangeValues);
            order.Target_Market__c = createMultipicklistValue(selectedTargetMarketValues);
            order.Token_Cost_Count__c = reportTokensCost;
            order.Total_Cost__c = reportTokensCost + searchTokensCost;
            insert order;

            for(String recordId : existingRecordId){
                Order_Line_Item__c oli = new Order_Line_Item__c();
                oli.Order__c = order.id;
                oli.Test_Item__c = recordId;
                oli.Regulation__c = testItems.get(recordId).Regulation__c;
                oli.Type__c = EXISTING_OLI_TYPE;
                orderLineItemList.add(oli);
            }
            for(String recordId : gapRecordId){
                Order_Line_Item__c oli = new Order_Line_Item__c();
                oli.Order__c = order.id;
                oli.Test_Item__c = recordId;
                oli.Regulation__c = testItems.get(recordId).Regulation__c;
                oli.Type__c = GAP_OLI_TYPE;
                orderLineItemList.add(oli);
            }
            for(String recordId : matchedRecordId){
                Order_Line_Item__c oli = new Order_Line_Item__c();
                oli.Order__c = order.id;
                oli.Test_Item__c = recordId;
                oli.Regulation__c = testItems.get(recordId).Regulation__c;
                oli.Type__c = MATCHED_OLI_TYPE;
                orderLineItemList.add(oli);
            }
            insert orderLineItemList;
        }

        return order.Id;
    }

    /**
     * Method for creating order of recall type based on search performed
     * @param recallIdValues List<String> -recalls id after search
     * @param orderType String - type of search performed
     * @param selectedMarketValues List<String> - markets selected in search
     * @param selectedProductValues List<String> - Products selected (e.g. for regulatory search)
     * @param riskTypeValues List<String> - risk types selected (e.g. for recall search)
     * @param fromDate String - from date selected in search (e.g. for recall search)
     * @param toDate String - to date selected in search (e.g. for recall search)
     * @return generated order record Id
     *
    */
    @AuraEnabled(cacheable=false)
    public static Id createRecallSummaryOrder(List<String> recallIdValues, String orderType,
                                    List<String> selectedMarketValues, List<String> selectedProductValues, 
                                    List<String> riskTypeValues, String toDate, String fromDate){
        Order__c order;
        List<Order_Line_Item__c> orderLineItemList = new List<Order_Line_Item__c>();
        User userValue = GmaPortalHelper.getCurrentUser();
        Date periodToDate;
        Date periodFromDate;
        if(toDate != null && fromDate != null){
            periodToDate = Date.valueof(toDate);
            periodFromDate = Date.valueof(fromDate);
        }
        if(!riskTypeValues.isEmpty() && riskTypeValues.get(0) == SEARCH_ALL_VALUES_SELECTED){
            riskTypeValues.clear();
        }

        String recTypeDevName = GMA_Variable__mdt.getInstance(ORDER_RECORD_TYPE_DEVNAME).Variable_Value__c;
        Id devRecordTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId();
        Integer tokenCost = getCostInTokens(orderType, selectedMarketValues, null, riskTypeValues, recallIdValues).reportCost;

        if(recallIdValues != null){
            order = new Order__c();
            order.Account__c = userValue.Contact.AccountId;
            order.Stage__c = ORDER_STATUS_IN_PROGRESS;
            order.EService__c = orderType;
            order.recordtypeID =devRecordTypeId ;
            order.Market__c = createMultipicklistValue(selectedMarketValues);
            order.Product__c = createMultipicklistValue(selectedProductValues);
            order.Risk_Type__c = createMultipicklistValue(riskTypeValues);
            order.Period_Start__c = periodFromDate;
            order.Period_End__c = periodToDate;
            order.Token_Cost_Count__c = tokenCost;
            order.Total_Cost__c = order.Token_Cost_Count__c;
            insert order;
            for(String recall : recallIdValues){
                Order_Line_Item__c oli = new Order_Line_Item__c();
                oli.Order__c = order.id;
                oli.Recall__c = recall;
                orderLineItemList.add(oli);
            }
            insert orderLineItemList;
        }

        return order.Id;
    }

    
    /**
     * Method to create string from multipicklist values 
     * @param multiPicklistValueList List<String>  : mutlipicklist values list
     * @return String: string formed from multipicklist list.
     *
    */
    private static String createMultipicklistValue(List<String> multiPicklistValueList){							 
        String multiPicklistValue = (multiPicklistValueList!= null ? String.join(multiPicklistValueList, ';') : '');													 
        return multiPicklistValue;	
    }

    /**
     * Method for generating search records based on search performed
     * @param productList List<String> - names of products selected
     * @param marketList List<String> - markets selected in search
     * @param materialList List<String> - materials selected (e.g. for regulatory search)
     * @param ageRangeList List<String> - age ranges selected (e.g. for regulatory search)
     * @param riskTypesList List<String> - risk types selected (e.g. for recall search)
     * @param fromDate String - from date selected in search (e.g. for recall search)
     * @param toDate String - to date selected in search (e.g. for recall search)
     * @param recordsMatched Integer - number of records found
     * @param orderType String - type of search performed
     * @param targetMarketList List<String> - list of target markets selected (e.g. for gap analyses)
     * 
     * @return generated search record Id
     *
    */
    private static Id createSearchHistoryRecord(List<String> productList, List<String> marketList, 
                                                        List<String> materialList, List<String> ageRangeList,
                                                        List<String> riskTypesList, String fromDate, String toDate,
                                                        Integer recordsMatched, String orderType, List<String> targetMarketList) {

        User thisUser = GmaPortalHelper.getCurrentUser();
        
        if (thisUser.Is_GMA_Portal_User__c) {
            Search__c searchHistory = new Search__c(
                Name = 'Search - ' + System.now().format(),
                Account__c = thisUser.Contact.AccountId,
                Contact__c = thisUser.ContactId,
                Date__c = Date.today(),
                Type__c = orderType,
                Records_Matched__c = recordsMatched,
                Market__c = createMultipicklistValue(marketList),
                Product__c = createMultipicklistValue(productList)
            );
            if (orderType==REGULATORY_REPORT_TYPE || orderType==TESTPLAN_REPORT_TYPE || orderType == GAPANALYSIS_REPORT_TYPE) {
                searchHistory.Age_Range__c = createMultipicklistValue(ageRangeList);
                searchHistory.Material__c = createMultipicklistValue(materialList);
            } else if (orderType==RECALL_REPORT_TYPE) {
                Date periodFromDate = (String.isNotBlank(fromDate) ? Date.valueof(fromDate) : null);
                Date periodToDate = (String.isNotBlank(toDate) ? Date.valueof(toDate) : null);
                searchHistory.Risk_Type__c = createMultipicklistValue(riskTypesList);
                searchHistory.From_Date__c = periodFromDate;
                searchHistory.To_Date__c = periodToDate;
            }
            if(orderType == GAPANALYSIS_REPORT_TYPE){
                searchHistory.Target_Market__c = createMultipicklistValue(targetMarketList);
            }

            insert searchHistory;
            return searchHistory.Id;
        }

        return null;
    }

    /**
     * Method to get max wait second for download
     * @return Integer: Wait seconds
     *
    */
    @AuraEnabled(cacheable=true)
    public static Integer getMaxWaitSecondsForDownloads() {
        GMA_Variable__mdt setting = GMA_Variable__mdt.getAll().get(METADATA_NAME_FOR_DOWNLOAD_MAX_WAIT);
        return Integer.valueOf(setting.Variable_Value__c);
    }

    /**
     * Method to retrieve document on an order
     * @param orderId String : Order Id
     * @return String: Download link
     *
    */

    @AuraEnabled(cacheable=false)
    public static String retrieveOrderDocument(String orderId) {
        Order__c thisOrder = [SELECT Stage__c FROM Order__c WHERE Id=:orderId];
        if (thisOrder.Stage__c==ORDER_STATUS_COMPLETED) { 
            return OrderHistoryCommunityComponentController.getDownloadLink(thisOrder.Id);
        }
        return null;
    }

    /**
     * Method to execute search cost token calculation (for gap analyses)
     * @param List<String> targetMarketValues selected
     * @return Integer - search cost in tokens
     *
    */
    private static Integer getSearchCostInTokens(List<String> targetMarketValues) {
        TokensAndPricingHelper.requestParameters r = new TokensAndPricingHelper.requestParameters();
        r.businessLine = TokensAndPricingHelper.BUSINESS_LINE.GMA_HLSL;
        r.reportType = REPORT_TYPES_FOR_CALCULATION.get(GAPANALYSIS_REPORT_TYPE);
        r.recordIds = new Set<String>();
        r.selectedMarkets = (targetMarketValues==null ? new Set<String>() : new Set<String>(targetMarketValues));
        r.selectedAgeGroups = new Set<String>();
        r.selectedRiskTypes = new Set<String>();
        TokensAndPricingHelper.calculationResult tokenCalculationResult = TokensAndPricingHelper.calculate(r);
        
        return Integer.valueOf(tokenCalculationResult.searchTokenCost);
    }

    /**
     * Method to execute token calculation for given report type
     * @param orderType - String to identify order type; please ensure this is in line with report types used above map REPORT_TYPES_FOR_CALCULATION
     * @param markets - list of string representing markets defined in search (e.g. for regulations)
     * @param ages - list of string representing age ranges defined in search (e.g. for regulations)
     * @param risks - list of string representing arisk types defined in search (e.g. for recalls)
     * @param recordIds - List<String> record Ids (regulations, recalls, etc.) to be used when calculating token cost
     *                   (system dynamically retrieves records based on Ids and custom metadata "Token Pricing Definitions" and calculates cost)
     * @return tokenCost - wrapper class that includes info about search cost and report cost in tokens
     *
    */
    private static tokenCost getCostInTokens(String orderType, List<String> markets, List<String> ages, List<String> risks, List<String> recordIds) {
        TokensAndPricingHelper.requestParameters r = new TokensAndPricingHelper.requestParameters();
        r.businessLine = TokensAndPricingHelper.BUSINESS_LINE.GMA_HLSL;
        r.reportType = REPORT_TYPES_FOR_CALCULATION.get(orderType);
        r.recordIds = new Set<String>(recordIds);
        r.selectedMarkets = (markets<>null ? new Set<String>(markets) : new Set<String>());
        r.selectedAgeGroups = (ages<>null ? new Set<String>(ages) : new Set<String>());
        r.selectedRiskTypes = (risks<>null ? new Set<String>(risks) : new Set<String>());
        TokensAndPricingHelper.calculationResult tokenCalculationResult = TokensAndPricingHelper.calculate(r);

        tokenCost w = new tokenCost();
        w.reportCost = Integer.valueOf(tokenCalculationResult.reportTokenCost);
        w.searchCost = Integer.valueOf(tokenCalculationResult.searchTokenCost);

        return w;
    }

    /**
     * Method to execute token calculation for given report type
     * @param recordId - RecordId to add to RecordId__c field on Platform Event
     * @param message - message to publish (255 chars)
     * @param amount - decimal to add to Amount__c field on platform event
     *
    */
    @AuraEnabled(cacheable=false)
    public static void publishPlatformEvent(String recordId, String message, Decimal amount) { 
        GMA_Portal_Event__e event = new GMA_Portal_Event__e(
            RecordId__c = recordId,
            Message__c = message,
            Amount__c = amount
        );
        EventBus.publish(new List<GMA_Portal_Event__e>{event});
    }
}