@isTest
public with sharing class UserUtilTest {
  // Get the current user running this test
  @isTest
  static void test_1_1() {
    Test.startTest();
    User u = UserUtil.getUserDetails(null);
    Test.stopTest();
    System.assert(u != null);
  }

  // Get the current user who is a site user
  @isTest
  static void test_1_2() {
    User u = TestDataFactory.createCommunityUser('MTC Admin Login');
    User userInfo;
    Test.startTest();
    System.runAs(u) {
      userInfo = UserUtil.getUserDetails(null);
    }
    Test.stopTest();
    System.assert(userInfo != null);
  }

  // Get a user from a provided userID
  @isTest
  static void test_1_3() {
    User u = TestDataFactory.createCommunityUser('MTC Admin Login');
    User userInfo;
    Test.startTest();
    System.runAs(u) {
      userInfo = UserUtil.getUserDetails(u.Id);
    }
    Test.stopTest();
    System.assert(userInfo != null);
  }

  //setEmailVisibility
  @isTest
  static void test_1_4() {
    User u = TestDataFactory.createCommunityUser('MTC Admin Login');
    Test.startTest();
    UserUtil.setEmailVisibilityNoDML(new List<User>{ u });
    Test.stopTest();
    System.assertEquals(true, u.UserPreferencesShowEmailToExternalUsers);
  }
}