/**
 * custom validation class for POST/incheckReport ZDHC Gateway API
 * @author Kevin Reader (oe:gen)
 * @date December 2021
 */
public with sharing class ZDHCPostInCheckReportRequestValidation implements IZDHCCustomValidation {
  /**
   * validates the request object for the correct structure and mandatory properties
   * @param requestObj - interface for the request object schema
   */
  public void validateRequestObject(ZDHCGatewaySchema requestObj) {
    ZDHCPostInCheckReportRequest incheckRequest = (ZDHCPostInCheckReportRequest) requestObj;
    ZDHCCalloutValidation validator = new ZDHCCalloutValidation();
    //validate outer object params
    validator.validateMandatoryRequestBodyParams(
      incheckRequest,
      new List<String>{
        'OrganizationGUID',
        'month',
        'year',
        'type',
        'inventory'
      }
    );
    //validate inner object params
    if (
      incheckRequest.inventory == null || incheckRequest.inventory.isEmpty()
    ) {
      throw new ZDHCGatewayServiceException(
        String.format(
          Label.ZDHC_Missing_Required_Params,
          new List<String>{ 'inventory' }
        )
      );
    }
    for (ZDHCInCheckReportInventory invLine : incheckRequest.inventory) {
      validator.validateMandatoryRequestBodyParams(
        invLine,
        new List<String>{ 'productGUID', 'weight', 'unit' }
      );
    }
  }
}