/**
 * response schema for when the UI requests product data from ZDHC
 * @author Kevin Reader (oe:gen)
 * @date January 2022
 */
public with sharing class TC_AddProductsResponse {
  @AuraEnabled
  public Boolean isSuccess;

  @AuraEnabled
  public List<String> errors;

  @AuraEnabled
  public List<TC_CombinedChemicalProduct> combinedProducts;
}