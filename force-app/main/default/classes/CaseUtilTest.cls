@isTest
public with sharing class CaseUtilTest {
  //Test with no where clause or order by
  @isTest
  static void test_1_1() {
    Test.startTest();
    CaseUtil.getCases('', '', 6);
    Test.stopTest();
  }

  // Test with where clause and order by
  @isTest
  static void test_1_2() {
    Test.startTest();
    CaseUtil.getCases('CaseNumber DESC', 'CaseNumber != null', 6);
    Test.stopTest();
  }
}