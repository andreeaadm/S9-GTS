public without sharing class ZDHCErrorLog {
  public String OriginalRequest;

  public String HTTPRequest;

  public String HTTPResponse;

  public String ErrorMessages;

  public ZDHCErrorLog() {
  }

  public ZDHCErrorLog(ZDHCGatewayServiceRequest request) {
    this.OriginalRequest = JSON.serialize(request);
  }

  public void commitLog() {
    if (String.isNotBlank(ErrorMessages)) {
      ZDHC_Error_Log__c log = new ZDHC_Error_Log__c();
      log.Original_Request__c = this.OriginalRequest;
      log.HTTP_Request__c = this.HTTPRequest;
      log.HTTP_Response__c = this.HTTPResponse;
      log.Error_Messages__c = this.ErrorMessages;
      insert log;
    }
  }

  public void commitLog(List<ZDHC_Error_Log__c> logEntries) {
    if (String.isNotBlank(ErrorMessages)) {
      logEntries.add(
        new ZDHC_Error_Log__c(
          Original_Request__c = OriginalRequest,
          HTTP_Request__c = HTTPRequest,
          HTTP_Response__c = HTTPResponse,
          Error_Messages__c = ErrorMessages
        )
      );
    }
  }

  public void addHTTPRequest(HttpRequest req) {
    Map<String, String> reqMap = new Map<String, String>{
      'endpoint' => req.getEndpoint(),
      'method' => req.getMethod(),
      'body' => req.getBody(),
      'content-type' => req.getHeader('Content-Type')
    };

    this.HTTPRequest = JSON.serialize(reqMap);
  }

  public void addHTTPResponse(HttpResponse res) {
    Map<String, String> resMap = new Map<String, String>{
      'status' => res.getStatus(),
      'statusCode' => String.valueOf(res.getStatusCode()),
      'body' => res.getBody()
    };

    for (String key : res.getHeaderKeys()) {
      resMap.put(key, res.getHeader(key));
    }

    this.HTTPResponse = JSON.serialize(resMap);
  }
}