/**
 * schema for error responses from the ZDHC API
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCGatewayErrorResponse extends ZDHCGatewaySchema {
  @AuraEnabled
  public List<String> Errors;

  @AuraEnabled
  public Integer StatusCode;
}