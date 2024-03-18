/**
 * unit tests for the ZDHCCalloutHelper class
 * @author Kevin Reader (oe:gen)
 * @date December 2021
 */
@isTest
private class ZDHCCalloutResponseHelperTest {
  /**
   * mocks a basic response from the API - used as needed by unit tests below
   * @param staticResourceName - name of the StaticResource containing the mocked response
   * @param successResponse - true if a 200 response and false for a failure
   * @return mocked HttpResponse
   */
  private static HttpResponse mockResponse(
    String staticResourceName,
    Boolean successResponse
  ) {
    StaticResourceMockResponseGenerator.setMock(
      staticResourceName,
      successResponse ? 200 : 401,
      successResponse ? 'OK' : 'Unauthorized',
      null
    );
    ZDHCCalloutRequestHelper requestHelper = new ZDHCCalloutRequestHelper();
    return requestHelper.sendHttpRequest(new HttpRequest());
  }

  @isTest
  private static void castResponseObjectSuccessTest() {
    HttpResponse response = mockResponse(
      'ActivateInCheckSubscriptionResponse',
      true
    );
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_activateInCheckSubscription'
    );

    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();

    Test.startTest();
    ZDHCGatewaySchema responseBody = helper.castResponseObject(
      response,
      apiMetadata
    );
    Test.stopTest();

