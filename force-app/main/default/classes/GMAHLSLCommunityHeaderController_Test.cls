@isTest
public with sharing class GMAHLSLCommunityHeaderController_Test {

    // Get icons for a valid config dev name
    @isTest private static void test_1_1() {
        Test.startTest();
        Map<String, Object> result = CommunityHeaderController.getNavIconsForConfig('Playground');
        Test.stopTest();
        System.assert(result.isEmpty() == true);
    }

    // Get icons for an invalid config dev name
    @isTest private static void test_1_2() {
        Test.startTest();
        Map<String, Object> result = CommunityHeaderController.getNavIconsForConfig('Not_A_Valid_Value');
        Test.stopTest();
        System.debug(LoggingLevel.ERROR, result);
        System.assert(result.isEmpty());
    }

    // Get nav items from default navigation
    @isTest private static void test_2_1() {
        Test.startTest();
        CommunityHeaderController.getBuilderNavItems('Default Navigation', 'Live');
        Test.stopTest();
    }
}