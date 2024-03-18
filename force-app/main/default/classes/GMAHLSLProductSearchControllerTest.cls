/**
 * @author Vikash <vikash.kumar@cloudshiftgroup.com>
 * @date 2022-06-06
 * @group CloudShiftGroup
 * @description Test class for GMAHLSLProductSearchController which is controller class for productSearch component.
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 06/06/2022    Vikash Kumar       Created Class
*/
@isTest
private class GMAHLSLProductSearchControllerTest { 
    @testSetup
    private static void createCoreData() {
        String CREDIT_RT_NAME = GMA_Variable__mdt.getInstance('GMA_CREDIT_TRANSACTION_RT').Variable_Value__c;
        Id CREDIT_RT_ID = Schema.SObjectType.Token_Transaction__c.getRecordTypeInfosByDeveloperName().get(CREDIT_RT_NAME).getRecordTypeId();
        
        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        TestDataFactory.createAccountsWithContacts(accounts, 1);
        
        Token_Transaction__c credits = new Token_Transaction__c(
            Account__c = accounts.get(0).Id,
            Amount__c = 100,
            Expired__c = false,
            RecordTypeId = CREDIT_RT_ID
        );
        insert credits;
        
        List<Regulation__c> regulationList = new List<Regulation__c>();
        List<Test_Item__c> testItemList = new List<Test_Item__c>();
        Regulation__c regulation1 = TestDataFactory.createRegulation('Aprons','Argentina','Adhesive','Adult',false);
        regulationList.add(regulation1);
        Regulation__c regulation2 = TestDataFactory.createRegulation('Aprons','Australia','Adhesive','Adult',false);
        regulationList.add(regulation2);
        Regulation__c regulation3 = TestDataFactory.createRegulation('Aprons','Belgium','Adhesive','Adult',false);
        regulationList.add(regulation3);
        insert regulationList;
        Test_Item__c testItem1 = TestDataFactory.createTestItem(regulationList[0].id,'Aprons','Argentina','Adhesive','Adult',false);
        testItemList.add(testItem1);
        Test_Item__c testItem2 = TestDataFactory.createTestItem(regulationList[1].id,'Aprons','Australia','Adhesive','Adult',false);
        testItemList.add(testItem2);
        Test_Item__c testItem3 = TestDataFactory.createTestItem(regulationList[2].id,'Aprons','Belgium','Adhesive','Adult',false);
        testItemList.add(testItem3);
        insert testItemList;
        Test_Item_Equivalency__c testEquivalency = TestDataFactory.createTestEquivalency(testItemList[0].id,testItemList[1].id,true);
        Recall__c recall = TestDataFactory.createRecall('Aprons','Argentina','Allergic');

        TestDataFactory.triggerPermissionsetUpdateForGmaPortal();
    }
    
