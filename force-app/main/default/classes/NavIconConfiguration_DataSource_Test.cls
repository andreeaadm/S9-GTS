@isTest
public with sharing class NavIconConfiguration_DataSource_Test {
    @isTest private static void test_1_1() {
        Test.startTest();
        NavIconConfiguration_DataSource datasource = new NavIconConfiguration_DataSource(null);
        datasource.getDefaultValue();
        VisualEditor.DynamicPickListRows rows = datasource.getValues();
        Test.stopTest();
        System.assert(rows != null);
    }
}