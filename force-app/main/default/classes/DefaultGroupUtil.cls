public with sharing class DefaultGroupUtil {
  private static Boolean defaultGroupCreationDisabled =
    !Test.isRunningTest() &&
    ('' + Label.MTC_System_DefaultGroup_Creation_Disabled)
      .equalsIgnoreCase('true');

  public static List<Contact_Group__c> createDefaultGroups(Set<Id> accountIds) {
    List<Contact_Group__c> result = new List<Contact_Group__c>();
    if (defaultGroupCreationDisabled) {
      return result;
    }
    for (Id accountId : accountIds) {
      result.add(
        new Contact_Group__c(
          Account__c = accountId,
          Group_Name__c = 'Default Group',
          Is_Default_Group__c = true
        )
      );
    }
    insert result;
    return result;
  }

  // returns a map AccountId => Default Contact Group when no *Active* Custom Groups exist
  public static Map<Id, Contact_Group__c> getDefaultGroupsForAccounts(
    Set<Id> accountIds
  ) {
    Map<Id, Contact_Group__c> result = new Map<Id, Contact_Group__c>();
    if (accountIds.isEmpty()) {
      return result;
    }

    Set<Id> seen = new Set<Id>();

    for (Contact_Group__c cg : [
      SELECT Id, Account__c, Group_Name__c, Is_Default_Group__c
      FROM Contact_Group__c
      WHERE Account__c IN :accountIds AND Has_Expired__c = FALSE
    ]) {
      if (result.containsKey(cg.Account__c)) {
        result.remove(cg.Account__c);
      } else if (!seen.contains(cg.Account__c) && cg.Is_Default_Group__c) {
        result.put(cg.Account__c, cg);
      }
      seen.add(cg.Account__c);
    }
    return result;
  }

  public static void newRelationshipAddToDefaultGroup(
    List<AccountContactRelation> acrs,
    Map<Id, AccountContactRelation> oldACRs
  ) {
    if (acrs.isEmpty()) {
      return;
    }
    List<Group_Membership__c> newMemberships = new List<Group_Membership__c>();
    Set<Id> accountIds = new Set<Id>();
    for (AccountContactRelation acr : acrs) {
      String previousRole = '';
      if (oldACRs.containsKey(acr.Id)) {
        previousRole = oldACRs.get(acr.Id).MTC_Role__c;
      }
      if (
        MTCUserUtil.isValidDefaultGroupRole(acr.MTC_Role__c) &&
        !MTCUserUtil.isValidDefaultGroupRole(previousRole)
      ) {
        accountIds.add(acr.AccountId);
      }
    }
    if (accountIds.isEmpty()) {
      return;
    }
    Map<Id, Contact_Group__c> defaultGroups = DefaultGroupUtil.getDefaultGroupsForAccounts(
      accountIds
    );

    for (AccountContactRelation acr : acrs) {
      if (
        defaultGroups.containsKey(acr.AccountId) &&
        MTCUserUtil.isValidDefaultGroupRole(acr.MTC_Role__c)
      ) {
        newMemberships.add(
          new Group_Membership__c(
            Contact_Group__c = defaultGroups.get(acr.AccountId).Id,
            Contact__c = acr.ContactId
          )
        );
      }
    }
    // Silently ignoring this as the membership already exists
    // Occurs when a contact goes from cga/admin/read-only => no-access/rejected => cga/admin/read-only
    // The membership entry still exists
    WithoutSharing.insertRecordsFailSilently(newMemberships);
  }

  public static void relationshipsMovingToNoAccess(
    List<AccountContactRelation> acrs,
    Map<Id, AccountContactRelation> oldACRs
  ) {
    if (acrs.isEmpty()) {
      return;
    }
    Map<Id, Set<Id>> conId2accIds = new Map<Id, Set<Id>>();
    for (AccountContactRelation acr : acrs) {
      String previousRole = '';
      if (oldACRs.containsKey(acr.Id)) {
        previousRole = oldACRs.get(acr.Id).MTC_Role__c;
      }
      if (acr.MTC_Role__c == 'no-access' && previousRole != 'no-access') {
        if (!conId2accIds.containsKey(acr.ContactId)) {
          conId2accIds.put(acr.ContactId, new Set<Id>{ acr.AccountId });
        } else {
          conId2accIds.get(acr.ContactId).add(acr.AccountId);
        }
      }
    }
    if (!conId2accIds.isEmpty()) {
      relationshipsDowngradedOrDeleted(conId2accIds);
    }
  }
  public static void relationshipsDeleted(List<AccountContactRelation> acrs) {
    Map<Id, Set<Id>> conId2accIds = new Map<Id, Set<Id>>();
    for (AccountContactRelation acr : acrs) {
      if (acr.MTC_Role__c != 'no-access') {
        // contact had some access
        if (!conId2accIds.containsKey(acr.ContactId)) {
          conId2accIds.put(acr.ContactId, new Set<Id>{ acr.AccountId });
        } else {
          conId2accIds.get(acr.ContactId).add(acr.AccountId);
        }
      }
    }
    if (!conId2accIds.isEmpty()) {
      relationshipsDowngradedOrDeleted(conId2accIds);
    }
  }
  // Delete membership records for contacts moved to no-access or where ACR record is deleted
  private static void relationshipsDowngradedOrDeleted(
    Map<Id, Set<Id>> conId2accIds
  ) {
    if (conId2accIds.isEmpty()) {
      return;
    }
    List<Group_Membership__c> membershipsToRemove = new List<Group_Membership__c>();
    List<Group_Membership__c> membershipsForContacts = ContactGroupUtil.getGroupMembershipsForContacts(
      conId2accIds.keySet()
    );
    for (Group_Membership__c membership : membershipsForContacts) {
      if (
        conId2accIds.get(membership.Contact__c)
          .contains(membership.Contact_Group__r.Account__c)
      ) {
        membershipsToRemove.add(membership);
      }
    }
    delete membershipsToRemove;
  }

  public static void newAssetAddToDefaultGroup(List<Asset> assets) {
    if (assets.isEmpty()) {
      return;
    }
    Set<Id> accountIds = new Set<Id>();
    List<Asset> reports = AssetUtil.filterReports(assets);
    for (Asset report : reports) {
      if (report.AccountId != null) {
        accountIds.add(report.AccountId);
      }
    }
    if (accountIds.isEmpty()) {
      return;
    }
    Map<Id, Contact_Group__c> defaultGroups = DefaultGroupUtil.getDefaultGroupsForAccounts(
      accountIds
    );
    List<Access__c> accessesToAdd = new List<Access__c>();
    for (Asset report : reports) {
      if (defaultGroups.containsKey(report.AccountId)) {
        accessesToAdd.add(
          new Access__c(
            Report_Asset__c = report.Id,
            Contact_Group__c = defaultGroups.get(report.AccountId).Id
          )
        );
      }
    }
    insert accessesToAdd;
  }
}