/**
 * @author Kaspars Rezgalis <kaspars@cloudshiftgroup.com>
 * @date 2022-08-18
 * @group CloudShiftGroup
 * @description Test class for TokenTransactionTrgHandler which handles trigger actions for Token_Transaction__c records
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 22/08/2022    Kaspars Rezgalis   Created Class
*/
@isTest
private class TokenTransactionTrgHandlerTest {
    private static final String ACCOUNT_NAME_PREFIX = 'GMA HLSL ';
    private static final Date EXPIRING_CREDIT_EARLIEST_DATE = Date.today().addDays(10);
    private static final Decimal EXPIRING_CREDIT_EARLIEST_AMOUNT = 10;
    private static final Decimal REGULAR_CREDIT_AMOUNT = 2;
    private static final Date EXPIRING_CREDIT_LATEST_DATE = Date.today().addDays(100);
    private static final Decimal EXPIRING_CREDIT_LATEST_AMOUNT = 5;

    private static final String CREDIT_RT_NAME = GMA_Variable__mdt.getInstance(TokenTransactionTrgHandler.CREDIT_TOKEN_TRANSACTION_RT_MD).Variable_Value__c;
    private static final Id CREDIT_RT_ID = Schema.SObjectType.Token_Transaction__c.getRecordTypeInfosByDeveloperName().get(CREDIT_RT_NAME).getRecordTypeId();

    private static final String DEBIT_RT_NAME = GMA_Variable__mdt.getInstance(TokenTransactionTrgHandler.DEBIT_TOKEN_TRANSACTION_RT_MD).Variable_Value__c;
    private static final Id DEBIT_RT_ID = Schema.SObjectType.Token_Transaction__c.getRecordTypeInfosByDeveloperName().get(DEBIT_RT_NAME).getRecordTypeId();
    
    @TestSetup
    private static void makeData(){
        List<Account> accs = TestDataFactory.createAccounts(2);
        accs.get(0).Name = ACCOUNT_NAME_PREFIX + ' 0';
        accs.get(1).Name = ACCOUNT_NAME_PREFIX + ' 1';
        insert accs;

        List<Token_Transaction__c> tokensForInsert = new List<Token_Transaction__c>();
        Token_Transaction__c expiring1_1 = new Token_Transaction__c(
            Account__c = accs.get(0).Id,
            Amount__c = EXPIRING_CREDIT_EARLIEST_AMOUNT,
            Expiry_Date__c = EXPIRING_CREDIT_EARLIEST_DATE,
            Expired__c = false,
            RecordTypeId = CREDIT_RT_ID
        );
        tokensForInsert.add(expiring1_1);

        Token_Transaction__c expiring1_2 = new Token_Transaction__c(
            Account__c = accs.get(1).Id,
            Amount__c = EXPIRING_CREDIT_EARLIEST_AMOUNT,
            Expiry_Date__c = EXPIRING_CREDIT_EARLIEST_DATE,
            Expired__c = false,
            RecordTypeId = CREDIT_RT_ID
        );
        tokensForInsert.add(expiring1_2);

        Token_Transaction__c regular_1 = new Token_Transaction__c(
            Account__c = accs.get(0).Id,
            Amount__c = REGULAR_CREDIT_AMOUNT,
            Expired__c = false,
            RecordTypeId = CREDIT_RT_ID
        );
        tokensForInsert.add(regular_1);

        Token_Transaction__c regular_2 = new Token_Transaction__c(
            Account__c = accs.get(1).Id,
            Amount__c = REGULAR_CREDIT_AMOUNT,
            Expired__c = false,
            RecordTypeId = CREDIT_RT_ID
        );
        tokensForInsert.add(regular_2);

        Token_Transaction__c expiring2_1 = new Token_Transaction__c(
            Account__c = accs.get(0).Id,
            Amount__c = EXPIRING_CREDIT_LATEST_AMOUNT,
            Expiry_Date__c = EXPIRING_CREDIT_LATEST_DATE,
            Expired__c = false,
            RecordTypeId = CREDIT_RT_ID
        );
        tokensForInsert.add(expiring2_1);

        Token_Transaction__c expiring2_2 = new Token_Transaction__c(
            Account__c = accs.get(1).Id,
            Amount__c = EXPIRING_CREDIT_LATEST_AMOUNT,
            Expiry_Date__c = EXPIRING_CREDIT_LATEST_DATE,
            Expired__c = false,
            RecordTypeId = CREDIT_RT_ID
        );
        tokensForInsert.add(expiring2_2);

        insert tokensForInsert;
    }

