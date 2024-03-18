/**
* @author Kaspars Rezgalis <kaspars.rezgalis@cloudshiftgroup.com>
* @date 2022-09-06
* @group CloudShiftGroup
* @description Trigger handler class for Regulation__c records.
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 06/09/2022        Kaspars Rezgalis     Created Class
*/

@IsTest
private class RegulationTrgHandlerTest {
    private static final String MARKET = 'Argentina';
    private static final String MATERIAL = 'Adhesive';
    private static final String AGE = 'Adult';

    private static List<String> getValidValueForPicklist(String objName, String fieldName) {
        List<String> retValues = new List<String>();
        Schema.SObjectField fieldPicklist = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(fieldName);
        for ( Schema.PicklistEntry val : fieldPicklist.getDescribe().getPicklistValues()) {
            if (val.isActive()) {
                retValues.add(val.getValue());
            }
        }
        return retValues;
    }

    @IsTest
    static void testSimpleRegulation(){
        List<String> productValues = getValidValueForPicklist('Regulation__c', 'Product__c');

        Regulation__c regulation = TestDataFactory.createRegulation(productValues.get(0), MARKET, MATERIAL, AGE, false);
        for (Integer i=9; i>1; i--) {
            regulation.Product__c += ';' + productValues.get(i);
        }

        Test.startTest();
        insert regulation;
        Test.stopTest();

        String soql = 'SELECT ' + RegulationTrgHandler.CONCAT_FIELD_NAME + ' FROM Regulation__c WHERE Id=\'' + regulation.Id + '\'';
        List<Regulation__c> toAssertRecords = Database.query(soql);
        String expectedOrder = productValues.get(0);
        for (Integer i=2; i<10; i++) {
            expectedOrder += ';' + productValues.get(i);
        }
        String actualOrder = (String)toAssertRecords.get(0).get(RegulationTrgHandler.CONCAT_FIELD_NAME);
        System.assertEquals(expectedOrder, actualOrder, 'Field for holding concat values from Regulation product multi-picklist should hold all values alphabetically. Expected: ' + expectedOrder + ' Actual: ' + actualOrder);
    }

    @IsTest
    static void testSimpleTestPlan(){
        List<String> productValues = getValidValueForPicklist('Test_Item__c', 'Product__c');

        Regulation__c regulation = TestDataFactory.createRegulation(productValues.get(0), MARKET, MATERIAL, AGE, true);

        Test_Item__c testItem = TestDataFactory.createTestItem(regulation.Id, productValues.get(0), MARKET, MATERIAL, AGE, true);
        testItem.Product__c = productValues.get(0);
        for (Integer i=9; i>1; i--) {
            testItem.Product__c += ';' + productValues.get(i);
        }

        Test.startTest();
        update testItem;
        Test.stopTest();

        String soql = 'SELECT ' + TestItemTrgHandler.CONCAT_FIELD_NAME + ' FROM Test_Item__c WHERE Id=\'' + testItem.Id + '\'';
        List<Test_Item__c> toAssertRecords = Database.query(soql);
        String expectedOrder = productValues.get(0);
        for (Integer i=2; i<10; i++) {
            expectedOrder += ';' + productValues.get(i);
        }
        String actualOrder = (String)toAssertRecords.get(0).get(TestItemTrgHandler.CONCAT_FIELD_NAME);
        System.assertEquals(expectedOrder, actualOrder, 'Field for holding concat values from Test item regulation multi-picklist should hold all values alphabetically. Expected: ' + expectedOrder + ' Actual: ' + actualOrder);
    }

    @IsTest
    static void testSimpleRegulationUpdate(){
        List<String> productValues = getValidValueForPicklist('Regulation__c', 'Product__c');

        Regulation__c regulation = TestDataFactory.createRegulation(productValues.get(0), MARKET, MATERIAL, AGE, true);
        for (Integer i=9; i>1; i--) {
            regulation.Product__c += ';' + productValues.get(i);
        }

        Test.startTest();
        update regulation;
        Test.stopTest();

        String soql = 'SELECT ' + RegulationTrgHandler.CONCAT_FIELD_NAME + ' FROM Regulation__c WHERE Id=\'' + regulation.Id + '\'';
        List<Regulation__c> toAssertRecords = Database.query(soql);
        String expectedOrder = productValues.get(0);
        for (Integer i=2; i<10; i++) {
            expectedOrder += ';' + productValues.get(i);
        }
        String actualOrder = (String)toAssertRecords.get(0).get(RegulationTrgHandler.CONCAT_FIELD_NAME);
        System.assertEquals(expectedOrder, actualOrder, 'Field for holding concat values from Regulation product multi-picklist should hold all values alphabetically. Expected: ' + expectedOrder + ' Actual: ' + actualOrder);
    }