    System.assertNotEquals(null, responseBody);
    System.assert(
      responseBody instanceof ZDHCActivateInCheckSubscriptionResponse
    );
  }

  @isTest
  private static void castResponseObjectIncorrectObjectTest() {
    HttpResponse response = mockResponse(
      'ActivateInCheckSubscriptionResponse',
      true
    );
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_Products'
    );

    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();

    Test.startTest();
    ZDHCGatewaySchema responseBody = helper.castResponseObject(
      response,
      apiMetadata
    );
    Test.stopTest();

    System.assertEquals(null, responseBody);
  }

  @isTest
  private static void castResponseObjectNoObjectTest() {
    HttpResponse response = new HttpResponse();
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_Products'
    );

    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();

    Test.startTest();
    ZDHCGatewaySchema responseBody = helper.castResponseObject(
      response,
      apiMetadata
    );
    Test.stopTest();

    System.assertEquals(null, responseBody);
  }

  @isTest
  private static void setHttpStatusTest() {
    HttpResponse response = mockResponse(
      'ActivateInCheckSubscriptionResponse',
      true
    );
    ZDHCGatewayServiceResponse gatewayResponse = new ZDHCGatewayServiceResponse();
    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();
    Test.startTest();
    helper.setHttpStatus(response, gatewayResponse);
    Test.stopTest();

    System.assertEquals(200, gatewayResponse.httpStatusCode);
    System.assertEquals('OK', gatewayResponse.httpStatus);
  }

  @isTest
  private static void processExpectedResponseSuccessTest() {
      ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_activateInCheckSubscription'
    );
    String staticResourceName = 'ActivateInCheckSubscriptionResponse';
    HttpResponse response = mockResponse(staticResourceName, true);
    ZDHCGatewayServiceResponse gatewayResponse = new ZDHCGatewayServiceResponse();
    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();
    ZDHCActivateInCheckSubscriptionResponse responseBody = (ZDHCActivateInCheckSubscriptionResponse) JSON.deserializeStrict(
      ZDHCGatewayTestUtility.getStaticResourceContents(staticResourceName),
      ZDHCActivateInCheckSubscriptionResponse.class
    );
    Test.startTest();
    helper.processExpectedResponse(response, gatewayResponse, responseBody, apiMetadata);
    helper.commitLog();
    Test.stopTest();

    System.assert(gatewayResponse.isSuccess);
    System.assertEquals(responseBody, gatewayResponse.response);
    System.assert(gatewayResponse.errors.isEmpty());

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
  private static void processExpectedResponseErrorTest() {
      ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'POST_activateInCheckSubscription'
    );
    String staticResourceName = 'EndpointErrorResponse';
    HttpResponse response = mockResponse(staticResourceName, false);
    ZDHCGatewayServiceResponse gatewayResponse = new ZDHCGatewayServiceResponse();
    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();
    ZDHCActivateInCheckSubscriptionResponse responseBody = (ZDHCActivateInCheckSubscriptionResponse) JSON.deserializeStrict(
      ZDHCGatewayTestUtility.getStaticResourceContents(staticResourceName),
      ZDHCActivateInCheckSubscriptionResponse.class
    );
    Test.startTest();
    helper.processExpectedResponse(response, gatewayResponse, responseBody, apiMetadata);
    helper.commitLog();
    Test.stopTest();

    System.assert(!gatewayResponse.isSuccess);
    System.assertEquals(responseBody, gatewayResponse.response);
    System.assert(!gatewayResponse.errors.isEmpty());
    System.assertEquals(1, gatewayResponse.errors.size());
    System.assertEquals(
      responseBody.result.errorMessage,
      gatewayResponse.errors[0]
    );

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
    System.assertEquals(
      responseBody.result.errorMessage,
      errorLogs[0].Error_Messages__c
    );
    System.assertEquals(null, errorLogs[0].HTTP_Request__c);
    System.assertEquals(null, errorLogs[0].HTTP_Response__c);
    System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
  }

  @isTest
  private static void processErrorResponseExpectedStructureTest() {
    String staticResourceName = 'PlatformErrorResponse';
    HttpResponse response = mockResponse(staticResourceName, false);
    ZDHCGatewayServiceResponse gatewayResponse = new ZDHCGatewayServiceResponse();
    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();
    ZDHCGatewayErrorResponse errorResponse = (ZDHCGatewayErrorResponse) JSON.deserializeStrict(
      ZDHCGatewayTestUtility.getStaticResourceContents(staticResourceName),
      ZDHCGatewayErrorResponse.class
    );
    Test.startTest();
    helper.processErrorResponse(response, gatewayResponse);
    helper.commitLog();
    Test.stopTest();

    System.assert(!gatewayResponse.isSuccess);
    System.assertEquals(0, gatewayResponse.errors.size());

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
    System.assertEquals(
      String.join(errorResponse.Errors, ', '),
      errorLogs[0].Error_Messages__c
    );
    System.assertEquals(null, errorLogs[0].HTTP_Request__c);
    System.assertEquals(null, errorLogs[0].HTTP_Response__c);
    System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
  }

  @isTest
  private static void processErrorResponseExpectedAltStructureTest() {
    String altJSON = '{"result" : { "errorMessage": "No results found."}}';
    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();
    HttpResponse response = new HttpResponse();
    response.setBody(altJSON);
    response.setStatusCode(500);
    ZDHCGatewayServiceResponse gatewayResponse = new ZDHCGatewayServiceResponse();

    Test.startTest();
    helper.processErrorResponse(response, gatewayResponse);
    helper.commitLog();
    Test.stopTest();

    System.assert(!gatewayResponse.isSuccess);
    System.assert(!gatewayResponse.errors.isEmpty());
    System.assertEquals(1, gatewayResponse.errors.size());
    System.assertEquals('No results found.', gatewayResponse.errors[0]);

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
    System.assertEquals(
      gatewayResponse.errors[0],
      errorLogs[0].Error_Messages__c
    );
    System.assertEquals(null, errorLogs[0].HTTP_Request__c);
    System.assertEquals(null, errorLogs[0].HTTP_Response__c);
    System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
  }

  @isTest
  private static void processErrorResponseUnExpectedStructureTest() {
    String unexpectedJSON = '[{"prop":[1,2,3,4]}]';
    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();
    HttpResponse response = new HttpResponse();
    response.setBody(unexpectedJSON);
    ZDHCGatewayServiceResponse gatewayResponse = new ZDHCGatewayServiceResponse();
    ZDHCGatewayUnexpectedResponse unexpectedResponse = new ZDHCGatewayUnexpectedResponse();
    unexpectedResponse.body = response.getBody();
    Test.startTest();
    helper.processErrorResponse(response, gatewayResponse);
    helper.commitLog();
    Test.stopTest();

    System.assert(!gatewayResponse.isSuccess);
    System.assertEquals(0, gatewayResponse.errors.size());
    System.assertEquals(
      (String) unexpectedResponse.body,
      (String) gatewayResponse.response.get('body')
    );

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
    System.assertEquals(
      Label.ZDHC_Unexpected_Response,
      errorLogs[0].Error_Messages__c
    );
    System.assertEquals(null, errorLogs[0].HTTP_Request__c);
    System.assertEquals(null, errorLogs[0].HTTP_Response__c);
    System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
  }

  @isTest
  private static void processResponseWithResponseBodyTest() {
    String staticResourceName = 'GetFormulatorsResponse';
    HttpResponse response = mockResponse(staticResourceName, true);
    ZDHC_Gateway_API__mdt apiMetadata = ZDHCGatewayTestUtility.getApiMetadata(
      'GET_formulators'
    );
    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();

    Test.startTest();
    ZDHCGatewayServiceResponse gatewayResponse = helper.processResponse(
      response,
      apiMetadata
    );
    helper.commitLog();
    Test.stopTest();

    System.assertNotEquals(null, gatewayResponse);
    System.assert(gatewayResponse.isSuccess);
    System.assertEquals(200, gatewayResponse.httpStatusCode);
    System.assertEquals('OK', gatewayResponse.httpStatus);
    System.assert(gatewayResponse.errors.isEmpty());
    System.assert(
      gatewayResponse.response instanceof ZDHCGetFormulatorsResponse
    );

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
  private static void processResponseWithoutResponseBodyTest() {
    String staticResourceName = 'PlatformErrorResponse';
    HttpResponse response = mockResponse(staticResourceName, false);
    ZDHCCalloutResponseHelper helper = new ZDHCCalloutResponseHelper();
    ZDHCGatewayErrorResponse errorResponse = (ZDHCGatewayErrorResponse) JSON.deserializeStrict(
      ZDHCGatewayTestUtility.getStaticResourceContents(staticResourceName),
      ZDHCGatewayErrorResponse.class
    );

    Test.startTest();
    ZDHCGatewayServiceResponse gatewayResponse = helper.processResponse(
      response,
      null
    );
    helper.commitLog();
    Test.stopTest();

    System.assertNotEquals(null, gatewayResponse);
    System.assert(!gatewayResponse.isSuccess);
    System.assertEquals(401, gatewayResponse.httpStatusCode);
    System.assertEquals('Unauthorized', gatewayResponse.httpStatus);
    System.assertEquals(0, gatewayResponse.errors.size());

    List<String> responseErrors = (List<String>) JSON.deserialize(
      JSON.serialize(gatewayResponse.response.get('Errors')),
      List<String>.class
    );

    System.assertEquals(errorResponse.Errors, responseErrors);

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
    System.assertEquals(
      String.join(errorResponse.Errors, ', '),
      errorLogs[0].Error_Messages__c
    );
    System.assertEquals(null, errorLogs[0].HTTP_Request__c);
    System.assertNotEquals(null, errorLogs[0].HTTP_Response__c);
    System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
  }
}