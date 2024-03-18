/*******************************************************************************************
 * @author       Globant
 * @description  Helper class to handle sharing logic between Users and Accounts
 * @date         8-March-2024
 *******************************************************************************************/
public with sharing class GTSAccountHistorySharingHelper {
  /**
   * @description method to share the Related Account with the users related to Parent account
   * @param newAccountRelationshipHistoryToProcess
   * @param permissionSets
   */
  public static void shareAccounts(
    List<GTS_Account_Relationship_History__c> newAccountRelationshipHistoryToProcess,
    List<PermissionSetGroup> permissionSets
  ) {
    Map<Id, List<Id>> exportersWithRelatedAccountsIds = getExportersWithAssociatedAccounts(
      newAccountRelationshipHistoryToProcess
    );

    List<User> usersToShareWith = getUsers(
      exportersWithRelatedAccountsIds.keySet(),
      permissionSets
    );
    Map<Id, List<User>> accountIdsWithGroupManagers = GTSJobSharingHelper.getUsersByAccountId(
      usersToShareWith
    );

    List<AccountShare> accountShares = new List<AccountShare>();
    for (Id exporterId : exportersWithRelatedAccountsIds.keySet()) {
      List<User> relatedUsers = accountIdsWithGroupManagers.get(exporterId);
      if (relatedUsers != null) {
        for (User relatedUser : relatedUsers) {
          for (Id accountId : exportersWithRelatedAccountsIds.get(exporterId)) {
            accountShares.add(constructShareRecord(accountId, relatedUser.Id));
          }
        }
      }
    }
    List<Database.SaveResult> saveResults = Database.insert(
      accountShares,
      false
    );

    GTSLogErrors.logDatabaseOperationErrors(saveResults);
  }
  /**
   * @description Method to recalculate AccountSharing
   * @param accountRelationshipHistoriesToProcess
   * @param permissionSets
   */
  public static void recalculateAccountRecordsSharingWithUsers(
    List<GTS_Account_Relationship_History__c> accountRelationshipHistoriesToProcess,
    List<PermissionSetGroup> permissionSets
  ) {
    Set<Id> parentAccountsIds = new Set<Id>();
    Set<Id> associatedAccountsIds = new Set<Id>();

    for (
      GTS_Account_Relationship_History__c accountRelationshipHistory : accountRelationshipHistoriesToProcess
    ) {
      parentAccountsIds.add(accountRelationshipHistory.GTS_Account__c);
      associatedAccountsIds.add(
        accountRelationshipHistory.GTS_Associated_Account__c
      );
    }

    Map<Id, List<Id>> relationshipsToDelete = getRelationshipsToDelete(
      parentAccountsIds,
      associatedAccountsIds,
      accountRelationshipHistoriesToProcess
    );

    List<User> usersToShareWith = getUsers(
      relationshipsToDelete.keySet(),
      permissionSets
    );
    Map<Id, List<User>> accountIdsWithUsers = GTSJobSharingHelper.getUsersByAccountId(
      usersToShareWith
    );

    Map<Id, List<AccountShare>> usersWithAssociatedAccounts = getUsersWithAssociatedAccounts(
      usersToShareWith,
      associatedAccountsIds
    );

    List<AccountShare> accountSharesToDelete = new List<AccountShare>();
    for (Id accountId : relationshipsToDelete.keySet()) {
      List<User> relatedUsers = accountIdsWithUsers.get(accountId);
      for (User relatedUser : relatedUsers) {
        List<AccountShare> relatedAccountShares = usersWithAssociatedAccounts.get(
          relatedUser.Id
        );
        for (AccountShare accountShare : relatedAccountShares) {
          if (relatedUser.AccountId != accountShare.AccountId) {
            if (
              relationshipsToDelete.get(accountId)
                .contains(accountShare.AccountId)
            ) {
              accountSharesToDelete.add(accountShare);
            }
          }
        }
      }
    }
    if (!accountSharesToDelete.isEmpty()) {
      if (AccountShare.sObjectType.getDescribe().isDeletable()) {
        delete accountSharesToDelete;
      }
    }
  }
  /**
   * @description Recalculate AccountSharing for the new GTS_Account_Relationship_History__c records
   * @param accountRelationshipHistoriesToProcess
   * @param oldAccountRelationshipHistoriesToProcess
   * @param permissionSets
   */
  public static void updateAccountRecordsSharingWithUsers(
    List<GTS_Account_Relationship_History__c> accountRelationshipHistoriesToProcess,
    List<GTS_Account_Relationship_History__c> oldAccountRelationshipHistoriesToProcess,
    List<PermissionSetGroup> permissionSets
  ) {
    if (!accountRelationshipHistoriesToProcess.isEmpty()) {
      shareAccounts(accountRelationshipHistoriesToProcess, permissionSets);
    }
    if (!oldAccountRelationshipHistoriesToProcess.isEmpty()) {
      recalculateAccountRecordsSharingWithUsers(
        oldAccountRelationshipHistoriesToProcess,
        permissionSets
      );
    }
  }
  /**
   * @description Share Related accounts with new users related to Parent Account
   * @param usersToProcessIds
   */
  public static void shareWithNewUsers(List<Id> usersToProcessIds) {
    List<User> usersToProcess = [
      SELECT Id, AccountId
      FROM User
      WHERE Id IN :usersToProcessIds
      WITH SECURITY_ENFORCED
    ];
    Map<Id, List<User>> accountIdsWithUsers = GTSJobSharingHelper.getUsersByAccountId(
      usersToProcess
    );
    Map<Id, List<Id>> exportersWithAssociatedAccounts = getExportersWithAssociatedAccounts(
      accountIdsWithUsers.keySet()
    );

    List<AccountShare> accountShares = new List<AccountShare>();
    for (Id exporterId : accountIdsWithUsers.keySet()) {
      List<User> users = accountIdsWithUsers.get(exporterId);
      List<Id> relatedAccounts = exportersWithAssociatedAccounts.get(
        exporterId
      );
      if (relatedAccounts != null) {
        for (User userRecord : users) {
          for (Id relatedAccountId : relatedAccounts) {
            accountShares.add(
              constructShareRecord(relatedAccountId, userRecord.Id)
            );
          }
        }
      }
    }
    List<Database.SaveResult> saveResults = Database.insert(
      accountShares,
      false
    );

    GTSLogErrors.logDatabaseOperationErrors(saveResults);
  }
  /**
   * @description Map Associated Accounts by Parent Account
   * @param parentAccountsIds
   * @param associatedAccountsIds
   * @param accountRelationshipHistoriesToProcess
   *
   * @return Map with Associated Accounts grouped by Parent Account
   */
  public static Map<Id, List<Id>> getRelationshipsToDelete(
    Set<Id> parentAccountsIds,
    Set<Id> associatedAccountsIds,
    List<GTS_Account_Relationship_History__c> accountRelationshipHistoriesToProcess
  ) {
    List<GTS_Account_Relationship_History__c> existingAccountRelationshipHistory = [
      SELECT Id, GTS_Account__c, GTS_Associated_Account__c
      FROM GTS_Account_Relationship_History__c
      WHERE
        GTS_Account__c IN :parentAccountsIds
        AND Id IN :associatedAccountsIds
      WITH SECURITY_ENFORCED
    ];
    Map<Id, List<Id>> exportersWithRelatedAccounts = getExportersWithAssociatedAccounts(
      existingAccountRelationshipHistory
    );

    Map<Id, List<Id>> relationshipsToDelete = new Map<Id, List<Id>>();

    for (
      GTS_Account_Relationship_History__c accountRelationshipHistory : accountRelationshipHistoriesToProcess
    ) {
      List<Id> associatedAccounts = exportersWithRelatedAccounts.get(
        accountRelationshipHistory.GTS_Account__c
      );

      if (
        associatedAccounts == null ||
        !associatedAccounts.contains(
          accountRelationshipHistory.GTS_Associated_Account__c
        )
      ) {
        if (
          relationshipsToDelete.containsKey(
            accountRelationshipHistory.GTS_Account__c
          )
        ) {
          relationshipsToDelete.get(accountRelationshipHistory.GTS_Account__c)
            .add(accountRelationshipHistory.GTS_Associated_Account__c);
        } else {
          relationshipsToDelete.put(
            accountRelationshipHistory.GTS_Account__c,
            new List<Id>{ accountRelationshipHistory.GTS_Associated_Account__c }
          );
        }
      }
    }
    return relationshipsToDelete;
  }
  /**
   * @description Map AccountShare by UserOrGroupId
   * @param usersToShareWith
   * @param associatedAccountsIds
   *
   * @return Map of AccountShare grouped by UserOrGroupId
   */
  public static Map<Id, List<AccountShare>> getUsersWithAssociatedAccounts(
    List<User> usersToShareWith,
    Set<Id> associatedAccountsIds
  ) {
    List<AccountShare> accountShares = [
      SELECT Id, UserOrGroupId, AccountId
      FROM AccountShare
      WHERE
        UserOrGroupId IN :usersToShareWith
        AND AccountId IN :associatedAccountsIds
      WITH SECURITY_ENFORCED
    ];

    Map<Id, List<AccountShare>> usersWithAssociatedAccounts = new Map<Id, List<AccountShare>>();
    for (AccountShare accountShare : accountShares) {
      if (usersWithAssociatedAccounts.containsKey(accountShare.UserOrGroupId)) {
        usersWithAssociatedAccounts.get(accountShare.UserOrGroupId)
          .add(accountShare);
      } else {
        usersWithAssociatedAccounts.put(
          accountShare.UserOrGroupId,
          new List<AccountShare>{ accountShare }
        );
      }
    }
    return usersWithAssociatedAccounts;
  }
  /**
   * @description Map Associated Accounts by Parent Account
   * @param accountRelationshipHistories
   *
   * @return  Map of Associated Accounts grouped by Parent Account
   */
  public static Map<Id, List<Id>> getExportersWithAssociatedAccounts(
    List<GTS_Account_Relationship_History__c> accountRelationshipHistories
  ) {
    Map<Id, List<Id>> exportersWithAssociatedAccounts = new Map<Id, List<Id>>();
    for (
      GTS_Account_Relationship_History__c accountRelationshipHistory : accountRelationshipHistories
    ) {
      if (
        exportersWithAssociatedAccounts.containsKey(
          accountRelationshipHistory.GTS_Account__c
        )
      ) {
        exportersWithAssociatedAccounts.get(
            accountRelationshipHistory.GTS_Account__c
          )
          .add(accountRelationshipHistory.GTS_Associated_Account__c);
      } else {
        exportersWithAssociatedAccounts.put(
          accountRelationshipHistory.GTS_Account__c,
          new List<Id>{ accountRelationshipHistory.GTS_Associated_Account__c }
        );
      }
    }
    return exportersWithAssociatedAccounts;
  }
  /**
   * @description Map Associated Accounts by Parent Account
   * @param exporterIds
   *
   * @return Map of Associated Accounts grouped by Parent Account
   */
  public static Map<Id, List<Id>> getExportersWithAssociatedAccounts(
    Set<Id> exporterIds
  ) {
    List<GTS_Account_Relationship_History__c> accountRelationshipHistories = [
      SELECT Id, GTS_Account__c, GTS_Associated_Account__c
      FROM GTS_Account_Relationship_History__c
      WHERE GTS_Account__c IN :exporterIds
      WITH SECURITY_ENFORCED
    ];
    Map<Id, List<Id>> exportersWithAssociatedAccounts = new Map<Id, List<Id>>();
    for (
      GTS_Account_Relationship_History__c accountRelationshipHistory : accountRelationshipHistories
    ) {
      if (
        exportersWithAssociatedAccounts.containsKey(
          accountRelationshipHistory.GTS_Account__c
        )
      ) {
        exportersWithAssociatedAccounts.get(
            accountRelationshipHistory.GTS_Account__c
          )
          .add(accountRelationshipHistory.GTS_Associated_Account__c);
      } else {
        exportersWithAssociatedAccounts.put(
          accountRelationshipHistory.GTS_Account__c,
          new List<Id>{ accountRelationshipHistory.GTS_Associated_Account__c }
        );
      }
    }
    return exportersWithAssociatedAccounts;
  }

  /**
   * @description Query Users based on ParentAccount and related PermissionSet
   * @param accountIds
   * @param permissionSets
   *
   * @return List of users
   */
  public static List<User> getUsers(
    Set<Id> accountIds,
    List<PermissionSetGroup> permissionSets
  ) {
    return [
      SELECT Id, AccountId
      FROM User
      WHERE
        AccountId IN :accountIds
        AND Id IN (
          SELECT AssigneeId
          FROM PermissionSetAssignment
          WHERE PermissionSetGroupId IN :permissionSets
        )
      WITH SECURITY_ENFORCED
    ];
  }
  /**
   * @description Create AccountShare
   * @param accountId
   * @param userId
   *
   * @return
   */
  public static AccountShare constructShareRecord(Id accountId, Id userId) {
    AccountShare shareRecord = new AccountShare();
    shareRecord.AccountAccessLevel = 'Read';
    shareRecord.AccountId = accountId;
    shareRecord.UserOrGroupId = userId;
    shareRecord.OpportunityAccessLevel = 'None';
    return shareRecord;
  }
}