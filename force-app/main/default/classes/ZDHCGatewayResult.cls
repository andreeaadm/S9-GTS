/**
 * schema for the result object returned as part of a ZDHC API response
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCGatewayResult {
  @AuraEnabled
  public Boolean success;

  @AuraEnabled
  public String errorMessage;
    
  @AuraEnabled
  public String Message;
}