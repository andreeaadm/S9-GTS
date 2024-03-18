/**
 * response object for the POST/inCheckReport ZDHC API
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCPostInCheckReportResponse extends ZDHCGatewaySchema {
  @AuraEnabled
  public ZDHCGatewayResult result;

  @AuraEnabled
  public String incheckReport;

  @AuraEnabled
  public String verificationId;
}