/**
 * schema for returning a response from the ZDHC Gateway API Service
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public class ZDHCGatewayServiceResponse {
  /**
   * true if the API callout was a success and a 2xx response is received
   */
  @AuraEnabled
  public Boolean isSuccess;

  /**
   * http status code received from the ZDHC Gateway
   */
  @AuraEnabled
  public Integer httpStatusCode;

  /**
   * http status received from the ZDHC Gateway
   */
  @AuraEnabled
  public String httpStatus;

  /**
   * error messages caught at any point in the processing of the request or response
   */
  @AuraEnabled
  public List<String> errors;

  /**
   * response object from the ZDHC Gateway API
   */
  @AuraEnabled
  public ZDHCGatewaySchema response;

  /**
   * class constructor
   */
  public ZDHCGatewayServiceResponse() {
    this.errors = new List<String>();
  }
}