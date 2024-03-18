/**
 * schema for ZDHC POST/incheckReport API requests
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public with sharing class ZDHCPostInCheckReportRequest extends ZDHCGatewaySchema {
  public String OrganizationGUID; //required by the API

  public String version;

  public Integer month; //required by the API

  public Integer year; //required by the API

  public Integer type; //required by the API

  public List<ZDHCInCheckReportInventory> inventory; //required by the API
}