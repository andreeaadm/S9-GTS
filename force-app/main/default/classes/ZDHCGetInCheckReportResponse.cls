/**
 * response object for the GET/inCheckReport ZDHC API
 * @author Kevin Reader (oe:gen)
 * @date December 2021
 */
public class ZDHCGetInCheckReportResponse extends ZDHCGatewaySchema {
  @AuraEnabled
  public ZDHCGatewayResult result;

  @AuraEnabled
  public String incheckReportId;

  @AuraEnabled
  public String incheckReport;
}