/**
 * response object for the GET/products ZDHC API - ProductCertifications property
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCGetProductsResponseCertifications extends ZDHCGatewaySchema {
  @AuraEnabled
  public String certificationId;

  @AuraEnabled
  public String certification;

  @AuraEnabled
  public String certificationResult;
}