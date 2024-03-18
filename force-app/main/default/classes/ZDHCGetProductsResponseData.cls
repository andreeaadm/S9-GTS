/**
 * response object for the GET/products ZDHC API - data property
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCGetProductsResponseData extends ZDHCGatewaySchema {
  @AuraEnabled
  public String productName;

  @AuraEnabled
  public String OtherName;

  @AuraEnabled
  public String productGUID;

  @AuraEnabled
  public String formulatorName;

  @AuraEnabled
  public String OrganizationCountry;

  @AuraEnabled
  public String formulatorGUID;

  @AuraEnabled
  public String productCode;

  @AuraEnabled
  public String productOtherName;

  @AuraEnabled
  public String zdhcPID;

  @AuraEnabled
  public String zdhcAID;

  @AuraEnabled
  public String registered;

  @AuraEnabled
  public String ProductID;

  @AuraEnabled
  public List<ZDHCGetProductsResponseCertifications> ProductCertifications;

  @AuraEnabled
  public Datetime LastUpdatedDate;
}