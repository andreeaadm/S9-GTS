public without sharing class UserAccessUtil {
  public static void createMissingUserShares(Set<Id> contactIds) {
    if (!contactIds.isEmpty()) {
      Map<Id, User> users = new Map<Id, User>(
        [
          SELECT Id, ContactId, AccountId
          FROM User
          WHERE ContactId IN :contactIds AND IsActive = TRUE
        ]
      );
      // start process to calculate access to these users
      if (!users.isEmpty()) {
        System.enqueueJob(new UserAccessCalcQAble(users));
      }
    }
  }
  public static void createMissingUserShares(
    List<AccountContactRelation> acrs
  ) {
    Set<Id> contactIds = new Set<Id>();
    for (AccountContactRelation acr : acrs) {
      contactIds.add(acr.ContactId);
    }
    createMissingUserShares(contactIds);
  }
  public static void createMissingUserShares(List<User> users) {
    List<User> activeUsers = new List<User>();
    for (User u : users) {
      if (u.IsActive) {
        activeUsers.add(u);
      }
    }
    if (!activeUsers.isEmpty()) {
      System.enqueueJob(new UserAccessCalcQAble(new Map<Id, User>(users)));
    }
  }

  public class UserTrack {
    Id userId;
    Id contactId;
    Id primaryAccountId;
    Set<Id> accountIds;
    UserTrack(Id userId, Id contactId, Id primaryAccountId) {
      this.userId = userId;
      this.contactId = contactId;
      this.primaryAccountId = primaryAccountId;
      accountIds = new Set<Id>();
    }
    public void addAccountId(Id accId) {
      accountIds.add(accId);
    }
  }

  public static void calculateAccess(Map<Id, User> users) {
    Map<Id, UserTrack> user2track = new Map<Id, UserTrack>();
    Map<Id, UserTrack> con2track = new Map<Id, UserTrack>();
    for (User user : users.values()) {
      UserTrack ut = new UserTrack(user.Id, user.ContactId, user.AccountId);
      user2track.put(user.Id, ut);
      con2track.put(user.ContactId, ut);
    }

    Set<Id> accountIds = new Set<Id>();
    for (AccountContactRelation acr : [
      SELECT AccountId, ContactId
      FROM AccountContactRelation
      WHERE
        ContactId IN :con2track.keySet()
        AND MTC_Role__c IN :MTCUserUtil.VALID_MTC_ROLES.keySet()
    ]) {
      accountIds.add(acr.AccountId);
      con2track.get(acr.ContactId).addAccountId(acr.AccountId);
    }
    Map<Id, Set<Id>> contactId2relatedAccounts = new Map<Id, Set<Id>>();
    // Holds all contacts for an account where MTC Role is valid
    Map<Id, Set<Id>> acc2contacts = new Map<Id, Set<Id>>();
    for (AccountContactRelation acr : [
      SELECT AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE AccountId IN :accountIds AND Account.Is_MTC_Account__c = TRUE
    ]) {
      Set<Id> accountsForContact = contactId2relatedAccounts.get(acr.ContactId);
      if (accountsForContact == null) {
        contactId2relatedAccounts.put(
          acr.ContactId,
          new Set<Id>{ acr.AccountId }
        );
      } else {
        accountsForContact.add(acr.AccountId);
      }

      Set<Id> contactIdsForAccount = acc2contacts.get(acr.AccountId);
      if (contactIdsForAccount == null) {
        acc2contacts.put(acr.AccountId, new Set<Id>{ acr.ContactId });
      } else {
        contactIdsForAccount.add(acr.ContactId);
      }
    }

    Map<Id, User> contactId2User = MTCUserUtil.getConId2User(
      contactId2relatedAccounts.keySet()
    );

    // for this user to *see* and *be seen* by the other users
    Set<String> sharesToCreate = new Set<String>();
    Set<String> accountSharesToCreate = new Set<String>();

    for (UserTrack ut : user2track.values()) {
      for (Id accId : ut.accountIds) {
        Set<Id> contactIdsForAccount = acc2contacts.get(accId);
        if (contactIdsForAccount != null) {
          for (Id contactId : contactIdsForAccount) {
            if (ut.ContactId != contactId) {
              Set<Id> accountsForContact = contactId2relatedAccounts.get(
                contactId
              );
              User relatedUser = contactId2User.get(contactId);
              if (relatedUser != null && relatedUser.isActive) {
                // to see
                sharesToCreate.add(buildKey(relatedUser.Id, ut.userId));
                // access to User's account required
                if (!ut.accountIds.contains(relatedUser.AccountId)) {
                  accountSharesToCreate.add(
                    buildKey(relatedUser.AccountId, ut.userId)
                  );
                }

                // to be seen
                sharesToCreate.add(buildKey(ut.userId, relatedUser.Id));
                // access to Account required to make ACRs and Contacts readable
                if (
                  accountsForContact != null &&
                  !accountsForContact.contains(ut.primaryAccountId)
                ) {
                  accountSharesToCreate.add(
                    buildKey(ut.primaryAccountId, relatedUser.Id)
                  );
                }
              }
            }
          }
        }
      }
    }

    if (!sharesToCreate.isEmpty()) {
      createSharingRecords(sharesToCreate);
    }
    System.debug(accountSharesToCreate);
    if (!accountSharesToCreate.isEmpty()) {
      createAccountSharingRecords(accountSharesToCreate);
    }
  }
  public static void createAccountSharingRecords(Set<String> observedUserKeys) {
    List<AccountShare> sharesToCreate = new List<AccountShare>();
    for (String a2u : observedUserKeys) {
      Id accId = a2u.substringBefore('-');
      Id userId = a2u.substringAfter('-');
      sharesToCreate.add(
        new AccountShare(
          AccountId = accId,
          UserOrGroupId = userId,
          AccountAccessLevel = 'Read',
          RowCause = 'Manual',
          CaseAccessLevel = 'None',
          OpportunityAccessLevel = 'None'
        )
      );
    }
    Database.SaveResult[] srList = Database.insert(sharesToCreate, false);

    // Iterate through each returned result
    for (Database.SaveResult sr : srList) {
      if (!sr.isSuccess()) {
        for (Database.Error err : sr.getErrors()) {
          System.debug('The following error has occurred.');
          System.debug(err.getStatusCode() + ': ' + err.getMessage());
          System.debug('Fields that affected this error: ' + err.getFields());
        }
      }
    }
  }
  public static void createSharingRecords(Set<String> observedUserKeys) {
    List<UserShare> sharesToCreate = new List<UserShare>();
    for (String u2u : observedUserKeys) {
      Id observedId = u2u.substringBefore('-');
      Id userId = u2u.substringAfter('-');
      sharesToCreate.add(
        new UserShare(
          UserId = observedId,
          UserOrGroupId = userId,
          UserAccessLevel = 'Read',
          RowCause = 'Manual'
        )
      );
    }

    Database.SaveResult[] srList = Database.insert(sharesToCreate, false);

    // Iterate through each returned result
    for (Database.SaveResult sr : srList) {
      if (!sr.isSuccess()) {
        for (Database.Error err : sr.getErrors()) {
          System.debug('The following error has occurred.');
          System.debug(err.getStatusCode() + ': ' + err.getMessage());
          System.debug('Fields that affected this error: ' + err.getFields());
        }
      }
    }
  }
  public static String buildKey(String observed, String viewer) {
    return observed + '-' + viewer;
  }
}