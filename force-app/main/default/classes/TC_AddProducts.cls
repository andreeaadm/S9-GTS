/**
 * handles a UI request to search for Chemical Products
 * @author Kevin Reader (oe:gen)
 * @date January 2022
 */
public with sharing class TC_AddProducts {
  /**
   * searches for Chemical Products against ZDHC and the Intertek Salesforce database
   * @param userAccessKey - access key required to authenticate with ZDHC
   * @param queryParams - key value pairs of query params that can be sent to ZDHC to filter the search results
   * @return object containing request status and combined product results
   */
  @AuraEnabled
  public static TC_AddProductsResponse searchProducts(
    String userAccessKey,
    Map<String, Object> queryParams
  ) {
    queryParams.put('recordLimit', 1000);
    TC_AddProductsResponse response = new TC_AddProductsResponse();
    TC_AddProductsCallout callout = new TC_AddProductsCallout();
    //search ZDHC
    ZDHCGatewayServiceResponse zdhcResponse = callout.callZdhc(
      userAccessKey,
      queryParams
    );
    if (callout.haveSuccessfulResponse(zdhcResponse)) {
      //process the response against the Salesforce chemical product database
      ZDHCGetProductsResponse getProductsResponse = (ZDHCGetProductsResponse) zdhcResponse.response;
      TC_MergeZdhcAndMasterChemicals mergeData = new TC_MergeZdhcAndMasterChemicals();
      response.combinedProducts = mergeData.mergeProductData(
        getProductsResponse.data,
        true
      );
      response.isSuccess = true;
      response.combinedProducts.sort();
    } else
      response.errors = zdhcResponse.errors;
    return response;
  }
}