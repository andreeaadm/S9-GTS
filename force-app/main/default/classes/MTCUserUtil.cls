/**
 * History:
 * 16-11-2023  Kamlesh.kahar   Fixed the license assignment issue    MBS-310
 */

public without sharing class MTCUserUtil {

  public static final String ADMIN_LOGIN_PROFILE = 'mtc admin login';
  public static final String ADMIN_PROFILE = 'mtc admin';
  public static final String STANDARD_LOGIN_PROFILE = 'mtc standard login';
  public static final String STANDARD_PROFILE = 'mtc standard';
  public static final String ADMIN_ROLE = 'admin';
  public static final String CGA_ROLE = 'cga';
  public static final Integer DEFAULT_TEMP_USER_EXPIRY = 30;
  public static final String APPROVALREQUIRED = 'pending approval';
  public static final String LOGIN_USER_LICENSE = 'Customer Community Plus Login';
  public static final String MEMBER_USER_LICENSE = 'Customer Community Plus';

  public static final Map<String, String> PROFILE2PERMISSIONSETGROUP = new Map<String, String>{
    'mtc admin' => 'mtc_admin_psg',
    'mtc standard' => 'mtc_standard_psg',
    'mtc admin login' => 'mtc_admin_psg',
    'mtc standard login' => 'mtc_standard_psg'
  };
  public static final Map<String, String> VALID_MTC_ROLES = new Map<String, String>{
    'admin' => 'mtc admin login',
    'cga' => 'mtc admin login',
    'pending approval' => 'mtc standard login',
    'read-only' => 'mtc standard login',
    'restricted' => 'mtc standard login'
  };
  public static final Map<String, String> PROFILEMAP_BASED_ON_MTCROLE_USERLICENSE = new Map<String, String>{
    'admin' + LOGIN_USER_LICENSE => 'mtc admin login',
    'admin' + MEMBER_USER_LICENSE => 'mtc admin',
    'cga' + LOGIN_USER_LICENSE => 'mtc admin login',
    'cga' + MEMBER_USER_LICENSE => 'mtc admin',
    'pending approval' + LOGIN_USER_LICENSE => 'mtc standard login',
    'pending approval' + MEMBER_USER_LICENSE => 'mtc standard',
    'read-only' + LOGIN_USER_LICENSE => 'mtc standard login',
    'read-only' + MEMBER_USER_LICENSE => 'mtc standard',
    'restricted' + LOGIN_USER_LICENSE => 'mtc standard login',
    'restricted' + MEMBER_USER_LICENSE => 'mtc standard'
  };
  public static Set<String> ROLES_FOR_DEFAULTGROUPS = new Set<String>{
    'admin',
    'cga',
    'read-only'
  };
  public static User currentUserObj {
    get {
      if (currentUserObj == null) {
        currentUserObj = [
          SELECT
            Id,
            ContactId,
            AccountId,
            Email,
            Username,
            ProfileId,
            Profile.Name,
            Notifications_Cutoff__c
          FROM User
          WHERE Id = :UserInfo.getUserId()
        ];
      }
      return currentUserObj;
    }
    private set;
  }

  //13-11-2023  MBS-311   Kamlesh.kahar   Fix: Adjusted the code to show/hide action buttons based on ACR role instead of profiles.
  public static Boolean isCurrentUserAdmin {
    get {
      if(isCurrentUserAdmin == null){
        isCurrentUserAdmin = !([SELECT Id FROM AccountContactRelation 
                                WHERE ContactId = :currentUserObj.ContactId 
                                AND MTC_Role__c IN (:CGA_ROLE, :ADMIN_ROLE)].isEmpty());
      }
      //return currentUserObj.Profile.Name == ADMIN_PROFILE;
      return isCurrentUserAdmin;
    }
    private set;
  }
  public static Id currentUserContactId {
    get {
      return currentUserObj.contactId;
    }
    private set;
  }

  // Organise profiles by Name
  public static Map<String, Profile> mtcProfilesByName {
    get {
      if (mtcProfilesByName == null) {
        mtcProfilesByName = new Map<String, Profile>();
        for (Profile pro : mtcProfiles.values()) {
          mtcProfilesByName.put(pro.Name.toLowerCase(), pro);
        }
      }
      return mtcProfilesByName;
    }
    private set;
  }

  // Organise profiles by Id
  public static Map<Id, Profile> mtcProfiles {
    get {
      if (mtcProfiles == null) {
        mtcProfiles = new Map<Id, Profile>(
          [SELECT Id, Name FROM Profile WHERE Name LIKE 'mtc%']
        );
      }
      return mtcProfiles;
    }
    private set;
  }

  // When a new user is created he gets the correct permission set group
  public static void assignMTCPermissionSet(List<User> users) {
    Map<String, PermissionSet> psName2permSet = new Map<String, PermissionSet>();
    for (PermissionSet ps : [
      SELECT Name, PermissionSetGroupId, Type
      FROM PermissionSet
      WHERE PermissionSetGroupId != NULL
    ]) {
      psName2permSet.put(ps.Name.toLowerCase(), ps);
    }

    List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
    for (User usr : users) {
      if (!usr.IsActive || !mtcProfiles.containsKey(usr.ProfileId)) {
        continue;
      }
      String profileNameLC = mtcProfiles.get(usr.ProfileId).Name.toLowerCase();

      if (PROFILE2PERMISSIONSETGROUP.containsKey(profileNameLC)) {
        String psgName = PROFILE2PERMISSIONSETGROUP.get(profileNameLC);
        psas.add(
          new PermissionSetAssignment(
            AssigneeId = usr.Id,
            PermissionSetGroupId = psName2permSet.get(psgName)
              .PermissionSetGroupId
          )
        );
      }
    }
    // if (Test.isRunningTest()) {
    //   insert psas;
    // } else {
    Database.insert(psas, false);
    // }
  }

  // Organise user Ids by contact Ids
  public static Map<Id, Id> getConId2UserId(Set<Id> contactIds) {
    Map<Id, Id> contactId2UserId = new Map<Id, Id>();
    for (User usr : getUsersFromContactIds(contactIds)) {
      contactId2UserId.put(usr.contactId, usr.Id);
    }
    return contactId2UserId;
  }

  // Organise user by contact Ids
  public static Map<Id, User> getConId2User(Set<Id> contactIds) {
    Map<Id, User> contactId2User = new Map<Id, User>();
    for (User usr : getUsersFromContactIds(contactIds)) {
      contactId2User.put(usr.contactId, usr);
    }
    return contactId2User;
  }
  // Query to retrieve Users
  public static List<User> getUsersFromContactIds(Set<Id> contactIds) {
    if (contactIds.isEmpty()) {
      return new List<user>();
    }
    return [
      SELECT Id, AccountId, ContactId, IsActive
      FROM User
      WHERE ContactId IN :contactIds
    ];
  }

  @future
  public static void userDeactivatedUpdateMTCACRsFuture(Set<Id> contactIds) {
    List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
    List<AccountContactRelation> acrs = AccountRelationUtil.getFilteredMTCACRsForContactIds(
      contactIds,
      new Set<String>{ 'cga', 'admin', 'read-only', 'restricted' }
    );
    for (AccountContactRelation acr : acrs) {
      if (acr.MTC_Role__c != 'no-access') {
        acrsToUpdate.add(
          new AccountContactRelation(Id = acr.Id, MTC_Role__c = 'no-access')
        );
      }
    }
    update acrsToUpdate;
  }

  public static void userDeactivatedUpdateMTCACRs(List<User> users) {
    Set<Id> contactIds = new Set<Id>();
    for (User user : users) {
      if (!user.IsActive) {
        contactIds.add(user.contactId);
      }
    }
    if (!contactIds.isEmpty()) {
      List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
      List<AccountContactRelation> acrs = AccountRelationUtil.getFilteredMTCACRsForContactIds(
        contactIds,
        new Set<String>{ 'cga', 'admin', 'read-only', 'restricted' }
      );
      for (AccountContactRelation acr : acrs) {
        if (acr.MTC_Role__c != 'no-access') {
          acrsToUpdate.add(
            new AccountContactRelation(Id = acr.Id, MTC_Role__c = 'no-access')
          );
        }
      }
      update acrsToUpdate;
    }
  }

  // Deals with updatedRelationship
  public static void updatedRelationship(
    List<AccountContactRelation> newACRs,
    Map<Id, AccountContactRelation> oldACRs
  ) {
    Set<Id> contactIdsToProcess = new Set<Id>();
    for (AccountContactRelation acr : newACRs) {
      AccountContactRelation oldACR;
      if (oldACRs.containsKey(acr.Id)) {
        // modified relationship
        oldACR = oldACRs.get(acr.Id);
        if (
          isValidMTCRole(acr.MTC_Role__c) &&
          acr.MTC_Role__c != oldACR.MTC_Role__c
        ) {
          contactIdsToProcess.add(acr.ContactId);
        }
      } else {
        // new relationship
        if (isValidMTCRole(acr.MTC_Role__c)) {
          contactIdsToProcess.add(acr.ContactId);
        }
      }
    }
    if (contactIdsToProcess.isEmpty()) {
      return;
    }
    Set<Id> conIdWithUserRequired = contactIdsToProcess.clone();
    // Map<Id, Id> conId2UserId = getConId2UserId(contactIdsToProcess);
    // conIdWithUserRequired.removeAll(conId2UserId.keySet());
    if (!conIdWithUserRequired.isEmpty()) {
      if (System.isBatch()) {
        createUpdateUsersForContacts(conIdWithUserRequired);
      } else {
        createUpdateUsersForContactsFuture(conIdWithUserRequired);
      }
    }
  }

  @future
  public static void activateDeactivateUserFuture(
    Id userId,
    Boolean toActivate,
    Boolean clearExpiry
  ) {
    List<User> theRecords = [
      SELECT Id, IsActive, Date_Expires__c, ProfileId
      FROM User
      WHERE Id = :userId
    ];
    if (!theRecords.isEmpty()) {
      User userToUpdate = new User(
        Id = userId,
        IsActive = toActivate,
        ProfileId = theRecords[0].ProfileId,
        Last_Notification_Reason__c = null,
        Last_Notification_Date__c = null
      );
      if (clearExpiry) {
        userToUpdate.Date_Expires__c = null;
      }
      update userToUpdate;
      if (toActivate) {
        assignMTCPermissionSet(new List<User>{ userToUpdate });
      }
    }
  }

  @future
  public static void deactivateUsersAccountDeactivated(
    Set<Id> accountDeactivatedIds
  ) {
    List<User> usersToDeactivate = [
      SELECT Id, IsActive
      FROM User
      WHERE
        IsActive = TRUE
        AND AccountId IN :accountDeactivatedIds
        AND ProfileId IN :mtcProfiles.keySet()
    ];
    for (User u : usersToDeactivate) {
      u.IsActive = false;
    }
    Database.update(usersToDeactivate, false);
  }

  @future
  public static void createUpdateUsersForContactsFuture(Set<Id> conIds) {
    createUpdateUsersForContacts(conIds);
  }

  public static void createUpdateUsersForContacts(Set<Id> conIds) {
    Map<Id, Contact> contactsWithUserCreationNeeded = new Map<Id, Contact>();
    Map<Id, Contact> contactsToCheckUser = new Map<Id, Contact>();
    List<Contact> contacts = [
      SELECT
        Id,
        FirstName,
        LastName,
        Email,
        AccountId,
        Is_User_Required__c,
        Approval_Status__c,
        (
          SELECT
            Id,
            ProfileId,
            IsActive,
            Date_Expires__c,
            Last_Notification_Date__c,
            Last_Notification_Reason__c,
            Profile.UserLicense.Name
          FROM Users
        ),
        (SELECT Id, MTC_Role__c FROM AccountContactRelations),
        (
          SELECT Id, Date_Issued__c, Date_Revised__c
          FROM Assets
          WHERE RecordTypeId = :AssetUtil.reportRT.recordId
        )
      FROM Contact
      WHERE Id IN :conIds
    ];
    for (Contact con : contacts) {
      if (con.Is_User_Required__c && con.Users.isEmpty()) {
        contactsWithUserCreationNeeded.put(con.Id, con);
      }
      if (!con.Users.isEmpty()) {
        contactsToCheckUser.put(con.Id, con);
      }
    }
    if (!contactsWithUserCreationNeeded.isEmpty()) {
      usersCreate(contactsWithUserCreationNeeded);
    }
    if (!contactsToCheckUser.isEmpty()) {
      checkUpdateUser(contactsToCheckUser);
    }
  }
  // Create users from contacts
  public static void usersCreate(Map<Id, Contact> contacts) {
    List<User> usersToCreate = new List<User>();
    for (Contact con : contacts.values()) {
      User userToCreate = userCreate(con);
      if (userToCreate != null) {
        usersToCreate.add(userToCreate);
      }
    }
    insert usersToCreate;

    if (!usersToCreate.isEmpty()) {
      assignMTCPermissionSet(usersToCreate);
    }
  }
    //Prateek
  public static User userCreate(Contact con) {
    Date expiry = computeExpiry(con);
    if (expiry == null || expiry > Date.today()) {
      Id profileId = profileFinder(con.AccountContactRelations, LOGIN_USER_LICENSE);
      Boolean userActive = approvalNotRequired(con.AccountContactRelations);
      if (profileId != null) {
        User usr = new User(
          FirstName = con.FirstName,
          LastName = con.LastName,
          Email = con.Email,
          UserRoleId = null,
          Username = con.Email,
          ProfileId = profileId,
          Alias = 'Test',
          TimeZoneSidKey = 'GMT',
          LanguageLocaleKey = 'en_US',
          EmailEncodingKey = 'UTF-8',
          LocaleSidKey = 'en_US',
          ContactId = con.Id,
          UserPreferencesShowEmailToExternalUsers = true,
          IsActive = userActive,
          Date_Expires__c = expiry
        );
        return usr;
      }
    }
    return null;
  }
  // Given a contact with ACRs and Reports, calculates an expiry
  // If contact has Read-Only, Admin or CGA access, returns null
  // If contact
  public static Date computeExpiry(Contact con) {
    Boolean hasRestrictedAccess = false;
    for (AccountContactRelation acr : con.AccountContactRelations) {
      if (String.isEmpty(acr.MTC_Role__c)) {
        continue;
      }
      if (acr.MTC_Role__c != 'restricted' && acr.MTC_Role__c != 'no-access') {
        return null;
      }
      if (acr.MTC_Role__c == 'restricted') {
        hasRestrictedAccess = true;
      }
    }
    Date expiry;
    if (hasRestrictedAccess) {
      expiry = Date.today().addDays(-DEFAULT_TEMP_USER_EXPIRY - 1);
      for (Asset report : con.Assets) {
        if (report.Date_Issued__c != null && report.Date_Issued__c > expiry) {
          expiry = report.Date_Issued__c;
        }
        if (report.Date_Revised__c != null && report.Date_Revised__c > expiry) {
          expiry = report.Date_Revised__c;
        }
      }
      expiry = expiry.addDays(DEFAULT_TEMP_USER_EXPIRY);
    }

    return expiry;
  }

  public static void checkUpdateUser(Map<Id, Contact> contacts) {
    List<User> usersToUpdate = new List<User>();
    List<User> profileUpdates = new List<User>();
    for (Contact con : contacts.values()) {
      User contactUser = con.Users[0];
      Id atBestProfileId = profileFinder(con.AccountContactRelations, contactUser.Profile.UserLicense.Name);
      Date userExpiry = computeExpiry(con);

      User userUpd = new User();
      userUpd.IsActive = con.Is_User_Required__c;

      if (atBestProfileId != null && contactUser.ProfileId != atBestProfileId) {
        userUpd.Id = contactUser.Id;
        userUpd.ProfileId = atBestProfileId;
        profileUpdates.add(userUpd);
      }
      if (contactUser.Date_Expires__c != userExpiry) {
        userUpd.Id = contactUser.Id;
        userUpd.Date_Expires__c = userExpiry;
      }
      userUpd = setNotificationFieldsWhenApprovalRequested(userUpd, con);
      if (userUpd.Id != null) {
        usersToUpdate.add(userUpd);
      }
    }
    update usersToUpdate;

    if (!profileUpdates.isEmpty()) {
      assignMTCPermissionSet(profileUpdates);
    }
  }

  public static Boolean isValidMTCRole(String mtcRole) {
    if (String.isEmpty(mtcRole)) {
      return false;
    }
    return (VALID_MTC_ROLES.containsKey(mtcRole.toLowerCase()));
  }
  // These roles will be managed with Default Groups
  public static Boolean isValidDefaultGroupRole(String mtcRole) {
    if (String.isEmpty(mtcRole)) {
      return false;
    }
    return (ROLES_FOR_DEFAULTGROUPS.contains(mtcRole.toLowerCase()));
  }

  public static Id profileFinder(List<AccountContactRelation> acrs, String userLicense) {
    Id atBestProfileId;
    for (AccountContactRelation acr : acrs) {
      String mtcRole = acr.MTC_Role__c.toLowerCase();
      String profileKey = mtcRole + userLicense;
      if(PROFILEMAP_BASED_ON_MTCROLE_USERLICENSE.containsKey(profileKey)){
        String profileName = PROFILEMAP_BASED_ON_MTCROLE_USERLICENSE.get(profileKey);
        atBestProfileId = mtcProfilesByName.get(profileName).Id;
      }
    }
    return atBestProfileId;
  }

  public static Boolean approvalNotRequired(List<AccountContactRelation> acrs) {
    Boolean result = true;
    for (AccountContactRelation acr : acrs) {
      String mtcRole = acr.MTC_Role__c.toLowerCase();
      if (VALID_MTC_ROLES.containsKey(mtcRole)) {
        if (mtcRole.equalsIgnoreCase(APPROVALREQUIRED)) {
          result = false;
        } else {
          // Any valid MTC roles other than APPROVALREQUIRED should create user as Active
          return true;
        }
      }
    }
    return result;
  }

  public static Set<Id> filterPermittedUsers(List<Id> ids) {
    Set<Id> accountIdsAdminFor = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();
    return new Set<Id>(
      new Map<Id, User>(
          [
            SELECT Id
            FROM User
            WHERE
              Id IN :ids
              AND ContactId IN (
                SELECT ContactId
                FROM AccountContactRelation
                WHERE AccountId IN :accountIdsAdminFor
              )
          ]
        )
        .keyset()
    );
  }
  public static Set<Id> filterUsersUserCanDeactivate(Set<Id> userIds) {
    Set<Id> result = new Set<Id>();
    Set<Id> accountIdsAdminFor = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();

    Map<Id, List<AccountContactRelation>> allACRsByUserId = WithoutSharing.getAllACRsRelatedToUsers(
      userIds
    );

    for (Id userId : allACRsByUserId.keySet()) {
      Boolean adminOnAllAccounts = true;
      for (AccountContactRelation acr : allACRsByUserId.get(userId)) {
        if (!accountIdsAdminFor.contains(acr.AccountId)) {
          adminOnAllAccounts = false;
          break;
        }
      }
      if (adminOnAllAccounts) {
        result.add(userId);
      }
    }

    return result;
  }

  // returns a list of newly activated users
  public static List<User> filterNewlyActivatedUsers(
    List<User> users,
    Map<Id, User> oldUsers
  ) {
    return filterOnIsActive(users, oldUsers, true);
  }

  // returns a list of newly deactivated users
  public static List<User> filterNewlyDeactivatedUsers(
    List<User> users,
    Map<Id, User> oldUsers
  ) {
    return filterOnIsActive(users, oldUsers, false);
  }
  // returns a list of users where the isactive flag has changed to the activeWanted parameter
  private static List<User> filterOnIsActive(
    List<User> users,
    Map<Id, User> oldUsers,
    Boolean activeWanted
  ) {
    List<User> result = new List<User>();
    for (User usr : users) {
      if (oldUsers.containsKey(usr.Id)) {
        if (
          usr.IsActive != oldUsers.get(usr.Id).IsActive &&
          usr.IsActive == activeWanted
        ) {
          result.add(usr);
        }
      } else if (usr.IsActive == activeWanted) {
        result.add(usr);
      }
    }
    return result;
  }

  public static List<User> getUsersWithContact(Set<Id> userIds) {
    List<User> result = new List<User>();
    if (!userIds.isEmpty()) {
      result = [
        SELECT
          Username,
          IsActive,
          IsPortalEnabled,
          AccountId,
          ContactId,
          Contact.Approval_Status__c,
          Contact.Email,
          Contact.Firstname,
          Contact.Lastname
        FROM User
        WHERE Id IN :userIds
      ];
    }
    return result;
  }
  // if the contact is requesting access via the Approval_Status__c field
  // and the user's Last_Notification_Reason__c does not match the correct value
  // then we set the notification fields
  public static User setNotificationFieldsWhenApprovalRequested(
    User userUpd,
    Contact con
  ) {
    User contactUser = con.Users[0];

    if (
      con.Approval_Status__c == Label.MTC_Approval_RequestedStatus &&
      contactUser.Last_Notification_Reason__c !=
      Label.MTC_User_Requesting_Access_Approval
    ) {
      userUpd.Id = contactUser.Id;
      userUpd.Last_Notification_Date__c = Datetime.now();
      userUpd.Last_Notification_Reason__c = Label.MTC_User_Requesting_Access_Approval;
    }
    return userUpd;
  }
}