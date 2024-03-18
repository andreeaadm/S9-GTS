/**
 * response object for the GET/userOrganizations ZDHC API - Organizations property
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCUserOrganizationsResponseData extends ZDHCGatewaySchema {
  @AuraEnabled
  public String Name;

  @AuraEnabled
  public String OrgGUID;

  @AuraEnabled
  public String SupplierAID;

  @AuraEnabled
  public String Type;
}