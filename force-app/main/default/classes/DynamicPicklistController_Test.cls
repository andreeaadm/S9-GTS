/**
* @author Buddy Winter <buddy.winter@cloudshiftgroup.com>
* @date 2022-04-28
* @group CloudShiftGroup
* @description      Test class for DynamicPicklistController
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 28/04/2022        Buddy Winter        Created Class
*/
@IsTest
public without sharing class DynamicPicklistController_Test {

    /**
	* Method tested: getPicklistOptions()
	* Test Scenario: Get the list of keywords for picklist value 'United Kingdom' in Regulation__c.Market__c
	* Expected Result: List of keywords correctly maps to the picklist value
	*/
    @IsTest
    static void testGetPicklistOptions(){
        String objectAPIName = 'Regulation__c';
        String fieldAPIName = 'Market__c';
        String picklistValue = 'United Kingdom';

        Dynamic_Picklist_Keywords__mdt keywordEntry = [SELECT Id, Keywords__c
                                                    FROM Dynamic_Picklist_Keywords__mdt
                                                    WHERE Object_API_Name__c = :objectAPIName
                                                    AND Field_API_Name__c = :fieldAPIName
                                                    AND Picklist_Value__c = :picklistValue LIMIT 1];

        Test.startTest();
        Map<String, DynamicPicklistController.keywordDefinition> keywordMap = DynamicPicklistController.getPicklistOptions(objectAPIName, fieldAPIName);
        Test.stopTest();

        System.assertEquals(picklistValue, keywordMap.get((picklistValue + ';' + keywordEntry.Keywords__c).toLowerCase()).picklistValue, 'Keyword map returned is correct');
    }
}