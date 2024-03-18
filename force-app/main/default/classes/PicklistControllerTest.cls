@isTest 
public with sharing class PicklistControllerTest {

    @IsTest
    static void testGetDependentPicklistValues(){
        String objectAPIName = 'iCare_Job_Request__c';
        String dependentFieldAPIName = 'iCare_Product_Type__c';
        String controllingFieldValue = 'IN';

       

        Test.startTest();
        List<PicklistController.picklistWrapper> picklistValue = PicklistController.getDependentPicklistValues(objectAPIName, dependentFieldAPIName, controllingFieldValue);       
        Test.stopTest();

        Assert.isNotNull(picklistValue);
    }
    
    @isTest
    static void testDecimalToBinary() {
        String binaryResult = PicklistController.decimalToBinary(10);
        System.assertEquals('1010', binaryResult);
    }
    
    @isTest
    static void testBase64ToBits() {
        String base64Value = 'f'; 
        String bitsResult = PicklistController.base64ToBits(base64Value);
        
        System.assertEquals('011111', bitsResult);
    }
}