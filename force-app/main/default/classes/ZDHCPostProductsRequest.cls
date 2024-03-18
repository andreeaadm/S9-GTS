/**
 * schema for ZDHC POST/products API requests
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public with sharing class ZDHCPostProductsRequest extends ZDHCGatewaySchema {
  public String name; //required by the API

  public String formulatorGUID; //required by the API

  public String description;

  public String substrate;

  public String category;

  public String type;

  public String otherName;

  public String productCode;

  public String version;

  public String sdsStandard;

  public String language;

  public String effectiveDate;

  public String filename;

  public String content;

  public String uploadedByText;
}