@isTest
public with sharing class MTCVFLoginFlowController_Test {
  // Test FinishLoginFlowHome without accepting terms
  @isTest
  private static void test_1_1() {
    Test.startTest();
    MTCVFLoginFlowController c = new MTCVFLoginFlowController();
    c.FinishLoginFlowHome();
    System.assert(c.error != null);
    Test.stopTest();
  }

  // Test FinishLoginFlowHome after accepting terms
  @isTest
  private static void test_1_2() {
    Test.startTest();
    MTCVFLoginFlowController c = new MTCVFLoginFlowController();
    c.acceptedTerms = true;
    c.FinishLoginFlowHome();
    System.assert(c.error == '');
    Test.stopTest();
  }

  // Test doInit before accepting terms
  @isTest
  private static void test_1_3() {
    Test.startTest();
    MTCVFLoginFlowController c = new MTCVFLoginFlowController();
    System.runAs(new User(Id = UserInfo.getUserId())) {
      c.doInit();
    }
    Test.stopTest();
  }

  // Test doInit after accepting terms
  @isTest
  private static void test_1_4() {
    Test.startTest();
    MTCVFLoginFlowController c = new MTCVFLoginFlowController();
    User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    u.Date_MTC_Terms_Accepted__c = DateTime.now();
    update u;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      c.doInit();
    }
    Test.stopTest();
  }
}