    /**
     * Method tested: GMAHLSLProductSearchController.productSearch()
     * Test Scenario: Fetch regulation records as per provided filters.
     * Expected Result: map of regulation id and test items.
    */
    @isTest
    private static void testProductSearch() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;    
        ID regulationId = [SELECT id from Regulation__c where Market__c = 'Argentina' LIMIT 1].Id;
        Integer testItemSize = [SELECT id from Test_Item__c where Regulation__c =:regulationId ].size();
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);
        List<String> productList = new List<String>{'Aprons'};
        List<String> marketList = new List<String>{'Argentina'};
        List<String> materialList = new List<String>{'Adhesive'};
        List<String> ageRangeList = new List<String>{'Adult'};
        GMAHLSLProductSearchController.searchResult productSearchResult = new GMAHLSLProductSearchController.searchResult();
        System.runAs(portalUser) {
        Test.startTest();
        productSearchResult = GMAHLSLProductSearchController.productSearch(productList,marketList,materialList,ageRangeList,'Regulatory Sheet');       
    	Test.stopTest();
        }
        System.assertEquals(testItemSize,productSearchResult.recordsMatched.get(regulationId), 'Size of Test items should match with the value of test items count in regulation map');
    }

    /**
     * Method tested: GMAHLSLProductSearchController.recallSearch()
     * Test Scenario:  Fetch recall records as per provided filters.
     * Expected Result: List of recall id.
    */
    @isTest
    private static void testRecallSearch() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;
        ID recallId = [SELECT id from Recall__c LIMIT 1].Id;
        List<String> productList = new List<String>{'Aprons'};
        List<String> marketList = new List<String>{'Argentina'};
        List<String> riskTypeList = new List<String>{'Allergic'};
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);
        GMAHLSLProductSearchController.searchResult searchResult = new GMAHLSLProductSearchController.searchResult();
        System.runAs(portalUser) {
            Test.startTest();
            searchResult = GMAHLSLProductSearchController.recallSearch(productList,marketList,riskTypeList,'2022-06-09','2022-06-03');       
            Test.stopTest();
        }
        System.assert(searchResult.recordsMatched.containsKey(recallId), 'Same recall id should be fetched');
    }

    /**
     * Method tested: GMAHLSLProductSearchController.createRegulatorySheetOrder()
     * Test Scenario:  create order record for the passed regulation id.
     * Expected Result: order should be created 
    */
    @isTest
    private static void testCreateRegulatorySheetOrder() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);
        ID regulationId = [SELECT id from Regulation__c LIMIT 1].Id;
        List<String> productList = new List<String>{'Aprons'};
        List<String> marketList = new List<String>{'Argentina'};
        List<String> materialList = new List<String>{'Adhesive'};
        List<String> ageRangeList = new List<String>{'Adult'};
        List<String> parentRecordId = new List<String>{regulationId};
        System.runAs(portalUser) {
            Test.startTest();
            GMAHLSLProductSearchController.createRegulatorySheetOrder(parentRecordId,'Regulatory Sheet',marketList,productList,materialList,ageRangeList);       
            Test.stopTest();
        }
        ID orderID = [SELECT id from Order__c where EService__c = 'Regulatory Sheet' limit 1].id;
        system.assertNotEquals(null, orderID, 'Order should be created of Regulatory Sheet type');
    }
    
    /**
     * Method tested: GMAHLSLProductSearchController.createRecallSummaryOrder()
     * Test Scenario:  create order record for the passed recall id.
     * Expected Result: order should be created 
    */
    @isTest
    private static void testCreateRecallSummaryOrder() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);
        ID recallID = [SELECT id from Recall__c LIMIT 1].Id;
        List<String> productList = new List<String>{'Aprons'};
        List<String> marketList = new List<String>{'Argentina'};
        List<String> riskTypeList = new List<String>{'Allergic'};
        List<String> parentRecordId = new List<String>{recallID};
        System.runAs(portalUser) {
            Test.startTest();
            GMAHLSLProductSearchController.createRecallSummaryOrder(parentRecordId,'Recall Summary',marketList,productList,riskTypeList,'2022-06-09','2022-06-03');       
            Test.stopTest();
        }
        ID orderID = [SELECT id from Order__c where EService__c = 'Recall Summary' limit 1].id;
        system.assertNotEquals(null, orderID, 'Order should be created of Recall Summary type');
    }

    /**
     * Method tested: GMAHLSLProductSearchController.getSearchTokenCost() and GMAHLSLProductSearchController.getUserData()
     * Test Scenario: Fetch  search token cost and portal user.
     * Expected Result: Search token and user data.
    */
    @isTest
    private static void testUtilityMethods() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;
        Integer testItemSize = [SELECT id from Test_Item__c].size();
        ID regulationId = [SELECT id from Regulation__c LIMIT 1].Id;
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);
        User returnUser = null;
        List<String> productList = new List<String>{'Aprons'};
        List<String> marketList = new List<String>{'Argentina'};
        List<String> materialList = new List<String>{'Adhesive'};
        List<String> ageRangeList = new List<String>{'Adult'};
        GMAHLSLProductSearchController.searchResult productSearchResult = new GMAHLSLProductSearchController.searchResult();
        System.runAs(portalUser) {
        Test.startTest();
        GMAHLSLProductSearchController.getSearchTokenCost(marketList); 
        returnUser = GMAHLSLProductSearchController.getUserData(portalUser.id);            
    	Test.stopTest();
        }
        System.assertEquals(returnUser.id,portalUser.id, 'User id should be same');
    }

    /**
     * Method tested: GMAHLSLProductSearchController.gapSearch()
     * Test Scenario: Fetch test items records as per provided filters.
     * Expected Result: maps of  test items as key.
    */
    @isTest
    private static void testgapSearch() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;
        Integer testItemSize = [SELECT id from Test_Item__c].size();
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);
        List<String> productList = new List<String>{'Aprons'};
        List<String> currentMarketList = new List<String>{'Argentina'};
        List<String> TargetMarketList = new List<String>{'Australia','Belgium'};
        List<String> materialList = new List<String>{'Adhesive'};
        List<String> ageRangeList = new List<String>{'Adult'};
        GMAHLSLProductSearchController.searchResult productSearchResult = new GMAHLSLProductSearchController.searchResult();
        System.runAs(portalUser) {
        Test.startTest();
        productSearchResult = GMAHLSLProductSearchController.gapSearch(productList,currentMarketList,TargetMarketList,materialList,ageRangeList,'Gap Analysis');       
    	Test.stopTest();
        }
        Integer returnTestItemSize = productSearchResult.recordsMatched.keyset().size();
        returnTestItemSize += productSearchResult.existingRecords.keyset().size();
        returnTestItemSize += productSearchResult.gapRecords.keyset().size();
        System.assertEquals(testItemSize,returnTestItemSize, 'Size of Test items should match with the value of test items count in regulation map');
    }
    
    /**
     * Method tested: GMAHLSLProductSearchController.createGapAnalysisOrder()
     * Test Scenario:   order record for the passed regulation id.
     * Expected Result: order should be created 
    */
    @isTest
    private static void testCreateGapAnalysisOrder() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);
        List<String> productList = new List<String>{'Aprons'};
        List<String> currentMarketList = new List<String>{'Argentina'};
        List<String> TargetMarketList = new List<String>{'Australia','Belgium'};
        List<String> materialList = new List<String>{'Adhesive'};
        List<String> ageRangeList = new List<String>{'Adult'};
        List<String> existingRecordId = new List<String>();
        List<String> matchedRecordId = new List<String>();
        List<String> gapRecordId = new List<String>();
        GMAHLSLProductSearchController.searchResult productSearchResult = new GMAHLSLProductSearchController.searchResult();
        System.runAs(portalUser) {
            Test.startTest();
            productSearchResult = GMAHLSLProductSearchController.gapSearch(productList,currentMarketList,TargetMarketList,materialList,ageRangeList,'Gap Analysis'); 
            matchedRecordId.addAll(productSearchResult.recordsMatched.keyset());
            existingRecordId.addAll(productSearchResult.existingRecords.keyset());
            gapRecordId.addAll(productSearchResult.gapRecords.keyset());      
            GMAHLSLProductSearchController.createGapAnalysisOrder(existingRecordId,gapRecordId,matchedRecordId,'Gap Analysis',currentMarketList,TargetMarketList,productList,materialList,ageRangeList);       
            Test.stopTest();
        }
        ID orderID = [SELECT id from Order__c where EService__c = 'Gap Analysis' limit 1].id;
        system.assertNotEquals(null, orderID, 'Order should be created of Gap Analysis type');
    }

    /**
     * Method tested: GMAHLSLProductSearchController.getPastSearches()
     * Test Scenario: verify that search hsitories are retrieved for given customer
     * Expected Result: search history list should have records returned once one search is run
    */
    @isTest
    private static void testGetPastSearches() {
        Id accountId = [SELECT AccountId FROM Contact WHERE AccountId<>'' LIMIT 1].AccountId;
        String profileName = GMA_VAriable__mdt.getAll().get('Portal_User_Profile_Name').Variable_Value__c;
        User portalUser = TestDataFactory.createCommunityUser(profileName, accountId);
        Regulation__c regulation = [SELECT Product__c, Market__c, Age_Range__c FROM Regulation__c LIMIT 1];
        List<String> productList = regulation.Product__c.split(GMAHLSLProductSearchController.MULTIPICKLIST_SPLIT_CHAR);
        List<String> marketList = regulation.Market__c.split(GMAHLSLProductSearchController.MULTIPICKLIST_SPLIT_CHAR);
        List<String> materialList = new List<String>();
        List<String> ageRangeList = regulation.Age_Range__c.split(GMAHLSLProductSearchController.MULTIPICKLIST_SPLIT_CHAR);

        List<GMAHLSLProductSearchController.searchHistory> histories;
        System.runAs(portalUser) {
            
            Test.startTest();
            histories = GMAHLSLProductSearchController.getPastSearches(GMAHLSLProductSearchController.REGULATORY_REPORT_TYPE);
            System.assertEquals(0, histories.size(), 'There should be no search histories for given account yet');

            GMAHLSLProductSearchController.searchResult productSearchResult = GMAHLSLProductSearchController.productSearch(
                                                                                    productList, marketList,
                                                                                    materialList, ageRangeList,
                                                                                    GMAHLSLProductSearchController.REGULATORY_REPORT_TYPE);

            histories = GMAHLSLProductSearchController.getPastSearches(GMAHLSLProductSearchController.REGULATORY_REPORT_TYPE);
            System.assertEquals(1, histories.size(), 'There should be no search histories for given account yet');
            Test.stopTest();
        }
    }
}