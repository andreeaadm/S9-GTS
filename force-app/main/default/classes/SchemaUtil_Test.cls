@isTest
private class SchemaUtil_Test {
  /**
   * Test the getPicklistEntries method on the SchemaUtil class against a Picklist field.
   *
   * @return void
   */
  @isTest
  static void testGetPicklistEntries_1() {
    Test.startTest();
    List<SchemaUtil.PicklistEntry> result = SchemaUtil.getPicklistEntries(
      'Account',
      'Industry'
    );

    System.assertNotEquals(null, result);
    System.assert(result.size() > 0);
    Test.stopTest();
  }

  /**
   * Test the getPicklistEntries method on the SchemaUtil class against a Text field.
   *
   * @return void
   */
  @isTest
  static void testGetPicklistEntries_2() {
    Test.startTest();
    List<SchemaUtil.PicklistEntry> result = SchemaUtil.getPicklistEntries(
      'Account',
      'Name'
    );

    System.assertEquals(null, result);
    Test.stopTest();
  }

  /**
   * Test the getPicklistValues method on the SchemaUtil class against a Picklist field with isValueFirst
   *
   * @return void
   */
  @isTest
  static void testGetPicklistEntries_3() {
    Test.startTest();
    Map<String, String> result = SchemaUtil.getPicklistValues(
      'Account',
      'Industry',
      true
    );
    System.assertNotEquals(null, result);
    System.assert(result.size() > 0);
    Test.stopTest();
  }

  /**
   * Test the getPicklistValueExists method on the SchemaUtil class against a Picklist field
   *
   * @return void
   */
  @isTest
  static void testGetPicklistEntries_4() {
    Test.startTest();
    Boolean result = SchemaUtil.getPicklistValueExists(
      'Account',
      'Industry',
      'Automotive'
    );
    System.assertEquals(true, result);
    Test.stopTest();
  }

  /**
   * Test the getField method on the SchemaUtil class.
   *
   * @return void
   */
  @isTest
  static void testGetField() {
    Test.startTest();
    SchemaUtil.Field result = SchemaUtil.getField('Account', 'Name');
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertNotEquals(null, result.field);
    System.assertNotEquals(null, result.fieldDescribe);
    System.assertEquals('Account Name', result.label);
    System.assertEquals('Name', result.name);
  }

  /**
   * Test the getFieldList method on the SchemaUtil class.
   *
   * @return void
   */
  @isTest
  static void testGetFieldList() {
    Test.startTest();
    List<SchemaUtil.Field> result = SchemaUtil.getFieldList('Account');
    Test.stopTest();

    System.assert(result.size() > 0);
  }

  /**
   * Test the getFieldMap method on the SchemaUtil class.
   *
   * @return void
   */
  @isTest
  static void testGetFieldMap() {
    Test.startTest();
    Map<String, SchemaUtil.Field> result = SchemaUtil.getFieldMap('Account');
    Test.stopTest();

    System.assert(result.size() > 0);
  }

  /**
   * Test the getRecordType method on the SchemaUtil class.
   *
   * @return void
   */
  @isTest
  static void testGetRecordType() {
    Test.startTest();
    SchemaUtil.RecordType result = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Report'
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertNotEquals(null, result.recordId);
    System.assertEquals('MTC_Report', result.recordName);
  }

  /*┌────────────────────────────────────────────────────────────────┐
   * Generate a list of accounts using the generateSOQLFields String
   * method so it not only generates the string but also shows how
   * it is useful.
   *└───────────────────────────────────────────────────────────┄ℌ𝔍┄┘*/
  @isTest
  private static void generateSOQLFieldsString_test_1() {
    TestDataFactory.createAccounts(1, true);

    List<Account> accounts = new List<Account>();

    Test.startTest();
    String theQuery = SchemaUtil.generateSOQLFieldsString('Account', false);
    // For complete code coverage use both boolean options.
    SchemaUtil.generateSOQLFieldsString('Account', true);

    accounts = Database.query(theQuery + ' FROM Account ORDER BY Name ASC');
    System.assert(accounts.size() != 0, accounts.size());

    Test.stopTest();
  }
}