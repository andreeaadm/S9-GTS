/**
 * supports the ZDHC callout classes with utility methods for sending a request
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public with sharing class ZDHCCalloutRequestHelper {
  private ZDHCErrorLog errorLog;

  public ZDHCCalloutRequestHelper(ZDHCErrorLog errorLog) {
    this.errorLog = errorLog;
  }

  public ZDHCCalloutRequestHelper() {
    this.errorLog = new ZDHCErrorLog();
  }

  /**
   * manages the process for sending a request to one of the ZDHC Gateway endpoints
   * @param zdhcRequest - object containing properties needed to make an API request to the ZDHC Gateway
   * @param apiMetadata - custom metadata object containing configuration info for processing the request and response
   * @return response from the callout or exception if the callout failed
   */
  public HttpResponse sendRequest(
    ZDHCGatewayServiceRequest zdhcRequest,
    ZDHC_Gateway_API__mdt apiMetadata
  ) {
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    //check we have an access key
    validator.validateUserAccessKey(zdhcRequest.userAccessKey);
    //get any mandatory params if the api has them
    List<String> mandatoryParams = apiMetadata.Mandatory_Parameters__c != null
      ? apiMetadata.Mandatory_Parameters__c.split(',')
      : new List<String>();
    //validate the request data against expected configuration for the API
    validator.validateExpectedRequestData(
      zdhcRequest,
      apiMetadata,
      mandatoryParams
    );
    //build the request
    HttpRequest request = this.buildHttpRequest(zdhcRequest);
    this.errorLog.addHTTPRequest(request);

    //make the callout
    return this.sendHttpRequest(request);
  }

  /**
   * builds the HttpRequest object to make the callout to ZDHC
   * @param zdhcRequest - object containing properties needed to make an API request to the ZDHC Gateway
   * @return request object that will be sent to ZDHC
   */
  @TestVisible
  private HttpRequest buildHttpRequest(ZDHCGatewayServiceRequest zdhcRequest) {
    HttpRequest request = new HttpRequest();

    request.setEndpoint(
      (OrgUtil.isProduction()
        ? 'callout:Mulesoft_TC/'
        : 'callout:Mulesoft_TC_Sandbox/') +
      zdhcRequest.apiName +
      '?' +
      this.buildUrlParams(zdhcRequest)
    );
    request.setMethod(zdhcRequest.method);
    if (zdhcRequest.requestBody != null) {
      request.setBody(JSON.serialize(zdhcRequest.requestBody));
    }
    request.setHeader('client_id', '{!$Credential.Username}');
    request.setHeader('client_secret', '{!$Credential.Password}');
    if (
      zdhcRequest.method == 'POST' &&
      zdhcRequest.apiName != 'renewInCheckSubscription' &&
      zdhcRequest.apiName != 'activateInCheckSubscription' &&
      zdhcRequest.apiName != 'purchaseIncheckSubscription'
    ) {
      request.setHeader('Content-Type', 'application/json');
    }
    request.setTimeout(120000);
    return request;
  }

  /**
   * builds the query params portion of the endpoint url
   * @param zdhcRequest - object containing properties needed to make an API request to the ZDHC Gateway
   * @return query params portion of the endpoint url
   */
  @TestVisible
  private String buildUrlParams(ZDHCGatewayServiceRequest zdhcRequest) {
    String urlParams = 'UserAccessKey=' + zdhcRequest.userAccessKey;
    if (zdhcRequest.queryParams != null) {
      for (String param : zdhcRequest.queryParams.keySet()) {
        urlParams +=
          '&' +
          param +
          '=' +
          this.encodeUrlParam(zdhcRequest.queryParams.get(param));
      }
    }
    return urlParams;
  }

  /**
   * encodes any string param values to be url safe
   * @param param - the search value provided by the caller
   * @return a url encoded parameter
   */
  @TestVisible
  private Object encodeUrlParam(Object param) {
    if (param instanceof String) {
      return EncodingUtil.urlEncode((String) param, 'UTF-8');
    }
    return param;
  }

  /**
   * sends the Http request to the ZDHC API
   * @param request - object that will be sent to ZDHC
   * @return object containing result and response data from the callout
   */
  @TestVisible
  private HttpResponse sendHttpRequest(HttpRequest request) {
    try {
      return new Http().send(request);
    } catch (System.Exception ex) {
      throw new ZDHCGatewayServiceException(
        String.format(
          Label.ZDHC_Callout_Error,
          new List<String>{ ex.getMessage() }
        )
      );
    }
  }
}