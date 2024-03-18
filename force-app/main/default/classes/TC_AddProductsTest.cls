@isTest
public class TC_AddProductsTest {
  @isTest
  private static void searchProducts_error() {
    ZDHCGatewayMockResponseGenerator mock = new ZDHCGatewayMockResponseGenerator();
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    TC_AddProductsResponse errorResponse = TC_AddProducts.searchProducts(
      '',
      new Map<String, Object>()
    );
    Test.stopTest();

    System.assertNotEquals(null, errorResponse);
    System.assertNotEquals(null, errorResponse.errors);
    System.assertNotEquals(0, errorResponse.errors.size());
  }
  @isTest
  private static void searchProducts_ok() {
    ZDHCGatewayMockResponseGenerator mock = new ZDHCGatewayMockResponseGenerator();
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    TC_AddProductsResponse okResponse = TC_AddProducts.searchProducts(
      'D5545F4B0AEC4277E0530100007F4C7B',
      new Map<String, Object>{ 'search' => 'INK' }
    );
    Test.stopTest();

    System.assertNotEquals(null, okResponse);
    System.assertEquals(null, okResponse.errors);
    System.assertNotEquals(0, okResponse.combinedProducts.size());
  }
}