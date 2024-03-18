/*
 * Deals with sharing edit access to Brand Supplier Connection Records
 * Brands and Suppliers should be able to edit any connection record they're named on
 */
public without sharing class TC_ConnectionSharing {
  private List<Brand_Supplier_Connection__c> connections;
  private Map<Id, List<Id>> userIdsByAccountId;
  private Map<Id, List<Id>> facilityUserIdsByAccountId;

  public List<Brand_Supplier_Connection__Share> connectionSharesToInsert;

  public TC_ConnectionSharing(
    List<Brand_Supplier_Connection__c> connections,
    Map<Id, List<Id>> userIdsByAccountId
  ) {
    this.connections = connections;
    this.userIdsByAccountId = userIdsByAccountId;
    if (this.userIdsByAccountId != null) {
      this.connectionSharesToInsert = createConnectionShares();
    }
  }

  public TC_ConnectionSharing(
    List<Brand_Supplier_Connection__c> connections,
    Map<Id, List<Id>> userIdsByAccountId,
    Map<Id, List<Id>> facilityUserIdsByAccountId
  ) {
    this.connections = connections;
    this.userIdsByAccountId = userIdsByAccountId;
    this.facilityUserIdsByAccountId = facilityUserIdsByAccountId;
    if (
      this.userIdsByAccountId != null ||
      this.facilityUserIdsByAccountId != null
    ) {
      this.connectionSharesToInsert = createConnectionShares();
    }
  }

  private List<Brand_Supplier_Connection__Share> createConnectionShares() {
    List<Brand_Supplier_Connection__Share> newShares = new List<Brand_Supplier_Connection__Share>();

    for (Brand_Supplier_Connection__c connection : this.connections) {
      List<Id> userIdsToAdd = new List<Id>();
      if (this.userIdsByAccountId != null) {
        if (this.userIdsByAccountId.get(connection.Brand_Account__c) != null) {
          userIdsToAdd.addAll(
            this.userIdsByAccountId.get(connection.Brand_Account__c)
          );
        }
        if (
          this.userIdsByAccountId.get(connection.Supplier_Account__c) != null
        ) {
          userIdsToAdd.addAll(
            this.userIdsByAccountId.get(connection.Supplier_Account__c)
          );
        }
      }

      if (
        this.facilityUserIdsByAccountId != null &&
        connection.Status__c == 'Approved' &&
        connection.Active__c
      ) {
        if (
          this.facilityUserIdsByAccountId.get(connection.Supplier_Account__c) !=
          null
        ) {
          userIdsToAdd.addAll(
            this.facilityUserIdsByAccountId.get(connection.Supplier_Account__c)
          );
        }
      }

      for (Id userIdToAdd : userIdsToAdd) {
        Brand_Supplier_Connection__Share share = new Brand_Supplier_Connection__Share(
          ParentId = connection.Id,
          AccessLevel = 'Edit',
          RowCause = 'Manual',
          UserOrGroupId = userIdToAdd
        );
        newShares.add(share);
      }
    }

    return newShares;
  }
}