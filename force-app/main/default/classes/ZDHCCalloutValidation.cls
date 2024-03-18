/**
 * supports the ZDHC callout classes with centralised validation methods
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public with sharing class ZDHCCalloutValidation {
  /**
   * validates a user access key has been supplied - required for authentication
   * @param userAccessKey - used to authenticate the user with ZDHC
   */
  public void validateUserAccessKey(String userAccessKey) {
    if (String.isBlank(userAccessKey)) {
      throw new ZDHCGatewayServiceException(Label.ZDHC_No_Access_Key);
    }
  }

  /**
   * validates if the request has provided the expected request data needed to correctly call the API
   * @param zdhcRequest - object containing properties needed to make an API request to the ZDHC Gateway
   * @param apiMetadata - custom metadata object containing configuration info for processing the request and response
   * @param mandatoryParams - collection of param names that we're expecting to be included and have a value
   */
  public void validateExpectedRequestData(
    ZDHCGatewayServiceRequest zdhcRequest,
    ZDHC_Gateway_API__mdt apiMetadata,
    List<String> mandatoryParams
  ) {
    //do we have values on the properties we expected to have values?
    this.validateExpectedParams(zdhcRequest, apiMetadata);
    //now go and check what's been supplied is as expected
    if (apiMetadata.Expect_Query_Params__c) {
      //validate any query params if expected
      this.validateMandatoryQueryParams(
        zdhcRequest.queryParams,
        mandatoryParams
      );
    }
    if (apiMetadata.Expect_Request_Body__c) {
      //do rountrip serialisation due to Apex unable to cast the object directly - mistakes the datatype for Map<ANY,ANY>
      ZDHCGatewaySchema requestBody = (ZDHCGatewaySchema) JSON.deserializeStrict(
        JSON.serialize(zdhcRequest.requestBody),
        Type.forName(apiMetadata.Request_Object_Class_Name__c)
      );
      //validate a request body if expected
      if (apiMetadata.Use_Custom_Validation_Class__c) {
        //more complex nested object validation needed
        Type t = Type.forName(apiMetadata.Custom_Validation_Class_Name__c);
        IZDHCCustomValidation customValidator = (IZDHCCustomValidation) t.newInstance();
        customValidator.validateRequestObject(requestBody);
      } else {
        this.validateMandatoryRequestBodyParams(requestBody, mandatoryParams);
      }
    }
  }

  /**
   * validates that we have some values if we're expecting them in the request
   * @param zdhcRequest - object containing properties needed to make an API request to the ZDHC Gateway
   * @param apiMetadata - custom metadata object containing configuration info for processing the request and response
   * @param mandatoryParams - collection of param names that we're expecting to be included and have a value
   */
  @TestVisible
  private void validateExpectedParams(
    ZDHCGatewayServiceRequest zdhcRequest,
    ZDHC_Gateway_API__mdt apiMetadata
  ) {
    if (
      apiMetadata.Expect_Query_Params__c &&
      (zdhcRequest.queryParams == null || zdhcRequest.queryParams.isEmpty())
    ) {
      throw new ZDHCGatewayServiceException(Label.ZDHC_Missing_Expected_Params);
    }
    if (apiMetadata.Expect_Request_Body__c && zdhcRequest.requestBody == null) {
      throw new ZDHCGatewayServiceException(
        Label.ZDHC_Missing_Expected_Request_Body
      );
    }
  }

  /**
   * validates all mandatory params have been included and a value is provided - query params
   * @param params - key value pairs containing any params to include in the callout
   * @param mandatoryParams - collection of param names that we're expecting to be included and have a value
   */
  @TestVisible
  private void validateMandatoryQueryParams(
    Map<String, Object> params,
    List<String> mandatoryParams
  ) {
    if (mandatoryParams != null && mandatoryParams.size() > 0) {
      List<String> missingParams = new List<String>();
      for (String param : mandatoryParams) {
        if (!params.containsKey(param) || params.get(param) == null) {
          missingParams.add(param);
        }
      }
      this.handleMissingParams(missingParams);
    }
  }

  /**
   * validates all mandatory params have been included and a value is provided - request body
   * @param requestObj - schema object being
   * @param mandatoryParams - collection of param names that we're expecting to be included and have a value
   */
  public void validateMandatoryRequestBodyParams(
    ZDHCGatewaySchema requestObj,
    List<String> mandatoryParams
  ) {
    List<String> missingParams = new List<String>();
    if (mandatoryParams != null && mandatoryParams.size() > 0) {
      for (String param : mandatoryParams) {
        param = param.trim();
        String value = String.valueOf(requestObj.get(param));
        if (String.isBlank(value)) {
          missingParams.add(param);
        }
      }
      this.handleMissingParams(missingParams);
    }
  }

  /**
   * throws an exception if there are any missing or null mandatory params
   * @param missingParams - array of missing param names
   */
  @TestVisible
  private void handleMissingParams(List<String> missingParams) {
    if (!missingParams.isEmpty()) {
      throw new ZDHCGatewayServiceException(
        String.format(
          Label.ZDHC_Missing_Required_Params,
          new List<String>{ String.join(missingParams, ', ') }
        )
      );
    }
  }
}