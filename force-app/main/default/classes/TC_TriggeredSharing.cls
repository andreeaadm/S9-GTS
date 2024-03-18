public without sharing class TC_TriggeredSharing {
  /*
   * Triggered by a new or updated User
   * Connection and TC account shares for the Users are deleted first
   * Then the correct connection and TC account shares are added back in
   */
  public static void processNewOrUpdatedUsers(List<Id> allUserIds) {
    // select any inserted or updated ToxClear users
    List<User> toxUsers = [
      SELECT
        Id,
        Contact.AccountId,
        Contact.Account.ParentId,
        Contact.Account.ToxClear_Account_Type__c,
        Contact.ToxClear_User_Type__c
      FROM User
      WHERE
        Id IN :allUserIds
        AND IsActive = TRUE
        AND Contact.Account.Is_ToxClear_Account__c = TRUE
        AND Contact.Account.ToxClear_Subscription_Status__c = 'Active'
        AND (Contact.Account.ToxClear_Account_Type__c = 'Brand'
        OR Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        OR Contact.Account.ToxClear_Account_Type__c = 'Facility')
    ];

    if (toxUsers.size() > 0) {
      List<User> suppliersOnly = new List<User>();
      List<User> adminUsers = new List<User>();
      List<User> suppliersAndBrands = new List<User>();
      List<User> facilitiesOnly = new List<User>();
      for (User u : toxUsers) {
        if (u.Contact.Account.ToxClear_Account_Type__c == 'Supplier') {
          suppliersOnly.add(u);
          suppliersAndBrands.add(u);
        } else if (u.Contact.Account.ToxClear_Account_Type__c == 'Brand') {
          suppliersAndBrands.add(u);
        } else if (u.Contact.Account.ToxClear_Account_Type__c == 'Facility') {
          facilitiesOnly.add(u);
        }

        if (
          u.Contact.ToxClear_User_Type__c == 'ToxClear Administrator' &&
          u.Contact.Account.ToxClear_Account_Type__c != 'Facility'
        ) {
          adminUsers.add(u);
        }
      }

      // do a full recalc of all sharing relating to the updated users
      recalcSharing(
        allUserIds,
        suppliersAndBrands,
        suppliersOnly,
        adminUsers,
        facilitiesOnly
      );
    }
  }

  /*
   * Triggered by a new or updated Connection
   * Connection shares are recalculated so all users can view their Connections
   * Account shares are recalculated as Brands can view their connected facilities
   */
  public static void processNewOrUpdatedConnections(
    List<Brand_Supplier_Connection__c> connections
  ) {
    // collate all the Supplier and Brand Account Ids on the connections
    List<Id> accountIdsToShare = new List<Id>();
    for (Brand_Supplier_Connection__c connection : connections) {
      accountIdsToShare.add(connection.Brand_Account__c);
      accountIdsToShare.add(connection.Supplier_Account__c);
    }

    // get all active Users associated with the Accounts above
    List<User> activeUsersWithAccounts = [
      SELECT
        Id,
        Contact.AccountId,
        Contact.Account.ParentId,
        Contact.ToxClear_User_Type__c,
        Contact.Account.ToxClear_Account_Type__c
      FROM User
      WHERE
        (Contact.AccountId IN :accountIdsToShare
        OR Contact.Account.ParentId IN :accountIdsToShare)
        AND IsActive = TRUE
        AND Contact.Account.Is_ToxClear_Account__c = TRUE
        AND Contact.Account.ToxClear_Subscription_Status__c = 'Active'
        AND (Contact.Account.ToxClear_Account_Type__c = 'Brand'
        OR Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        OR Contact.Account.ToxClear_Account_Type__c = 'Facility')
    ];

    if (activeUsersWithAccounts.size() > 0) {
      List<Id> allUserIds = new List<Id>();
      List<User> suppliersAndBrands = new List<User>();
      List<User> suppliersOnly = new List<User>();
      List<User> adminUsers = new List<User>();
      List<User> facilitiesOnly = new List<User>();
      for (User u : activeUsersWithAccounts) {
        allUserIds.add(u.Id);
        if (u.Contact.Account.ToxClear_Account_Type__c == 'Brand') {
          suppliersAndBrands.add(u);
        } else if (u.Contact.Account.ToxClear_Account_Type__c == 'Supplier') {
          suppliersAndBrands.add(u);
          suppliersOnly.add(u);
        } else if (u.Contact.Account.ToxClear_Account_Type__c == 'Facility') {
          facilitiesOnly.add(u);
        }

        if (
          u.Contact.ToxClear_User_Type__c == 'ToxClear Administrator' &&
          u.Contact.Account.ToxClear_Account_Type__c != 'Facility'
        ) {
          adminUsers.add(u);
        }
      }

      // do a full recalc of all sharing relating to the updated users
      recalcSharing(
        allUserIds,
        suppliersAndBrands,
        suppliersOnly,
        adminUsers,
        facilitiesOnly
      );
    }
  }

  /*
   * Triggered by a new or updated Account
   * Connection and TC account shares for the Users are deleted first
   * Then the correct connection and TC account shares are added back in
   */
  public static void processNewOrUpdatedAccounts(List<Account> accounts) {
    Set<Id> accountIds = new Set<Id>();
    for (Account a : accounts) {
      // facility users can affect their parent suppliers
      if (a.ToxClear_Account_Type__c == 'Facility') {
        accountIds.add(a.ParentId);
      }
      accountIds.add(a.Id);
    }

    // get all active Users associated with the updated/inserted accounts
    // only active Users matter because deactivated users have sharing revoked automatically
    List<User> activeUsersWithAccounts = [
      SELECT
        Id,
        Contact.AccountId,
        Contact.ToxClear_User_Type__c,
        Contact.Account.Is_ToxClear_Account__c,
        Contact.Account.ToxClear_Subscription_Status__c,
        Contact.Account.ToxClear_Account_Type__c,
        Contact.Account.ParentId
      FROM User
      WHERE IsActive = TRUE AND Contact.AccountId IN :accountIds
    ];

    if (activeUsersWithAccounts.size() > 0) {
      List<Id> allUserIds = new List<Id>();
      List<User> suppliersAndBrands = new List<User>();
      List<User> suppliersOnly = new List<User>();
      List<User> adminUsers = new List<User>();
      List<User> facilitiesOnly = new List<User>();
      for (User u : activeUsersWithAccounts) {
        allUserIds.add(u.Id);
        if (
          u.Contact.Account.Is_ToxClear_Account__c == true &&
          u.Contact.Account.ToxClear_Subscription_Status__c == 'Active'
        ) {
          if (u.Contact.Account.ToxClear_Account_Type__c == 'Brand') {
            suppliersAndBrands.add(u);
          } else if (u.Contact.Account.ToxClear_Account_Type__c == 'Supplier') {
            suppliersAndBrands.add(u);
            suppliersOnly.add(u);
          } else if (u.Contact.Account.ToxClear_Account_Type__c == 'Facility') {
            facilitiesOnly.add(u);
          }

          if (
            u.Contact.ToxClear_User_Type__c == 'ToxClear Administrator' &&
            u.Contact.Account.ToxClear_Account_Type__c != 'Facility'
          ) {
            adminUsers.add(u);
          }
        }
      }

      // do a full recalc of all sharing relating to the updated users
      recalcSharing(
        allUserIds,
        suppliersAndBrands,
        suppliersOnly,
        adminUsers,
        facilitiesOnly
      );
    }
  }

  /*
   * Triggered by and updated Contact
   * Deals with Account sharing to admin ToxClear users as this is controlled by the Contact
   */
  public static void processUpdatedContacts(List<Contact> contacts) {
    List<Id> contactIds = new List<Id>();
    for (Contact c : contacts) {
      contactIds.add(c.Id);
    }

    List<User> usersToUpdate = [
      SELECT Contact.ToxClear_User_Type__c, Contact.AccountId
      FROM User
      WHERE
        IsActive = TRUE
        AND Contact.Account.Is_ToxClear_Account__c = TRUE
        AND Contact.Account.ToxClear_Subscription_Status__c = 'Active'
        AND (Contact.Account.ToxClear_Account_Type__c = 'Brand'
        OR Contact.Account.ToxClear_Account_Type__c = 'Supplier')
        AND ContactId IN :contactIds
    ];

    if (usersToUpdate.size() > 0) {
      List<Id> stdUserIds = new List<Id>();
      List<User> adminUsers = new List<User>();
      for (User u : usersToUpdate) {
        if (u.Contact.ToxClear_User_Type__c == 'ToxClear Standard User') {
          stdUserIds.add(u.Id);
        } else if (
          u.Contact.ToxClear_User_Type__c == 'ToxClear Administrator'
        ) {
          adminUsers.add(u);
        }
      }

      Map<Id, List<Id>> adminUserIdsByAccountId = getUsersByAccountId(
        adminUsers,
        false
      );

      // get all TC sharing records with Edit access to be deleted
      TC_removeTCAccountShares accountRemoval = new TC_removeTCAccountShares(
        stdUserIds,
        false,
        true
      );
      // create sharing records for admin users to edit their own accounts
      TC_AdminAccountSharing adminAccountSharing = new TC_AdminAccountSharing(
        adminUserIdsByAccountId
      );
      // create sharing records for Suppliers to view/edit their associated Facilities
      TC_SupplierFacilitySharing supplierFacilitySharing = new TC_SupplierFacilitySharing(
        adminUserIdsByAccountId,
        adminUserIdsByAccountId
      );

      // collate all AccountShares
      List<AccountShare> totalAccountSharesToInsert = new List<AccountShare>();
      totalAccountSharesToInsert.addAll(
        adminAccountSharing?.accountSharesToInsert
      );
      totalAccountSharesToInsert.addAll(
        supplierFacilitySharing?.accountSharesToInsert
      );

      // recalc sharing records as async
      System.enqueueJob(
        new insertAndRemoveSharingQAble(
          null,
          null,
          totalAccountSharesToInsert,
          accountRemoval?.accountSharesToDelete
        )
      );
    }
  }

  // creates a map of Account Ids to a list of associated User Ids
  private static Map<Id, List<Id>> getUsersByAccountId(
    List<User> userList,
    Boolean useParentAccount
  ) {
    Map<Id, List<Id>> userIdsByAccountId = new Map<Id, List<Id>>();
    for (User u : userList) {
      if (useParentAccount) {
        if (userIdsByAccountId.get(u.Contact.Account.ParentId) != null) {
          userIdsByAccountId.get(u.Contact.Account.ParentId).add(u.Id);
        } else {
          userIdsByAccountId.put(
            u.Contact.Account.ParentId,
            new List<Id>{ u.Id }
          );
        }
      } else {
        if (userIdsByAccountId.get(u.Contact.AccountId) != null) {
          userIdsByAccountId.get(u.Contact.AccountId).add(u.Id);
        } else {
          userIdsByAccountId.put(u.Contact.AccountId, new List<Id>{ u.Id });
        }
      }
    }
    return userIdsByAccountId;
  }

  //handles duplicated logic for doing a full recalc of sharing for a given set of users
  private static void recalcSharing(
    List<Id> allUserIds,
    List<User> suppliersAndBrands,
    List<User> suppliersOnly,
    List<User> adminUsers,
    List<User> facilitiesOnly
  ) {
    // create maps of TC Account Id to a list of all associated User Ids
    Map<Id, List<Id>> supplierAndBrandIdsByAccountId = getUsersByAccountId(
      suppliersAndBrands,
      false
    );
    Map<Id, List<Id>> supplierIdsByAccountId = getUsersByAccountId(
      suppliersOnly,
      false
    );
    Map<Id, List<Id>> adminIdsByAccountId = getUsersByAccountId(
      adminUsers,
      false
    );
    Map<Id, List<Id>> facilityIdsByParentAccountId = getUsersByAccountId(
      facilitiesOnly,
      true
    );

    // get all connections with an inserted/updated User associated
    List<Brand_Supplier_Connection__c> connections = [
      SELECT Id, Brand_Account__c, Supplier_Account__c, Status__c, Active__c
      FROM Brand_Supplier_Connection__c
      WHERE
        Brand_Account__c IN :supplierAndBrandIdsByAccountId.keySet()
        OR Supplier_Account__c IN :supplierAndBrandIdsByAccountId.keySet()
        OR Supplier_Account__c IN :facilityIdsByParentAccountId.keySet()
    ];

    // get all TC sharing records to be deleted
    TC_removeTCAccountShares accountRemoval = new TC_removeTCAccountShares(
      allUserIds,
      true,
      true
    );
    // get all connection sharing record to be deleted
    TC_removeConnectionShares connectionRemoval = new TC_removeConnectionShares(
      allUserIds
    );
    // create sharing records for Tox users to read their Connections
    TC_ConnectionSharing connectionSharing = new TC_ConnectionSharing(
      connections,
      supplierAndBrandIdsByAccountId,
      facilityIdsByParentAccountId
    );
    // create sharing records for Brand/Supplier Users to read Accounts they have an approved Connection with
    TC_ConnectedAccountSharing accountSharing = new TC_ConnectedAccountSharing(
      connections,
      supplierAndBrandIdsByAccountId
    );
    // create sharing records for Suppliers to view/edit their associated Facilities
    TC_SupplierFacilitySharing supplierFacilitySharing = new TC_SupplierFacilitySharing(
      supplierIdsByAccountId,
      adminIdsByAccountId
    );
    // create sharing records for admin users to edit their own accounts
    TC_AdminAccountSharing adminAccountSharing = new TC_AdminAccountSharing(
      adminIdsByAccountId
    );

    // collate all AccountShares
    List<AccountShare> totalAccountSharesToInsert = new List<AccountShare>();
    totalAccountSharesToInsert.addAll(accountSharing?.accountSharesToInsert);
    totalAccountSharesToInsert.addAll(
      supplierFacilitySharing?.accountSharesToInsert
    );
    totalAccountSharesToInsert.addAll(
      adminAccountSharing?.accountSharesToInsert
    );

    // recalc sharing records as async
    System.enqueueJob(
      new insertAndRemoveSharingQAble(
        connectionSharing?.connectionSharesToInsert,
        connectionRemoval?.connectionSharesToDelete,
        totalAccountSharesToInsert,
        accountRemoval?.accountSharesToDelete
      )
    );
  }
}