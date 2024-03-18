public with sharing class GroupAccessUtil {
  // facility to disable report access sharing calculations

  @testVisible
  private static Boolean sharingProcessingDisabled = ('' +
    Label.MTC_System_Disable_Sharing_Processing)
    .equalsIgnoreCase('true');

  private static Boolean systemFlagSharingProcessingDisabled = ('' +
    Label.MTC_System_Disable_Sharing_Processing)
    .equalsIgnoreCase('true');

  public static void disableSharingProcessing() {
    GroupAccessUtil.sharingProcessingDisabled = true;
  }
  public static void enableSharingProcessing() {
    GroupAccessUtil.sharingProcessingDisabled =
      false || systemFlagSharingProcessingDisabled;
  }

  // when a new contact group is created
  public static void newContactGroup(Map<Id, Contact_Group__c> contactGroups) {
    if (sharingProcessingDisabled) {
      return;
    }
    calculateAccess(contactGroups);
  }

  public static void newAccountRelation(
    List<AccountContactRelation> acrs,
    Map<Id, AccountContactRelation> oldValues
  ) {
    if (sharingProcessingDisabled || acrs.isEmpty()) {
      return;
    }
    Set<Id> accountIds = new Set<Id>();
    for (AccountContactRelation acr : acrs) {
      String priorValue = '';
      String newValue = acr.MTC_Role__c;
      if (oldValues.containsKey(acr.Id)) {
        priorValue = oldValues.get(acr.Id).MTC_Role__c;
      }
      if (priorValue != newValue) {
        if (priorValue == 'admin' || newValue == 'admin') {
          accountIds.add(acr.AccountId);
        }
      }
    }

    if (!accountIds.isEmpty()) {
      Map<Id, Contact_Group__c> contactGroups = ContactGroupUtil.getContactGroupsForAccounts(
        accountIds
      );
      calculateAccess(contactGroups);
    }
  }

  public static void newUser(List<User> users) {
    if (users.isEmpty()) {
      return;
    }
    Set<Id> contactIds = new Set<Id>();
    for (User u : users) {
      if (u.Contactid != null) {
        contactIds.add(u.Contactid);
      }
    }
    newAccountRelation(
      AccountRelationUtil.getMTCACRsForContactIds(contactIds),
      new Map<Id, AccountContactRelation>()
    );
  }
  public static void calculateAccess(Map<Id, Contact_Group__c> contactGroups) {
    Map<Id, Set<Id>> accountId2cgId = new Map<Id, Set<Id>>();
    for (Contact_Group__c cg : contactGroups.values()) {
      if (!accountId2cgId.containsKey(cg.Account__c)) {
        accountId2cgId.put(cg.Account__c, new Set<Id>());
      }
      accountId2cgId.get(cg.Account__c).add(cg.Id);
    }
    List<AccountContactRelation> adminACRsForCGs = AccountRelationUtil.getAdminACRsForAccountIds(
      accountId2cgId.keySet()
    );
    Map<Id, Map<Id, AccountContactRelation>> conId2AccountId2ACR = AccountRelationUtil.buildCon2AccACRMap(
      adminACRsForCGs
    );
    Map<Id, Id> contactId2UserId = MTCUserUtil.getConId2UserId(
      conId2AccountId2ACR.keySet()
    );

    Set<String> sharingToEstablish = new Set<String>();

    for (Id userEnabledContactId : contactId2UserId.keySet()) {
      Id userId = contactId2UserId.get(userEnabledContactId);
      for (
        Id accountId : conId2AccountId2ACR.get(userEnabledContactId).keySet()
      ) {
        for (Id cgId : accountId2cgId.get(accountId)) {
          sharingToEstablish.add(buildKey(cgId, userId));
        }
      }
    }
    if (!sharingToEstablish.isEmpty()) {
      createSharingRecords(sharingToEstablish);
    }

    removeExpiredSharingRecords(contactGroups.keySet(), sharingToEstablish);
  }

  public static void removeExpiredSharingRecords(
    Set<Id> cgIds,
    Set<String> keysToKeep
  ) {
    Map<Id, Contact_Group__Share> shareRecords = getShareRecsForContactGroups(
      cgIds
    );
    Map<String, Contact_Group__Share> cgUserKeys2CGShare = new Map<String, Contact_Group__Share>();
    for (Contact_Group__Share cgShr : shareRecords.values()) {
      cgUserKeys2CGShare.put(
        buildKey(cgShr.ParentId, cgShr.UserOrGroupId),
        cgShr
      );
    }

    Set<String> reportUserKeysToRemove = cgUserKeys2CGShare.keySet();
    reportUserKeysToRemove.removeAll(keysToKeep);

    List<Contact_Group__Share> cgSharesToRemove = new List<Contact_Group__Share>();

    for (String ruk : reportUserKeysToRemove) {
      cgSharesToRemove.add(cgUserKeys2CGShare.get(ruk));
    }
    DeleteCGShares.removeExpiredSharingRecordsExtended(cgSharesToRemove);
  }
  public static Map<Id, Contact_Group__Share> getShareRecsForContactGroups(
    Set<Id> cgIds
  ) {
    return new Map<Id, Contact_Group__Share>(
      [
        SELECT Id, UserOrGroupId, ParentId
        FROM Contact_Group__Share
        WHERE ParentId IN :cgIds AND RowCause = 'Manual'
      ]
    );
  }

  public static void createSharingRecords(Set<String> groupUserKeys) {
    List<Contact_Group__Share> sharesToCreate = new List<Contact_Group__Share>();
    for (String groupUserKey : groupUserKeys) {
      Id cgId = groupUserKey.substringBefore('-');
      Id userId = groupUserKey.substringAfter('-');
      sharesToCreate.add(
        new Contact_Group__Share(
          ParentId = cgId,
          UserOrGroupId = userId,
          AccessLevel = 'Edit',
          RowCause = 'Manual'
        )
      );
    }
    Database.insert(sharesToCreate, false);
  }

  // builds the composite key to track user entitlement to asset
  public static String buildKey(String what, String who) {
    return what + '-' + who;
  }
}