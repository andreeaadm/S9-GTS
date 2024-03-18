@isTest
private with sharing class AsyncUserOpsTrgHandlerTest {
  @isTest
  static void handlesAsyncUserOpsEvents() {
    Account a = TestDataFactory.createAccount();
    TestDataFactory.CONTACTS_USER_REQD_FLAG = false;
    List<Contact> contacts = TestDataFactory.createContacts(2, true, a.Id);
    List<AccountContactRelation> acrs = [
      SELECT MTC_Role__c
      FROM AccountContactRelation
      WHERE AccountId = :a.Id
    ];
    for (AccountContactRelation acr : acrs) {
      acr.MTC_Role__c = 'admin';
    }
    update acrs;
    List<User> users = [SELECT Id FROM User WHERE AccountId = :a.Id];
    System.assertEquals(true, users.isEmpty());

    contacts[0].Is_User_Required__c = contacts[1].Is_User_Required__c = true;
    update contacts;

    Test.startTest();
    List<Async_User_Ops__e> pesToCreate = new List<Async_User_Ops__e>{
      new Async_User_Ops__e(Contact_Id__c = contacts[0].Id),
      new Async_User_Ops__e(Contact_Id__c = contacts[1].Id)
    };
    EventBus.publish(pesToCreate);
    Test.stopTest();

    List<User> afterUsers = [SELECT Id FROM User WHERE AccountId = :a.Id];
    System.assertEquals(false, afterUsers.isEmpty());
  }
}