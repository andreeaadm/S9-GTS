@IsTest
public with sharing class ChatterButtonControllerTest {
  static Map<String, Id> setup() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

    User u = new User(
      Alias = 'standt',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = StringUtil.random(10) + '@testorg.com'
    );
    insert u;

    Account a = new Account(Name = 'Test');
    insert a;

    Map<String, Id> toReturn = new Map<String, Id>{
      'userId' => u.Id,
      'accountId' => a.Id
    };

    return toReturn;
  }

  @IsTest
  static void test_isUserSubscribed_true() {
    Map<String, Id> setupMap = setup();
    EntitySubscription sub = new EntitySubscription(
      ParentId = setupMap.get('accountId'),
      SubscriberId = setupMap.get('userId')
    );
    insert sub;

    System.assert(
      ChatterButtonController.isUserSubscribed(
        setupMap.get('accountId'),
        setupMap.get('userId')
      )
    );
  }

  static void test_isUserSubscribed_false() {
    Map<String, Id> setupMap = setup();

    System.assert(
      !ChatterButtonController.isUserSubscribed(
        setupMap.get('accountId'),
        setupMap.get('userId')
      )
    );
  }

  @IsTest
  static void test_subscribeUserToRecord_newSubscription() {
    Map<String, Id> setupMap = setup();

    ChatterButtonController.subscribeUserToRecord(
      setupMap.get('accountId'),
      setupMap.get('userId'),
      null
    );

    List<EntitySubscription> subs = [
      SELECT Id
      FROM EntitySubscription
      WHERE
        ParentId = :setupMap.get('accountId')
        AND SubscriberId = :setupMap.get('userId')
    ];

    System.assertEquals(1, subs.size());
  }

  @IsTest
  static void test_subscribeUserToRecord_error() {
    Map<String, Id> setupMap = setup();

    ChatterButtonController.subscribeUserToRecord(
      setupMap.get('accountId'),
      setupMap.get('userId'),
      null
    );

    Boolean threwException = false;

    try {
      ChatterButtonController.subscribeUserToRecord(
        setupMap.get('accountId'),
        setupMap.get('userId'),
        null
      );
    } catch (Exception e) {
      threwException = true;
    }

    System.assert(threwException);
  }

  @IsTest
  static void test_unsubscribeUserFromRecord() {
    Map<String, Id> setupMap = setup();

    EntitySubscription sub = new EntitySubscription(
      ParentId = setupMap.get('accountId'),
      SubscriberId = setupMap.get('userId')
    );
    insert sub;

    ChatterButtonController.unsubscribeUserFromRecord(
      setupMap.get('accountId'),
      setupMap.get('userId')
    );

    List<EntitySubscription> subs = [
      SELECT Id
      FROM EntitySubscription
      WHERE
        ParentId = :setupMap.get('accountId')
        AND SubscriberId = :setupMap.get('userId')
    ];

    System.assertEquals(0, subs.size());
  }

  @IsTest
  static void test_unsubscribeUserFromRecord_notSubscribed() {
    Map<String, Id> setupMap = setup();

    ChatterButtonController.unsubscribeUserFromRecord(
      setupMap.get('accountId'),
      setupMap.get('userId')
    );

    List<EntitySubscription> subs = [
      SELECT Id
      FROM EntitySubscription
      WHERE
        ParentId = :setupMap.get('accountId')
        AND SubscriberId = :setupMap.get('userId')
    ];

    System.assertEquals(0, subs.size());
  }
}