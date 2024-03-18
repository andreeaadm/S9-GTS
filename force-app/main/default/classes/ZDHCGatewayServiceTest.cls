/**
 * unit tests for the ZDHCGatewayService class
 * @author Kevin Reader (oe:gen)
 * @date December 2021
 */
@isTest
private class ZDHCGatewayServiceTest {
  @isTest
  private static void handeExceptionTest() {
    ZDHCGatewayServiceRequest request;
    ZDHCErrorLog errorLog = new ZDHCErrorLog();
    Test.startTest();
    try {
      String str = request.method;
    } catch (System.Exception ex) {
      ZDHCGatewayServiceResponse response = ZDHCGatewayService.handleException(
        ex,
        errorLog
      );
      errorLog.commitLog();
      System.assert(!response.isSuccess);
      System.assert(!response.errors.isEmpty());
      System.assertEquals(ex.getMessage(), response.errors[0]);

      List<ZDHC_Error_Log__c> errorLogs = [
        SELECT
          Error_Messages__c,
          HTTP_Request__c,
          HTTP_Response__c,
          Original_Request__c,
          Timestamp__c
        FROM ZDHC_Error_Log__c
      ];

      System.assertEquals(1, errorLogs.size());
      System.assertEquals(null, errorLogs[0].Original_Request__c);
      System.assertEquals(ex.getMessage(), errorLogs[0].Error_Messages__c);
      System.assertEquals(null, errorLogs[0].HTTP_Request__c);
      System.assertEquals(null, errorLogs[0].HTTP_Response__c);
      System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
    }
    Test.stopTest();
  }

