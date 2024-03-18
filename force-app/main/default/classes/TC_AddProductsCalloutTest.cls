@isTest
public class TC_AddProductsCalloutTest {
  @isTest
  private static void callingZdhcReturnsResponse() {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'products';
    zdhcRequest.method = 'POST';

    Test.startTest();
    ZDHCGatewayServiceResponse result = ZDHCGatewayService.makeCallout(
      zdhcRequest
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
  }
}