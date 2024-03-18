/**
 * @author Vikash <vikash.kumar@cloudshiftgroup.com>
 * @date 2022-06-05
 * @group CloudShiftGroup
 * @description Class to fetch token transaction
 *
 * Date          Author             Change Description
 * -----------------------------------------------------------------------------------
 * 06/05/2022    Vikash Kumar       Created Class
*/
public with sharing class GMAHLSLTokenTransactionController {
    private static final String CREDIT_TRANSACTION_OWNER = 'Intertek';
    private static final String CREDIT_TRANSACTION_FRIENDLY_NAME = 'Addition';
    private static final String DEBIT_TRANSACTION_FRIENDLY_NAME = 'Deduction';

    public class tokenHistoryItem {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String recordType;
        @AuraEnabled
        public Decimal amount;
        @AuraEnabled
        public String timestamp;
        @AuraEnabled
        public String ownerName;
    }

    @AuraEnabled(cacheable=false)
    public static List<tokenHistoryItem> getTokenTransaction(String daysCount){
        String CREDIT_RT_NAME = GMA_Variable__mdt.getInstance('GMA_CREDIT_TRANSACTION_RT').Variable_Value__c;

        List<tokenHistoryItem> returnTokenTransaction = new List<tokenHistoryItem>();

        User runningUser = GmaPortalHelper.getCurrentUser();

        if (String.isNotBlank(runningUser.ContactId) && String.isNotBlank(runningUser.Contact.AccountId)) {
            Id accId = runningUser.Contact.AccountId;
            String queryString = 'SELECT Id, Name, RecordType.DeveloperName, Amount__c, CreatedDate, ';
            queryString += ' CreatedBy.FirstName, CreatedBy.LastName, Order__c, Expired_Tokens__c, ';
            queryString += ' Order__r.CreatedBy.FirstName, Order__r.CreatedBy.LastName ';
            queryString += ' FROM Token_Transaction__c';
            if(daysCount?.isNumeric()){
                queryString += ' WHERE CreatedDate = LAST_N_DAYS:' + daysCount;
            }

            queryString += (queryString.contains(' WHERE ') ? ' AND ' : ' WHERE ');
            queryString += ' Account__c=:accId ';
            queryString += ' ORDER BY CreatedDate DESC';
            for (Token_Transaction__c t : Database.query(queryString)) {
                tokenHistoryItem w = new tokenHistoryItem();
                w.key = t.Id;
                w.recordType = (t.RecordType.DeveloperName==CREDIT_RT_NAME ? CREDIT_TRANSACTION_FRIENDLY_NAME : DEBIT_TRANSACTION_FRIENDLY_NAME);
                w.amount = t.Amount__c;
                String ownerName = (t.RecordType.DeveloperName==CREDIT_RT_NAME ?
                                     CREDIT_TRANSACTION_OWNER : t.CreatedBy.FirstName + ' ' + t.CreatedBy.LastName);
                ownerName = (t.RecordType.DeveloperName!=CREDIT_RT_NAME && String.isNotBlank(t.Order__c) ?
                                    t.Order__r.CreatedBy.FirstName + ' ' + t.Order__r.CreatedBy.LastName : ownerName);
                                    
                w.timestamp = GmaPortalHelper.prettifyTimestamp(t.CreatedDate);
                w.ownerName = ownerName;

                Decimal expiredTokens = (t.Expired_Tokens__c != null && t.Expired_Tokens__c>0 ? t.Expired_Tokens__c : 0);
                w.name = t.Name + (expiredTokens>0 ? ' (' + expiredTokens + ' token(s) expired)' : '');

                returnTokenTransaction.add(w);
            }
        }
        return returnTokenTransaction;
    }
}