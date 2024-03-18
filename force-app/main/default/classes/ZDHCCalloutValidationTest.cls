/**
 * unit tests for the ZDHCCalloutValidation class
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
@isTest
private class ZDHCCalloutValidationTest {
  private static Map<String, Object> testParams = new Map<String, Object>{
    'param1' => 'testparam',
    'param2' => 100
  };

  @isTest
  private static void validateUserAccessKeyWithAccessKeyTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    Test.startTest();
    validator.validateUserAccessKey('123456');
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateUserAccessKeyWithoutAccessKeyTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    Test.startTest();
    try {
      validator.validateUserAccessKey(null);
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(Label.ZDHC_No_Access_Key, ex.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  private static void validateMandatoryQueryParamsWithParamsTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    Test.startTest();
    validator.validateMandatoryQueryParams(
      testParams,
      new List<String>{ 'param1' }
    );
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateMandatoryQueryParamsWithNullParamsTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    Test.startTest();
    validator.validateMandatoryQueryParams(testParams, null);
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateMandatoryQueryParamsWithEmptyParamsTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    Test.startTest();
    validator.validateMandatoryQueryParams(testParams, new List<String>());
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateMandatoryQueryParamsWithMissingParamsTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    testParams.put('param3', null);

    Test.startTest();
    try {
      validator.validateMandatoryQueryParams(
        testParams,
        new List<String>{ 'param1', 'param3', 'param4' }
      );
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(
        String.format(
          Label.ZDHC_Missing_Required_Params,
          new List<String>{
            String.join(new List<String>{ 'param3', 'param4' }, ', ')
          }
        ),
        ex.getMessage()
      );
    }
    Test.stopTest();
  }

  @isTest
  private static void validateMandatoryObjectParamsWithParamsTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    ZDHCInCheckReportInventory requestObj = new ZDHCInCheckReportInventory();
    requestObj.productGUID = '12345';
    requestObj.unit = 'kg';
    requestObj.weight = 1000;

    Test.startTest();
    validator.validateMandatoryRequestBodyParams(
      requestObj,
      new List<String>{ 'productGUID', 'unit', 'weight' }
    );
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateMandatoryObjectParamsWithEmptyParamsTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    ZDHCPostProductsRequest requestObj = new ZDHCPostProductsRequest();
    requestObj.name = 'Test';

    Test.startTest();
    validator.validateMandatoryRequestBodyParams(
      requestObj,
      new List<String>()
    );
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateMandatoryObjectParamsWithNullParamsTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    ZDHCPostFormulatorRequest requestObj = new ZDHCPostFormulatorRequest();
    requestObj.name = 'Test';

    Test.startTest();
    validator.validateMandatoryRequestBodyParams(requestObj, null);
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateMandatoryObjectParamsWithMissingParamsTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    ZDHCPostInCheckReportRequest requestObj = new ZDHCPostInCheckReportRequest();
    List<String> mandatoryParams = new List<String>{
      'OrganizationGUID',
      'month',
      'year'
    };

    Test.startTest();
    try {
      validator.validateMandatoryRequestBodyParams(requestObj, mandatoryParams);
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(
        String.format(
          Label.ZDHC_Missing_Required_Params,
          new List<String>{ String.join(mandatoryParams, ', ') }
        ),
        ex.getMessage()
      );
    }
    Test.stopTest();
  }

  @isTest
  private static void handleMissingParamsWithParamsTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    List<String> missingParams = new List<String>{
      'OrganizationGUID',
      'month',
      'year'
    };

    Test.startTest();
    try {
      validator.handleMissingParams(missingParams);
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(
        String.format(
          Label.ZDHC_Missing_Required_Params,
          new List<String>{ String.join(missingParams, ', ') }
        ),
        ex.getMessage()
      );
    }
    Test.stopTest();
  }

  @isTest
  private static void handleMissingParamsWithoutParamsTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();

    Test.startTest();
    validator.handleMissingParams(new List<String>());
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateExpectedParamsNothingExpectedTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'GET_formulators'
    );

    Test.startTest();
    validator.validateExpectedParams(
      new ZDHCGatewayServiceRequest(),
      apiMetadata
    );
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateExpectedParamsExpectedQuerySuccessTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'GET_incheckReport'
    );

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    request.queryParams = new Map<String, Object>{
      'reportId' => '763748670968677465'
    };

    Test.startTest();
    validator.validateExpectedParams(request, apiMetadata);
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateExpectedParamsExpectedQueryFailureTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'GET_incheckReport'
    );

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();

    Test.startTest();
    try {
      validator.validateExpectedParams(request, apiMetadata);
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(Label.ZDHC_Missing_Expected_Params, ex.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  private static void validateExpectedParamsExpectedBodySuccessTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_products'
    );

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    request.requestBody = new ZDHCPostProductsRequest();

    Test.startTest();
    validator.validateExpectedParams(request, apiMetadata);
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateExpectedParamsExpectedBodyFailureTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_products'
    );

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();

    Test.startTest();
    try {
      validator.validateExpectedParams(request, apiMetadata);
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(
        Label.ZDHC_Missing_Expected_Request_Body,
        ex.getMessage()
      );
    }
    Test.stopTest();
  }

  @isTest
  private static void validateExpectedRequestDataWithParamsSuccessTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'GET_incheckReport'
    );

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    request.queryParams = new Map<String, Object>{
      'reportId' => '763748670968677465'
    };

    List<String> mandatoryParams = apiMetadata.Mandatory_Parameters__c.split(
      ','
    );

    Test.startTest();
    validator.validateExpectedRequestData(
      request,
      apiMetadata,
      mandatoryParams
    );
    Test.stopTest();

    System.assert(true); //only gets here if passes validation
  }

  @isTest
  private static void validateExpectedRequestDataWithBodySuccessTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_products'
    );

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    request.requestBody = new ZDHCPostProductsRequest();

    List<String> mandatoryParams = apiMetadata.Mandatory_Parameters__c.split(
      ','
    );

    Test.startTest();
    try {
      validator.validateExpectedRequestData(
        request,
        apiMetadata,
        mandatoryParams
      );
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(
        String.format(
          Label.ZDHC_Missing_Required_Params,
          new List<String>{ String.join(mandatoryParams, ', ') }
        ),
        ex.getMessage()
      );
    }
    Test.stopTest();
  }

  @isTest
  private static void validateExpectedRequestDataWithCustomSuccessTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_incheckReport'
    );

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    ZDHCPostInCheckReportRequest requestBody = new ZDHCPostInCheckReportRequest();
    requestBody.OrganizationGUID = '546789087654678';
    requestBody.month = 10;
    requestBody.year = 2021;
    requestBody.type = 0;

    ZDHCInCheckReportInventory inventoryObj = new ZDHCInCheckReportInventory();
    inventoryObj.productGUID = '76878987657687686747675';
    inventoryObj.unit = 'kg';
    inventoryObj.weight = 123.45;

    requestBody.inventory = new List<ZDHCInCheckReportInventory>{
      inventoryObj
    };

    request.requestBody = requestBody;

    Test.startTest();
    validator.validateExpectedRequestData(request, apiMetadata, null);
    Test.stopTest();
  }

  @isTest
  private static void validateRequestWithoutInventoryTest() {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_incheckReport'
    );

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    ZDHCPostInCheckReportRequest requestBody = new ZDHCPostInCheckReportRequest();
    requestBody.OrganizationGUID = '0123456789ABCDEF0123456789ABCDEF';
    requestBody.month = 10;
    requestBody.year = 2021;
    requestBody.type = 0;

    requestBody.inventory = new List<ZDHCInCheckReportInventory>();

    request.requestBody = requestBody;

    Test.startTest();
    try {
      validator.validateExpectedRequestData(request, apiMetadata, null);
      System.assert(false, 'ZDHCGatewayServiceException expected');
    } catch (ZDHCGatewayServiceException e) {
      Test.stopTest();
      System.assertEquals(
        'Missing required parameters: inventory',
        e.getMessage(),
        'Message for empty inventory list'
      );
    } catch (Exception e) {
      System.assert(false, 'System.Exception not expected');
    }
  }
}