@isTest
public class TC_CombinedChemicalProductZdhcTest {
  /*
  Scenarios to test:

    | productToCompare Product Category | productCategory Product Category | expected value
    | zdhcgw | zdhcgw | 0 |
    | zdhcgw | intertek | -1 |
    | zdhcgw | crowdsourced | -1 |  
  */

  /*
    Compare zdhcgw
  */
  @isTest
  static void compareZdhcgwToZdhcgw() {
    TC_CombinedChemicalProduct chemicalProduct = new TC_CombinedChemicalProduct();
    chemicalProduct.productCategory = 'zdhcgw';

    TC_CombinedChemicalProduct chemicalProductToCompare = new TC_CombinedChemicalProduct();
    chemicalProductToCompare.productCategory = 'zdhcgw';

    System.Test.startTest();
    Integer compared = chemicalProduct.compareTo(chemicalProductToCompare);
    System.Test.stopTest();

    System.assertEquals(
      0,
      compared,
      'Incorrect integer returned comparing zdhcgw to zdhcgw.'
    );
  }

  @isTest
  static void compareZdhcgwToIntertek() {
    TC_CombinedChemicalProduct chemicalProduct = new TC_CombinedChemicalProduct();
    chemicalProduct.productCategory = 'zdhcgw';

    TC_CombinedChemicalProduct chemicalProductToCompare = new TC_CombinedChemicalProduct();
    chemicalProductToCompare.productCategory = 'intertek';

    System.Test.startTest();
    Integer compared = chemicalProduct.compareTo(chemicalProductToCompare);
    System.Test.stopTest();

    System.assertEquals(
      -1,
      compared,
      'Incorrect integer returned comparing zdhcgw to intertek.'
    );
  }

  @isTest
  static void compareZdhcgwToCrowdsourced() {
    TC_CombinedChemicalProduct chemicalProduct = new TC_CombinedChemicalProduct();
    chemicalProduct.productCategory = 'zdhcgw';

    TC_CombinedChemicalProduct chemicalProductToCompare = new TC_CombinedChemicalProduct();
    chemicalProductToCompare.productCategory = 'crowdsourced';

    System.Test.startTest();
    Integer compared = chemicalProduct.compareTo(chemicalProductToCompare);
    System.Test.stopTest();

    System.assertEquals(
      -1,
      compared,
      'Incorrect integer returned comparing zdhcgw to crowdsourced.'
    );
  }
}