/********************************************************************************************
* @Name         iCare_GTSDeclarationControllerTest
* @Author       Michael Thomas
* @Description  Test class for iCare_GTSDeclarationController to validate functionality 
*               works as expected
*********************************************************************************************/
@isTest
private class iCare_GTSDeclarationControllerTest {

    @TestSetup
    static void makeData(){
        Account sampleAccount = new Account(Name = 'Sample Account');
        insert sampleAccount;
        TestDataFactory.createCommunityUser('iCare External Standard User', sampleAccount.Id);
    }

    @isTest
    static void testValidCountry(){
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        testAccount.BillingCountry = 'Vietnam';
        update testAccount;
        User testUser = [SELECT Id FROM User WHERE AccountId = :testAccount.Id LIMIT 1];
        Test.startTest();
        List<iCare_Country_specific_information__mdt> termsAndConditions = iCare_GTSDeclarationController.getTermsAndConditions(testUser.Id);
        Test.stopTest();
        
        //Verify a Vietnamese account has a related metadata record
        System.assertNotEquals(0,termsAndConditions.size());
        System.assertNotEquals(true,termsAndConditions[0].GTS_T_Cs_required__c, 'The vietnamese custom metadata record may have been updated, please verify');
        System.assertEquals('VN',termsAndConditions[0].DeveloperName);
    }

    @isTest
    static void testInvalidCountry(){
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        testAccount.BillingCountry = 'Algeria';
        update testAccount;
        User testUser = [SELECT Id FROM User WHERE AccountId = :testAccount.Id LIMIT 1];
        Test.startTest();
        List<iCare_Country_specific_information__mdt> termsAndConditions = iCare_GTSDeclarationController.getTermsAndConditions(testUser.Id);
        Test.stopTest();
        
        //Verify an algerian account has no related metadata record
        System.assertEquals(0,termsAndConditions.size());
    }
}