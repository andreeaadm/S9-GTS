/**
 * response object for the GET/subscriptionStatus ZDHC API
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCSubscriptionStatusResponse extends ZDHCGatewaySchema {
  @AuraEnabled
  public ZDHCGatewayResult result;

  @AuraEnabled
  public List<ZDHCSubscriptionStatusResponseData> SubscriptionStatus;
  
  @AuraEnabled
  public String InCheckStatus;
    
  @AuraEnabled
  public String OrganisationAID;

  @AuraEnabled
  public Date InCheckExpirationDate;
    
  @AuraEnabled
  public Date InCheckStartDate;
}