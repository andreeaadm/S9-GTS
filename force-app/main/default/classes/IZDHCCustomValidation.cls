/**
 * contract for implementing complex request object validation
 * @author Kevin Reader (oe:gen)
 * @date December 2021
 */
public interface IZDHCCustomValidation {
  /**
   * validates the request object for the correct structure and mandatory properties
   * @param requestObj - abstract class for the request object schema
   */
  void validateRequestObject(ZDHCGatewaySchema requestObj);
}