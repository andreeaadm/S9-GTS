/**
 * response object for the GET/subscriptionStatus ZDHC API - SubscriptionStatus property
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCSubscriptionStatusResponseData extends ZDHCGatewaySchema {
  @AuraEnabled
  public String OrganizationName;

  @AuraEnabled
  public String OrganizationGUID;

  @AuraEnabled
  public String InCheckStatus;

  @AuraEnabled
  public String ReportingStatus;

  @AuraEnabled
  public Date InCheckExpirationDate;
}