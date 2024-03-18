/**
* @author Buddy Winter <buddy.winter@cloudshiftgroup.com>
* @date 2022-04-22
* @group CloudShiftGroup
* @description Test class for RecallDigestProcessor
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 22/04/2022        Buddy Winter        Created Class
*/
@IsTest
public without sharing class RecallDigestProcessor_Test {

    @TestSetup
    static void makeData(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RecallDigestProcessor.ACCOUNT_RECORDTYPE_DEVNAME).getRecordTypeId();
        Account acc = new Account(Name = 'HLSL Account', RecordTypeId = accRecordTypeId);
        insert acc;
        Contact con = new Contact(AccountId = acc.Id, FirstName = 'Test', LastName = 'Contact', Email = 'fakeemail@emailtest.com', Is_GMA_HL_SL_User__c = true, Opt_In_Recall_Digest__c = true);
        insert con;
        Search__c search = new Search__c(Account__c = acc.Id, Market__c = 'United Kingdom;United States (USA)', Product__c = 'Aprons;Bags');
        insert search;
    }

    @IsTest
    static void testGenerateEmails(){
        Recall__c recall = new Recall__c(Market__c = 'United Kingdom', Product__c = 'Bags', Recall_Date__c = System.today()-3);
        insert recall;

        Test.startTest();
        RecallDigestProcessor.generateEmails(System.today() - 7, System.today());
        Test.stopTest();

        System.assertEquals(1, RecallDigestProcessor.emailsToSend.size(), 'One email has been composed');
    }

    @IsTest
    static void testSchedulerClass(){
        Recall__c recall = new Recall__c(Market__c = 'United Kingdom', Product__c = 'Bags', Recall_Date__c = System.today()-3);
        insert recall;

        Test.startTest();
        SchedulableContext sc = null;
        RecallDigestSchedulable tsc = new RecallDigestSchedulable();
        tsc.execute(sc);
        Test.stopTest();

        System.assertEquals(1, RecallDigestProcessor.emailsToSend.size(), 'One email has been composed');
    }
}