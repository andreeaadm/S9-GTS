/**
 * service class used by other Salesforce artefacts to access the ZDHC Gateway APIs
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public without sharing virtual class ZDHCGatewayService {
  private List<ZDHC_Error_Log__c> calloutLogEntries;

  public ZDHCGatewayService() {
    calloutLogEntries = new List<ZDHC_Error_Log__c>();
  }

  public ZDHCGatewayService(List<ZDHC_Error_Log__c> calloutLogEntries) {
    this.calloutLogEntries = calloutLogEntries;
  }

  /**
   * gets the ZDHC UserAccessKey value from a User record that is associated to the Facility Contact
   * @param recordId - record Id of either the Facility Manager Contact or an Experience Cloud User
   * @return UserAccessKey value from the linked User sObject
   */
  @AuraEnabled(cacheable=true)
  public static String getUserAccessKey(Id recordId) {
    if (recordId == null)
      return null;
    String objectName = recordId.getSobjectType().getDescribe().getName();
    String queryStr = String.format(
      'SELECT ZDHC_User_Access_Key__c FROM User WHERE {0} = {1} LIMIT 1',
      new List<String>{
        objectName == 'User' ? 'Id' : 'ContactId',
        '\'' +
        recordId +
        '\''
      }
    );
    try {
      SObject record = Database.query(queryStr);
      return (String) record.get('ZDHC_User_Access_Key__c');
    } catch (System.Exception ex) {
      //no user found for the supplied contact
      throw new ZDHCGatewayServiceException(Label.ZDHC_No_User_Found);
    }
  }

  /**
   * entry point to the ZDHC Gateway APIs for UI components (Aura / LWC) and other apex classes
   * @param zdhcRequest - object containing properties needed to make an API request to the ZDHC Gateway
   * @return ZDHC Gateway Service response containing an endpoint specific response object
   */
  @AuraEnabled
  public static ZDHCGatewayServiceResponse makeCallout(
    ZDHCGatewayServiceRequest zdhcRequest
  ) {
    List<ZDHC_Error_Log__c> calloutLogEntries = new List<ZDHC_Error_Log__c>();
    ZDHCGatewayService service = new ZDHCGatewayService(calloutLogEntries);
    ZDHCGatewayServiceResponse response = service.callout(zdhcRequest);
    try {
      if (calloutLogEntries.size() > 0) {
        insert calloutLogEntries;
      }
    } catch (System.Exception ex) {
      // There's already a response, failure to insert log entries is not as important.
    }
    return response;
  }

  public ZDHCGatewayServiceResponse callout(
    ZDHCGatewayServiceRequest zdhcRequest
  ) {
    ZDHCGatewayServiceResponse serviceResponse;
    //get original request into a log object in case there are errors
    ZDHCErrorLog errorLog = new ZDHCErrorLog(zdhcRequest);

    //wrapping try catch to ensure consistent response to the client
    try {
      //get the metadata for the API in the request
      ZDHC_Gateway_API__mdt apiMetadata = getApiMetadata(zdhcRequest);
      if (apiMetadata != null) {
        //metadata found - process the request
        ZDHCCalloutRequestHelper requestHelper = new ZDHCCalloutRequestHelper(
          errorLog
        );

        HttpResponse response = requestHelper.sendRequest(
          zdhcRequest,
          apiMetadata
        );
        //process the response and return to the client
        ZDHCCalloutResponseHelper responseHelper = new ZDHCCalloutResponseHelper(
          errorLog
        );
        serviceResponse = responseHelper.processResponse(response, apiMetadata);
      } else {
        throw new ZDHCGatewayServiceException(Label.ZDHC_No_Callout_Class);
      }
    } catch (System.Exception ex) {
      System.debug(ex.getStackTraceString());
      serviceResponse = handleException(ex, errorLog);
    }
    errorLog.commitLog(calloutLogEntries);
    return serviceResponse;
  }

  /**
   * gets callout metadata settings
   * @param zdhcRequest - object containing properties needed to make an API request to the ZDHC Gateway
   * @return custom metadata object containing configuration info for processing the request and response
   */
  @TestVisible
  private static ZDHC_Gateway_API__mdt getApiMetadata(
    ZDHCGatewayServiceRequest zdhcRequest
  ) {
    List<ZDHC_Gateway_API__mdt> apis = ZDHC_Gateway_API__mdt.getAll().values();
    for (ZDHC_Gateway_API__mdt mdt : apis) {
      if (
        mdt.Http_Method__c.toUpperCase() == zdhcRequest.method.toUpperCase() &&
        mdt.Endpoint_Name__c.toUpperCase() == zdhcRequest.apiName.toUpperCase()
      ) {
        return mdt;
      }
    }
    return null;
  }

  /**
   * updates Account with new subscription date
   * @param recordId - Account that needs updating
   * @param dateString - String value containing the update date (will be given in format MM-DD-YYYY)
   * @return String value of either "success" or "error - [error message]" depending on result of update
   */

  @AuraEnabled
  public static String updateInCheckSubscriptionDate(
    String recordId,
    String dateString
  ) {
    try {
      Account accToUpdate = [
        SELECT Id, InCheck_Subscription_Expiration_Date__c
        FROM Account
        WHERE Id = :recordId
      ];
      List<String> dateParts = dateString.split('-');
      Date dateObject = Date.newInstance(
        Integer.valueOf(dateParts[0]),
        Integer.valueOf(dateParts[1]),
        Integer.valueOf(dateParts[2])
      );
      accToUpdate.Incheck_Subscription_Expiration_Date__c = dateObject;
      update accToUpdate;
      return 'success';
    } catch (System.QueryException e) {
      // Typically; 'List has no rows for assignment to SObject'
      throw new AuraHandledException('error - No Account found');
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * handles a thrown or unexpected exception during the process
   * @param ex - object containing the exception details
   * @return ZDHC Gateway Service response containing exception details
   */
  @TestVisible
  private static ZDHCGatewayServiceResponse handleException(
    System.Exception ex,
    ZDHCErrorLog errorLog
  ) {
    ZDHCGatewayServiceResponse response = new ZDHCGatewayServiceResponse();
    response.isSuccess = false;
    response.errors.add(ex.getMessage());

    errorLog.ErrorMessages = ex.getMessage();

    return response;
  }
}