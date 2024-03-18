// Utility methods to deal with the Account record
public with sharing class AccountUtil {
  // when a contact's role is set to CGA for the Account
  public static void replaceCGA(
    List<AccountContactRelation> acrs,
    Map<Id, AccountContactRelation> oldAcrs
  ) {
    Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
    Map<Id, Id> accountId2cgaId = new Map<Id, Id>();
    Map<Id, Id> accountId2priorCgaId = new Map<Id, Id>();

    for (AccountContactRelation acr : acrs) {
      Boolean isCGA = (acr.MTC_Role__c == 'CGA');
      Boolean wasCGA = (oldAcrs.containsKey(acr.Id) &&
      oldAcrs.get(acr.Id).MTC_Role__c == 'CGA');

      if (isCGA && !wasCGA) {
        accountsToUpdate.put(acr.AccountId, null);
        accountId2cgaId.put(acr.AccountId, acr.ContactId);
      } else if (!isCGA && wasCGA) {
        accountsToUpdate.put(acr.AccountId, null);
        accountId2priorCgaId.put(acr.AccountId, acr.ContactId);
      }
    }
    if (!accountsToUpdate.isEmpty()) {
      Set<String> accIdconIds = new Set<String>();
      accountsToUpdate = new Map<Id, Account>(
        [
          SELECT Name, CGA_Id__c
          FROM Account
          WHERE Id IN :accountsToUpdate.keySet()
        ]
      );
      for (Account acc : accountsToUpdate.values()) {
        if (accountId2cgaId.containsKey(acc.Id)) {
          if (acc.CGA_Id__c != null) {
            accIdconIds.add(acc.Id + '-' + acc.CGA_Id__c);
          }
          acc.CGA_Id__c = accountId2cgaId.get(acc.Id);
        } else {
          // Demotion scenario
          if (
            accountId2priorCgaId.containsKey(acc.Id) &&
            acc.CGA_Id__c == accountId2priorCgaId.get(acc.Id)
          ) {
            acc.CGA_Id__c = null;
          }
        }
      }

      WithoutSharing.updateRecords(accountsToUpdate.values());
      // update acr role for demoted CGAs
      AccountRelationUtil.demotePreviousCGAtoReadOnly(
        accIdconIds,
        oldAcrs.keySet()
      );
    }
  }

  public static void onAccountDeactivated(
    List<Account> accounts,
    Map<Id, Account> oldValues
  ) {
    Map<Id, Account> accountsToggled = new Map<Id, Account>();
    for (Account acc : accounts) {
      Account oldValue = oldValues.get(acc.Id);
      if (
        acc.Is_Account_Deactivated__c &&
        oldValue.Is_Account_Deactivated__c != acc.Is_Account_Deactivated__c
      ) {
        accountsToggled.put(acc.Id, acc);
      }
    }
    if (!accountsToggled.isEmpty()) {
      AccountRelationUtil.accountDeactivatedPrefixRole(accountsToggled);
      MTCUserUtil.deactivateUsersAccountDeactivated(accountsToggled.keySet());
    }
  }
}