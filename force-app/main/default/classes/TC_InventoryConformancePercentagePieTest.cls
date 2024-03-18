@isTest
public with sharing class TC_InventoryConformancePercentagePieTest {
    @testSetup
    static void setup() {
        TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
            1,
            0, // inactive
            new List<Integer>{ 1 },
            new List<Integer>{ 0 }, // inactive
            1,
            0 // inactive
        );
        TC_TestDataFactory_Contacts tdfc = new TC_TestDataFactory_Contacts(
            tdfa,
            'unittest@example.com',
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 }
        );
        TC_TestDataFactory_Connections bsc = new TC_TestDataFactory_Connections(
            tdfa,
            tdfc
        );
        TC_TestDataFactory_Formulators tdff = new TC_TestDataFactory_Formulators(
            tdfa.facilities
        );
        TC_TestDataFactory_Chemicals chemical = new TC_TestDataFactory_Chemicals(
            tdff,
            null
        );
        TC_TestDataFactory_Inventories inventory = new TC_TestDataFactory_Inventories(
            tdfa.facilities,
            new List<Integer>{ 3 },
            Date.today()
        );
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(tdfc, true);
        TC_TestDataFactory_Users.insertPermissionSetAssignments(
            tdfu.permissionSetAssignments
        );
    }
    
    @isTest
    static void getOptions_parameter() {
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();
        
        ChartDataProvider.ChartOption supplierAdminUsersResult;
        ChartDataProvider.ChartOption supplierStdUsersResult;
        ChartDataProvider.ChartOption facilityAdminUsersResult;
        ChartDataProvider.ChartOption facilityStdUsersResult;
        ChartDataProvider.ChartOption brandAdminUsersResult;
        ChartDataProvider.ChartOption brandStdUsersResult;
        
        // getOptions(Object)
        Object parameter = null;
        
        Test.startTest();
        System.runAs(tdfu.supplierAdminUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            supplierAdminUsersResult = context.getOptions(parameter);
        }
        System.runAs(tdfu.supplierStdUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            supplierStdUsersResult = context.getOptions(parameter);
        }
        System.runAs(tdfu.facilityAdminUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            facilityAdminUsersResult = context.getOptions(parameter);
        }
        System.runAs(tdfu.facilityStdUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            facilityStdUsersResult = context.getOptions(parameter);
        }
        System.runAs(tdfu.brandAdminUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            brandAdminUsersResult = context.getOptions(parameter);
        }
        System.runAs(tdfu.brandStdUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            brandStdUsersResult = context.getOptions(parameter);
        }
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            supplierAdminUsersResult,
            'supplierAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            supplierStdUsersResult,
            'supplierStdUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            facilityAdminUsersResult,
            'facilityAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            facilityStdUsersResult,
            'facilityStdUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            brandAdminUsersResult,
            'brandAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            brandStdUsersResult,
            'brandStdUsersResult should not be null.'
        );
    }
    
    @isTest
    static void getSupplierLocationsListTest(){
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();
        
        String brandAdminUsersResult;
        String brandStdUsersResult;
        
        Test.startTest();
        System.runAs(tdfu.brandAdminUsers[0]) {
            brandAdminUsersResult = TC_InventoryConformancePercentagePie.getSupplierLocationsList();
        }
        System.runAs(tdfu.brandStdUsers[0]) {
            brandStdUsersResult = TC_InventoryConformancePercentagePie.getSupplierLocationsList();
        }
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            brandAdminUsersResult,
            'brandAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            brandStdUsersResult,
            'brandStdUsersResult should not be null.'
        );
    }
    
    @isTest
    static void getSupplierTypeListTest(){
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();
        
        String brandAdminUsersResult;
        String brandStdUsersResult;
        
        Test.startTest();
        System.runAs(tdfu.brandAdminUsers[0]) {
            brandAdminUsersResult = TC_InventoryConformancePercentagePie.getSupplierTypeList();
        }
        System.runAs(tdfu.brandStdUsers[0]) {
            brandStdUsersResult = TC_InventoryConformancePercentagePie.getSupplierTypeList();
        }
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            brandAdminUsersResult,
            'brandAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            brandStdUsersResult,
            'brandStdUsersResult should not be null.'
        );
    }
    
    @isTest
    static void getInventoryTypeListTest(){
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();
        
        String brandAdminUsersResult;
        String brandStdUsersResult;
        
        Test.startTest();
        System.runAs(tdfu.brandAdminUsers[0]) {
            brandAdminUsersResult = TC_InventoryConformancePercentagePie.getInventoryTypeList();
        }
        System.runAs(tdfu.brandStdUsers[0]) {
            brandStdUsersResult = TC_InventoryConformancePercentagePie.getInventoryTypeList();
        }
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            brandAdminUsersResult,
            'brandAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            brandStdUsersResult,
            'brandStdUsersResult should not be null.'
        );
    }
    
    @isTest
    static void getConfAndClassfTypeListTest(){
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();
        
        String brandAdminUsersResult;
        String brandStdUsersResult;
        String supplierAdminUsersResult;
        String supplierStdUsersResult;
        
        Test.startTest();
        System.runAs(tdfu.brandAdminUsers[0]) {
            brandAdminUsersResult = TC_InventoryConformancePercentagePie.getConformanceTypeList();
            brandAdminUsersResult = TC_InventoryConformancePercentagePie.getClassificationList();
        }
        System.runAs(tdfu.brandStdUsers[0]) {
            brandStdUsersResult = TC_InventoryConformancePercentagePie.getConformanceTypeList();
            brandStdUsersResult = TC_InventoryConformancePercentagePie.getClassificationList();
        }
        System.runAs(tdfu.supplierAdminUsers[0]) {
            supplierAdminUsersResult = TC_InventoryConformancePercentagePie.getConformanceTypeList();
            supplierAdminUsersResult = TC_InventoryConformancePercentagePie.getClassificationList();
        }
        System.runAs(tdfu.supplierStdUsers[0]) {
            supplierStdUsersResult = TC_InventoryConformancePercentagePie.getConformanceTypeList();
            supplierStdUsersResult = TC_InventoryConformancePercentagePie.getClassificationList();
        }
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            brandAdminUsersResult,
            'brandAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            brandStdUsersResult,
            'brandStdUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            supplierAdminUsersResult,
            'supplierAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            supplierStdUsersResult,
            'supplierStdUsersResult should not be null.'
        );
    }
    
    // prettier-ignore
    @isTest
    static void getData_parameter() {
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();
        
        List<ChartDataProvider.ChartData> supplierAdminUsersResult;
        List<ChartDataProvider.ChartData> supplierStdUsersResult;
        List<ChartDataProvider.ChartData> facilityAdminUsersResult;
        List<ChartDataProvider.ChartData> facilityStdUsersResult;
        List<ChartDataProvider.ChartData> brandAdminUsersResult;
        List<ChartDataProvider.ChartData> brandStdUsersResult;
        
        // getData(Object)
        String parameter = '{ "recordId": "ALL", "month": "0", "location" : "United States of America", "supplierType" : null, "inventoryType" : "Usage_Inventory_Line_Item" }';
            /*, "location" : "United States of America"*/
        
        Test.startTest();
        System.runAs(tdfu.supplierAdminUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            supplierAdminUsersResult = context.getData(parameter);
        }
        System.runAs(tdfu.supplierStdUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            supplierStdUsersResult = context.getData(parameter);
        }
        System.runAs(tdfu.facilityAdminUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            facilityAdminUsersResult = context.getData(parameter);
        }
        System.runAs(tdfu.facilityStdUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            facilityStdUsersResult = context.getData(parameter);
        }
        System.runAs(tdfu.brandAdminUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            brandAdminUsersResult = context.getData(parameter);
        }
        System.runAs(tdfu.brandStdUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            brandStdUsersResult = context.getData(parameter);
        }
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            supplierAdminUsersResult,
            'List<ChartDataProvider.ChartData> supplierAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            supplierStdUsersResult,
            'List<ChartDataProvider.ChartData> supplierStdUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            facilityAdminUsersResult,
            'List<ChartDataProvider.ChartData> facilityAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            facilityStdUsersResult,
            'List<ChartDataProvider.ChartData> facilityStdUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            brandAdminUsersResult,
            'List<ChartDataProvider.ChartData> brandAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            brandStdUsersResult,
            'List<ChartDataProvider.ChartData> brandStdUsersResult should not be null.'
        );
        
        System.assertEquals(false, supplierAdminUsersResult[0].allZero,'allZero should be false');
        System.assertEquals(true, supplierStdUsersResult[0].allZero,'allZero should be true');
        System.assertEquals(true, facilityAdminUsersResult[0].allZero,'allZero should be true');
        System.assertEquals(false, facilityStdUsersResult[0].allZero,'allZero should be false');
        System.assertEquals(false, brandAdminUsersResult[0].allZero,'allZero should be false');
        System.assertEquals(false, brandStdUsersResult[0].allZero,'allZero should be false');
        
        System.assertEquals(99.99, (Decimal)supplierAdminUsersResult[0].detail[0] + (Decimal)supplierAdminUsersResult[0].detail[1] + (Decimal)supplierAdminUsersResult[0].detail[2] + (Decimal)supplierAdminUsersResult[0].detail[3],'Should total 100%');
        System.assertEquals(0, (Decimal)supplierStdUsersResult[0].detail[0] + (Decimal)supplierStdUsersResult[0].detail[1] + (Decimal)supplierStdUsersResult[0].detail[2] + (Decimal)supplierStdUsersResult[0].detail[3],'Should total 0%');
        System.assertEquals(0, (Decimal)facilityAdminUsersResult[0].detail[0] + (Decimal)facilityAdminUsersResult[0].detail[1] + (Decimal)facilityAdminUsersResult[0].detail[2] + (Decimal)facilityAdminUsersResult[0].detail[3],'Should total 0%');
        System.assertEquals(99.99, (Decimal)facilityStdUsersResult[0].detail[0] + (Decimal)facilityStdUsersResult[0].detail[1] + (Decimal)facilityStdUsersResult[0].detail[2] + (Decimal)facilityStdUsersResult[0].detail[3],'Should total 100%');
        System.assertEquals(99.99, (Decimal)brandAdminUsersResult[0].detail[0] + (Decimal)brandAdminUsersResult[0].detail[1] + (Decimal)brandAdminUsersResult[0].detail[2] + (Decimal)brandAdminUsersResult[0].detail[3],'Should total 100%');
        System.assertEquals(99.99, (Decimal)brandStdUsersResult[0].detail[0] + (Decimal)brandStdUsersResult[0].detail[1] + (Decimal)brandStdUsersResult[0].detail[2] + (Decimal)brandStdUsersResult[0].detail[3],'Should total 100%');
    }
    
    // prettier-ignore
    @isTest
    static void getData_parameter_inditex() {
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();
        
        List<ChartDataProvider.ChartData> supplierAdminUsersResult;
        List<ChartDataProvider.ChartData> supplierStdUsersResult;
        List<ChartDataProvider.ChartData> facilityAdminUsersResult;
        List<ChartDataProvider.ChartData> facilityStdUsersResult;
        List<ChartDataProvider.ChartData> brandAdminUsersResult;
        List<ChartDataProvider.ChartData> brandStdUsersResult;
        
        // getData(Object)
        String parameter = '{ "recordId": "ALL", "month": "0", "location" : "United States of America", "supplierType" : null, "inventoryType" : "Usage_Inventory_Line_Item", "conformanceType" : "Inditex The List" }';
            /*, "location" : "United States of America"*/
        
        Test.startTest();
        System.runAs(tdfu.supplierAdminUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            supplierAdminUsersResult = context.getData(parameter);
        }
        System.runAs(tdfu.supplierStdUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            supplierStdUsersResult = context.getData(parameter);
        }
        System.runAs(tdfu.facilityAdminUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            facilityAdminUsersResult = context.getData(parameter);
        }
        System.runAs(tdfu.facilityStdUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            facilityStdUsersResult = context.getData(parameter);
        }
        System.runAs(tdfu.brandAdminUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            brandAdminUsersResult = context.getData(parameter);
        }
        System.runAs(tdfu.brandStdUsers[0]) {
            TC_InventoryConformancePercentagePie context = new TC_InventoryConformancePercentagePie();
            brandStdUsersResult = context.getData(parameter);
        }
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            supplierAdminUsersResult,
            'List<ChartDataProvider.ChartData> supplierAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            supplierStdUsersResult,
            'List<ChartDataProvider.ChartData> supplierStdUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            facilityAdminUsersResult,
            'List<ChartDataProvider.ChartData> facilityAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            facilityStdUsersResult,
            'List<ChartDataProvider.ChartData> facilityStdUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            brandAdminUsersResult,
            'List<ChartDataProvider.ChartData> brandAdminUsersResult should not be null.'
        );
        System.assertNotEquals(
            null,
            brandStdUsersResult,
            'List<ChartDataProvider.ChartData> brandStdUsersResult should not be null.'
        );
        
        System.assertEquals(false, supplierAdminUsersResult[0].allZero,'allZero should be false');
        System.assertEquals(true, supplierStdUsersResult[0].allZero,'allZero should be true');
        System.assertEquals(true, facilityAdminUsersResult[0].allZero,'allZero should be true');
        System.assertEquals(false, facilityStdUsersResult[0].allZero,'allZero should be false');
        System.assertEquals(false, brandAdminUsersResult[0].allZero,'allZero should be false');
        System.assertEquals(false, brandStdUsersResult[0].allZero,'allZero should be false');
        
        System.assertEquals(99.99, (Decimal)supplierAdminUsersResult[0].detail[0] + (Decimal)supplierAdminUsersResult[0].detail[1] + (Decimal)supplierAdminUsersResult[0].detail[2] + (Decimal)supplierAdminUsersResult[0].detail[3],'Should total 100%');
        System.assertEquals(0, (Decimal)supplierStdUsersResult[0].detail[0] + (Decimal)supplierStdUsersResult[0].detail[1] + (Decimal)supplierStdUsersResult[0].detail[2] + (Decimal)supplierStdUsersResult[0].detail[3],'Should total 0%');
        System.assertEquals(0, (Decimal)facilityAdminUsersResult[0].detail[0] + (Decimal)facilityAdminUsersResult[0].detail[1] + (Decimal)facilityAdminUsersResult[0].detail[2] + (Decimal)facilityAdminUsersResult[0].detail[3],'Should total 0%');
        System.assertEquals(99.99, (Decimal)facilityStdUsersResult[0].detail[0] + (Decimal)facilityStdUsersResult[0].detail[1] + (Decimal)facilityStdUsersResult[0].detail[2] + (Decimal)facilityStdUsersResult[0].detail[3],'Should total 100%');
        System.assertEquals(99.99, (Decimal)brandAdminUsersResult[0].detail[0] + (Decimal)brandAdminUsersResult[0].detail[1] + (Decimal)brandAdminUsersResult[0].detail[2] + (Decimal)brandAdminUsersResult[0].detail[3],'Should total 100%');
        System.assertEquals(99.99, (Decimal)brandStdUsersResult[0].detail[0] + (Decimal)brandStdUsersResult[0].detail[1] + (Decimal)brandStdUsersResult[0].detail[2] + (Decimal)brandStdUsersResult[0].detail[3],'Should total 100%');
    }
}