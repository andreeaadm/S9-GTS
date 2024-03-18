@isTest
private class iCarePassResetTest {
  @isTest
  static void testGetMergedText() {
    // Test data setup
    iCarePassReset controllerInstance = new iCarePassReset();

    controllerInstance.communityNamePassed = 'iCare';
    controllerInstance.communityURLPassed = 'https://example.salesforce.com';

    // Invoke the method being tested
    String mergedText = controllerInstance.getMergedText();

    // Assert the results
    System.assertEquals(
      true,
      mergedText.contains('iCare'),
      'Merged text does not contain Community name'
    );
    System.assertEquals(
      true,
      mergedText.contains('https://example.salesforce.com'),
      'Merged text does not contain Community url'
    );
  }

  @isTest
  static void testGetMergedTextWithNullValues() {
    // Test data setup
    iCarePassReset controllerInstance = new iCarePassReset();

    // Do not set communityNamePassed or communityURLPassed

    // Invoke the method being tested
    String mergedText = controllerInstance.getMergedText();
    // Assert the results
    System.assertEquals(
      2,
      mergedText.countMatches('null'),
      'Merged text does not match expected text'
    );
  }
}