/*
 * Deals with sharing read/write access for users to their own accounts if they are admins
 */
public without sharing class TC_AdminAccountSharing {
  private Map<Id, List<Id>> userIdsByAccountId;
  public List<AccountShare> accountSharesToInsert;

  public TC_AdminAccountSharing(Map<Id, List<Id>> userIdsByAccountId) {
    this.userIdsByAccountId = userIdsByAccountId;

    if (this.userIdsByAccountId != null) {
      this.accountSharesToInsert = createAccountShares();
    }
  }

  private List<AccountShare> createAccountShares() {
    List<AccountShare> newShares = new List<AccountShare>();

    for (Id accountId : userIdsByAccountId.keySet()) {
      for (Id userId : userIdsByAccountId.get(accountId)) {
        newShares.add(
          new AccountShare(
            AccountId = accountId,
            UserOrGroupId = userId,
            AccountAccessLevel = 'Edit',
            RowCause = 'Manual',
            OpportunityAccessLevel = 'None'
          )
        );
      }
    }

    return newShares;
  }
}