    /*
    Scenario tested - Add debit token transaction for full amount (equal to credits available)
    for one test account and verify that number of tokens available is correctly counted.
    */
    @isTest
    private static void testTokenDeductionSimple() {
        String expectedAccountName = ACCOUNT_NAME_PREFIX + ' 0';
        Account acc0 = [SELECT Id FROM Account WHERE Name=:expectedAccountName];

        Decimal tokensToDebit = EXPIRING_CREDIT_EARLIEST_AMOUNT + REGULAR_CREDIT_AMOUNT + EXPIRING_CREDIT_LATEST_AMOUNT;

        Token_Transaction__c debit = new Token_Transaction__c(
            Account__c = acc0.Id,
            Amount__c = tokensToDebit,
            RecordTypeId = DEBIT_RT_ID
        );
        insert debit;

        for (Account acc : [SELECT Name, GMA_Available_Tokens__c FROM Account]) {
            if (acc.Name==expectedAccountName) {
                System.assertEquals(0, acc.GMA_Available_Tokens__c, 'There should be no more tokens available for first test account.');
            } else {
                System.assertEquals(tokensToDebit, acc.GMA_Available_Tokens__c, 'Other accounts should still have all original tokens available.');
            }
        }
    }

    /*
    Scenario tested - Add debit token transaction for partial amount (compared to credits available)
    and verify that debit transactions are correctly associated with expiring / regular credit token transactions
    */
    @isTest
    private static void testTokenDeductionStaggered_1() {
        String expectedAccountName = ACCOUNT_NAME_PREFIX + ' 0';
        Account acc0 = [SELECT Id FROM Account WHERE Name=:expectedAccountName];

        Decimal creditsInTotal = EXPIRING_CREDIT_EARLIEST_AMOUNT + REGULAR_CREDIT_AMOUNT + EXPIRING_CREDIT_LATEST_AMOUNT;
        Decimal tokensToDebit = EXPIRING_CREDIT_EARLIEST_AMOUNT + Math.round(EXPIRING_CREDIT_LATEST_AMOUNT / 2);

        Token_Transaction__c debit = new Token_Transaction__c(
            Account__c = acc0.Id,
            Amount__c = tokensToDebit,
            RecordTypeId = DEBIT_RT_ID
        );
        insert debit;

        for (Account acc : [SELECT Name, GMA_Available_Tokens__c FROM Account]) {
            if (acc.Name==expectedAccountName) {
                System.assertEquals(creditsInTotal - tokensToDebit, acc.GMA_Available_Tokens__c, 'The amount of tokens remaining for given test account should be reduced.');
            } else {
                System.assertEquals(creditsInTotal, acc.GMA_Available_Tokens__c, 'Other accounts should still have all original tokens available.');
            }
        }

        List<Token_Transaction_Link__c> transactionLinks = new List<Token_Transaction_Link__c>([SELECT Credit_Transaction__c, 
                                                                                                Credit_Transaction__r.Expiry_Date__c, Debit_Amount__c
                                                                                                 FROM Token_Transaction_Link__c
                                                                                                 WHERE Credit_Transaction__r.Account__c=:acc0.Id
                                                                                                 ORDER BY Credit_Transaction__r.Expiry_Date__c ASC NULLS LAST]);
        System.assertEquals(2, transactionLinks.size(), 'There should be 2 transaction link records - we are trying to apply debit equal to total amount of earliest credited expiring tokens and half of the tokens from latest expiring credited tokens');
        Token_Transaction_Link__c earliestTransaction = transactionLinks.get(0);
        Token_Transaction_Link__c secondTransaction = transactionLinks.get(1);
        System.assertEquals(EXPIRING_CREDIT_EARLIEST_AMOUNT, earliestTransaction.Debit_Amount__c, 'Earliest transaction link amount should be for whole amount of earliest expiring credit');
        System.assertEquals(EXPIRING_CREDIT_EARLIEST_DATE, earliestTransaction.Credit_Transaction__r.Expiry_Date__c, 'Linked credit transaction should be for earliest expiring credit token transaction');
        System.assertEquals(Math.round(EXPIRING_CREDIT_LATEST_AMOUNT / 2), secondTransaction.Debit_Amount__c, 'Second transaction link amount should be for half of the latest expiring credit');
        System.assertEquals(EXPIRING_CREDIT_LATEST_DATE, secondTransaction.Credit_Transaction__r.Expiry_Date__c, 'Linked credit transaction should be for latest expiring credit token transaction');
    }

