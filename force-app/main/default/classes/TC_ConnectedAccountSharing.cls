/*
 * Deals with sharing read access to accounts based on Brand Supplier Connection Records
 * Brands should be able to read details of Suppliers they hold an approved connection with and vice versa
 */
public without sharing class TC_ConnectedAccountSharing {
  private List<Brand_Supplier_Connection__c> connections;
  private Map<Id, List<Id>> userIdsByAccountId;
  private Set<Id> supplierIds;

  public List<AccountShare> accountSharesToInsert;

  public TC_ConnectedAccountSharing(
    List<Brand_Supplier_Connection__c> connections,
    Map<Id, List<Id>> userIdsByAccountId
  ) {
    this.connections = connections;
    this.userIdsByAccountId = userIdsByAccountId;

    if (this.userIdsByAccountId != null && this.connections != null) {
      this.accountSharesToInsert = createAccountShares();
    }
  }

  private List<AccountShare> createAccountShares() {
    List<AccountShare> newShares = new List<AccountShare>();
    Map<Id, List<Id>> brandUserIdsByConnectedSupplierId = new Map<Id, List<Id>>();

    // loop through all Active Approved connections
    for (Brand_Supplier_Connection__c connection : this.connections) {
      if (connection.Active__c && connection.Status__c == 'Approved') {
        // if the supplier account is in the account and users map then grant them read access to the brand account
        if (
          this.userIdsByAccountId.get(connection.Supplier_Account__c) != null
        ) {
          for (
            Id suppId : this.userIdsByAccountId.get(
              connection.Supplier_Account__c
            )
          ) {
            newShares.add(
              new AccountShare(
                AccountId = connection.Brand_Account__c,
                UserOrGroupId = suppId,
                AccountAccessLevel = 'Read',
                RowCause = 'Manual',
                OpportunityAccessLevel = 'None'
              )
            );
          }
        }

        if (this.userIdsByAccountId.get(connection.Brand_Account__c) != null) {
          for (
            Id brandId : this.userIdsByAccountId.get(
              connection.Brand_Account__c
            )
          ) {
            // grant the brand users read access to the supplier account
            newShares.add(
              new AccountShare(
                AccountId = connection.Supplier_Account__c,
                UserOrGroupId = brandId,
                AccountAccessLevel = 'Read',
                RowCause = 'Manual',
                OpportunityAccessLevel = 'None'
              )
            );
          }
          // create a map of supplier account to brand users with an active approved connection
          if (
            brandUserIdsByConnectedSupplierId.get(
              connection.Supplier_Account__c
            ) != null
          ) {
            brandUserIdsByConnectedSupplierId.get(
                connection.Supplier_Account__c
              )
              .addAll(this.userIdsByAccountId.get(connection.Brand_Account__c));
          } else {
            brandUserIdsByConnectedSupplierId.put(
              connection.Supplier_Account__c,
              this.userIdsByAccountId.get(connection.Brand_Account__c)
            );
          }
        }
      }
    }

    // use the supplierFacilitySharing logic to create shares for read access on the correct facilities to the brands
    TC_SupplierFacilitySharing supplierFacilitySharing = new TC_SupplierFacilitySharing(
      brandUserIdsByConnectedSupplierId,
      new Map<Id, List<Id>>()
    );

    newShares.addAll(supplierFacilitySharing?.accountSharesToInsert);
    return newShares;
  }
}