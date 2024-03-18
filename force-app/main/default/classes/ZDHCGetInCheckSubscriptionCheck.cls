public without sharing class ZDHCGetInCheckSubscriptionCheck extends ZDHCGatewayService{
    private ZDHCGatewayServiceRequest request;
    private ZDHCGatewayServiceResponse gatewayResponse;
    public ZDHCSubscriptionStatusResponse response;
    
    public ZDHCGetInCheckSubscriptionCheck(
        List<ZDHC_Error_Log__c> calloutLogEntries,
        Id accountId,
        Map<String, Object> queryParams
    ) {
        super(calloutLogEntries);
        String userAccessKey = getUserAccessKey(accountId);
        request = new ZDHCGatewayServiceRequest();
        request.apiName = 'inCheckSubscriptionStatus';
        request.method = 'GET';
        request.userAccessKey = userAccessKey;
        request.queryParams = queryParams;
    }
    
    public Boolean call() {
    gatewayResponse = callout(request);
    if (gatewayResponse.isSuccess) {
      response = (ZDHCSubscriptionStatusResponse) gatewayResponse.response;
      return true;
    }
    return false;
  }
}