/******************************************************************************
Created Date: 2022 by Oegen
@description: test class of controller which creates inventory line items from CSV and update product details on them.
@author: Oegen
Modification History:
Ver			Date			Author			Modification
1			5 Jan 2024		Akshay			Added new method which covers line item update process
******************************************************************************/
@isTest
public with sharing class TC_ImportInventoryLineItemsTest {
    static User setupAndGetAdminUser() {
        TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            accounts.facility.Id,
            30,
            Date.today().addMonths(-1),
            'Delivery',
            2,
            2,
            'kg',
            5.00,
            30.00,
            6.00
        );
        User adminUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            adminUser = TestDataFactory.createAdminUser(
                'ToxClear_Intertek_Back_Office_Administrator'
            );
        }
        return adminUser;
    }
    // importLineItems with a valid base64 string and valid parentId, and a matching chemical product
    @isTest
    private static void test_importLineItems_valid() {
        User admin = setupAndGetAdminUser();
        CSVImportController csv = new CSVImportController();
        VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
        Chemical_Product__c c = [
            SELECT Id, ZDHC_Product_GUID__c
            FROM Chemical_Product__c
            LIMIT 1
        ];
        c.ZDHC_Product_GUID__c = '1234';
        update c;
        Blob csvData = Blob.valueOf(
            'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
            'Test,Test,' +
            c.ZDHC_Product_GUID__c +
            ',KG,1,2,3,Nottingham,1,2022-02-23\n' +
            'Test,Test,' +
            c.ZDHC_Product_GUID__c +
            ',LB,1,2,3,London,1,2022-01-01'
        );
        APIResponse response;
        Test.startTest();
        System.runAs(admin) {
            response = TC_ImportInventoryLineItemsController.importLineItems(
                String.valueOf(defaultSetting.getValue()),
                EncodingUtil.base64Encode(csvData),
                [SELECT Id FROM Inventory__c LIMIT 1]
                .Id
            );
        }
        Test.stopTest();
        System.assertEquals(
            4,
            [
                SELECT Id
                FROM Inventory_Line_Item__c
                WHERE ZDHC_Product_GUID__c = '1234'
            ]
            .size()
        );
        System.assertEquals('OK', response.status);
        System.assertEquals(200, response.statusCode);
    }
    // importLineItems with a valid base64 string and valid parentId, but no matching chemical product
    @isTest
    private static void test_importLineItems_noMatchingChemicalProduct() {
        User admin = setupAndGetAdminUser();
        CSVImportController csv = new CSVImportController();
        VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
        Blob csvData = Blob.valueOf(
            'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
            'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23\n' +
            'Test,Test,importLineItems_noMatchingChemicalProduct,LB,1,2,3,London,1,2022-01-01'
        );
        APIResponse response;
        Test.startTest();
        System.runAs(admin) {
            response = TC_ImportInventoryLineItemsController.importLineItems(
                String.valueOf(defaultSetting.getValue()),
                EncodingUtil.base64Encode(csvData),
                [SELECT Id FROM Inventory__c LIMIT 1]
                .Id
            );
        }
        Test.stopTest();
        System.assertEquals(
            0,
            [
                SELECT Id
                FROM Inventory_Line_Item__c
                WHERE
                ZDHC_Product_GUID__c = 'importLineItems_noMatchingChemicalProduct'
            ]
            .size()
        );
        System.assertEquals('Bad Request', response.status);
        System.assertEquals(400, response.statusCode);
    }
    
    /******************************************************************************
Created Date: 5 Jan 2024
@description: creates test data to cover line item update process
@author: Akshay
@param: NA
@return: NA
Modification History:
Ver			Date			Author			Modification
1			5 Jan 2024		Akshay			NA
******************************************************************************/
    @TestSetup
    static void setup() {
        TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
            4,
            1, // inactive
            new List<Integer>{ 10, 3, 1 },
            new List<Integer>{ 1, 1, 1 }, // inactive
            7,
            3 // inactive
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
        TC_TestDataFactory_Formulators tdff = new TC_TestDataFactory_Formulators(
            tdfa.facilities
        );
        
        TC_TestDataFactory_Chemicals chemical = new TC_TestDataFactory_Chemicals(
            tdff,
            75
        );
        // Setup inventories for these facilities.
        TC_TestDataFactory_Inventories inv1 = new TC_TestDataFactory_Inventories(
            new List<Account>{
                tdfa.facilities[0],
                    tdfa.facilities[1],
                    tdfa.facilities[2],
                    tdfa.facilities[11]
                    },
            new List<Integer>{ 3 },
            Date.today()
        );
    }
    
    /******************************************************************************
Created Date: 5 Jan 2024
@description: covers line item update process
@author: Akshay
@param: NA
@return: NA
Modification History:
Ver			Date			Author			Modification
1			5 Jan 2024		Akshay			NA
******************************************************************************/
    @isTest
    private static void testGetLatestProductDetailsFromGateway() {
        Set<String>  productGUIDS = new Set<String>();
        For(Chemical_Product__c cp : [SELECT  Id,ZDHC_Product_GUID__c FROM Chemical_Product__c]){
            productGUIDS.add(cp.ZDHC_Product_GUID__c);
        }
        List<Chemical_Product__c> cpList = [SELECT Id,ZDHC_Product_GUID__c 
                                            FROM Chemical_Product__c 
                                            WHERE ZDHC_Product_GUID__c IN ('B8DA5825B3732393E0530100007FE2C3','8780DFA33FDB77C2E0530100007F8143')];
        
        cpList[0].registered__c = 'BluChain';
        cpList[0].ZDHC_PID__c = 'P759QH90';
        cpList[0].ZDHC_Product_Id__c = '186316';
        cpList[0].ZDHC_Product_Code__c = 'A927FN89';
        update cpList[0];
        
        cpList[1].Product_Status__c = 'Deactivated';
        cpList[1].Chemical_Product_Name__c = 'Corafix Navy GDB ASG';
        update cpList[1];
        
        TC_ImpInvLineItemMockResponseGenerator mock = new TC_ImpInvLineItemMockResponseGenerator();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        TC_ImportInventoryLineItemsController.getLatestProductDetailsFromGateway(productGUIDS);
        Test.stopTest();
    }
}