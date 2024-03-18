/**
 * response object for the GET/formulators ZDHC API
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCGetFormulatorsResponse extends ZDHCGatewaySchema {
  @AuraEnabled
  public ZDHCGatewayResult result;

  @AuraEnabled
  public List<ZDHCGetFormulatorsResponseData> data;

  @AuraEnabled
  public Long totalResults;
}