  @isTest
  private static void getApiMetadataSuccessTest() {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'formulators';
    zdhcRequest.method = 'POST';

    ZDHC_Gateway_API__mdt mdt = [
      SELECT Id
      FROM ZDHC_Gateway_API__mdt
      WHERE DeveloperName = 'POST_formulators'
    ];

    Test.startTest();
    ZDHC_Gateway_API__mdt result = ZDHCGatewayService.getApiMetadata(
      zdhcRequest
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(mdt.Id, result.Id);
  }

  @isTest
  private static void getApiMetadataFailureTest() {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'formulators';
    zdhcRequest.method = 'PATCH';

    Test.startTest();
    ZDHC_Gateway_API__mdt result = ZDHCGatewayService.getApiMetadata(
      zdhcRequest
    );
    Test.stopTest();

    System.assertEquals(null, result);
  }

  @isTest
  private static void makeCalloutSuccessTest() {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'products';
    zdhcRequest.method = 'GET';
    zdhcRequest.userAccessKey = 'kuyb&O7876b';

    StaticResourceMockResponseGenerator.setMock(
      'GetProductsResponse',
      200,
      'OK',
      null
    );

    Test.startTest();
    ZDHCGatewayServiceResponse result = ZDHCGatewayService.makeCallout(
      zdhcRequest
    );
    Test.stopTest();

    System.debug(result);

    System.assertNotEquals(null, result);
    System.assert(result.isSuccess);
    System.assertEquals(200, result.httpStatusCode);
    System.assertEquals('OK', result.httpStatus);
    System.assert(result.response instanceof ZDHCGetProductsResponse);

    List<ZDHC_Error_Log__c> errorLogs = [
      SELECT
        Error_Messages__c,
        HTTP_Request__c,
        HTTP_Response__c,
        Original_Request__c,
        Timestamp__c
      FROM ZDHC_Error_Log__c
    ];

    System.assertEquals(0, errorLogs.size());
  }

  @isTest
  private static void makeCalloutFailedFindApiMetadataTest() {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'formulators';
    zdhcRequest.method = 'PATCH';

    Test.startTest();
    ZDHCGatewayServiceResponse result = ZDHCGatewayService.makeCallout(
      zdhcRequest
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assert(!result.isSuccess);
    System.assertEquals(1, result.errors.size());
    System.assertEquals(Label.ZDHC_No_Callout_Class, result.errors[0]);

    List<ZDHC_Error_Log__c> errorLogs = [
      SELECT
        Error_Messages__c,
        HTTP_Request__c,
        HTTP_Response__c,
        Original_Request__c,
        Timestamp__c
      FROM ZDHC_Error_Log__c
    ];

    System.assertEquals(1, errorLogs.size());
    System.assertEquals(
      JSON.serialize(zdhcRequest),
      errorLogs[0].Original_Request__c
    );
    System.assertEquals(
      Label.ZDHC_No_Callout_Class,
      errorLogs[0].Error_Messages__c
    );
    System.assertEquals(null, errorLogs[0].HTTP_Request__c);
    System.assertEquals(null, errorLogs[0].HTTP_Response__c);
    System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
  }

  @isTest
  private static void makeCalloutFailedNoUserAccessKeyTest() {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'products';
    zdhcRequest.method = 'GET';

    Test.startTest();
    ZDHCGatewayServiceResponse result = ZDHCGatewayService.makeCallout(
      zdhcRequest
    );
    Test.stopTest();

    System.debug(result);

    System.assertNotEquals(null, result);
    System.assert(!result.isSuccess);
    System.assertEquals(1, result.errors.size());
    System.assertEquals(Label.ZDHC_No_Access_Key, result.errors[0]);

    List<ZDHC_Error_Log__c> errorLogs = [
      SELECT
        Error_Messages__c,
        HTTP_Request__c,
        HTTP_Response__c,
        Original_Request__c,
        Timestamp__c
      FROM ZDHC_Error_Log__c
    ];

    System.assertEquals(1, errorLogs.size());
    System.assertEquals(
      JSON.serialize(zdhcRequest),
      errorLogs[0].Original_Request__c
    );
    System.assertEquals(
      Label.ZDHC_No_Access_Key,
      errorLogs[0].Error_Messages__c
    );
    System.assertEquals(null, errorLogs[0].HTTP_Request__c);
    System.assertEquals(null, errorLogs[0].HTTP_Response__c);
    System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
  }

  @isTest
  private static void makeCalloutFailedRequestValidationTest() {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'activateInCheckSubscription';
    zdhcRequest.method = 'POST';
    zdhcRequest.userAccessKey = '5745687jhgfjf';

    Test.startTest();
    ZDHCGatewayServiceResponse result = ZDHCGatewayService.makeCallout(
      zdhcRequest
    );
    Test.stopTest();

    System.debug(result);

    System.assertNotEquals(null, result);
    System.assert(!result.isSuccess);
    System.assertEquals(1, result.errors.size());
    System.assertEquals(Label.ZDHC_Missing_Expected_Params, result.errors[0]);

    List<ZDHC_Error_Log__c> errorLogs = [
      SELECT
        Error_Messages__c,
        HTTP_Request__c,
        HTTP_Response__c,
        Original_Request__c,
        Timestamp__c
      FROM ZDHC_Error_Log__c
    ];

    System.assertEquals(1, errorLogs.size());
    System.assertEquals(
      JSON.serialize(zdhcRequest),
      errorLogs[0].Original_Request__c
    );
    System.assertEquals(
      Label.ZDHC_Missing_Expected_Params,
      errorLogs[0].Error_Messages__c
    );
    System.assertEquals(null, errorLogs[0].HTTP_Request__c);
    System.assertEquals(null, errorLogs[0].HTTP_Response__c);
    System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
  }

  @isTest
  private static void makeCalloutUnexpectedResponseTest() {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'activateInCheckSubscription';
    zdhcRequest.method = 'POST';
    zdhcRequest.userAccessKey = '5745687jhgfjf';
    zdhcRequest.queryParams = new Map<String, Object>{
      'organizationGUID' => '56789098765434567'
    };

    StaticResourceMockResponseGenerator.setMock(
      'PlatformErrorResponse',
      401,
      'Unauthorized',
      null
    );

    Test.startTest();
    ZDHCGatewayServiceResponse result = ZDHCGatewayService.makeCallout(
      zdhcRequest
    );
    Test.stopTest();

    System.debug(result);

    System.assertNotEquals(null, result);
    System.assert(!result.isSuccess);
    System.assertEquals(0, result.errors.size());
    System.assert(result.response instanceof ZDHCGatewayErrorResponse);

    List<ZDHC_Error_Log__c> errorLogs = [
      SELECT
        Error_Messages__c,
        HTTP_Request__c,
        HTTP_Response__c,
        Original_Request__c,
        Timestamp__c
      FROM ZDHC_Error_Log__c
    ];

    System.assertEquals(1, errorLogs.size());
    System.assertEquals(
      JSON.serialize(zdhcRequest),
      errorLogs[0].Original_Request__c
    );
    System.assertEquals(
      'The \'organizationGUID\' URL parameter is missing in the request.',
      errorLogs[0].Error_Messages__c
    );
    System.assertNotEquals(null, errorLogs[0].HTTP_Response__c);
    System.assertNotEquals(null, errorLogs[0].HTTP_Request__c);
    System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
  }

  @isTest
  private static void getUserAccessKeyFromContactTest() {
    TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
      1,
      0, // inactive
      new List<Integer>{ 1 },
      new List<Integer>{ 0 }, // inactive
      1,
      0
    ); // inactive
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
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(tdfc, true);
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      tdfu.permissionSetAssignments
    );

    Test.startTest();
    String result = ZDHCGatewayService.getUserAccessKey(
      tdfu.supplierAdminUsers[0].ContactId
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(
      tdfu.supplierAdminUsers[0].ZDHC_User_Access_Key__c,
      result
    );
  }

  @isTest
  private static void getUserAccessKeyFromUserTest() {
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(thisUser) {
      TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
        null
      );
    }
    User testUser = [
      SELECT ZDHC_User_Access_Key__c
      FROM User
      WHERE UserType = 'PowerCustomerSuccess' AND ContactId != NULL
      LIMIT 1
    ];
    String zdhcUserAccessKey = '234567876543';
    testUser.ZDHC_User_Access_Key__c = zdhcUserAccessKey;

    Test.startTest();
    Database.update(testUser);
    String result = ZDHCGatewayService.getUserAccessKey(testUser.Id);
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(zdhcUserAccessKey, result);
  }

