/**
 * response object for the GET/products ZDHC API
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCGetProductsResponse extends ZDHCGatewaySchema {
  @AuraEnabled
  public ZDHCGatewayResult result;

  @AuraEnabled
  public List<ZDHCGetProductsResponseData> data;

  @AuraEnabled
  public Long totalResults;
}