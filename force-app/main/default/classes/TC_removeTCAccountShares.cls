/*
 * Class finds all AccountShare objects for the Users which relate to TC Accounts
 */
public without sharing class TC_removeTCAccountShares {
  private List<Id> userIds;
  private Boolean getReadOnly;
  private Boolean getEdit;

  public List<AccountShare> accountSharesToDelete;

  public TC_removeTCAccountShares(
    List<Id> userIds,
    Boolean getReadOnly,
    Boolean getEdit
  ) {
    this.userIds = userIds;
    this.getReadOnly = getReadOnly;
    this.getEdit = getEdit;

    if (this.userIds != null) {
      this.accountSharesToDelete = getAccountSharesToDelete();
    }
  }

  private List<AccountShare> getAccountSharesToDelete() {
    String queryString = 'SELECT AccountId, UserOrGroupId, AccountAccessLevel, RowCause FROM AccountShare WHERE UserOrGroupId IN :userIds AND Account.Is_ToxClear_Account__c = TRUE AND RowCause = \'Manual\'';

    if (this.getReadOnly && this.getEdit) {
      queryString += ' AND (AccountAccessLevel = \'Read\' OR AccountAccessLevel = \'Edit\')';
    } else if (this.getReadOnly) {
      queryString += 'AND AccountAccessLevel = \'Read\'';
    } else if (this.getEdit) {
      queryString += ' AND AccountAccessLevel = \'Edit\'';
    } else {
      return new List<AccountShare>();
    }

    return Database.query(queryString);
  }
}