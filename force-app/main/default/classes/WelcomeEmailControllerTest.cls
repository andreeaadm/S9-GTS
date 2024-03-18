@isTest
private class WelcomeEmailControllerTest {
  @isTest
  static void testGetMergedText() {
    // Test data setup
    welcomeEmailController controllerInstance = new welcomeEmailController();

    controllerInstance.communityNamePassed = 'iCare';
    controllerInstance.communityURLPassed = 'https://example.salesforce.com';
    controllerInstance.usernamePassed = 'testUser';

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
    System.assertEquals(
      true,
      mergedText.contains('testUser'),
      'Merged text does not contain username'
    );
  }

  @isTest
  static void testGetMergedTextWithNullValues() {
    // Test data setup
    welcomeEmailController controllerInstance = new welcomeEmailController();

    // Do not set communityNamePassed, communityURLPassed, or usernamePassed

    // Invoke the method being tested
    String mergedText = controllerInstance.getMergedText();
    // Assert the results
    System.assertEquals(
      4,
      mergedText.countMatches('null'),
      'Merged text does not match expected text'
    );
  }
}