/**
 * schema for ZDHC POST/formulators API requests
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public with sharing class ZDHCPostFormulatorRequest extends ZDHCGatewaySchema {
  public String name; //required by the API

  public String phone;

  public String address;

  public String cityTown;

  public String stateProvince;

  public String country; //required by the API

  public String postalCode;

  public String contactName;

  public String contactEmail;

  public String higgID;
}