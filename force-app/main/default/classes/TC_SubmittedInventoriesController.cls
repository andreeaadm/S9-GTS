public with sharing class TC_SubmittedInventoriesController {
  @AuraEnabled(cacheable=true)
  public static string getPercentageSubmittedInventories() {
    try {
      // get the account Id associated with logged in Brand user
      Id accountId = [
        SELECT Contact.AccountId
        FROM User
        WHERE Id = :UserInfo.getUserId()
      ]
      .Contact.AccountId;

      // get all Active and Approved connections with the logged in Brand
      List<Brand_Supplier_Connection__c> connList = [
        SELECT Supplier_Account__c
        FROM Brand_Supplier_Connection__c
        WHERE
          Status__c = 'Approved'
          AND Brand_Account__c = :accountId
          AND Active__c = TRUE
      ];

      // list all Suppliers the logged in user is connected with
      Set<Id> supplierIds = new Set<Id>();
      for (Brand_Supplier_Connection__c bsc : connList) {
        supplierIds.add(bsc.Supplier_Account__c);
      }

      // get all inventories from this month associated with those Suppliers
      List<Inventory__c> totalInvList = [
        SELECT Status__c
        FROM Inventory__c
        WHERE
          Inventory_Date__c >= THIS_MONTH
          AND Facility__r.Parent.ToxClear_Subscription_Status__c = 'Active'
          AND Facility__r.ParentId IN :supplierIds
      ];

      if (totalInvList.size() > 0) {
        Integer submittedCount = 0;
        for (Inventory__c i : totalInvList) {
          if (i.Status__c == 'Submitted') {
            submittedCount++;
          }
        }

        return String.valueOf(
          math.roundToLong(
            ((Decimal) submittedCount / (Decimal) totalInvList.size()) * 100
          )
        );
      }
      return '0';
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}