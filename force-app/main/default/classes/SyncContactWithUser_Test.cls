@IsTest
public with sharing class SyncContactWithUser_Test {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_TOXCLEAR = true;
    List<Account> accounts = TestDataFactory.createAccounts(1, false);
    accounts[0].Country__c = 'Armenia';
    insert accounts[0];
    List<Contact> contacts = TestDataFactory.createContacts(
      1,
      true,
      accounts[0].Id
    );

    System.assertEquals('Test', contacts[0].FirstName);
    System.assertEquals('Contact 0', contacts[0].LastName);
    System.assertEquals(null, contacts[0].MailingStreet);
    System.assertEquals(null, contacts[0].MailingCity);
    System.assertEquals(null, contacts[0].MailingState);
    System.assertEquals(null, contacts[0].MailingPostalCode);
    System.assertEquals(null, contacts[0].MailingCountry);
    System.assertNotEquals(null, contacts[0].Phone);
    System.assert(contacts[0].Email.contains('test@oegen.co.uk'));

    List<User> users = TestDataFactory.createCommunityUsers(
      'Experience Cloud Site Standard - Login',
      contacts
    );

    // usually this handler would run off a flow trigger on the platform event
    UserUpsertTrgHandler.afterInsert(
      new List<User_Upsert__e>{
        new User_Upsert__e(
          Is_Insert__c = true,
          User_Ids__c = JSON.serialize(new List<Id>{ users[0].Id })
        )
      }
    );
  }

  @IsTest
  static void updateContact_Test() {
    Contact testSubject = [
      SELECT
        FirstName,
        LastName,
        Email,
        Phone,
        MailingStreet,
        MailingCity,
        MailingState,
        MailingPostalCode,
        Community_User_Type__c
      FROM Contact
      LIMIT 1
    ];

    // Contact values were changed during insert of the user
    System.assertEquals('CustTest', testSubject.FirstName);
    System.assertEquals('CustTest', testSubject.LastName);
    System.assertEquals('Test', testSubject.MailingStreet);
    System.assertEquals('Test', testSubject.MailingCity);
    System.assertEquals('Test', testSubject.MailingPostalCode);
    System.assertEquals('ToxClear', testSubject.Community_User_Type__c);
    System.assertNotEquals(null, testSubject.Phone);
    System.assert(testSubject.Email.contains('test@oegen.co.uk'));

    testSubject.Phone = '07555555555';
    testSubject.Title = 'Doctor';
    System.runAs(new User(Id = UserInfo.getUserId())) {
      update testSubject;
    }

    User testUser = [
      SELECT
        FirstName,
        LastName,
        Email,
        Phone,
        Street,
        City,
        State,
        PostalCode,
        Country,
        Title
      FROM User
      WHERE ContactId = :testSubject.Id
      LIMIT 1
    ];

    System.assertEquals('CustTest', testUser.FirstName);
    System.assertEquals('CustTest', testUser.LastName);
    System.assertEquals('Test', testUser.Street);
    System.assertEquals('Test', testUser.City);
    System.assertEquals('Test', testUser.PostalCode);
    System.assertEquals('07555555555', testUser.Phone);
    System.assert(testUser.Email.contains('test@oegen.co.uk'));
    System.assertEquals(null, testUser.Title);
  }

  @IsTest
  static void updateUser_Test() {
    Contact testSubject = [
      SELECT
        FirstName,
        LastName,
        Email,
        Phone,
        MailingStreet,
        MailingCity,
        MailingState,
        MailingPostalCode,
        MailingCountry,
        Community_User_Type__c,
        (
          SELECT
            FirstName,
            LastName,
            Email,
            Phone,
            Street,
            City,
            State,
            PostalCode,
            Country
          FROM Users
        )
      FROM Contact
      LIMIT 1
    ];

    // Contact values were changed during insert of the user
    System.assertEquals('CustTest', testSubject.FirstName);
    System.assertEquals('CustTest', testSubject.LastName);
    System.assertEquals('Test', testSubject.MailingStreet);
    System.assertEquals('Test', testSubject.MailingCity);
    System.assertEquals('Test', testSubject.MailingPostalCode);
    System.assertEquals('ToxClear', testSubject.Community_User_Type__c);
    System.assertNotEquals(null, testSubject.Phone);
    System.assert(testSubject.Email.contains('test@oegen.co.uk'));

    testSubject.Users[0].Phone = '07555555555';
    testSubject.Users[0].Title = 'Doctor';
    test.startTest();
    update testSubject.Users[0];
    test.stopTest();

    Contact testContact = [
      SELECT
        FirstName,
        LastName,
        Email,
        Phone,
        MailingStreet,
        MailingCity,
        MailingState,
        MailingPostalCode,
        MailingCountry,
        Title
      FROM Contact
      WHERE Id = :testSubject.Id
      LIMIT 1
    ];

    System.assertEquals('CustTest', testContact.FirstName);
    System.assertEquals('CustTest', testContact.LastName);
    System.assertEquals('Test', testContact.MailingStreet);
    System.assertEquals('Test', testContact.MailingCity);
    System.assertEquals('Test', testContact.MailingPostalCode);
    System.assertEquals('07555555555', testContact.Phone);
    System.assert(testContact.Email.contains('test@oegen.co.uk'));
    System.assertEquals(null, testContact.Title);
  }
}