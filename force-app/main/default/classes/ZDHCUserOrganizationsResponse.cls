/**
 * response object for the GET/userOrganizations ZDHC API
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCUserOrganizationsResponse extends ZDHCGatewaySchema {
  @AuraEnabled
  public ZDHCGatewayResult result;

  @AuraEnabled
  public List<ZDHCUserOrganizationsResponseData> Organizations;
}