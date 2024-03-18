public without sharing class ZDHCGetProducts extends ZDHCGatewayService {
  private ZDHCGatewayServiceRequest request;
  private ZDHCGatewayServiceResponse gatewayResponse;
  public ZDHCGetProductsResponse response;

  /**
   * get errors (and clear)
   * Written especially for gathering errors elsewhere in a report, to not
   * repeat errors already read from this attribute.
   */
  public List<String> errors {
    get {
      List<String> v = new List<String>();
      if (gatewayResponse != null && gatewayResponse.errors != null) {
        v = gatewayResponse.errors;
        // The errors where taken so start afresh.
        gatewayResponse.errors = new List<String>();
      }
      return v; // Return errors gathered.
    }
    private set;
  }

  private Integer startIndex;
  private Integer recordLimit;
  private Long totalResults;

  /**
   * ZDHCGetProducts Construct with parameters for an iterable callout.
   * @param userAccessKey (String): The user access key to use.
   * @param queryParams (Map<String, Object>): The query parameters.
   * @param recordLimit (Integer): Record limit for iterating pages.
   */
  public ZDHCGetProducts(
    List<ZDHC_Error_Log__c> calloutLogEntries,
    String userAccessKey,
    Map<String, Object> queryParams,
    Integer recordLimit
  ) {
    super(calloutLogEntries);
    this.recordLimit = recordLimit;
    startIndex = 0;
    request = new ZDHCGatewayServiceRequest();
    request.apiName = 'products';
    request.method = 'GET';
    request.userAccessKey = userAccessKey;
    request.queryParams = queryParams;
    request.queryParams.put('recordLimit', recordLimit);
  }

  /**
   * ZDHCGetProducts Construct with parameters for a single callout.
   * @param userAccessKey (String): The user access key to use.
   * @param queryParams (Map<String, Object>): The query parameters.
   */
  public ZDHCGetProducts(
    List<ZDHC_Error_Log__c> calloutLogEntries,
    String userAccessKey,
    Map<String, Object> queryParams
  ) {
    super(calloutLogEntries);
    request = new ZDHCGatewayServiceRequest();
    request.apiName = 'products';
    request.method = 'GET';
    request.userAccessKey = userAccessKey;
    request.queryParams = queryParams;
  }

  /**
   * call Performs the callout.
   * @return Boolean: The callout was successful?
   */
  public Boolean call() {
    if (startIndex != null) {
      request.queryParams.put('startIndex', startIndex);
    }
    if (recordLimit != null) {
      request.queryParams.put('recordLimit', recordLimit);
    }
    gatewayResponse = callout(request);
    if (gatewayResponse.isSuccess) {
      response = (ZDHCGetProductsResponse) gatewayResponse.response;
      totalResults = response.totalResults;
      return true;
    }
    return false;
  }

  /**
   * next Failure aware iteration.
   */
  public void next() {
    if (gatewayResponse != null && !gatewayResponse.isSuccess) {
      startIndex = null;
    }
    if (startIndex != null && recordLimit != null) {
      startIndex += recordLimit;
    }
  }

  /**
   * isEnd
   * @return Boolean: is it the end?
   */
  public Boolean isEnd() {
    return startIndex == null || startIndex >= totalResults;
  }

  /**
   * mapByProductGUID Organise the ZDHC Gateway response by productGUID.
   * @return Map<String, ZDHCGetProductsResponseData>: productGUID keyed map.
   */
  public Map<String, ZDHCGetProductsResponseData> mapByProductGUID() {
    Map<String, ZDHCGetProductsResponseData> products = new Map<String, ZDHCGetProductsResponseData>();
    for (ZDHCGetProductsResponseData i : response.data) {
      products.put(i.productGUID, i);
    }
    return products;
  }
}