/**
 * schema for ZDHC POST/incheckReport API requests - inventory property
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public with sharing class ZDHCInCheckReportInventory extends ZDHCGatewaySchema {
  public String productGUID; //required by the API

  public Decimal weight; //required by the API

  public String unit; //required by the API

  public String commodityName; // Optional CR-12-01 IT-1560
}