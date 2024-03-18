@isTest
public class TC_CombinedChemicalProductIntertekTest {
  /*
  Scenarios to test:

    | productToCompare Product Category | productCategory Product Category | expected value
    | intertek | intertek | 0 |
    | intertek | zdhcgw | 1 |
    | intertek | crowdsourced | -1 |
  */

  @isTest
  static void compareIntertekToIntertek() {
    TC_CombinedChemicalProduct chemicalProduct = new TC_CombinedChemicalProduct();
    chemicalProduct.productCategory = 'intertek';

    TC_CombinedChemicalProduct chemicalProductToCompare = new TC_CombinedChemicalProduct();
    chemicalProductToCompare.productCategory = 'intertek';

    System.Test.startTest();
    Integer compared = chemicalProduct.compareTo(chemicalProductToCompare);
    System.Test.stopTest();

    System.assertEquals(
      0,
      compared,
      'Incorrect integer returned comparing intertek to intertek.'
    );
  }

  @isTest
  static void compareIntertekToZdhc() {
    TC_CombinedChemicalProduct chemicalProduct = new TC_CombinedChemicalProduct();
    chemicalProduct.productCategory = 'intertek';

    TC_CombinedChemicalProduct chemicalProductToCompare = new TC_CombinedChemicalProduct();
    chemicalProductToCompare.productCategory = 'zdhcgw';

    System.Test.startTest();
    Integer compared = chemicalProduct.compareTo(chemicalProductToCompare);
    System.Test.stopTest();

    System.assertEquals(
      1,
      compared,
      'Incorrect integer returned comparing intertek to zdhcgw.'
    );
  }

  @isTest
  static void compareIntertekToCrowdsourced() {
    TC_CombinedChemicalProduct chemicalProduct = new TC_CombinedChemicalProduct();
    chemicalProduct.productCategory = 'intertek';

    TC_CombinedChemicalProduct chemicalProductToCompare = new TC_CombinedChemicalProduct();
    chemicalProductToCompare.productCategory = 'crowdsourced';

    System.Test.startTest();
    Integer compared = chemicalProduct.compareTo(chemicalProductToCompare);
    System.Test.stopTest();

    System.assertEquals(
      -1,
      compared,
      'Incorrect integer returned comparing intertek to crowdsourced.'
    );
  }
}