    /*
    Scenario tested - Add debit token transaction for partial amount (compared to credits available)
    and verify that debit transactions are correctly associated with expiring / regular credit token transactions
    */
    @isTest
    private static void testTokenDeductionStaggered_2() {
        String expectedAccountName = ACCOUNT_NAME_PREFIX + ' 0';
        Account acc0 = [SELECT Id FROM Account WHERE Name=:expectedAccountName];

        Decimal creditsInTotal = EXPIRING_CREDIT_EARLIEST_AMOUNT + REGULAR_CREDIT_AMOUNT + EXPIRING_CREDIT_LATEST_AMOUNT;
        Decimal tokensToDebit = EXPIRING_CREDIT_EARLIEST_AMOUNT + EXPIRING_CREDIT_LATEST_AMOUNT + Math.round(REGULAR_CREDIT_AMOUNT / 2);

        Token_Transaction__c debit = new Token_Transaction__c(
            Account__c = acc0.Id,
            Amount__c = tokensToDebit,
            RecordTypeId = DEBIT_RT_ID
        );
        insert debit;

        for (Account acc : [SELECT Name, GMA_Available_Tokens__c FROM Account]) {
            if (acc.Name==expectedAccountName) {
                System.assertEquals(creditsInTotal - tokensToDebit, acc.GMA_Available_Tokens__c, 'The amount of tokens remaining for given test account should be reduced.');
            } else {
                System.assertEquals(creditsInTotal, acc.GMA_Available_Tokens__c, 'Other accounts should still have all original tokens available.');
            }
        }

        List<Token_Transaction_Link__c> transactionLinks = new List<Token_Transaction_Link__c>([SELECT Credit_Transaction__c, 
                                                                                                Credit_Transaction__r.Expiry_Date__c, Debit_Amount__c
                                                                                                 FROM Token_Transaction_Link__c
                                                                                                 WHERE Credit_Transaction__r.Account__c=:acc0.Id
                                                                                                 ORDER BY Credit_Transaction__r.Expiry_Date__c ASC NULLS LAST]);
        System.assertEquals(3, transactionLinks.size(), 'There should be 3 transaction link records - we are trying to apply debit equal to total amount of earliest and latest credited tokens and half of the tokens for regular credits');
        Token_Transaction_Link__c earliestTransaction = transactionLinks.get(0);
        Token_Transaction_Link__c secondTransaction = transactionLinks.get(1);
        Token_Transaction_Link__c thirdTransaction = transactionLinks.get(2);
        System.assertEquals(EXPIRING_CREDIT_EARLIEST_AMOUNT, earliestTransaction.Debit_Amount__c, 'Earliest transaction link amount should be for whole amount of earliest expiring credit');
        System.assertEquals(EXPIRING_CREDIT_EARLIEST_DATE, earliestTransaction.Credit_Transaction__r.Expiry_Date__c, 'Linked credit transaction should be for earliest expiring credit token transaction');
        System.assertEquals(EXPIRING_CREDIT_LATEST_AMOUNT, secondTransaction.Debit_Amount__c, 'Second transaction link amount should be for full amount of the latest expiring credit');
        System.assertEquals(EXPIRING_CREDIT_LATEST_DATE, secondTransaction.Credit_Transaction__r.Expiry_Date__c, 'Linked credit transaction should be for latest expiring credit token transaction');
        System.assertEquals(Math.round(REGULAR_CREDIT_AMOUNT / 2), thirdTransaction.Debit_Amount__c, 'Third transaction link amount should be for half of the regular credit');
        System.assertEquals(null, thirdTransaction.Credit_Transaction__r.Expiry_Date__c, 'Linked credit transaction should be regular credit without expiry date');
    }
}