/*******************************************************************************************
* @Name         iCareExpertComponentControllerTest
* @Author       Regan Smiith
* @Description  This acts as the test class to iCareExpertComponentController
*******************************************************************************************/
@isTest
private class iCareExpertComponentControllerTest {
    private static User createTestUser() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Country = 'United States',
            Alias = 'TUser',
            Email = 'TUser.Email@example.com',
            UserName = 'TUser.Username@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            timeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        return testUser;
    }
    
    @isTest
    static void testGetExpertsList() {
        User testUser = createTestUser();
        
        List<iCare_Expert__c> testExperts = new List<iCare_Expert__c>();
        // Create experts for positive test
        for (Integer i = 0; i < 200; i++) {
            iCare_Expert__c expert = new iCare_Expert__c(
                Name = 'Test ' + i,
                iCare_Bio__c = 'Test Bio ' + i,
                GTS_Bio__c = 'Test Bio ' + i,
                iCare_Country__c = 'GB',
                GTS_Country__c = 'GB',
                iCare_IsActive__c = true,
                iCare_Profile_Picture__c = 'Test Profile Picture' + i,
                iCare_Role__c = 'Test role ' + i,
                GTS_Role__c ='Test role ' + i
            );
            testExperts.add(expert);
        }
        // Create experts for negative test
        for (Integer i = 0; i < 200; i++) {
            iCare_Expert__c expert = new iCare_Expert__c(
                Name = 'Test ' + i,
                iCare_Bio__c = 'Test Bio ' + i,
                GTS_Bio__c = 'Test Bio ' + i,
                iCare_Country__c = 'US',
                iCare_IsActive__c = true,
                iCare_Profile_Picture__c = 'Test Profile Picture' + i,
                iCare_Role__c = 'Test role ' + i,
                GTS_Role__c ='Test role ' + i
            );
            testExperts.add(expert);
        }
        insert testExperts;
        system.assertEquals(400, testExperts.size());
        
        System.runAs(testUser) {
            Test.startTest();
            
            List<iCare_Expert__c> localExpertsReturned = new List<iCare_Expert__c>();
            List<iCare_Expert__c> globalExpertsReturned = new List<iCare_Expert__c>();
            localExpertsReturned = iCareExpertComponentController.getExpertsList('Local');
            globalExpertsReturned = iCareExpertComponentController.getExpertsList('Global');
            String recTypeId = iCareExpertComponentController.getGtsExpertQueryRecordtypeId();
            String queueId = iCareExpertComponentController.getGtsExpertQueryQueueId();
            system.assertEquals(
                0,
                localExpertsReturned.size(),
                'Error: Incorrect amount of experts has been returned from the query'
            );
            
            Test.stopTest();
        }
    }
    
        @isTest
    static void testGetExpertsTranslation() {
        User testUser = createTestUser();
        
        List<iCare_Expert__c> testExperts = new List<iCare_Expert__c>();
        List<GTS_Expert_Translation__c> testExpertTranslations = new List<GTS_Expert_Translation__c>();
        // Create experts for positive test
        for (Integer i = 0; i < 5; i++) {
            iCare_Expert__c expert = new iCare_Expert__c(
                Name = 'Test ' + i,
                iCare_Bio__c = 'Test Bio ' + i,
                GTS_Bio__c = 'Test Bio ' + i,
                iCare_Country__c = 'GB',
                GTS_Country__c = 'GB',
                iCare_IsActive__c = true,
                iCare_Profile_Picture__c = 'Test Profile Picture' + i,
                iCare_Role__c = 'Test role ' + i,
                GTS_Role__c ='Test role ' + i
            );
            testExperts.add(expert);
        }
        for (Integer i = 0; i < 5; i++) {
            GTS_Expert_Translation__c expertTrans = new GTS_Expert_Translation__c(
               
                GTS_Bio_Translation__c = 'Test Bio ' + i,
                GTS_Associated_Expert__c = testExperts[i].Id,
                GTS_Language_ISO_Code__c = 'en_US',
                GTS_Role_Translation__c ='Test role ' + i
            );
            testExpertTranslations.add(expertTrans);
        }
        insert testExpertTranslations;
        system.assertEquals(5, testExpertTranslations.size());

        System.runAs(testUser) {
            Test.startTest();
            
           GTS_Expert_Translation__c translationReturned  = iCareExpertComponentController.getGtsExpertTranslation(testExperts[0].Id);
            system.assertEquals(
                'Test role 0',
                translationReturned.GTS_Role_Translation__c,
                'Error: No data has been returned from the query'
            );
            
            Test.stopTest();
        }
    }
}