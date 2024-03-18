/**
 * schema for returning a response from the ZDHC Gateway API Service that has an unexpected structure
 * @author Kevin Reader (oe:gen)
 * @date December 2021
 */
public class ZDHCGatewayUnexpectedResponse extends ZDHCGatewaySchema {
  @AuraEnabled
  public Object body;
}