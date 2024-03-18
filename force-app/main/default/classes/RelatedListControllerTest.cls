@isTest
public with sharing class RelatedListControllerTest {
  @isTest
  static void basicCheck() {
    // public static List<sObject> getRelatedRecords(String relatedObjectApiName, String parentFieldApiName, String parentRecordId) {
    List<Account> accounts = TestDataFactory.createAccounts(1, true);
    List<Case> cases = new List<Case>{
      new Case(AccountId = accounts[0].Id, Subject = 'A test case')
    };
    insert cases;
    List<SObject> related = RelatedListController.getRelatedRecords(
      'Case',
      'AccountId',
      accounts[0].Id
    );
    System.assertEquals(1, related.size());
  }
}