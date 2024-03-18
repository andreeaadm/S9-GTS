/**
 * schema for making a request to a ZDHC Gateway API
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public with sharing class ZDHCGatewayServiceRequest {
  /**
   * name of the api endpoint at the ZDHC Gateway, e.g. inCheckReport
   */
  @AuraEnabled
  public String apiName { get; set; }

  /**
   * GET or POST
   */
  @AuraEnabled
  public String method { get; set; }

  /**
   * used to authenticate the user with ZDHC
   */
  @AuraEnabled
  public String userAccessKey { get; set; }

  /**
   * object containing key:value pairs (i.e. Map<String,Object>) to be included in a callout endpoint url
   */
  @AuraEnabled
  public Map<String, Object> queryParams { get; set; }

  /**
   * complex JSON objects can be accepted for endpoints requiring a message body, e.g. POST/formulators
   */
  @AuraEnabled
  public Object requestBody { get; set; }
}