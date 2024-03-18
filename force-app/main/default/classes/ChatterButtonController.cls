public without sharing class ChatterButtonController {
  @AuraEnabled(cacheable=true)
  public static Boolean isUserSubscribed(Id recordId, Id userId) {
    List<EntitySubscription> subs = [
      SELECT Id
      FROM EntitySubscription
      WHERE ParentId = :recordId AND SubscriberId = :userId
    ];

    return subs.size() > 0;
  }

  @AuraEnabled
  public static void subscribeUserToRecord(
    Id recordId,
    Id userId,
    Id networkId
  ) {
    try {
      EntitySubscription sub = new EntitySubscription(
        ParentId = recordId,
        SubscriberId = userId,
        NetworkId = networkId
      );
      insert sub;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void unsubscribeUserFromRecord(Id recordId, Id userId) {
    try {
      List<EntitySubscription> subs = [
        SELECT Id
        FROM EntitySubscription
        WHERE ParentId = :recordId AND SubscriberId = :userId
      ];

      delete subs;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}