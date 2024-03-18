@isTest
public with sharing class TC_BrandInventoryListController_Test {
    @IsTest
    static void test_getFilterLists_noConnections() {
        test.startTest();
        TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
            testData.brand,
            testData.supplier,
            testData.brandContacts[0],
            'Requested'
        );
        
        insert conn;
        test.stopTest();
        
        List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            testData.facility.Id,
            12,
            Date.today().addMonths(-1),
            'Delivery',
            2,
            2,
            'kg',
            5.00,
            30.00,
            6.00
        );
        
        inventories.addAll(
            TC_TestDataFactory_Inventories.insertInventoriesForFacility(
                testData.facility2.Id,
                12,
                Date.today().addMonths(-1),
                'Delivery',
                2,
                2,
                'kg',
                5.00,
                30.00,
                6.00
            )
        );
        
        for (Inventory__c i : inventories) {
            i.Status__c = 'Submitted';
        }
        
        update inventories;
        
        System.runAs(testData.brandUsers[0]) {
            String jsonResponse = TC_BrandInventoryListController.getFilterLists();
            
            Map<String, Object> responseMap = ((Map<String, Object>) JSON.deserializeUntyped(
                jsonResponse
            ));
            System.assertEquals(
                0,
                ((List<Object>) responseMap.get('suppliers')).size()
            );
            System.assertEquals(
                0,
                ((List<Object>) responseMap.get('facilities')).size()
            );
            System.assertEquals(
                0,
                ((List<Object>) responseMap.get('inventories')).size()
            );
            System.assertEquals(
                0,
                ((List<Object>) responseMap.get('validFacilityIds')).size()
            );
        }
    }
    
    @IsTest
    static void test_getFilterLists_validConnections() {
        test.startTest();
        TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
            testData.brand,
            testData.supplier,
            testData.brandContacts[0],
            'Approved'
        );
        
        insert conn;
        test.stopTest();
        
        List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            testData.facility.Id,
            12,
            Date.today().addMonths(-1),
            'Delivery',
            2,
            2,
            'kg',
            5.00,
            30.00,
            6.00
        );
        
        inventories.addAll(
            TC_TestDataFactory_Inventories.insertInventoriesForFacility(
                testData.facility2.Id,
                12,
                Date.today().addMonths(-1),
                'Delivery',
                2,
                2,
                'kg',
                5.00,
                30.00,
                6.00
            )
        );
        
        for (Inventory__c i : inventories) {
            i.Status__c = 'Submitted';
        }
        
        update inventories;
        
        System.runAs(testData.brandUsers[0]) {
            String jsonResponse = TC_BrandInventoryListController.getFilterLists();
            
            Map<String, Object> responseMap = ((Map<String, Object>) JSON.deserializeUntyped(
                jsonResponse
            ));
            
            System.assertEquals(
                1,
                ((List<Object>) responseMap.get('suppliers')).size()
            );
            for (Object instance : (List<Object>) responseMap.get('suppliers')) {
                System.assertEquals(
                    testData.supplier.Id,
                    ((Map<String, Object>) instance).get('value')
                );
            }
            
            System.assertEquals(
                2,
                ((List<Object>) responseMap.get('facilities')).size()
            );
            for (Object instance : (List<Object>) responseMap.get('facilities')) {
                System.assert(
                    ((Map<String, Object>) instance).get('value') ==
                    testData.facility.Id ||
                    ((Map<String, Object>) instance).get('value') == testData.facility2.Id
                );
            }
            
            System.assertEquals(
                12,
                ((List<Object>) responseMap.get('inventories')).size()
            );
            
            System.assertEquals(
                2,
                ((List<Object>) responseMap.get('validFacilityIds')).size()
            );
        }
    }
    
    @IsTest
    static void test_getFilterLists_wrongUserType() {
        test.startTest();
        TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
            testData.brand,
            testData.supplier,
            testData.brandContacts[0],
            'Approved'
        );
        
        insert conn;
        test.stopTest();
        
        List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            testData.facility.Id,
            12,
            Date.today().addMonths(-1),
            'Delivery',
            2,
            2,
            'kg',
            5.00,
            30.00,
            6.00
        );
        
        inventories.addAll(
            TC_TestDataFactory_Inventories.insertInventoriesForFacility(
                testData.facility2.Id,
                12,
                Date.today().addMonths(-1),
                'Delivery',
                2,
                2,
                'kg',
                5.00,
                30.00,
                6.00
            )
        );
        
        for (Inventory__c i : inventories) {
            i.Status__c = 'Submitted';
        }
        
        update inventories;
        
        System.runAs(testData.supplierUsers[0]) {
            String jsonResponse = TC_BrandInventoryListController.getFilterLists();
            
            Map<String, Object> responseMap = ((Map<String, Object>) JSON.deserializeUntyped(
                jsonResponse
            ));
            System.assertEquals(
                0,
                ((List<Object>) responseMap.get('suppliers')).size()
            );
            System.assertEquals(
                0,
                ((List<Object>) responseMap.get('facilities')).size()
            );
            System.assertEquals(
                0,
                ((List<Object>) responseMap.get('inventories')).size()
            );
            System.assertEquals(
                0,
                ((List<Object>) responseMap.get('validFacilityIds')).size()
            );
        }
    }
    
    @IsTest
    static void test_getInventoriesListTableData_noFilters() {
        test.startTest();
        TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
            testData.brand,
            testData.supplier,
            testData.brandContacts[0],
            'Approved'
        );
        
        insert conn;
        test.stopTest();
        
        List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            testData.facility.Id,
            12,
            Date.today().addMonths(-1),
            'Delivery',
            2,
            2,
            'kg',
            5.00,
            30.00,
            6.00
        );
        
        for (Inventory__c i : inventories) {
            i.Status__c = 'Submitted';
        }
        
        update inventories;
        
        TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            testData.facility2.Id,
            12,
            Date.today().addMonths(-1),
            'Delivery',
            2,
            2,
            'kg',
            5.00,
            30.00,
            6.00
        );
        
        ListResponse returnedData = TC_BrandInventoryListController.getInventoriesListTableData(
            null,
            null,
            null,
            null,
            new Map<Id, Id>{ testData.supplier.Id => conn.Id },
            new List<Id>{ testData.facility.Id, testData.facility2.Id }
        );
        
        System.assertEquals(12, returnedData.totalRows);
        System.assertEquals(11, returnedData.table.columns.size());
        System.assertEquals(12, returnedData.table.rows.size());
    }
    
    @IsTest
    static void test_getInventoriesListTableData_filterValuesNotAllowed() {
        test.startTest();
        TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
            testData.brand,
            testData.supplier,
            testData.brandContacts[0],
            'Approved'
        );
        
        insert conn;
        test.stopTest();
        
        List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            testData.facility.Id,
            12,
            Date.today().addMonths(-1),
            'Delivery',
            2,
            2,
            'kg',
            5.00,
            30.00,
            6.00
        );
        
        inventories.addAll(
            TC_TestDataFactory_Inventories.insertInventoriesForFacility(
                testData.facility2.Id,
                12,
                Date.today().addMonths(-1),
                'Delivery',
                2,
                2,
                'kg',
                5.00,
                30.00,
                6.00
            )
        );
        
        for (Inventory__c i : inventories) {
            i.Status__c = 'Submitted';
        }
        
        update inventories;
        
        ListResponse returnedData = TC_BrandInventoryListController.getInventoriesListTableData(
            null,
            testData.brand.Id,
            testData.brand.Id,
            null,
            new Map<Id, Id>{ testData.supplier.Id => conn.Id },
            new List<Id>{ testData.facility.Id, testData.facility2.Id }
        );
        
        System.assertEquals(24, returnedData.totalRows);
        System.assertEquals(11, returnedData.table.columns.size());
        System.assertEquals(24, returnedData.table.rows.size());
    }
    
    @IsTest
    static void test_getInventoriesListTableData_filterValuesAllowed() {
        test.startTest();
        TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
            testData.brand,
            testData.supplier,
            testData.brandContacts[0],
            'Approved'
        );
        
        insert conn;
        test.stopTest();
        
        List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            testData.facility.Id,
            12,
            Date.today().addMonths(-1),
            'Delivery',
            2,
            2,
            'kg',
            5.00,
            30.00,
            6.00
        );
        
        inventories.addAll(
            TC_TestDataFactory_Inventories.insertInventoriesForFacility(
                testData.facility2.Id,
                12,
                Date.today().addMonths(-1),
                'Delivery',
                2,
                2,
                'kg',
                5.00,
                30.00,
                6.00
            )
        );
        
        for (Inventory__c i : inventories) {
            i.Status__c = 'Submitted';
        }
        
        update inventories;
        
        Datetime latestInv = Date.today().addMonths(-1);
        String dateString = latestInv.format('MMMM YYYY');
        
        ListResponse returnedData = TC_BrandInventoryListController.getInventoriesListTableData(
            null,
            testData.supplier.Id,
            testData.facility2.Id,
            dateString,
            new Map<Id, Id>{ testData.supplier.Id => conn.Id },
            new List<Id>{ testData.facility.Id, testData.facility2.Id }
        );
        
        if(returnedData.totalRows != null) {
            System.assertEquals(1, returnedData.totalRows);
            System.assertEquals(11, returnedData.table.columns.size());
            System.assertEquals(1, returnedData.table.rows.size());  
        }
    }
    
    @IsTest
    static void test_getColumns_returnsColumns() {
        List<DataTable.Column> returnData = TC_BrandInventoryListController.getColumns();
        
        System.assertEquals(11, returnData.size());
        System.assertEquals(Label.TC_Supplier_Name_Column, returnData[0].label);
        System.assertEquals(Label.TC_Facility_Name_Column, returnData[1].label);
        System.assertEquals(Label.TC_HIGGID,returnData[2].label);
        System.assertEquals(Label.TC_SupplierAID,returnData[3].label);
        System.assertEquals(Label.TC_Facility_Street_Column, returnData[4].label);
        System.assertEquals(Label.TC_Facility_CityTown_Column, returnData[5].label);
        System.assertEquals(Label.TC_Facility_Country_Column, returnData[6].label);
        System.assertEquals(Label.TC_Facility_Postal_Code_Column,returnData[7].label);
        System.assertEquals(Label.TC_Inventory_Name_Column, returnData[8].label);
        System.assertEquals('', returnData[9].label);
        System.assertEquals('', returnData[10].label);
    }
    
    @IsTest
    static void test_getRows_noData() {
        List<DataTable.Row> returnData = TC_BrandInventoryListController.getRows(
            new List<Inventory__c>(),
            new Map<Id, Id>()
        );
        
        System.assertEquals(0, returnData.size());
    }
    
    @IsTest
    static void test_getRows_withData() {
        TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
            testData.brand,
            testData.supplier,
            testData.brandContacts[0],
            'Approved'
        );
        
        insert conn;
        
        List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            testData.facility.Id,
            12,
            Date.today().addMonths(-1),
            'Delivery',
            2,
            2,
            'kg',
            5.00,
            30.00,
            6.00
        );
        
        for (Inventory__c i : inventories) {
            i.Status__c = 'Submitted';
        }
        
        update inventories;
        
        List<DataTable.Row> returnData = TC_BrandInventoryListController.getRows(
            inventories,
            new Map<Id, Id>{ testData.supplier.Id => conn.Id }
        );
        
        System.assertEquals(12, returnData.size());
        System.assertEquals(inventories[0].Id, returnData[0].rowId);
        System.assertEquals(
            'standard__recordPage',
            ((Map<String, Object>) returnData[0].rowCells[0].navMixinPageRef)
            .get('type')
        );
        System.assertNotEquals(
            null,
            ((Map<String, Object>) returnData[0].rowCells[0].navMixinPageRef)
            .get('attributes')
        );
        System.assertEquals(
            inventories[0].Inventory_Name__c,
            returnData[0].rowCells[5].value
        );
    }
}