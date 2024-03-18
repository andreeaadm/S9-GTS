/*
 * Deals with sharing all child Facilities to a Supplier user
 * Suppliers should have access to all Facilities with them as a Parent Account
 */
public without sharing class TC_SupplierFacilitySharing {
  private Map<Id, List<Id>> userIdsByAccountId;
  private Map<Id, List<Id>> adminUserIdsByAccountId;

  public List<AccountShare> accountSharesToInsert;

  public TC_SupplierFacilitySharing(
    Map<Id, List<Id>> userIdsByAccountId,
    Map<Id, List<Id>> adminUserIdsByAccountId
  ) {
    this.userIdsByAccountId = userIdsByAccountId;
    this.adminUserIdsByAccountId = adminUserIdsByAccountId;
    if (this.userIdsByAccountId != null) {
      this.accountSharesToInsert = createAccountShares();
    }
  }

  private List<AccountShare> createAccountShares() {
    Set<Id> parentAccountIds = userIdsByAccountId.keySet();

    // Get all suppliers with their child facilities
    List<Account> accountsAndChildren = [
      SELECT
        Id,
        (
          SELECT
            Is_ToxClear_Account__c,
            ToxClear_Subscription_Status__c,
            ToxClear_Account_Type__c
          FROM ChildAccounts
        )
      FROM Account
      WHERE
        Id IN :parentAccountIds
        AND Is_ToxClear_Account__c = TRUE
        AND ToxClear_Subscription_Status__c = 'Active'
        AND ToxClear_Account_Type__c = 'Supplier'
    ];

    List<AccountShare> accountSharesToInsert = new List<AccountShare>();
    for (Account parent : accountsAndChildren) {
      for (Account child : parent.ChildAccounts) {
        if (
          child.Is_ToxClear_Account__c == true &&
          child.ToxClear_Subscription_Status__c == 'Active' &&
          child.ToxClear_Account_Type__c == 'Facility'
        ) {
          for (Id uId : userIdsByAccountId.get(parent.Id)) {
            if (
              adminUserIdsByAccountId.get(parent.Id) != null &&
              adminUserIdsByAccountId.get(parent.Id).contains(uId)
            ) {
              AccountShare share = new AccountShare(
                AccountId = child.Id,
                UserOrGroupId = uId,
                AccountAccessLevel = 'Edit',
                RowCause = 'Manual',
                OpportunityAccessLevel = 'None'
              );
              accountSharesToInsert.add(share);
            } else {
              AccountShare share = new AccountShare(
                AccountId = child.Id,
                UserOrGroupId = uId,
                AccountAccessLevel = 'Read',
                RowCause = 'Manual',
                OpportunityAccessLevel = 'None'
              );
              accountSharesToInsert.add(share);
            }
          }
        }
      }
    }
    return accountSharesToInsert;
  }
}