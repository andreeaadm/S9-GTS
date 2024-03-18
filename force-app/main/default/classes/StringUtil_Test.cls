@isTest
private class StringUtil_Test {
  /**
   * Test the random method on StringUtil with 1 parameter.
   *
   * @return void
   */
  @isTest
  static void testRandom_1() {
    Test.startTest();
    String result = StringUtil.random(255);

    System.assertNotEquals(null, result);
    Test.stopTest();
  }

  /**
   * Test the random method on StringUtil with 2 parameters.
   *
   * @return void
   */
  @isTest
  static void testRandom_2() {
    String result = StringUtil.random(10, 'A');

    System.assertNotEquals(null, result);
    System.assertEquals('AAAAAAAAAA', result);
  }

  @isTest
  static void test_formatForCsv_null() {
    String returnedVal = StringUtil.formatForCsv(null);

    System.assertEquals('', returnedVal);
  }

  @isTest
  static void test_formatForCsv_specialCharacters() {
    String returnedVal = StringUtil.formatForCsv('test, "String');

    System.assertEquals('"test, ""String"', returnedVal);
  }

  @isTest
  static void test_formatForCsv_text() {
    String returnedVal = StringUtil.formatForCsv('test string');

    System.assertEquals('test string', returnedVal);
  }

  @isTest
  static void test_tokenize() {
    String returnedVal = StringUtil.tokenize('Test,Test,Test', ',');

    System.assertEquals('Test', returnedVal);
  }

  @isTest
  static void test_tokenize_emptyStr() {
    String returnedVal = StringUtil.tokenize('', ',');

    System.assertEquals('', returnedVal);
  }

  @isTest
  static void format_stringToFormat_formattingArguments() {
    // format(String, List<Object>)
    System.assertEquals(
      'Hello',
      StringUtil.format('Hello {0}', new List<Object>{ null })
    );
    System.assertEquals(
      'Hello Zero',
      StringUtil.format('Hello {0}', new List<Object>{ 'Zero' })
    );
    System.assertEquals(
      'Hello Zero',
      StringUtil.format('Hello {0} {1}', new List<Object>{ 'Zero', null })
    );
    System.assertEquals(
      'Hello Zero One',
      StringUtil.format('Hello {0} {1}', new List<Object>{ 'Zero', 'One' })
    );
    System.assertEquals(
      'Hello One',
      StringUtil.format('Hello {0} {1}', new List<Object>{ null, 'One' })
    );
    System.assertEquals(
      'Hello One',
      StringUtil.format('{0} Hello {1}\t', new List<Object>{ null, 'One' })
    );
  }

  @isTest
  static void newGUID() {
    String guid = StringUtil.newGUID();
    System.assertEquals(32, guid.length(), 'check guid string length');
  }
}