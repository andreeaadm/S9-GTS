/**
 * @author Kaspars Rezgalis <kaspars@cloudshiftgroup.com>
 * @date 2022-08-18
 * @group CloudShiftGroup
 * @description Handler for processing trigger actions for Token_ransaction__c object
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 18/08/2022    Kaspars Rezgalis   Created Class
*/
public without sharing class TokenTransactionTrgHandler extends TriggerHandler {
    @testVisible private static final String DEBIT_TOKEN_TRANSACTION_RT_MD ='GMA_DEBIT_TRANSACTION_RT';
    @testVisible private static final String CREDIT_TOKEN_TRANSACTION_RT_MD ='GMA_CREDIT_TRANSACTION_RT';
    
    public override void afterInsert() {
        String debitRtDevName = GMA_Variable__mdt.getInstance(DEBIT_TOKEN_TRANSACTION_RT_MD).Variable_Value__c;
        Id debitRecordTypeId = Schema.SObjectType.Token_Transaction__c.getRecordTypeInfosByDeveloperName().get(debitRtDevName).getRecordTypeId();

        List<Token_Transaction__c> debitTransactionsForLinking = new List<Token_Transaction__c>();

        for (Token_Transaction__c token : (List<Token_Transaction__c>)Trigger.new) {
            //during insert, add any debit token transactions for further processing (need to link them to credit token transactions)
            if (token.RecordTypeId==debitRecordTypeId) {
                debitTransactionsForLinking.add(token);
            }
        }

        if (!debitTransactionsForLinking.isEmpty()) {
            linkToCreditTransactions(debitTransactionsForLinking);
        }
    }


    /**
     * Method for linking given debit token transactions with relevant credit token transactions 
     * @param debitTransactions List<Token_Transaction__c> - debit token transactions to link
    */
    private static void linkToCreditTransactions (List<Token_Transaction__c> debitTransactions) {
        //please note at this stage we are assuming customer has enough tokens (otherwise why would you create debit transaction?)
        Map<Id, List<Token_Transaction__c>> accIdWithDebitTransactions = new Map<Id, List<Token_Transaction__c>>();
        for (Token_Transaction__c t : debitTransactions) {
            List<Token_Transaction__c> tmpList = (accIdWithDebitTransactions.containsKey(t.Account__c) ? accIdWithDebitTransactions.get(t.Account__c) : new List<Token_Transaction__c>());
            tmpList.add(t);
            accIdWithDebitTransactions.put(t.Account__c, tmpList);
        }

        String creditRtDevName = GMA_Variable__mdt.getInstance(CREDIT_TOKEN_TRANSACTION_RT_MD).Variable_Value__c;
        Id creditRecordTypeId = Schema.SObjectType.Token_Transaction__c.getRecordTypeInfosByDeveloperName().get(creditRtDevName).getRecordTypeId();

        Map<Id, List<Token_Transaction__c>> accIdWithCreditTransactions = new Map<Id, List<Token_Transaction__c>>();
        Map<Id, Decimal> creditIdWithRemainingAmount = new Map<Id, Decimal>();
        for (Token_Transaction__c t : [SELECT Id, Remaining_Credit_Amount__c, Account__c, Expiry_Date__c FROM Token_Transaction__c
                                        WHERE Account__c IN :accIdWithDebitTransactions.keySet() AND RecordTypeId=:creditRecordTypeId
                                        AND Remaining_Credit_Amount__c>0 AND Expired__c = false
                                         ORDER BY Expiry_Date__c ASC NULLS LAST]) {
            List<Token_Transaction__c> tmpList = (accIdWithCreditTransactions.containsKey(t.Account__c) ? accIdWithCreditTransactions.get(t.Account__c) : new List<Token_Transaction__c>());
            tmpList.add(t);
            creditIdWithRemainingAmount.put(t.Id, t.Remaining_Credit_Amount__c);
            accIdWithCreditTransactions.put(t.Account__c, tmpList);
        }

        List<Token_Transaction_Link__c> linksForInsert = new List<Token_Transaction_Link__c>();
        for (Id accId : accIdWithDebitTransactions.keySet()) {
            Map<Id, Token_Transaction__c> accountDebitTransactions = new Map<Id, Token_Transaction__c>(accIdWithDebitTransactions.get(accId));
            Map<Id, Token_Transaction__c> accountCredits = new Map<Id, Token_Transaction__c>(accIdWithCreditTransactions.get(accId));

            for (Token_Transaction__c debitTransaction : accountDebitTransactions.values()) {
                Decimal amountToCover = debitTransaction.Amount__c;
                for (Token_Transaction__c credit : accountCredits.values()) {
                    Decimal remainingCreditAmount = creditIdWithRemainingAmount.get(credit.Id);
                    Boolean creditCoversDebit = (amountToCover < remainingCreditAmount);
                    Boolean noMoreCreditWouldRemain = (amountToCover == remainingCreditAmount);
                    if (noMoreCreditWouldRemain) {
                        //debit amount == credit, so no more credits left after this on credit token transaction
                        linksForInsert.add(generateLink(credit, debitTransaction, amountToCover));
                        creditIdWithRemainingAmount.put(credit.Id, 0);
                        break;
                    } else if (creditCoversDebit) {
                        //debit amount < credit, so some credits still remain after this on credit token transaction
                        linksForInsert.add(generateLink(credit, debitTransaction, amountToCover));
                        creditIdWithRemainingAmount.put(credit.Id, remainingCreditAmount - amountToCover);
                        break;
                    } else {
                        //debit amount > credit, so we use all credits and will need another credit token transaction to cover costs
                        linksForInsert.add(generateLink(credit, debitTransaction, remainingCreditAmount));
                        amountToCover = amountToCover - remainingCreditAmount;
                        creditIdWithRemainingAmount.put(credit.Id, 0);
                    }
                }
            }
        }

        insert linksForInsert;
    }

    private static Token_Transaction_Link__c generateLink(Token_Transaction__c credit, Token_Transaction__c debit, Decimal amount) {
        Token_Transaction_Link__c link = new Token_Transaction_Link__c(
            Credit_Transaction__c = credit.Id,
            Debit_Transaction__c = debit.Id,
            Debit_Amount__c = (amount==null ? debit.Amount__c : amount)
        );
        return link;
    }
}