/**
 * matches ZDHC Get Products responce data with the master checmical list (Chemical_Product__c sObject)
 * @author Kevin Reader (oe:gen)
 * @date January 2022
 */
public with sharing class TC_MergeZdhcAndMasterChemicals {
  /**
   * merges the supplied ZDHC product data with the Salesforce master chemical list
   * @param zdhcProducts - collection of product objects returned from the ZDHC Gateway API
   * @param setProductCategory - optionally determine the product category to show in a UI component
   * @return collection of objects containing data from ZDHC and Salesforce
   */
  public List<TC_CombinedChemicalProduct> mergeProductData(
    List<ZDHCGetProductsResponseData> zdhcProducts,
    Boolean setProductCategory
  ) {
    Map<String, ZDHCGetProductsResponseData> zdhcProductsMap = this.buildProductsMap(
      zdhcProducts
    );
    Map<String, Chemical_Product__c> salesforceProductsMap = this.getChemicalProductsMap(
      zdhcProductsMap.keySet()
    );
    return this.combineData(
      zdhcProductsMap,
      salesforceProductsMap,
      setProductCategory
    );
  }

  /**
   * builds a map of the supplied products for easier processing
   * @param zdhcProducts - collection of product objects returned from the ZDHC Gateway API
   * @return key value pair collection of productGUID and zdhc product object
   */
  @TestVisible
  private Map<String, ZDHCGetProductsResponseData> buildProductsMap(
    List<ZDHCGetProductsResponseData> zdhcProducts
  ) {
    Map<String, ZDHCGetProductsResponseData> zdhcProductsMap = new Map<String, ZDHCGetProductsResponseData>();
    for (ZDHCGetProductsResponseData product : zdhcProducts) {
      zdhcProductsMap.put(product.productGUID, product);
    }
    return zdhcProductsMap;
  }

  /**
   * gets the 'master chemical list' from Salesforce and organises for further processing
   * @param productGuids - collection of unique product identifiers used to find records in Salesforce
   * @return key value pair of ZDHC product GUID and an sObject that matches the ZDHC data
   */
  @TestVisible
  private Map<String, Chemical_Product__c> getChemicalProductsMap(
    Set<String> productGuids
  ) {
    Map<String, Chemical_Product__c> salesforceProductsMap = new Map<String, Chemical_Product__c>();
    for (Chemical_Product__c product : this.getChemicalProducts(productGuids)) {
      salesforceProductsMap.put(product.ZDHC_Product_GUID__c, product);
    }
    return salesforceProductsMap;
  }

  /**
   * gets the 'master chemical list' from Salesforce
   * @param productGuids - collection of unique product identifiers used to find records in Salesforce
   * @return collection of sObjects that match the ZDHC data
   */
  @TestVisible
  private List<Chemical_Product__c> getChemicalProducts(
    Set<String> productGuids
  ) {
    return [
      SELECT Origin__c, ZDHC_Product_GUID__c, Substrate__c, Conformant__c, Commodity_Chemical_Standard_Name__c,
        Inditex_Classification_for_Babies__c,Inditex_Classification_for_Child_Adult__c	
      FROM Chemical_Product__c
      WHERE
        ZDHC_Product_GUID__c IN :productGuids
        AND Product_Status__c = 'Active'
    ];
  }

  /**
   * merges the supplied ZDHC product data with the Salesforce master chemical list
   * @param zdhcProductsMap - key value pair collection of productGUID and zdhc product object
   * @param salesforceProductsMap - key value pair of ZDHC product GUID and an sObject that matches the ZDHC data
   * @param setProductCategory - optionally determine the product category to show in a UI component
   * @return collection of objects containing data from ZDHC and Salesforce
   */
  @TestVisible
  private List<TC_CombinedChemicalProduct> combineData(
    Map<String, ZDHCGetProductsResponseData> zdhcProductsMap,
    Map<String, Chemical_Product__c> salesforceProductsMap,
    Boolean setProductCategory
  ) {
    List<TC_CombinedChemicalProduct> combinedProducts = new List<TC_CombinedChemicalProduct>();
    for (String productGuid : zdhcProductsMap.keySet()) {
      TC_CombinedChemicalProduct combinedProduct = new TC_CombinedChemicalProduct();
      combinedProduct.zdhcProductData = zdhcProductsMap.get(productGuid);
      combinedProduct.salesforceProduct = salesforceProductsMap.get(
        productGuid
      );
      if (combinedProduct.zdhcProductData.ProductCertifications != null) {
        Map<String, String> parsedCerts = TC_ParseProductCertifications.parse(
          combinedProduct.zdhcProductData.ProductCertifications
        );
        combinedProduct.mrsl2Level = parsedCerts.get('mrsl2');
        combinedProduct.mrsl3Level = parsedCerts.get('mrsl3');
        combinedProduct.otherCertifications = parsedCerts.get(
          'otherCertifications'
        );
      }
      if (setProductCategory) {
        this.getProductCategory(combinedProduct);
      }
      combinedProducts.add(combinedProduct);
    }
    return combinedProducts;
  }

  /**
   * determines the product category used to aid the user in the UI
   * @param combindProduct - object containing ZDHC and Salesforce product data
   */
    public void getProductCategory(TC_CombinedChemicalProduct combinedProduct) {
        if (combinedProduct.zdhcProductData.registered == 'ZDHC Gateway') {
            if(combinedProduct.salesforceProduct != null && combinedProduct.salesforceProduct.Origin__c == 'Inditex') {
                combinedProduct.productCategory = 'inditexzdhc'; 
            }
            else {
                combinedProduct.productCategory = 'zdhcgw';
            }
        } else if (
            combinedProduct.zdhcProductData.registered != 'ZDHC Gateway' &&
            combinedProduct.salesforceProduct != null){
                if(combinedProduct.salesforceProduct.Origin__c == 'Intertek') {
                    combinedProduct.productCategory = 'intertek';  
                }
                else if(combinedProduct.salesforceProduct.Origin__c == 'Inditex') {
                    combinedProduct.productCategory = 'inditex';
                }
                else combinedProduct.productCategory = 'crowdsourced';
            }
        else combinedProduct.productCategory = 'crowdsourced';
    }
}