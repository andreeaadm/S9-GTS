@isTest
public class ZDHCGetProductsTest {
  @isTest
  public static void byFormulatorName() {
    // Mock 0 sends 39 results.
    StaticResourceMockResponseGenerator.setMock(
      'GetProductsResponse2_0',
      200,
      'OK',
      null
    );
    List<ZDHC_Error_Log__c> calloutLogEntries = new List<ZDHC_Error_Log__c>();
    ZDHCGetProducts zdhcGetProducts = new ZDHCGetProducts(
      calloutLogEntries,
      'D5545F4B0AEC4277E0530100007F4C7B',
      new Map<String, Object>{
        'FormulatorName' => 'Kemin Quimica Textil do Brasil Ltda'
      }
    );
    Test.StartTest();
    Boolean result = zdhcGetProducts.call();
    Map<String, ZDHCGetProductsResponseData> first = zdhcGetProducts.mapByProductGUID();
    // Mock 1 sends the remaining 1 result.
    StaticResourceMockResponseGenerator.setMock(
      'GetProductsResponse2_1',
      200,
      'OK',
      null
    );
    if (!zdhcGetProducts.isEnd()) {
      zdhcGetProducts.next();
    }
    Boolean result2 = zdhcGetProducts.call();
    Map<String, ZDHCGetProductsResponseData> second = zdhcGetProducts.mapByProductGUID();
    Test.stopTest();

    System.assertEquals(true, result, 'OK');
    System.assertEquals(true, result2, 'OK');
    System.assertEquals(
      40,
      zdhcGetProducts.response.totalResults,
      'Expect 40 product results total'
    );
    System.assertEquals(
      39,
      first.values().size(),
      'Expect 1 product map item in this page'
    );
    System.assertEquals(
      1,
      second.values().size(),
      'Expect 1 product map item in this page'
    );
    System.assertEquals(
      '90426863F26007D1E0530100007F7DA8',
      zdhcGetProducts.response.data[0].formulatorGUID,
      'Expect this GUID'
    );
  }

  public static void byProductGUID() {
    StaticResourceMockResponseGenerator.setMock(
      'GetProductsResponse3',
      200,
      'OK',
      null
    );
    List<ZDHC_Error_Log__c> calloutLogEntries = new List<ZDHC_Error_Log__c>();
    ZDHCGetProducts zdhcGetProducts = new ZDHCGetProducts(
      calloutLogEntries,
      'D5545F4B0AEC4277E0530100007F4C7B',
      new Map<String, Object>{
        'productGUID' => '8E54C4140D431375E0530100007F5CB6'
      }
    );
    Test.StartTest();
    Boolean result = zdhcGetProducts.call();
    if (zdhcGetProducts.isEnd()) {
      zdhcGetProducts.next();
    } // handle cases when not used
    Test.stopTest();

    System.assertEquals(true, result, 'OK');
    System.assertEquals(
      1,
      zdhcGetProducts.response.totalResults,
      'Only expect 1 product result'
    );
    System.assertEquals(
      '8E54C4140D431375E0530100007F5CB6',
      zdhcGetProducts.response.data[0].productGUID,
      'Expect this GUID'
    );
  }
}