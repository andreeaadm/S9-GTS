/**
 * response object for the POST/formulators ZDHC API
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCPostFormulatorsResponse extends ZDHCGatewaySchema {
  @AuraEnabled
  public ZDHCGatewayResult result;

  @AuraEnabled
  public String formulatorGUID;
}