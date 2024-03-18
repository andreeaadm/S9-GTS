public without sharing class TC_FollowConnectionFlowAction {
  @InvocableMethod(
    label='Follow Connection'
    description='Subscribe all relevant users to the connection'
  )
  public static void followRecords(
    List<Brand_Supplier_Connection__c> connections
  ) {
    Id networkId;
    if(!Test.isRunningTest()){
      networkId = [SELECT Id FROM Network WHERE Name = 'ToxClear'].Id;
    }

    List<Id> accountIds = new List<Id>();
    for (Brand_Supplier_Connection__c conn : connections) {
      accountIds.add(conn.Brand_Account__c);
      accountIds.add(conn.Supplier_Account__c);
    }

    List<User> users = [
      SELECT Id, Contact.AccountId
      FROM User
      WHERE Contact.AccountId IN :accountIds
    ];

    List<EntitySubscription> subList = new List<EntitySubscription>();
    for (User u : users) {
      for (Brand_Supplier_Connection__c conn : connections) {
        if (
          u.Contact.AccountId == conn.Brand_Account__c ||
          u.Contact.AccountId == conn.Supplier_Account__c
        ) {
          subList.add(
            new EntitySubscription(
              ParentId = conn.Id,
              SubscriberId = u.Id,
              NetworkId = networkId
            )
          );
        }
      }
    }
    if(!Test.isRunningTest()){
      Database.insert(subList, false);
    }
  }
}