/**
 * unit tests for the ZDHCCalloutRequestHelper class
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
@isTest
private class ZDHCCalloutRequestHelperTest {
  private static Map<String, Object> testParams = new Map<String, Object>{
    'param1' => 'test param',
    'param2' => 100
  };

  @isTest
  private static void buildUrlParamsWithParamsTest() {
    ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    request.userAccessKey = '123456';
    request.queryParams = testParams;

    Test.startTest();
    String result = helper.buildUrlParams(request);
    Test.stopTest();
    System.assertNotEquals(null, result);
    System.assertEquals(
      'UserAccessKey=123456&param1=test+param&param2=100',
      result
    );
  }

  @isTest
  private static void buildUrlParamsWithoutParamsTest() {
    ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    request.userAccessKey = '123456';

    Test.startTest();
    String result = helper.buildUrlParams(request);
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals('UserAccessKey=123456', result);
  }

  @isTest
  private static void buildHttpRequestWithParamsMapTest() {
    ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();

    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'formulators';
    zdhcRequest.method = 'GET';
    zdhcRequest.queryParams = testParams;
    zdhcRequest.userAccessKey = 'erfun987UY76gv';

    Test.startTest();
    HttpRequest request = helper.buildHttpRequest(zdhcRequest);
    Test.stopTest();

    System.assertNotEquals(null, request);
    System.assert(
      request.getEndpoint()
        .contains(
          '/formulators?UserAccessKey=erfun987UY76gv&param1=test+param&param2=100'
        ) //endpoint url not confirmed at time of writing
    );
    System.assertEquals('GET', request.getMethod());
    System.assert(String.isBlank(request.getBody()));
  }

  @isTest
  private static void buildHttpRequestWithRequestBodyTest() {
    ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();

    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'products';
    zdhcRequest.method = 'POST';
    zdhcRequest.userAccessKey = 'erfun987UY76gv';

    ZDHCPostProductsRequest requestBody = new ZDHCPostProductsRequest();
    requestBody.name = 'Testing Chemical Product';
    requestBody.formulatorGUID = '871872682768768768276';

    zdhcRequest.requestBody = requestBody;

    Test.startTest();
    HttpRequest request = helper.buildHttpRequest(zdhcRequest);
    Test.stopTest();

    System.assertNotEquals(null, request);
    System.assert(
      request.getEndpoint().contains('/products?UserAccessKey=erfun987UY76gv')
    );
    System.assertEquals('POST', request.getMethod());
    System.assert(String.isNotBlank(request.getBody()));

    ZDHCPostProductsRequest deserialisedReq = (ZDHCPostProductsRequest) JSON.deserializeStrict(
      request.getBody(),
      ZDHCPostProductsRequest.class
    );
    System.assertEquals(requestBody.name, deserialisedReq.name);
    System.assertEquals(
      requestBody.formulatorGUID,
      deserialisedReq.formulatorGUID
    );
  }

  @isTest
  private static void buildHttpRequestWithoutParamsTest() {
    ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();

    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'userOrganizations';
    zdhcRequest.method = 'GET';
    zdhcRequest.userAccessKey = 'erfun987UY76gv';

    Test.startTest();
    HttpRequest request = helper.buildHttpRequest(zdhcRequest);
    Test.stopTest();

    System.assertNotEquals(null, request);
    System.assert(
      request.getEndpoint()
        .contains('/userOrganizations?UserAccessKey=erfun987UY76gv')
    );
    System.assertEquals('GET', request.getMethod());
    System.assert(String.isBlank(request.getBody()));
  }

  @isTest
  private static void sendRequestQueryParamsSuccessTest() {
    ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();

    StaticResourceMockResponseGenerator.setMock(
      'SubscriptionStatusResponse',
      200,
      'OK',
      null
    );
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'subscriptionStatus';
    zdhcRequest.method = 'GET';
    zdhcRequest.userAccessKey = 'erfun987UY76gv';
    zdhcRequest.queryParams = new Map<String, Object>{
      'organizationGUID' => '9876545678987655678'
    };

    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'GET_subscriptionStatus'
    );

    Test.startTest();
    HttpResponse response = helper.sendRequest(zdhcRequest, apiMetadata);
    Test.stopTest();

    ZDHCGatewaySchema responseObj = (ZDHCGatewaySchema) JSON.deserializeStrict(
      response.getBody(),
      Type.forName(apiMetadata.Response_Object_Class_Name__c)
    );

    System.assert(responseObj instanceof ZDHCSubscriptionStatusResponse);
  }

  @isTest
  private static void sendRequestRequestBodySuccessTest() {
    ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();

    StaticResourceMockResponseGenerator.setMock(
      'PostFormulatorsResponse',
      200,
      'OK',
      null
    );
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'formulators';
    zdhcRequest.method = 'POST';
    zdhcRequest.userAccessKey = 'erfun987UY76gv';

    ZDHCPostFormulatorRequest requestBody = new ZDHCPostFormulatorRequest();
    requestBody.name = 'Test Formulator';
    requestBody.country = 'Ireland';

    zdhcRequest.requestBody = requestBody;

    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_formulators'
    );

    Test.startTest();
    HttpResponse response = helper.sendRequest(zdhcRequest, apiMetadata);
    Test.stopTest();

    ZDHCGatewaySchema responseObj = (ZDHCGatewaySchema) JSON.deserializeStrict(
      response.getBody(),
      Type.forName(apiMetadata.Response_Object_Class_Name__c)
    );

    System.assert(responseObj instanceof ZDHCPostFormulatorsResponse);
  }

  @isTest
  private static void sendRequestFailedRequestBodyValidationTest() {
    ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();

    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'formulators';
    zdhcRequest.method = 'POST';
    zdhcRequest.userAccessKey = 'erfun987UY76gv';

    ZDHCPostFormulatorRequest requestBody = new ZDHCPostFormulatorRequest();
    requestBody.name = 'Test Formulator';

    zdhcRequest.requestBody = requestBody;

    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_formulators'
    );

    Test.startTest();
    try {
      HttpResponse response = helper.sendRequest(zdhcRequest, apiMetadata);
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(
        String.format(
          Label.ZDHC_Missing_Required_Params,
          new List<String>{ 'country' }
        ),
        ex.getMessage()
      );
    }
    Test.stopTest();
  }

  @isTest
  private static void sendRequestFailedQueryParamValidationTest() {
    ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'GET_incheckReport'
    );

    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'incheckReport';
    zdhcRequest.method = 'GET';
    zdhcRequest.userAccessKey = 'erfun987UY76gv';
    zdhcRequest.queryParams = new Map<String, Object>{ 'reportId' => null };

    Test.startTest();
    try {
      HttpResponse response = helper.sendRequest(zdhcRequest, apiMetadata);
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(
        String.format(
          Label.ZDHC_Missing_Required_Params,
          new List<String>{ 'reportId' }
        ),
        ex.getMessage()
      );
    }
    Test.stopTest();
  }

  @isTest
  private static void sendRequestFailedCustomValidationTest() {
    ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_incheckReport'
    );

    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'incheckReport';
    zdhcRequest.method = 'POST';
    zdhcRequest.userAccessKey = 'erfun987UY76gv';

    ZDHCPostInCheckReportRequest requestBody = new ZDHCPostInCheckReportRequest();
    requestBody.OrganizationGUID = '546789087654678';
    requestBody.month = 10;
    requestBody.year = 2021;
    requestBody.type = 0;

    ZDHCInCheckReportInventory inventoryObj = new ZDHCInCheckReportInventory();
    inventoryObj.productGUID = '76878987657687686747675';
    inventoryObj.unit = 'kg';

    requestBody.inventory = new List<ZDHCInCheckReportInventory>{
      inventoryObj
    };

    zdhcRequest.requestBody = requestBody;

    Test.startTest();
    try {
      HttpResponse response = helper.sendRequest(zdhcRequest, apiMetadata);
    } catch (System.Exception ex) {
      System.assertEquals('ZDHCGatewayServiceException', ex.getTypeName());
      System.assertEquals(
        String.format(
          Label.ZDHC_Missing_Required_Params,
          new List<String>{ 'weight' }
        ),
        ex.getMessage()
      );
    }
    Test.stopTest();
  }
    @isTest
    private static void sendRequestPostInCheckReportCommodityName_Success_Test() {
      ZDHCCalloutRequestHelper helper = new ZDHCCalloutRequestHelper();

      StaticResourceMockResponseGenerator.setMock(
        'PostInCheckReportResponse',
        200,
        'OK',
        null
      );

      ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
        'POST_incheckReport'
      );
  
      ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
      zdhcRequest.apiName = 'incheckReport';
      zdhcRequest.method = 'POST';
      zdhcRequest.userAccessKey = 'D92BB4C7F95A7DC4E0530100007F1CBF'; //Melissa UAK UAT 2022.06
  
      ZDHCPostInCheckReportRequest requestBody = new ZDHCPostInCheckReportRequest();
      requestBody.OrganizationGUID = '546789087654678';
      requestBody.month = 10;
      requestBody.year = 2021;
      requestBody.type = 0;
  
      ZDHCInCheckReportInventory inventoryObj = new ZDHCInCheckReportInventory();
      inventoryObj.productGUID = '76878987657687686747675';
      inventoryObj.unit = 'kg';
      inventoryObj.weight = 10;
      inventoryObj.commodityName = 'Acetic acid'; // CR-12-01 IT-1560
    
  
      requestBody.inventory = new List<ZDHCInCheckReportInventory>{
        inventoryObj
      };
  
      zdhcRequest.requestBody = requestBody;
  
      Test.startTest();
      HttpResponse response = helper.sendRequest(zdhcRequest, apiMetadata);
      
      ZDHCGatewaySchema responseObj = (ZDHCGatewaySchema) JSON.deserializeStrict(
        response.getBody(),
        Type.forName(apiMetadata.Response_Object_Class_Name__c)
      );
    
      System.assert(responseObj instanceof ZDHCPostInCheckReportResponse);
      Test.stopTest();
  }
}