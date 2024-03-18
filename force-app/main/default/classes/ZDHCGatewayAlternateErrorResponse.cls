/**
 * alternate schema for error responses from the ZDHC API
 */
public class ZDHCGatewayAlternateErrorResponse extends ZDHCGatewaySchema {
  @AuraEnabled
  public ZDHCGatewayAlternateErrorResponseResult result;
}