  @isTest
  private static void getUserAccessKeyNoMatchingUserTest() {
    Contact newContact = new Contact(
      FirstName = 'Firsiaci',
      LastName = 'Test Contact',
      Phone = StringUtil.random(12, '0123456789'),
      Email = 'test.contact@unittest.invalid'
    );
    Database.insert(newContact);

    Test.startTest();
    try {
      String result = ZDHCGatewayService.getUserAccessKey(newContact.Id);
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(Label.ZDHC_No_User_Found, ex.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  private static void getUserAccessKeyNoAccessKeyTest() {
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(thisUser) {
      TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
        null
      );
    }
    // Make sure to get a user without a key
    User testUser = [
      SELECT ZDHC_User_Access_Key__c, ContactId
      FROM User
      WHERE ZDHC_User_Access_Key__c = NULL
      LIMIT 1
    ];

    Test.startTest();
    String result = ZDHCGatewayService.getUserAccessKey(testUser.ContactId);
    Test.stopTest();

    System.assertEquals(null, result);
  }

  @isTest
  private static void updateInCheckSubscriptionDate() {
    TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
      1,
      0, // inactive
      new List<Integer>{ 1 },
      new List<Integer>{ 0 }, // inactive
      1,
      0
    ); // inactive

    // String updateInCheckSubscriptionDate(String recordId, String dateString)
    Test.startTest();
    String resultSuccess = ZDHCGatewayService.updateInCheckSubscriptionDate(
      tdfa.facilities[0].Id,
      '2022-07-07'
    );
    try {
      ZDHCGatewayService.updateInCheckSubscriptionDate(
        '0012F00000xbdInQAI',
        '2022-07-07'
      );
      System.assert(false, 'expect exception');
    } catch (AuraHandledException e) {
      Test.stopTest();
    }

    System.assertNotEquals(null, resultSuccess);
    System.assertEquals('success', resultSuccess);
  }

  @isTest
  private static void constructor() {
    ZDHCGatewayService serviceDefault = new ZDHCGatewayService();
    ZDHCGatewayService serviceWithLogList = new ZDHCGatewayService(
      new List<ZDHC_Error_Log__c>()
    );
    System.assertNotEquals(null, serviceDefault);
    System.assertNotEquals(null, serviceWithLogList);
  }
}