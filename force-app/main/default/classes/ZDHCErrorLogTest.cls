@isTest
public with sharing class ZDHCErrorLogTest {
  @isTest
  static void constructFromRequest() {
    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    request.userAccessKey = '123456';
    request.queryParams = new Map<String, Object>{
      'param1' => 'test param',
      'param2' => 100
    };
    request.apiName = 'incheckReport';
    request.method = 'POST';

    ZDHCErrorLog log = new ZDHCErrorLog(request);

    System.assertEquals(null, log.HTTPRequest);
    System.assertEquals(null, log.HTTPResponse);
    System.assertEquals(null, log.ErrorMessages);
    System.assertEquals(JSON.serialize(request), log.OriginalRequest);
  }

  @isTest
  static void addHttpRequest() {
    HttpRequest httpReq = new HttpRequest();
    httpReq.setBody('myTestBody');
    httpReq.setMethod('GET');
    httpReq.setEndpoint('myTestEndpoint');

    ZDHCErrorLog log = new ZDHCErrorLog();
    log.addHTTPRequest(httpReq);
    Map<String, String> reqMap = (Map<String, String>) JSON.deserializeStrict(
      log.HTTPRequest,
      Map<String, String>.class
    );

    System.assertEquals(4, reqMap.keySet().size());
    System.assertEquals('myTestBody', reqMap.get('body'));
    System.assertEquals('GET', reqMap.get('method'));
    System.assertEquals('myTestEndpoint', reqMap.get('endpoint'));
    System.assertEquals(null, reqMap.get('content-type'));
    System.assertEquals(null, log.HTTPResponse);
    System.assertEquals(null, log.ErrorMessages);
    System.assertEquals(null, log.OriginalRequest);
  }

  @isTest
  static void addHttpResponse() {
    HttpResponse httpRes = new HttpResponse();
    httpRes.setBody('myTestBody');
    httpRes.setStatus('myTestStatus');
    httpRes.setStatusCode(404);
    httpRes.setHeader('testKey1', 'testValue1');
    httpRes.setHeader('testKey2', 'testValue2');

    ZDHCErrorLog log = new ZDHCErrorLog();
    log.addHTTPResponse(httpRes);
    Map<String, String> resMap = (Map<String, String>) JSON.deserializeStrict(
      log.HTTPResponse,
      Map<String, String>.class
    );

    System.assertEquals(5, resMap.keySet().size());
    System.assertEquals('myTestBody', resMap.get('body'));
    System.assertEquals('myTestStatus', resMap.get('status'));
    System.assertEquals('404', resMap.get('statusCode'));
    System.assertEquals('testValue1', resMap.get('testKey1'));
    System.assertEquals('testValue2', resMap.get('testKey2'));
    System.assertEquals(null, log.HTTPRequest);
    System.assertEquals(null, log.ErrorMessages);
    System.assertEquals(null, log.OriginalRequest);
  }

  @isTest
  static void buildAndCommitLog() {
    HttpResponse httpRes = new HttpResponse();
    httpRes.setStatus('myTestStatus');

    HttpRequest httpReq = new HttpRequest();
    httpReq.setBody('myTestBody');

    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    request.userAccessKey = '123456';

    ZDHCErrorLog log = new ZDHCErrorLog(request);
    log.addHTTPResponse(httpRes);
    log.addHTTPRequest(httpReq);
    log.ErrorMessages = 'Message';
    log.commitLog();

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
    System.assertEquals('Message', errorLogs[0].Error_Messages__c);
    System.assertEquals(
      'myTestBody',
      ((Map<String, String>) JSON.deserializeStrict(
          errorLogs[0].HTTP_Request__c,
          Map<String, String>.class
        ))
        .get('body')
    );
    System.assertEquals(
      'myTestStatus',
      ((Map<String, String>) JSON.deserializeStrict(
          errorLogs[0].HTTP_Response__c,
          Map<String, String>.class
        ))
        .get('status')
    );
    System.assertEquals(
      '123456',
      ((Map<String, String>) JSON.deserializeStrict(
          errorLogs[0].Original_Request__c,
          Map<String, String>.class
        ))
        .get('userAccessKey')
    );
    System.assertEquals(Date.today(), errorLogs[0].Timestamp__c.date());
  }
}