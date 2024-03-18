@isTest
public class TC_CombinedChemicalProdCrowdsourcedTest {
  /*
  Scenarios to test:

    | productToCompare Product Category | productCategory Product Category | expected value
    | crowdsourced | crowdsourced | 0 |
    | crowdsourced | zdhcgw | 1 |
    | crowdsourced | intertek | 1 |    
  */

  @isTest
  static void compareCrowdsourcedToCrowdsourced() {
    TC_CombinedChemicalProduct chemicalProduct = new TC_CombinedChemicalProduct();
    chemicalProduct.productCategory = 'crowdsourced';

    TC_CombinedChemicalProduct chemicalProductToCompare = new TC_CombinedChemicalProduct();
    chemicalProductToCompare.productCategory = 'crowdsourced';

    System.Test.startTest();
    Integer compared = chemicalProduct.compareTo(chemicalProductToCompare);
    System.Test.stopTest();

    System.assertEquals(
      0,
      compared,
      'Incorrect integer returned comparing crowdsourced to crowdsourced.'
    );
  }

  @isTest
  static void compareCrowdsourcedToZdhc() {
    TC_CombinedChemicalProduct chemicalProduct = new TC_CombinedChemicalProduct();
    chemicalProduct.productCategory = 'crowdsourced';

    TC_CombinedChemicalProduct chemicalProductToCompare = new TC_CombinedChemicalProduct();
    chemicalProductToCompare.productCategory = 'zdhcgw';

    System.Test.startTest();
    Integer compared = chemicalProduct.compareTo(chemicalProductToCompare);
    System.Test.stopTest();

    System.assertEquals(
      1,
      compared,
      'Incorrect integer returned comparing crowdsourced to zdhcgw.'
    );
  }

  @isTest
  static void compareCrowdsourcedToIntertek() {
    TC_CombinedChemicalProduct chemicalProduct = new TC_CombinedChemicalProduct();
    chemicalProduct.productCategory = 'crowdsourced';

    TC_CombinedChemicalProduct chemicalProductToCompare = new TC_CombinedChemicalProduct();
    chemicalProductToCompare.productCategory = 'intertek';

    System.Test.startTest();
    Integer compared = chemicalProduct.compareTo(chemicalProductToCompare);
    System.Test.stopTest();

    System.assertEquals(
      1,
      compared,
      'Incorrect integer returned comparing crowdsourced to intertek.'
    );
  }
}