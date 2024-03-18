@isTest
private class MTC_deleteACCRrecords_Test {
    @TestSetup
    static void makeData() {
        TestDataFactory.ISTEST_FOR_MTC = true;
        ReportAccessUtil.disableSharingProcessing();
        ReportAccessUtil.bypassQueueable = true;
        
        List<Account> accounts = TestDataFactory.createAccounts(2, true);
        Schema.DescribeSObjectResult assetDescr = Asset.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMapByDevName = assetDescr.getRecordTypeInfosByDeveloperName();
        // TestDataFactory.createAccountsWithContacts(accounts, 2);
        
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
        Contact newContact = new Contact();
            newContact.Email = 'test@oegen.co.uk';
            newContact.Phone = '0123456789';
            newContact.FirstName = 'Test';
            newContact.LastName = 'Contact ';
            newContact.Is_User_Required__c = true;
            newContact.AccountId = accounts[0].Id;
        insert newContact;
        Asset report = new Asset();
            report.AccountId = accounts[0].ID;
            report.RecordTypeId = rtMapByDevName.get('MTC_Report').getRecordTypeId();
            report.Name = 'Report ' ;
            report.Type__c = 'Report';
            report.MTC_Status__c = 'Official';
            report.Date_Issued__c = Date.today();
            report.Date_Revised__c = Date.today();
            report.ContactId = newContact.Id;
        insert report;
       
        /*List<Asset> reports = TestDataFactory.createReportForAccounts(
            accounts,
            false
        );*/
       // reports[0].ContactId = newContact.id;//contacts[0].Id;
       // insert reports;
        
        ReportAccessUtil.enableSharingProcessing();
    }
    @isTest
    static void testDeleteACCR(){
        List<Asset> reports = [
            SELECT Name, ContactId, AccountId, Contact.Name, Contact.Email
            FROM Asset
            WHERE Account.Name = 'Account 1'
        ];
        
        Asset report = reports[0];
        List<Asset_Contact_Relationship__c> testACR = new List<Asset_Contact_Relationship__c>();
        for(Integer i= 0; i <19; i++){
            Asset_Contact_Relationship__c accr = new Asset_Contact_Relationship__c();
            accr.Asset__c = report.Id;
            accr.Contact__c = report.ContactId;
            accr.Asset_Synced_Date__c = Date.today().addDays(-130);
            // accr.CreatedDate = Date.today().addDays(-121);
            // Test.setCreatedDate(accr.Id, Date.today().addDays(-121));  
            testACR.add(accr);
        }
        insert testACR;
        
        List<Asset_Contact_Relationship__c> insertedACCR = [Select Id from Asset_Contact_Relationship__c where Asset__c =: report.Id];
        system.assertEquals(20,insertedACCR.size());
        
        Test.startTest();
        MTC_deleteACCRrecords mtcdelete = new MTC_deleteACCRrecords();
        Id batchprocessId = Database.executeBatch(mtcdelete,200);
        Test.stopTest();
        
        List<Asset_Contact_Relationship__c> deletedACCR = [Select Id from Asset_Contact_Relationship__c where Asset__c =: report.Id];
        system.assertEquals(1,deletedACCR.size());
    }
    
    public static testMethod void testschedule() {
        Test.StartTest();
        MTC_deleteACCRrecordsScheduled testsche = new MTC_deleteACCRrecordsScheduled();
        String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, testsche );
        Test.stopTest();
    }
    
}