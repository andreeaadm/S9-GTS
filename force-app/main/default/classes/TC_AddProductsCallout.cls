/**
 * manages the callout via the ZDHC Gateway service for the AddProducts UI
 * @author Kevin Reader (oe:gen)
 * @date January 2022
 */
public with sharing class TC_AddProductsCallout {
  /**
   * calls the ZDHC gateway service to get results from their API
   * @param userAccessKey - access key required to authenticate with ZDHC
   * @param queryParams - key value pairs of query params that can be sent to ZDHC to filter the search results
   * @return response object from the gateway service
   */
  public ZDHCGatewayServiceResponse callZdhc(
    String userAccessKey,
    Map<String, Object> queryParams
  ) {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'products';
    zdhcRequest.method = 'GET';
    zdhcRequest.userAccessKey = userAccessKey;
    zdhcRequest.queryParams = queryParams;
    return ZDHCGatewayService.makeCallout(zdhcRequest);
  }

  /**
   * checks if we've received a successfully response from Zdhc before attempting data processing
   * @param response - object returned from the gateway service
   * @return true if the servicxe and Zdhc returned a success response, otherwise false
   */
  public Boolean haveSuccessfulResponse(ZDHCGatewayServiceResponse response) {
    if (response.isSuccess && response.response != null) {
      try {
        ZDHCGetProductsResponse zdhcResponse = (ZDHCGetProductsResponse) response.response;
        return zdhcResponse.result.success;
      } catch (System.Exception ex) {
        //hits here if unexpected response type (typically an error)
        //do nothing - picked up in caller
      }
    }
    return false;
  }
}