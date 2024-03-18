@isTest
public with sharing class FacilityListTableHelperTest {
    @isTest
    static void test_buildTable() {
        TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        test.startTest();
        TC_TriggeredSharing.processNewOrUpdatedAccounts(
            new List<Account>{ testData.Supplier }
        );
        test.stopTest();
        
        System.runAs(testData.supplierUsers[0]) {
            ListResponse tableData = FacilityListTableHelper.buildTable();
            System.assertEquals(10, tableData.table.columns.size());
            System.assertEquals(2, tableData.totalRows);
        }
    }
    
    @IsTest
    static void test_getFacilitiesForTable_returns0() {
        List<Account> returnData = FacilityListTableHelper.getFacilitiesForTable();
        
        System.assertEquals(0, returnData.size());
    }
    
    @IsTest
    static void test_getFacilitiesForTable_returnsCorrect() {
        TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        test.startTest();
        TC_TriggeredSharing.processNewOrUpdatedAccounts(
            new List<Account>{ testData.Supplier }
        );
        test.stopTest();
        
        System.runAs(testData.supplierUsers[0]) {
            List<Account> returnData = FacilityListTableHelper.getFacilitiesForTable();
            System.assertEquals(2, returnData.size());
            for (Account a : returnData) {
                System.assert(a.Name.indexOf('Facility') != -1);
            }
        }
    }
    
    @IsTest
    static void test_getColumns_returnsColumns() {
        List<DataTable.Column> returnData = FacilityListTableHelper.getColumns();
        
        System.assertEquals(10, returnData.size());
        System.assertEquals(Label.TC_Facility_Name_Column, returnData[0].label);
        System.assertEquals(Label.TC_HIGGID,returnData[1].label);
        System.assertEquals(Label.TC_SupplierAID,returnData[2].label);
        System.assertEquals(Label.TC_Street_Column, returnData[3].label);
        System.assertEquals(Label.TC_CityTown_Column, returnData[4].label);
        System.assertEquals(Label.TC_Country_Column, returnData[5].label);
        System.assertEquals(Label.Postal_Code, returnData[6].label);
        System.assertEquals(
            Label.TC_Subscription_Status_Column,
            returnData[7].label
        );
        System.assertEquals(
            Label.TC_Subscription_Expiry_Column,
            returnData[8].label
        );
        System.assertEquals(Label.TC_Facility_Manager_Column, returnData[9].label);
    }
    
    @IsTest
    static void test_getRows_returns0() {
        List<DataTable.Row> returnData = FacilityListTableHelper.getRows(
            new List<Account>()
        );
        
        System.assertEquals(0, returnData.size());
    }
    
    @IsTest
    static void test_getRows_returnsRows() {
        TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        List<Account> facList = [
            SELECT
            Name,
            HIGG_Id__c,
            Supplier_AID__c,
            BillingStreet,
            BillingCity,
            BillingCountry,
            BillingPostalCode,
            ToxClear_Subscription_Status__c,
            InCheck_Subscription_Expiration_Date__c,
            Facility_Manager__r.Name
            FROM Account
            WHERE
            ToxClear_Account_Type__c = 'Facility'
            AND Is_ToxClear_Account__c = TRUE
        ];
        
        System.assertEquals(2, facList.size());
        
        List<DataTable.Row> returnData = FacilityListTableHelper.getRows(facList);
        
        System.assertEquals(2, returnData.size());
        System.assertEquals(facList[0].Id, returnData[0].rowId);
        System.assertEquals(facList[0].Name, returnData[0].rowCells[0].value);
    }
}