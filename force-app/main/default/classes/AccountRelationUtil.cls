public with sharing class AccountRelationUtil {
  private static Set<Id> relatedAccountIds;

  public static List<AccountContactRelation> filterMTCRoleChange(
    List<AccountContactRelation> acrs,
    Map<Id, AccountContactRelation> oldACRs
  ) {
    if (acrs.isEmpty()) {
      return new List<AccountContactRelation>();
    }
    List<AccountContactRelation> result = new List<AccountContactRelation>();

    for (AccountContactRelation acr : acrs) {
      String newRole = acr.MTC_Role__c;
      AccountContactRelation oldACR;
      String previousRole = '';
      if (oldACRs.containsKey(acr.Id)) {
        // modified relationship
        previousRole = oldACRs.get(acr.Id).MTC_Role__c;
      }

      if (newRole != previousRole) {
        if (
          MTCUserUtil.isValidMTCRole(newRole) ||
          MTCUserUtil.isValidMTCRole(previousRole)
        ) {
          result.add(acr);
        }
      }
    }
    return result;
  }
  public static List<AccountContactRelation> filterWithUserRecord(
    List<AccountContactRelation> acrs
  ) {
    if (acrs.isEmpty()) {
      return new List<AccountContactRelation>();
    }
    List<AccountContactRelation> result = new List<AccountContactRelation>();
    Set<Id> contactIds = new Set<Id>();

    for (AccountContactRelation acr : acrs) {
      contactIds.add(acr.contactId);
    }
    Set<Id> contactsWithUser = new Set<Id>();
    for (User u : MTCUserUtil.getUsersFromContactIds(contactIds)) {
      contactsWithUser.add(u.ContactId);
    }
    for (AccountContactRelation acr : acrs) {
      if (contactsWithUser.contains(acr.ContactId)) {
        result.add(acr);
      }
    }
    return result;
  }

  // will change the role to "restricted"
  // for existing restricted users, will recalculate expiry date
  public static void updateRoleWhenReportContact(
    List<Asset> newAssets,
    Map<Id, Asset> oldAssets
  ) {
    Set<String> accCon2ACR = new Set<String>();
    List<Asset> filteredReports = new List<Asset>();

    List<asset> reports = AssetUtil.filterDateless(
      AssetUtil.filterContactless(AssetUtil.filterReports(newAssets))
    );

    for (Asset report : reports) {
      if (oldAssets.containsKey(report.Id)) {
        if (
          oldAssets.get(report.Id).ContactId != report.ContactId ||
          oldAssets.get(report.Id).Date_Issued__c != report.Date_Issued__c ||
          oldAssets.get(report.Id).Date_Revised__c != report.Date_Revised__c
        ) {
          // Relevant change occured
          filteredReports.add(report);
        }
      } else {
        // New Report with ContactId
        filteredReports.add(report);
      }
    }

    if (filteredReports.isEmpty()) {
      return;
    }

    Set<Id> contactIds = new Set<Id>();
    for (Asset report : filteredReports) {
      accCon2ACR.add('' + report.AccountId + report.ContactId);
      contactIds.add(report.ContactId);
    }
    List<AccountContactRelation> acrs = [
      SELECT ContactId, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId IN :contactIds
    ];
    List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
    Set<Id> contactIdsToReview = new Set<Id>();
    for (AccountContactRelation acr : acrs) {
      if (
        acr.MTC_Role__c.equalsIgnoreCase('no-access') &&
        accCon2ACR.contains('' + acr.AccountId + acr.ContactId)
      ) {
        acrsToUpdate.add(
          new AccountContactRelation(Id = acr.Id, MTC_Role__c = 'Restricted')
        );
      } else if (
        acr.MTC_Role__c.equalsIgnoreCase('restricted') &&
        accCon2ACR.contains('' + acr.AccountId + acr.ContactId)
      ) {
        contactIdsToReview.add(acr.ContactId);
      }
    }
    if (!contactIdsToReview.isEmpty()) {
      // future method
      MTCUserUtil.createUpdateUsersForContacts(contactIdsToReview);
    }
    update acrsToUpdate;
  }

  public static void accountDeactivatedPrefixRole(
    Map<Id, Account> accountsDeactivated
  ) {
    List<AccountContactRelation> acrs = getACRsForAccountIds(
      accountsDeactivated.keySet()
    );
    List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();

    for (AccountContactRelation acr : acrs) {
      String role = acr.MTC_Role__c;
      if (
        !String.isEmpty(role) &&
        !role.equalsIgnoreCase('no-access') &&
        !role.left(2).equalsIgnoreCase('x.')
      ) {
        acrsToUpdate.add(
          new AccountContactRelation(Id = acr.Id, MTC_Role__c = 'x.' + role)
        );
      }
    }
    update acrsToUpdate;
  }

  public static List<AccountContactRelation> linkAccountToContacts(
    Id accountId,
    List<Contact> contacts,
    String role
  ) {
    List<AccountContactRelation> acrs = new List<AccountContactRelation>();
    for (Contact con : contacts) {
      acrs.add(
        new AccountContactRelation(
          AccountId = accountId,
          ContactId = con.Id,
          MTC_Role__c = role
        )
      );
    }
    insert acrs;
    return acrs;
  }
  public static List<AccountContactRelation> linkContactToAccounts(
    Id contactId,
    List<Account> accounts,
    String role
  ) {
    List<AccountContactRelation> acrs = new List<AccountContactRelation>();
    for (Account acc : accounts) {
      acrs.add(
        new AccountContactRelation(
          AccountId = acc.Id,
          ContactId = contactId,
          MTC_Role__c = role
        )
      );
    }
    Database.insert(acrs, true);
    return acrs;
  }
  // Builds { contactId => { accountId => ACR }}
  public static Map<Id, Map<Id, AccountContactRelation>> buildCon2AccACRMap(
    List<AccountContactRelation> acrs
  ) {
    Map<Id, Map<Id, AccountContactRelation>> conId2AccountId2ACR = new Map<Id, Map<Id, AccountContactRelation>>();
    for (AccountContactRelation acr : acrs) {
      if (!conId2AccountId2ACR.containsKey(acr.ContactId)) {
        conId2AccountId2ACR.put(
          acr.ContactId,
          new Map<Id, AccountContactRelation>()
        );
      }
      conId2AccountId2ACR.get(acr.ContactId).put(acr.AccountId, acr);
    }
    return conId2AccountId2ACR;
  }
  public static List<AccountContactRelation> getAdminACRsForAccountIds(
    Set<Id> accountIds
  ) {
    return getFilteredACRsForAccountIds(accountIds, new Set<String>{ 'Admin' });
  }

  public static List<AccountContactRelation> getFilteredACRsForAccountIds(
    Set<Id> accountIds,
    Set<String> roleFilter
  ) {
    if (roleFilter == null || roleFilter.isEmpty()) {
      return new List<AccountContactRelation>();
    }
    return [
      SELECT AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE AccountId IN :accountIds AND MTC_Role__c IN :roleFilter
    ];
  }

  public static List<AccountContactRelation> getACRsForAccountIds(
    Set<Id> accountIds
  ) {
    if (accountIds.isEmpty()) {
      return new List<AccountContactRelation>();
    }
    return [
      SELECT AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE AccountId IN :accountIds
    ];
  }

  public static List<AccountContactRelation> getMTCACRsForContactIds(
    Set<Id> contactIds
  ) {
    if (contactIds.isEmpty()) {
      return new List<AccountContactRelation>();
    }
    return [
      SELECT AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId IN :contactIds AND Account.Is_MTC_Account__c = TRUE
    ];
  }
  public static List<AccountContactRelation> getFilteredMTCACRsForContactIds(
    Set<Id> contactIds,
    Set<String> roleFilters
  ) {
    if (contactIds.isEmpty() || roleFilters.isEmpty()) {
      return new List<AccountContactRelation>();
    }
    return [
      SELECT AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE
        ContactId IN :contactIds
        AND Account.Is_MTC_Account__c = TRUE
        AND MTC_Role__c IN :roleFilters
    ];
  }

  // On Contacts added to Groups where the Accounts are different than their parent, ACRs are required if not pre-existing.
  public static void createACRsForContactsAddedToGroupsInAccountsDifferentThanParent(
    List<Group_Membership__c> newMembers,
    String roleToApply
  ) {
    Map<Id, Id> contactIdToAssociatedAccountIdMap = ContactGroupUtil.getAssociatedAccountIdsPerContactFromGroupMemberships(
      newMembers
    );
    Map<Id, Id> contactGroupToAccIdMap = ContactGroupUtil.getContactGroupIdsAndAssociatedAccountIdsFromGroupMemberships(
      newMembers
    );
    Map<Id, Set<Id>> contactIdToAccIdsRquiringACRs = new Map<Id, Set<Id>>();
    Set<Id> accIdsForSOQLFilter = new Set<Id>();
    for (Group_Membership__c gm : (LIST<Group_Membership__c>) Trigger.new) {
      if (
        contactIdToAssociatedAccountIdMap.get(gm.Contact__c) !=
        contactGroupToAccIdMap.get(gm.Contact_Group__c)
      ) {
        accIdsForSOQLFilter.add(
          contactGroupToAccIdMap.get(gm.Contact_Group__c)
        );
        if (contactIdToAccIdsRquiringACRs.get(gm.Contact__c) == null) {
          contactIdToAccIdsRquiringACRs.put(
            gm.Contact__c,
            new Set<Id>{ contactGroupToAccIdMap.get(gm.Contact_Group__c) }
          );
        } else {
          contactIdToAccIdsRquiringACRs.get(gm.Contact__c)
            .add(contactGroupToAccIdMap.get(gm.Contact_Group__c));
        }
      }
    }

    if (!contactIdToAccIdsRquiringACRs.isEmpty()) {
      contactIdToAccIdsRquiringACRs = filterContactsRequiringACRSPerAccountIfACRAlreadyExists(
        contactIdToAccIdsRquiringACRs,
        accIdsForSOQLFilter
      );

      if (!contactIdToAccIdsRquiringACRs.isEmpty()) {
        createACRsForUpToMultipleAccountsForSingleContacts(
          contactIdToAccIdsRquiringACRs,
          roleToApply
        );
      }
    }
  }

  public static Map<Id, Set<Id>> filterContactsRequiringACRSPerAccountIfACRAlreadyExists(
    Map<Id, Set<Id>> contactIdToAccIdsRquiringACR,
    Set<Id> accIdsForSOQLFilter
  ) {
    // Check if ACR's already exist for the contact on the asociated account. Exclude if pre-existing.
    for (AccountContactRelation acr : [
      SELECT AccountId, ContactId
      FROM AccountContactRelation
      WHERE
        ContactId IN :contactIdToAccIdsRquiringACR.keySet()
        AND AccountID IN :accIdsForSOQLFilter
    ]) {
      if (contactIdToAccIdsRquiringACR.get(acr.ContactId) != null) {
        if (
          contactIdToAccIdsRquiringACR.get(acr.ContactId)
            .contains(acr.AccountId)
        ) {
          contactIdToAccIdsRquiringACR.get(acr.ContactId).remove(acr.AccountId);
        }
        if (contactIdToAccIdsRquiringACR.get(acr.ContactId).isEmpty()) {
          contactIdToAccIdsRquiringACR.remove(acr.ContactId);
        }
      }
    }

    return contactIdToAccIdsRquiringACR;
  }

  public static void createACRsForUpToMultipleAccountsForSingleContacts(
    Map<Id, Set<Id>> contactIdToAccIdsRquiringACRs,
    String roleToApply
  ) {
    List<AccountContactRelation> newACRS = new List<AccountContactRelation>();
    for (Id contactID : contactIdToAccIdsRquiringACRs.keySet()) {
      for (Id accId : contactIdToAccIdsRquiringACRs.get(contactID)) {
        newACRS.add(
          new AccountContactRelation(
            ContactId = contactID,
            AccountId = accId,
            MTC_Role__c = roleToApply
          )
        );
      }
    }
    insert newACRS;
  }
  // Given a set of accountId-contactId (contact was previous cga)
  // ACR gets updated to read-only
  // An exclusion set is provided
  public static void demotePreviousCGAtoReadOnly(
    Set<String> accIdconIds,
    Set<Id> excludedACRIds
  ) {
    if (!accIdconIds.isEmpty()) {
      Set<Id> contactIds = new Set<Id>();
      for (String accIdconId : accIdconIds) {
        List<String> parts = accIdconId.split('-');
        contactIds.add(parts[1]);
      }
      List<AccountContactRelation> ACRstoUpdate = new List<AccountContactRelation>();
      for (AccountContactRelation acr : [
        SELECT ContactId, AccountId, MTC_Role__c
        FROM AccountContactRelation
        WHERE
          ContactId IN :contactIds
          AND MTC_Role__c = 'CGA'
          AND Id NOT IN :excludedACRIds
      ]) {
        if (accIdconIds.contains(acr.accountId + '-' + acr.contactId)) {
          ACRstoUpdate.add(
            new AccountContactRelation(Id = acr.Id, MTC_Role__c = 'Read-Only')
          );
        }
      }
      update ACRstoUpdate;
    }
  }

  // get a set of account ids related to the contact id if the MTC_Role is a valid MTC role
  public static Set<Id> getRelatedMTCAccountIdsforContact() {
    relatedAccountIds = getRelatedMTCAccountIdsforContact(
      MTCUserUtil.currentUserContactId
    );
    return relatedAccountIds;
  }
  // get the cached version if exists, of account ids related to the contact id if the MTC_Role is a valid MTC role
  public static Set<Id> getCachedRelatedMTCAccountIdsforContact() {
    if (relatedAccountIds == null) {
      getRelatedMTCAccountIdsforContact();
    }
    return relatedAccountIds;
  }

  public static Set<Id> getContactIdsFromAccountIds(Set<Id> accountIds) {
    if (accountIds.isEmpty()) {
      return new Set<Id>();
    }
    Set<Id> result = new Set<Id>();
    for (AccountContactRelation acr : [
      SELECT ContactId
      FROM AccountContactRelation
      WHERE AccountId IN :accountIds AND MTC_Role__c != 'Rejected'
    ]) {
      result.add(acr.ContactId);
    }
    return result;
  }

  // get a set of account ids related to the contact id if the MTC_Role is a valid MTC role
  public static Set<Id> getRelatedMTCAccountIdsforContact(Id contactId) {
    Set<Id> result = new Set<Id>();
    for (AccountContactRelation acr : getMTCACRsForContact(contactId)) {
      result.add(acr.AccountId);
    }
    return result;
  }
  // get a set of account ids related to the current user contact if the MTC_Role is a valid MTC role
  public static Set<Id> getRelatedMTCAccountIdsforContactWhenAdmin() {
    return getRelatedMTCAccountIdsforContactWhenAdmin(
      MTCUserUtil.currentUserContactId
    );
  }

  // get a set of account ids related to the contact id if the MTC_Role is a valid MTC role
  public static Set<Id> getRelatedMTCAccountIdsforContactWhenAdmin(
    Id contactId
  ) {
    Set<Id> result = new Set<Id>();
    for (
      AccountContactRelation acr : getMTCACRsForContactWhenAdmin(contactId)
    ) {
      result.add(acr.AccountId);
    }
    return result;
  }

  // a list of acrs for a contact id where the role is a valid MTC role
  public static List<AccountContactRelation> getMTCACRsForContact(
    Id contactId
  ) {
    return [
      SELECT AccountId, Account_Name_FF__c, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE
        ContactId = :contactId
        AND MTC_Role__c IN :MTCUserUtil.VALID_MTC_ROLES.keySet()
    ];
  }

  public static List<AccountContactRelation> getMTCACRsForContactWhenAdmin() {
    return getMTCACRsForContactWhenAdmin(MTCUserUtil.currentUserContactId);
  }

  public static List<AccountContactRelation> getMTCACRsForContactWhenAdmin(
    Id contactId
  ) {
    Set<String> adminRoles = new Set<String>{
      MTCUserUtil.ADMIN_ROLE,
      MTCUserUtil.CGA_ROLE
    };
    return [
      SELECT AccountId, Account_Name_FF__c, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId = :contactId AND MTC_Role__c IN :adminRoles
    ];
  }

  public static Set<Id> getMTCContactIdsFromAccountIds(Set<Id> accountIds) {
    Set<Id> contactIds = new Set<Id>();
    for (AccountContactRelation acr : [
      SELECT AccountId, ContactId, MTC_Role__c
      FROM AccountContactRelation
      WHERE AccountId IN :accountIds AND Account.Is_MTC_Account__c = TRUE
    ]) {
      contactIds.add(acr.ContactId);
    }
    return contactIds;
  }

  public static Set<Id> accountIdsWhenAssignedToGroup(Id contactId) {
    Set<Id> result = new Set<Id>();
    List<Contact> cons = [
      SELECT
        Id,
        (
          SELECT Contact_Group__r.Account__c
          FROM Group_Memberships__r
          WHERE
            Contact_Group__r.Expiry__c = NULL
            OR Contact_Group__r.Expiry__c >= TODAY
        ),
        (
          SELECT AccountId
          FROM AccountContactRelations
          WHERE MTC_Role__c IN :MTCUserUtil.VALID_MTC_ROLES.keySet()
        )
      FROM Contact
      WHERE
        Id = :contactId
        AND Approval_Status__c != :Label.MTC_Approval_DeclinedStatus
    ];
    if (!cons.isEmpty()) {
      Contact thisCon = cons[0];
      Set<Id> validAccountIds = new Set<Id>();
      for (AccountContactRelation acr : thisCon.AccountContactRelations) {
        validAccountIds.add(acr.AccountId);
      }
      for (Group_Membership__c gm : thisCon.Group_Memberships__r) {
        if (validAccountIds.contains(gm.Contact_Group__r.Account__c)) {
          result.add(gm.Contact_Group__r.Account__c);
        }
      }
    }
    return result;
  }
}