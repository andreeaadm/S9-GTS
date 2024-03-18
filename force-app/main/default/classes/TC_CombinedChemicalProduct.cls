/******************************************************************************
Created Date: January 2022
@description: schema for combined ZDHC product and Chemical_Product__c data
@test class: TC_CombinedChemicalProductIntertekTest,TC_CombinedChemicalProductZdhcTest,TC_CombinedChemicalProdCrowdsourcedTest
@author: Kevin Reader (oe:gen)
Modification History:
Ver			Date			Author			Modification
1.0         Nov 2023		Akshay			Added sorting for Inditex products(INC00669339)
******************************************************************************/

public with sharing class TC_CombinedChemicalProduct implements Comparable {
  @AuraEnabled
  public Chemical_Product__c salesforceProduct;

  @AuraEnabled
  public ZDHCGetProductsResponseData zdhcProductData;

  @AuraEnabled
  public String productCategory;

  @AuraEnabled
  public String mrsl2Level;
  
  @AuraEnabled
  public String mrsl3Level;

  @AuraEnabled
  public String otherCertifications;
    
/******************************************************************************
Created Date: January 2022
@description: handles custom sorting of the data by product category
@author: Kevin Reader (oe:gen)
@param: productToCompare - another product in the list to compare to
@return: integer used to determine position in the list
Modification History:
Ver			Date			Author			Modification
1.0         Nov 2023		Akshay			Added sorting for Inditex products(INC00669339)
******************************************************************************/

  public Integer compareTo(Object productToCompareObj) {
    Map<String, Integer> productCategoryOrder = new Map<String, Integer>{
        'zdhcgw' => 0,
            'inditexzdhc' => 1,
            'inditex' => 2,
            'intertek' => 3,
            'crowdsourced' => 4
    };
    TC_CombinedChemicalProduct productToCompare = (TC_CombinedChemicalProduct) productToCompareObj;
    Integer returnValue = 0;
    if (
      productCategoryOrder.get(productCategory) <
      productCategoryOrder.get(productToCompare.productCategory)
    ) {
      returnValue = -1;
    } else if (
      productCategoryOrder.get(productCategory) >
      productCategoryOrder.get(productToCompare.productCategory)
    ) {
      returnValue = 1;
    }
    return returnValue;
  }
}