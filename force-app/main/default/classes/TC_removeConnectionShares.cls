public without sharing class TC_removeConnectionShares {
  private List<Id> userIds;

  public List<Brand_Supplier_Connection__Share> connectionSharesToDelete;

  public TC_removeConnectionShares(List<Id> userIds) {
    this.userIds = userIds;

    if (this.userIds != null) {
      this.connectionSharesToDelete = getConnectionSharesToDelete();
    }
  }

  private List<Brand_Supplier_Connection__Share> getConnectionSharesToDelete() {
    return [
      SELECT Id
      FROM Brand_Supplier_Connection__Share
      WHERE UserOrGroupId IN :userIds AND RowCause = 'Manual'
    ];
  }
}