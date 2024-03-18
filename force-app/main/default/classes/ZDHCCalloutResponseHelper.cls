/**
 * supports the ZDHC callout classes with utility methods for processing a response
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public with sharing virtual class ZDHCCalloutResponseHelper {
  private ZDHCErrorLog errorLog;

  public ZDHCCalloutResponseHelper(ZDHCErrorLog errorLog) {
    this.errorLog = errorLog;
  }

  public ZDHCCalloutResponseHelper() {
    this.errorLog = new ZDHCErrorLog();
  }

  public void commitLog() {
    errorLog.commitLog();
  }

  public void commitLog(List<ZDHC_Error_Log__c> calloutLogEntries) {
    errorLog.commitLog(calloutLogEntries);
  }

  /**
   * processes the response from the API against the spec and business rules
   * @param response - object containing the result and response data from the callout
   * @param apiMetadata - custom metadata object containing configuration info for processing the request and response
   * @return ZDHC Gateway Service response containing an endpoint specific response object
   */
  public ZDHCGatewayServiceResponse processResponse(
    HttpResponse response,
    ZDHC_Gateway_API__mdt apiMetadata
  ) {
    this.errorLog.addHTTPResponse(response);
    ZDHCGatewayServiceResponse gatewayResponse = new ZDHCGatewayServiceResponse();
    //first deserialise the response body into an apex object for processing
    ZDHCGatewaySchema responseBody = this.castResponseObject(
      response,
      apiMetadata
    );
    //set default status values
    this.setHttpStatus(response, gatewayResponse);
    if (responseBody != null) {
      //successfully deserialised to the expected response structure
      this.processExpectedResponse(response, gatewayResponse, responseBody, apiMetadata);
    } else {
      //didn't receive the expected response from the API
      this.processErrorResponse(response, gatewayResponse);
    }
    return gatewayResponse;
  }

  @TestVisible
  private ZDHCGatewaySchema castResponseObject(
    HttpResponse response,
    ZDHC_Gateway_API__mdt apiMetadata
  ) {
    try {
      //cast the response object to the expected schema as set in the custom metadata record
      return (ZDHCGatewaySchema) JSON.deserializeStrict(
        response.getBody(),
        Type.forName(apiMetadata.Response_Object_Class_Name__c)
      );
    } catch (System.Exception ex) {
      return null; //no action - this will be managed further down the process
    }
  }

  /**
   * sets the response properties relating to the Http status
   * @param response - object containing the result and response data from the callout
   * @param gatewayResponse - ZDHC Gateway Service response containing an endpoint specific response object
   */
  @TestVisible
  private void setHttpStatus(
    HttpResponse response,
    ZDHCGatewayServiceResponse gatewayResponse
  ) {
    gatewayResponse.httpStatusCode = response.getStatusCode();
    gatewayResponse.httpStatus = response.getStatus();
  }

  /**
   * processes the api response in line with the expected response object structure
   * @param response - object containing the result and response data from the callout
   * @param gatewayResponse - ZDHC Gateway Service response containing an endpoint specific response object
   * @param responseBody - deserialized response body
   */
  @TestVisible
  private void processExpectedResponse(
    HttpResponse response,
    ZDHCGatewayServiceResponse gatewayResponse,
    ZDHCGatewaySchema responseBody,
    ZDHC_Gateway_API__mdt apiMetadata
  ) {
    //long way around to get to ZDHCGatewayResult object due to invalid conversion at runtime error
    String resultJSON = JSON.serialize(responseBody.get('result'));
    ZDHCGatewayResult calloutResult = (ZDHCGatewayResult) JSON.deserializeStrict(
      resultJSON,
      ZDHCGatewayResult.class
    );
    gatewayResponse.isSuccess = calloutResult.success != null
      ? calloutResult.success
      : false;
    if (!gatewayResponse.isSuccess) {
        if(apiMetadata.Endpoint_Name__c == 'incheckReport' ||
           apiMetadata.Endpoint_Name__c == 'renewInCheckSubscription' ||
           apiMetadata.Endpoint_Name__c == 'purchaseInCheckSubscription' ||
           apiMetadata.Endpoint_Name__c == 'inCheckSubscriptionStatus' 
          ){
            gatewayResponse.errors.add(calloutResult.Message);
            this.errorLog.ErrorMessages = calloutResult.Message;  
        }
        else {
            gatewayResponse.errors.add(calloutResult.errorMessage);
            this.errorLog.ErrorMessages = calloutResult.errorMessage;
        }
    }
    gatewayResponse.response = responseBody;
  }

  /**
   * processes the api response as an error - used if deserializing to the expected object type wasn't successful
   * @param response - object containing the result and response data from the callout
   * @param gatewayResponse - ZDHC Gateway Service response containing an endpoint specific response object
   */
  @TestVisible
  private void processErrorResponse(
    HttpResponse response,
    ZDHCGatewayServiceResponse gatewayResponse
  ) {
    //if failed then attempt to cast to the known error response format
    gatewayResponse.isSuccess = false;

    //strip out escape characters from the response
    String bodyString = response.getBody().replace('\"', '"');
    try {
      ZDHCGatewayErrorResponse errorResponse = (ZDHCGatewayErrorResponse) JSON.deserializeStrict(
        bodyString,
        ZDHCGatewayErrorResponse.class
      );

      if (response.getStatusCode() == 500) {
        gatewayResponse.errors = errorResponse.Errors;
      }
      gatewayResponse.response = errorResponse;

      this.errorLog.ErrorMessages = String.join(errorResponse.Errors, ', ');
    } catch (System.Exception e) {
      try {
        ZDHCGatewayAlternateErrorResponse errorResponse = (ZDHCGatewayAlternateErrorResponse) JSON.deserializeStrict(
          bodyString,
          ZDHCGatewayAlternateErrorResponse.class
        );

        if (response.getStatusCode() == 500) {
          gatewayResponse.errors.add(errorResponse.result.errorMessage);
        }
        gatewayResponse.response = errorResponse;

        this.errorLog.ErrorMessages = errorResponse.result.errorMessage;
      } catch (System.Exception ex) {
        //if it fails again then it's an unknown response type
        ZDHCGatewayUnexpectedResponse unexpectedResponse = new ZDHCGatewayUnexpectedResponse();
        unexpectedResponse.body = bodyString;
        gatewayResponse.response = unexpectedResponse;

        this.errorLog.ErrorMessages = Label.ZDHC_Unexpected_Response;
      }
    }
  }
}