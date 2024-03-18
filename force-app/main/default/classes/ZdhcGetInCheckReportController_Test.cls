@IsTest
public with sharing class ZdhcGetInCheckReportController_Test {
  static TC_TestDataFactory_SupplierFacilityBrand setup() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    List<Inventory__c> inventoryList = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      accounts.facility.Id,
      30,
      Date.today().addMonths(-1),
      'Delivery',
      2,
      0,
      'kg',
      5.00,
      30.00,
      6.00
    );

    return accounts;
  }

  static ZDHCGatewayServiceResponse setupResponse(
    Boolean totalSuccess,
    Boolean partialSuccess
  ) {
    ZDHCGatewayResult gatewayResult = new ZDHCGatewayResult();
    gatewayResult.success = partialSuccess;

    ZDHCGetInCheckReportResponse responseData = new ZDHCGetInCheckReportResponse();
    responseData.result = gatewayResult;
    responseData.incheckReportId = '123IAmAReportId';
    responseData.incheckReport = 'IamAPDFStringOfReportData';

    ZDHCGatewayServiceResponse response = new ZDHCGatewayServiceResponse();
    response.isSuccess = totalSuccess;
    response.httpStatus = totalSuccess ? 'OK' : 'ERROR';
    response.httpStatusCode = totalSuccess ? 200 : 400;
    response.errors = new List<String>{ 'error1', 'error2' };
    response.response = responseData;

    return response;
  }

  @IsTest
  static void getInCheckReportForInventory() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();
    Brand_Supplier_Connection__c connection = TC_TestDataFactory_Connections.create(
      accounts.brand,
      accounts.supplier,
      accounts.brandContacts[0],
      'Approved'
    );
    insert connection;

    String verification = '1234567890';
    Inventory__c inventory = [SELECT Id FROM Inventory__c LIMIT 1];
    inventory.InCheck_Report_Verification_Id__c = verification;
    inventory.Status__c = 'Submitted';
    update inventory;

    Test.startTest();
    TC_TriggeredSharing.processNewOrUpdatedUsers(
      new List<Id>{
        accounts.brandUsers[0].Id,
        accounts.supplierUsers[0].Id,
        accounts.facilityUsers[0].Id
      }
    );
    Test.stopTest();

    // String getInCheckReportForInventory(String inventoryId)
    String report = ZdhcGetInCheckReportController.getInCheckReportForInventory(
      inventory.Id
    );

    System.assertNotEquals(null, report);
  }

  @IsTest
  static void getInventory_differentUserAccess() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();

    Brand_Supplier_Connection__c connection = TC_TestDataFactory_Connections.create(
      accounts.brand,
      accounts.supplier,
      accounts.brandContacts[0],
      'Approved'
    );
    insert connection;

    String verification = '1234567890';
    Inventory__c inventory = [SELECT Id FROM Inventory__c LIMIT 1];
    inventory.InCheck_Report_Verification_Id__c = verification;
    inventory.Status__c = 'Submitted';
    update inventory;

    Test.startTest();
    TC_TriggeredSharing.processNewOrUpdatedUsers(
      new List<Id>{
        accounts.brandUsers[0].Id,
        accounts.supplierUsers[0].Id,
        accounts.facilityUsers[0].Id
      }
    );
    Test.stopTest();

    // test the method as a non-TC user
    Inventory__c returnedInv = ZdhcGetInCheckReportController.getInventory(
      inventory.Id
    );
    System.assertEquals(
      verification,
      returnedInv.InCheck_Report_Verification_Id__c
    );
    System.assertEquals(
      accounts.supplier.Name,
      returnedInv.Facility__r.Parent.Name
    );
    System.assertEquals(accounts.facility.Name, returnedInv.Facility__r.Name);

    // test the method as a brand user
    System.runAs(accounts.brandUsers[0]) {
      Inventory__c brandInv = ZdhcGetInCheckReportController.getInventory(
        inventory.Id
      );
      System.assertEquals(
        verification,
        brandInv.InCheck_Report_Verification_Id__c
      );
      System.assertEquals(
        accounts.supplier.Name,
        brandInv.Facility__r.Parent.Name
      );
      System.assertEquals(accounts.facility.Name, brandInv.Facility__r.Name);
    }

    // test the method as a supplier user
    System.runAs(accounts.supplierUsers[0]) {
      Inventory__c supplierInv = ZdhcGetInCheckReportController.getInventory(
        inventory.Id
      );
      System.assertEquals(
        verification,
        supplierInv.InCheck_Report_Verification_Id__c
      );
      System.assertEquals(
        accounts.supplier.Name,
        supplierInv.Facility__r.Parent.Name
      );
      System.assertEquals(accounts.facility.Name, supplierInv.Facility__r.Name);
    }

    // test the method as a facility user
    System.runAs(accounts.facilityUsers[0]) {
      Inventory__c facilityInv = ZdhcGetInCheckReportController.getInventory(
        inventory.Id
      );
      System.assertEquals(
        verification,
        facilityInv.InCheck_Report_Verification_Id__c
      );
      System.assertEquals(
        accounts.supplier.Name,
        facilityInv.Facility__r.Parent.Name
      );
      System.assertEquals(accounts.facility.Name, facilityInv.Facility__r.Name);
    }
  }

  @IsTest
  static void getInventory_invalidInventoryId() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();
    Inventory__c inventory = [SELECT Id FROM Inventory__c LIMIT 1];

    Boolean threwException = false;

    try {
      Inventory__c returnedInv = ZdhcGetInCheckReportController.getInventory(
        inventory.Id
      );
    } catch (Exception e) {
      threwException = true;
    }
    System.assert(threwException);
  }

  @IsTest
  static void constructRequest_returnsCorrect() {
    String userKey = '123IAmAUserAccessKey';
    String inCheckId = '543IAmAnInCheckId';

    ZDHCGatewayServiceRequest request = ZdhcGetInCheckReportController.constructRequest(
      userKey,
      inCheckId
    );

    System.assertEquals('incheckReport', request.apiName);
    System.assertEquals('GET', request.method);
    System.assertEquals(userKey, request.userAccessKey);
    System.assertEquals(inCheckId, request.queryParams.get('reportId'));
  }

  @IsTest
  static void processResponse_partialSuccess() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();
    ZDHCGatewayServiceResponse response = setupResponse(false, true);
    Inventory__c inventory = [
      SELECT Facility__r.Name, Facility__r.Parent.Name, Inventory_Name__c
      FROM Inventory__c
      LIMIT 1
    ];

    String returnVal = ZdhcGetInCheckReportController.processResponse(
      response,
      inventory
    );

    System.assertEquals('error1, error2', returnVal);
  }

  @IsTest
  static void processResponse_totalSuccess() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();
    ZDHCGatewayServiceResponse response = setupResponse(true, true);
    Inventory__c inventory = [
      SELECT Facility__r.Name, Facility__r.Parent.Name, Inventory_Name__c
      FROM Inventory__c
      LIMIT 1
    ];

    String returnVal = ZdhcGetInCheckReportController.processResponse(
      response,
      inventory
    );
    Map<String, String> returnMap = (Map<String, String>) JSON.deserialize(
      returnVal,
      Map<String, String>.class
    );

    System.assertEquals(
      accounts.supplier.Name +
      ' - ' +
      accounts.facility.Name +
      ' - ' +
      inventory.Inventory_Name__c +
      '.pdf',
      returnMap.get('fileName')
    );
    System.assertEquals('IamAPDFStringOfReportData', returnMap.get('fileData'));
  }

  @IsTest
  static void processResponse_totalFailure() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = setup();
    ZDHCGatewayServiceResponse response = setupResponse(false, false);
    Inventory__c inventory = [
      SELECT Facility__r.Name, Facility__r.Parent.Name, Inventory_Name__c
      FROM Inventory__c
      LIMIT 1
    ];

    String returnVal = ZdhcGetInCheckReportController.processResponse(
      response,
      inventory
    );

    System.assertEquals('error1, error2', returnVal);
  }
}