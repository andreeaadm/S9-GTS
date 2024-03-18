/**
 * response object for the GET/formulators ZDHC API - data property
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCGetFormulatorsResponseData extends ZDHCGatewaySchema {
  @AuraEnabled
  public Integer totalCount;

  @AuraEnabled
  public String organizationName;

  @AuraEnabled
  public String address;

  @AuraEnabled
  public String formulatorGUID;

  @AuraEnabled
  public String supplierAID;
}