@isTest
public with sharing class WithoutSharingTest {
  static Map<String, Id> buildName2Id() {
    Map<String, Id> name2Id = new Map<String, Id>();
    for (Account acc : [SELECT Name FROM Account]) {
      name2Id.put(acc.Name, acc.Id);
    }
    return name2Id;
  }
  @TestSetup
  static void makeData() {
    TestDataFactory.createAccounts(4, true);
    Map<String, Id> name2Id = buildName2Id();

    Contact con = TestDataFactory.createContacts(
      1,
      false,
      name2Id.get('Account 2')
    )[0];
    Contact conWithUser = TestDataFactory.createContacts(
      1,
      false,
      name2Id.get('Account 3')
    )[0];
    Contact conOtherApp = TestDataFactory.createContacts(
      1,
      false,
      name2Id.get('Account 4')
    )[0];
    insert new List<Contact>{ con, conWithUser, conOtherApp };

    AccountContactRelation acrForConWithUser = [
      SELECT MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :conWithUser.Id
      LIMIT 1
    ];
    acrForConWithUser.MTC_Role__c = 'read-only';
    update acrForConWithUser;
  }
  @isTest
  static void userCreationNoExisting() {
    Map<String, Id> name2Id = buildName2Id();
    Contact con = TestDataFactory.createContacts(
      1,
      false,
      name2Id.get('Account 1')
    )[0];
    Test.startTest();
    WithoutSharing.createUpdateAccountContactRelation(
      'read-only',
      JSON.serialize(con)
    );
    Test.stopTest();
  }
  @isTest
  static void userCreationWithContactNoExistingUser() {
    Map<String, Id> name2Id = buildName2Id();
    Contact existingCon = [
      SELECT Email, FirstName, LastName, AccountId
      FROM Contact
      WHERE AccountId = :name2Id.get('Account 2')
    ];
    Id savedContactId = existingCon.Id;
    existingCon.Id = null;
    existingCon.AccountId = name2Id.get('Account 1');

    Test.startTest();
    WithoutSharing.createUpdateAccountContactRelation(
      'Read-Only',
      JSON.serialize(existingCon)
    );
    Test.stopTest();
    List<AccountContactRelation> acrs = [
      SELECT Id, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :savedContactId
    ];

    System.assertEquals(2, acrs.size());
    for (AccountContactRelation acr : acrs) {
      if (acr.AccountId == name2Id.get('Account 1')) {
        System.assertEquals('Read-Only', acr.MTC_Role__c);
      } else if (acr.AccountId == name2Id.get('Account 2')) {
        System.assertEquals('No-Access', acr.MTC_Role__c);
      } else {
        System.assert(false, 'Not an expected relationship: ' + acr.AccountId);
      }
    }
  }

  @isTest
  static void userCreationWithExistingUser() {
    Map<String, Id> name2Id = buildName2Id();
    Contact existingCon = [
      SELECT Email, FirstName, LastName, AccountId
      FROM Contact
      WHERE AccountId = :name2Id.get('Account 3')
    ];
    Id savedContactId = existingCon.Id;
    existingCon.Id = null;
    existingCon.AccountId = name2Id.get('Account 1');

    Test.startTest();
    WithoutSharing.createUpdateAccountContactRelation(
      'admin',
      JSON.serialize(existingCon)
    );
    Test.stopTest();
    List<AccountContactRelation> acrs = [
      SELECT Id, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :savedContactId
    ];

    System.assertEquals(2, acrs.size());
    for (AccountContactRelation acr : acrs) {
      if (acr.AccountId == name2Id.get('Account 1')) {
        System.assertEquals('Admin', acr.MTC_Role__c);
      } else if (acr.AccountId == name2Id.get('Account 3')) {
        System.assertEquals('Read-Only', acr.MTC_Role__c);
      } else {
        System.assert(false, 'Not an expected relationship: ' + acr.AccountId);
      }
    }
  }
  @isTest
  static void userCreationWithExistingUserOtherApplication() {
    Map<String, Id> name2Id = buildName2Id();
    Contact existingCon = [
      SELECT Email, FirstName, LastName, AccountId
      FROM Contact
      WHERE AccountId = :name2Id.get('Account 4')
    ];
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new User(
        LastName = 'CustTest other app',
        FirstName = 'CustTest',
        Alias = 'CustTest',
        Phone = StringUtil.random(12, '0123456789'),
        Email = existingCon.email,
        Username = existingCon.email,
        ProfileId = [
          SELECT id
          FROM profile
          WHERE name LIKE 'experience%'
          LIMIT 1
        ]
        .Id,
        TimeZoneSidKey = 'GMT',
        LanguageLocaleKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LocaleSidKey = 'en_US',
        ContactId = existingCon.Id,
        Street = 'Test',
        City = 'Test',
        countryCode = 'GB',
        //State = 'Test',
        PostalCode = 'Test',
        //Country = 'Test',
        isActive = true
      );
    }
    Id savedContactId = existingCon.Id;
    existingCon.Id = null;
    existingCon.AccountId = name2Id.get('Account 1');

    Test.startTest();
    APIResponse response = WithoutSharing.createUpdateAccountContactRelation(
      'admin',
      JSON.serialize(existingCon)
    );
    Test.stopTest();
    List<AccountContactRelation> acrs = [
      SELECT Id, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :savedContactId
    ];

    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);

    System.assertEquals(1, acrs.size());

    System.assertEquals('No-Access', acrs[0].MTC_Role__c);
  }

  @isTest
  static void verifyGetAllACRsRelatedToUsers() {
    Map<String, Id> name2Id = buildName2Id();

    User conWithUser = [
      SELECT Id
      FROM User
      WHERE AccountId = :name2Id.get('Account 3')
      LIMIT 1
    ];

    Map<Id, List<AccountContactRelation>> u2acrs = WithoutSharing.getAllACRsRelatedToUsers(
      new Set<Id>{ conWithUser.Id }
    );
    System.assertEquals(1, u2acrs.size());
    System.assertEquals(true, u2acrs.containsKey(conWithUser.Id));
  }
}