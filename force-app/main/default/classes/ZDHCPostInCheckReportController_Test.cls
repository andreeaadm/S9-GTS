@IsTest
public with sharing class ZDHCPostInCheckReportController_Test {
    static List<Inventory__c> makeData() {
        TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        List<Inventory__c> inventoriesWLineItems = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            accounts.facility.Id,
            2,
            Date.today(),
            'Delivery',
            2,
            0,
            'kg',
            5.00,
            3.00,
            6.00
        );
        
        inventoriesWLineItems[1].Status__c = 'Complete';
        update inventoriesWLineItems[1];
        
        List<Inventory__c> inventoryWOLineItems = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            accounts.facility.Id,
            1,
            Date.today(),
            'Delivery',
            0,
            0,
            'kg',
            5.00,
            3.00,
            6.00
        );
        
        inventoryWOLineItems[0].Status__c = 'Complete';
        update inventoryWOLineItems[0];
        
        List<Inventory__c> insertedInventories = new List<Inventory__c>(
            inventoriesWLineItems
        );
        
        insertedInventories.addAll(inventoryWOLineItems);
        
        List<Inventory__c> inventoryWLineItemsUsage = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            accounts.facility.Id,
            1,
            Date.today(),
            'Usage',
            2,
            0,
            'kg',
            5.00,
            3.00,
            6.00
        );
        
        inventoryWLineItemsUsage[0].Status__c = 'Complete';
        update inventoryWLineItemsUsage[0];
        
        insertedInventories.addAll(inventoryWLineItemsUsage);
        
        return insertedInventories;
    }
    
    @isTest
    static void test_postInCheckReportForInventory_deliveryType() {
        List<Inventory__c> inventories = makeData();
        
        String returnString = ZDHCPostInCheckReportController.postInCheckReportForInventory(
            inventories[1].Id
        ); 
    }
    
    @isTest
    static void test_postInCheckReportForInventory_usageType() {
        List<Inventory__c> inventories = makeData();
        
        String returnString = ZDHCPostInCheckReportController.postInCheckReportForInventory(
            inventories[3].Id
        ); 
    }
    
    @IsTest
    static void test_postInCheckReportForInventory_wrongStatus() {
        /*
* First inventory is 'Pending'
* Second inventory is 'Complete' with 2 line items
* Third inventory is 'Complete' with 0 line items
*/
        List<Inventory__c> inventories = makeData();
        
        String returnString = ZDHCPostInCheckReportController.postInCheckReportForInventory(
            inventories[0].Id
        );
        System.assertEquals(
            'List has no rows for assignment to SObject',
            returnString
        );
    }
    
    @IsTest
    static void test_postInCheckReportForInventory_noLineItems() {
        /*
* First inventory is 'Pending'
* Second inventory is 'Complete' with 2 line items
* Third inventory is 'Complete' with 0 line items
*/
        List<Inventory__c> inventories = makeData();
        
        String returnString = ZDHCPostInCheckReportController.postInCheckReportForInventory(
            inventories[2].Id
        );
        System.assertEquals(Label.TC_InCheck_Error_No_Items, returnString);
    }
    
    @IsTest
    static void test_constructRequest_returnsCorrect() {
        String fakeUserKey = 'iAmAFakeUserKey';
        ZDHCGatewayServiceRequest returnVal = ZDHCPostInCheckReportController.constructRequest(
            fakeUserKey
        );
        
        System.assertEquals('incheckReport', returnVal.apiName);
        System.assertEquals('POST', returnVal.method);
        System.assertEquals(fakeUserKey, returnVal.userAccessKey);
    }
    
    @IsTest
    static void test_constructRequestBody_returnsCorrect() {
/*       
* First inventory is 'Pending'
* Second inventory is 'Complete' with 2 line items
* Third inventory is 'Complete' with 0 line items
*/
        List<Inventory__c> inventories = makeData();
        
        Inventory__c inventoryToTest = [
            SELECT
            Facility__r.Facility_Manager__c,
            Facility__r.ZDHC_Organisation_GUID__c,
            Inventory_Date__c,
            Type__c,
            (
                SELECT ZDHC_Product_GUID__c, Calculated_Usage__c, Unit__c,Commodity_Chemical_Standard_Name__c
                FROM Inventory_Line_Items__r
            )
            FROM Inventory__c
            WHERE Id = :inventories[1].Id
        ];
                
        ZDHCPostInCheckReportRequest returnVal = ZDHCPostInCheckReportController.constructRequestBody(
            inventoryToTest
        );
        System.assertEquals(null, returnVal.OrganizationGUID);
        System.assertEquals(Date.today().addMonths(-1).year(), returnVal.year);
        System.assertEquals(Date.today().addMonths(-1).month(), returnVal.month);
        System.assertEquals(2, returnVal.type);
        System.assertEquals(2, returnVal.inventory.size());
        
        for (ZDHCInCheckReportInventory lineItem : returnVal.inventory) {
            System.assertNotEquals(null, lineItem.productGUID);
            System.assertEquals(6.00, lineItem.weight);
            System.assertEquals('kg', lineItem.unit);
        }
    }
    
    @IsTest
    static void test_processZDHCResponse_success() {
        /*
* First inventory is 'Pending'
* Second inventory is 'Complete' with 2 line items
* Third inventory is 'Complete' with 0 line items
*/
        List<Inventory__c> inventories = makeData();
        
        ZDHCGatewayResult result = new ZDHCGatewayResult();
        result.success = true;
        
        ZDHCPostInCheckReportResponse incheckReponse = new ZDHCPostInCheckReportResponse();
        incheckReponse.verificationId = '123456789';
        incheckReponse.result = result;
        
        ZDHCGatewayServiceResponse response = new ZDHCGatewayServiceResponse();
        response.isSuccess = true;
        response.httpStatusCode = 200;
        response.httpStatus = 'OK';
        response.response = incheckReponse;
        
        String returnVal = ZDHCPostInCheckReportController.processZDHCResponse(
            response,
            inventories[1]
        );
        
        System.assertEquals(null, returnVal);
        
        Inventory__c submittedInventory = [
            SELECT
            InCheck_Report_Status__c,
            InCheck_Report_Error_Message__c,
            InCheck_Report_Verification_Id__c,
            Status__c,
            Submitted_Date__c
            FROM Inventory__c
            WHERE Id = :inventories[1].Id
        ];
        System.assertEquals('Success', submittedInventory.InCheck_Report_Status__c);
        System.assertEquals(
            null,
            submittedInventory.InCheck_Report_Error_Message__c
        );
        System.assertEquals(
            '123456789',
            submittedInventory.InCheck_Report_Verification_Id__c
        );
        System.assertEquals('Submitted', submittedInventory.Status__c);
        System.assertEquals(
            Datetime.now().year(),
            submittedInventory.Submitted_Date__c.year()
        );
        System.assertEquals(
            Datetime.now().month(),
            submittedInventory.Submitted_Date__c.month()
        );
        System.assertEquals(
            Datetime.now().day(),
            submittedInventory.Submitted_Date__c.day()
        );
    }
    
    @IsTest
    static void test_processZDHCResponse_error() {
        /*
* First inventory is 'Pending'
* Second inventory is 'Complete' with 2 line items
* Third inventory is 'Complete' with 0 line items
*/
        List<Inventory__c> inventories = makeData();
        
        List<String> errorList = new List<String>{
            'error message 1',
                'error message 2'
                };
                    String errorJoined = String.join(errorList, ', ');
        
        ZDHCGatewayServiceResponse response = new ZDHCGatewayServiceResponse();
        response.isSuccess = false;
        response.httpStatusCode = 404;
        response.httpStatus = 'NOT OK';
        response.errors = errorList;
        
        String returnVal = ZDHCPostInCheckReportController.processZDHCResponse(
            response,
            inventories[1]
        );
        
        System.assertEquals(errorJoined, returnVal);
        
        Inventory__c submittedInventory = [
            SELECT
            InCheck_Report_Status__c,
            InCheck_Report_Error_Message__c,
            InCheck_Report_Verification_Id__c,
            Status__c,
            Submitted_Date__c
            FROM Inventory__c
            WHERE Id = :inventories[1].Id
        ];
        System.assertEquals('Error', submittedInventory.InCheck_Report_Status__c);
        System.assertEquals(
            errorJoined,
            submittedInventory.InCheck_Report_Error_Message__c
        );
        System.assertEquals(
            null,
            submittedInventory.InCheck_Report_Verification_Id__c
        );
        System.assertEquals('Complete', submittedInventory.Status__c);
        System.assertEquals(null, submittedInventory.Submitted_Date__c);
    }
}