    @IsTest
    static void testRegulationUpdateBulk(){
        List<String> productValues = getValidValueForPicklist('Regulation__c', 'Product__c');

        Regulation__c regulation = TestDataFactory.createRegulation(productValues.get(0), MARKET, MATERIAL, AGE, false);
        Integer count = 1;
        for (Integer i=1; i<RegulationTrgHandler.MAX_MULTIPICKLIST_VALUES; i++) {
            if (productValues.size()>i) {
                regulation.Product__c += ';' + productValues.get(i);
                count++;
            }
        }

        Test.startTest();
        insert regulation;
        Test.stopTest();

        String soql = 'SELECT ' + RegulationTrgHandler.CONCAT_FIELD_NAME + ' FROM Regulation__c WHERE Id=\'' + regulation.Id + '\'';
        List<Regulation__c> toAssertRecords = Database.query(soql);
        Integer actualCount = (((String)toAssertRecords.get(0).get(RegulationTrgHandler.CONCAT_FIELD_NAME)).split(RegulationTrgHandler.MULTIPICKLIST_SPLIT_CHAR)).size();
        System.assertEquals(count, actualCount, 'Field for holding concat values from Regulation product multi-picklist should hold all 100 values added');
    }

    @IsTest
    static void testRegulationUpdateBulk_2(){
        List<String> productValues = getValidValueForPicklist('Regulation__c', 'Product__c');
        List<String> multiPicklistFieldApiNames = new List<String>(RegulationTrgHandler.MULTIPICKLISTS_TO_CONCAT);
        Regulation__c regulation = TestDataFactory.createRegulation(productValues.get(0), MARKET, MATERIAL, AGE, false);
        String valuesForFirstField = productValues.get(0);
        String valuesForSecondField = '';
        productValues.remove(0);
        regulation.put(multiPicklistFieldApiNames.get(1), '');
        Integer count = 1;
        for (String s : productValues) {
            if (count < (RegulationTrgHandler.MAX_MULTIPICKLIST_VALUES - 10)) {
                valuesForFirstField += ';' + s;
                count++;
            } else if (count < RegulationTrgHandler.MAX_MULTIPICKLIST_VALUES*2-10) {
                valuesForSecondField += ';' + s;
                count++;
            }
        }

        regulation.put(multiPicklistFieldApiNames.get(0), valuesForFirstField);
        regulation.put(multiPicklistFieldApiNames.get(1), valuesForSecondField);

        Test.startTest();
        insert regulation;
        Test.stopTest();

        String soql = 'SELECT ' + RegulationTrgHandler.CONCAT_FIELD_NAME + ', ';
        soql += String.join(multiPicklistFieldApiNames, ', ');
        soql += ' FROM Regulation__c WHERE Id=\'' + regulation.Id + '\'';
        List<Regulation__c> toAssertRecords = Database.query(soql);
        Integer actualCount = (((String)toAssertRecords.get(0).get(RegulationTrgHandler.CONCAT_FIELD_NAME)).split(RegulationTrgHandler.MULTIPICKLIST_SPLIT_CHAR)).size();
        System.assertEquals(count, actualCount, 'Field for holding concat values from Regulation product multi-picklist should hold all values added');

        String vasluesInFirstField = (String)toAssertRecords.get(0).get(multiPicklistFieldApiNames.get(0));
        String vasluesInSecondField = (String)toAssertRecords.get(0).get(multiPicklistFieldApiNames.get(1));
        Integer valuesCountInFirstField = vasluesInFirstField.split(RegulationTrgHandler.MULTIPICKLIST_SPLIT_CHAR).size();
        Integer valuesCountInSecondField = vasluesInSecondField.split(RegulationTrgHandler.MULTIPICKLIST_SPLIT_CHAR).size();
        System.assertEquals(RegulationTrgHandler.MAX_MULTIPICKLIST_VALUES, valuesCountInFirstField, 'Values in first product picklist should be sorted and appended and it should be max possible - 100 entries');
        System.assertEquals(count - RegulationTrgHandler.MAX_MULTIPICKLIST_VALUES, valuesCountInSecondField, 'Values in second product picklist should be sorted and all remaining values on top of 100 which could not be added to first multi-picklist field');
    }
}