/**
 * @author Kaspars Rezgalis <kaspars@cloudshiftgroup.com>
 * @date 2022-05-24
 * @group CloudShiftGroup
 * @description Generic helper class for performing cost calculation (in tokens) for given business line and type of report
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 24/05/2022    Kaspars Rezgalis   Created Class
*/
public without sharing class TokensAndPricingHelper {
    
    //the below should match to Token_Pricing_Definition__mdt Business_Line__c picklist API names
    public enum BUSINESS_LINE {GMA_HLSL, TOXCLEAR, MTC, ELECTRICAL}
    //the below should match to Token_Pricing_Definition__mdt Report_Type__c picklist API names
    public enum REPORT_TYPE {REGULATORY, RECALL, GAP_ANALYSIS, TEST_PLAN}
    private static final String CALCULATION_ADD = 'ADD';
    private static final String CALCULATION_DEFAULT_ADD = 'DEFAULT_ADD';
    private static final String MATCHING_SEARCH_FILTER_AGE = 'Age Range';
    private static final String MATCHING_SEARCH_FILTER_MARKET = 'Market';
    private static final String MATCHING_SEARCH_FILTER_RISK = 'Risk Type';

    public static final String ERROR_CALCULATION_FAILED = 'Token pricing calculation failed, please try again.';

    public class requestParameters {
        public BUSINESS_LINE businessLine;
        public REPORT_TYPE reportType;
        public Set<String> recordIds = new Set<String>();
        public Set<String> selectedMarkets;
        public Set<String> selectedAgeGroups;
        public Set<String> selectedRiskTypes;
        private List<Sobject> records = new List<Sobject>();
        private Decimal searchCostPerMarket = 0;
    }

    public class calculationResult {
        public Decimal searchTokenCost;
        public Decimal reportTokenCost;
    }

    private static List<Token_Pricing_Definition__mdt> pricingSettings;
    private static requestParameters reportRequest;

    
    public class TokensAndPricingHelperException extends Exception {
    
    }
    
    public static calculationResult calculate(requestParameters reportData) {

        if (reportData.businessLine==null || reportData.reportType==null) {
            throw new TokensAndPricingHelperException('No Business Line or Report Type specified');
        }

        reportRequest = reportData;
        getPricingDefitions();

        if (pricingSettings.isEmpty()) {
            throw new TokensAndPricingHelperException('No Pricing definitions found');
        }

        if (reportRequest.recordIds != null && !reportRequest.recordIds.isEmpty()) {
            retrieveRecords();
        }

        calculationResult result = new calculationResult();
        if (reportRequest.reportType == REPORT_TYPE.GAP_ANALYSIS) {
            result.searchTokenCost = getDefaultCostTotal();
        }

        if (reportRequest.records != null && !reportRequest.records.isEmpty()) {
            result.reportTokenCost = getCalculationTotal(CALCULATION_ADD);
        }

        return result;
    }

    private static void getPricingDefitions() {
        pricingSettings = new List<Token_Pricing_Definition__mdt>();

        for (Token_Pricing_Definition__mdt md : [SELECT DeveloperName, Calculation__c, Processing_Order__c,
                                                    Field_Values__c, Number_of_Tokens__c, Matching_Search_Filter__c,
                                                    Salesforce_Object__c, Salesforce_Field__c, 
                                                    Salesforce_Object__r.QualifiedApiName, 
                                                    Salesforce_Field__r.QualifiedApiName
                                                FROM Token_Pricing_Definition__mdt
                                                 WHERE Business_Line__c=:reportRequest.businessLine.name()
                                                 AND Report_Type__c=:reportRequest.reportType.name()
                                                 ORDER BY Processing_Order__c ASC, Salesforce_Field__c ASC]) {
            pricingSettings.add(md);
        }
    }

    private static void retrieveRecords() {
        Set<String> recordIds = reportRequest.recordIds;

        String sObjectName = '';
        for (Token_Pricing_Definition__mdt def : pricingSettings) {
            if (String.isNotBlank(def.Salesforce_Object__c)) {
                sObjectName = def.Salesforce_Object__r.QualifiedApiName;
                break;
            }
        }
        
        Set<String> fieldsToRetrieve = new Set<String>();

        for (Token_Pricing_Definition__mdt md : pricingSettings) {
            if (String.isNotBlank(md.Salesforce_Field__c)) {
                fieldsToRetrieve.add(md.Salesforce_Field__r.QualifiedApiName);
            }
        }
        
        String soqlQuery = 'SELECT ' + String.join(new List<String>(fieldsToRetrieve), ', ') + ' FROM ' + sObjectName;
        soqlQuery += ' WHERE Id IN :recordIds';
        reportRequest.records = Database.query(soqlQuery);
    }

    private static Decimal getDefaultCostTotal() {
        Decimal total = 0;
        reportRequest.searchCostPerMarket = 0;

        for (Token_Pricing_Definition__mdt md : pricingSettings) {
            if (md.Calculation__c.equals(CALCULATION_DEFAULT_ADD)) {
                reportRequest.searchCostPerMarket += md.Number_of_Tokens__c;
            }
        }

        for (String market : reportRequest.selectedMarkets) {
            total += reportRequest.searchCostPerMarket;
        }

        total = (total<=1 ? reportRequest.searchCostPerMarket : total);

        return total;
    }

    private static Decimal getCalculationTotal(String operation) {
        Decimal total = 0;

        //concatenated attributes (e.g. Market#AgeGroup) representing matched records => records
        //this is final list that is used to calculate tokens
        Map<String, List<Sobject>> finalGroupedRecords = new Map<String, List<Sobject>>();

        //concatenated attributes (e.g. Market#AgeGroup) representing matched records => records
        //this is temporary list that is appended to when processing pricing settings for the same field (e.g. Age groupsS)
        //data is appended to finalGroupedRecords once system identifies that pricing settings are for different field (=next grouping level)
        Map<String, List<Sobject>> thisGroupingLevelRecords = new Map<String, List<Sobject>>();
        Map<String, Token_Pricing_Definition__mdt> pricingDetails = new Map<String, Token_Pricing_Definition__mdt>();

        String groupedFieldName = '';
        for (Token_Pricing_Definition__mdt md : pricingSettings) {
            if (!md.Calculation__c.equals(operation)) {
                continue;
            }

            Boolean mustGroupFieldValues = String.isNotBlank(md.Field_Values__c);
            String fieldApiName = md.Salesforce_Field__r.QualifiedApiName;
            Boolean groupingForSameField = (groupedFieldName==fieldApiName);

            groupedFieldName = fieldApiName;

            if (finalGroupedRecords.isEmpty()) {
                //simply populate map so we can always process map below (as in subsequent runs) this map is populated by actually grouped records
                finalGroupedRecords.put('#', reportRequest.records);
            } else if (!groupingForSameField) {
                //otherwise, if pricing is for different field (compared to previous pricing definition), append it to grouping
                finalGroupedRecords.clear();
                finalGroupedRecords.putAll(thisGroupingLevelRecords);
                thisGroupingLevelRecords.clear();
            }

            Map<String, List<Sobject>> newlyGroupedRecords = new Map<String, List<Sobject>>();
            for (String groupingLevelKey : finalGroupedRecords.keySet()) {
                for (Sobject record : finalGroupedRecords.get(groupingLevelKey)) {
                    //if field on record is not populated we skip that field
                    Boolean fieldOnRecordIsPopulated = (record.get(fieldApiName) != null && String.isNotBlank(String.valueOf(record.get(fieldApiName))));
                    if (!fieldOnRecordIsPopulated) {
                        continue;
                    }

                    Set<String> recordFieldValues = new Set<String>(((String)record.get(fieldApiName)).split(';'));
                    Map<String, String> fieldValueToRemainingValue = new Map<String, String>();
                    //group values if this should be done (e.g. two values if both or any are found cost only one 1 token, not more)
                    //if grouping not required, retain the value

                    if (mustGroupFieldValues) {
                        List<String> tmpAllValues = md.Field_Values__c.split(';');
                        tmpAllValues.sort();
                        Set<String> allowedValuesForGrouping = new Set<String>(tmpAllValues);
                        String valueNameForGroup = '';
                        for (String fieldValue : allowedValuesForGrouping) {
                            Boolean givenFieldValueIsPresent = recordFieldValues.contains(fieldValue);
                            if (String.isBlank(valueNameForGroup)) {
                                valueNameForGroup = fieldValue;
                            }
                            if (givenFieldValueIsPresent) {
                                fieldValueToRemainingValue.put(fieldValue, valueNameForGroup);
                            }
                        }
                    } else {
                        for (String recordValue : recordFieldValues) {
                            fieldValueToRemainingValue.put(recordValue, recordValue);
                        }
                    }

                    //check if field being processed should be matched to search filters used
                    // if so, we should ensure we only keep field values used in search (e.g. if matched regulation 
                    // is for adults and kids, but search was for kids only, adults value should not be retained (and therefore there should be no token cost for that)
                    if (String.isNotBlank(md.Matching_Search_Filter__c)) {
                        Set<String> valuesUsedInSearch = new Set<String>();
                        valuesUsedInSearch = (md.Matching_Search_Filter__c==MATCHING_SEARCH_FILTER_MARKET ? reportRequest.selectedMarkets : valuesUsedInSearch);
                        valuesUsedInSearch = (md.Matching_Search_Filter__c==MATCHING_SEARCH_FILTER_AGE ? reportRequest.selectedAgeGroups : valuesUsedInSearch);
                        valuesUsedInSearch = (md.Matching_Search_Filter__c==MATCHING_SEARCH_FILTER_RISK ? reportRequest.selectedRiskTypes : valuesUsedInSearch);

                        for (String fieldValue : fieldValueToRemainingValue.keySet()) {
                            if (valuesUsedInSearch<>null && !valuesUsedInSearch.isEmpty() && !valuesUsedInSearch.contains(fieldValue)) {
                                fieldValueToRemainingValue.remove(fieldValue);
                            }
                        }           
                    }

                    Set<String> remainingFieldValues = new Set<String>(fieldValueToRemainingValue.values());

                    for (String fieldValue : remainingFieldValues) {
                        String groupedKey = groupingLevelKey + '#' + fieldValue;
                        List<Sobject> tmpGroupedRecordsList = (newlyGroupedRecords.containsKey(groupedKey) ? newlyGroupedRecords.get(groupedKey) : new List<Sobject>());
                        tmpGroupedRecordsList.add(record);
                        newlyGroupedRecords.put(groupedKey, tmpGroupedRecordsList);
                        pricingDetails.put(groupedKey, md);
                    }
                }
            }
            thisGroupingLevelRecords.putAll(newlyGroupedRecords);
        }

        finalGroupedRecords.clear();
        finalGroupedRecords.putAll(thisGroupingLevelRecords);

        for (String key : finalGroupedRecords.keySet()) {
            Decimal tokensCount = pricingDetails.get(key).Number_of_Tokens__c;
            System.debug('Adding ' + tokensCount + ' token(s) for ' + key + ' according to ' + pricingDetails.get(key).DeveloperName);
            total += tokensCount;
        }

        if (reportRequest.reportType == REPORT_TYPE.GAP_ANALYSIS && total>0) {
            //if dealing with gap analysis, should deduct number of tokens from total that were paid to run search
            //if search has a match for given market, debit one token back
            //if search has no matches, don't debit token
            Set<String> targetMarketsWithResults = new Set<String>();  //reportRequest.selectedMarkets
            for (String key : finalGroupedRecords.keySet()) {
                String firstGroupingMarket = key.substring(key.indexOf('##')+2, key.length());
                firstGroupingMarket = firstGroupingMarket.substring(0, firstGroupingMarket.indexOf('#'));
                targetMarketsWithResults.add(firstGroupingMarket);
            }

            for (String market : targetMarketsWithResults) {
                total -= reportRequest.searchCostPerMarket;
            }
        }

        if (total < 1) {
            throw new TokensAndPricingHelperException(ERROR_CALCULATION_FAILED);
        }
        return total;
    }
}