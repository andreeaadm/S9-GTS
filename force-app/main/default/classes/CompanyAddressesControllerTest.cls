@isTest
public with sharing class CompanyAddressesControllerTest {
  @isTest
  static void test_1_1() {
    User u = TestDataFactory.createCommunityUser('MTC Admin Login');
    u = [
      SELECT Id, ContactId, Contact.AccountId
      FROM User
      WHERE Id = :u.Id
      LIMIT 1
    ];
    List<AccountContactRelation> acrs = new List<AccountContactRelation>(
      [
        SELECT Id
        FROM AccountContactRelation
        WHERE AccountId = :u.Contact.AccountId AND ContactId = :u.ContactId
      ]
    );
    if (acrs.size() < 1) {
      AccountContactRelation acr = new AccountContactRelation(
        ContactId = u.ContactId,
        AccountId = u.Contact.AccountId,
        MTC_Role__c = 'CGA'
      );
      insert acr;
    }
    Boolean result;
    Test.startTest();
    System.runAs(u) {
      Case c = new Case(
        Description = 'Address UPDATE request',
        ContactId = u.ContactId,
        Origin = 'MTC'
      );
      result = CompanyAddressesController.insertCase(c);
    }
    Test.stopTest();
    System.assertEquals(true, result);
  }
}