@isTest
public with sharing class TC_TestDataFactory_Users {
  private static Integer remainingLoginLicenses = getRemainingLicenses(
    'Customer Community Plus Login'
  );
  private static Integer remainingMemberLicenses = getRemainingLicenses(
    'Customer Community Plus'
  );
  public static Id adminLoginId = [
    SELECT Id
    FROM Profile
    WHERE Name = 'Experience Cloud Site Admin - Login'
    LIMIT 1
  ]
  .Id;
  public static Id adminMemberId = [
    SELECT Id
    FROM Profile
    WHERE Name = 'Experience Cloud Site Admin - Member'
    LIMIT 1
  ]
  .Id;
  public static Id standardLoginId = [
    SELECT Id
    FROM Profile
    WHERE Name = 'Experience Cloud Site Standard - Login'
    LIMIT 1
  ]
  .Id;
  public static Id standardMemberId = [
    SELECT Id
    FROM Profile
    WHERE Name = 'Experience Cloud Site Standard - Member'
    LIMIT 1
  ]
  .Id;
  public static Id accessPermissionSetId = [
    SELECT Id
    FROM PermissionSet
    WHERE Name = 'ToxClear_Experience_Cloud_Access'
    LIMIT 1
  ]
  .Id;

  private static Integer getRemainingLicenses(String masterLabel) {
    UserLicense l = [
      SELECT
        MasterLabel,
        Name,
        Status,
        TotalLicenses,
        UsedLicenses,
        UsedLicensesLastUpdated
      FROM UserLicense
      WHERE MasterLabel = :masterLabel
      LIMIT 1
    ];
    return l.TotalLicenses - l.UsedLicenses;
  }

  public static User create(User template) {
    User u = withRequiredFields(
      template != null ? template.clone() : new User()
    );
    // Set to false to avoid going over license limit. Remember to switch it active when needed.
    // Leaves one license free to set User.IsEnabled=true.
    if (u.isActive == null) {
      u.IsActive = u.ProfileId == adminLoginId ||
        u.ProfileId == standardLoginId
        ? (--remainingLoginLicenses) > 0
        : (--remainingMemberLicenses) > 0;
    }
    // Special case, domain suffix can be supplied in template:
    if (
      template != null &&
      String.isNotBlank(template.Username) &&
      template.Username.startsWith('@')
    ) {
      u.Username = (u.FirstName + u.LastName + template.Username).toLowerCase();
    }
    if (String.isBlank(u.Username)) {
      u.Username = 'test' + TC_TestDataFactory.random(12, '0123456789');
    }
    return u;
  }

  public static User withRequiredFields(User u) {
    if (String.isBlank(u.ProfileId)) {
      u.ProfileId = standardMemberId;
    }
    if (String.isBlank(u.FirstName)) {
      u.FirstName = TC_TestDataFactory.getFirstname();
    }
    if (String.isBlank(u.LastName)) {
      u.LastName = TC_TestDataFactory.getLastname();
    }
    if (String.isBlank(u.Email)) {
      u.Email = (u.FirstName + '.' + u.LastName + '@example.com').toLowerCase();
    }
    if (String.isBlank(u.Phone)) {
      u.Phone = TC_TestDataFactory.random(12, '0123456789');
    }
    if (String.isBlank(u.Username)) {
      u.Username = u.Email;
    }
    if (String.isBlank(u.Alias)) {
      u.Alias = u.FirstName.length() > 8 ? u.FirstName.left(8) : u.FirstName;
    }
    if (String.isBlank(u.TimeZoneSidKey)) {
      u.TimeZoneSidKey = 'Europe/London';
    }
    if (String.isBlank(u.LocaleSidKey)) {
      u.LocaleSidKey = 'en_US';
    }
    if (String.isBlank(u.EmailEncodingKey)) {
      u.EmailEncodingKey = 'UTF-8';
    }
    if (String.isBlank(u.LanguageLocaleKey)) {
      u.LanguageLocaleKey = 'en_US';
    }
    return u;
  }

  // New User copying contact details:
  public static User create(Contact contact, User template) {
    User u = create(template); // Random user.
      
    u.countryCode = 'GB';
    // Overwrite to match contact.
    u.Email = contact.Email;
    u.Username = contact.Email;
    u.ContactId = contact.Id;
    u.Title = contact.Title;
    u.FirstName = contact.FirstName;
    u.LastName = contact.LastName;
    u.Phone = contact.Phone;
    u.MobilePhone = contact.MobilePhone;
    u.Fax = contact.Fax;
    u.Alias = contact.FirstName.length() > 8
      ? contact.FirstName.left(8)
      : contact.FirstName;
    return u;
  }

  public static void insertPermissionSetAssignments(
    List<PermissionSetAssignment> permissionSetAssignments
  ) {
    if (!permissionSetAssignments.isEmpty()) {
      if (Test.isRunningTest()) {
        Set<Id> uniquePSG = new Set<Id>();
        for (PermissionSetAssignment psa : permissionSetAssignments) {
          if (psa.PermissionSetGroupId != null) {
            uniquePSG.add(psa.PermissionSetGroupId);
          }
        }
        List<PermissionSetGroup> psgForUpdate = [
          SELECT Id
          FROM PermissionSetGroup
          WHERE Status != 'Updated' AND Id IN :uniquePSG
        ];

        if (psgForUpdate.size() > 0) {
          List<Id> idForUpdate = new List<Id>();
          for (PermissionSetGroup psg : psgForUpdate) {
            idForUpdate.add(psg.Id);
          }
          Test.calculatePermissionSetGroup(idForUpdate);
        }
      }

      insertPermissionSetAssignments(
        JSON.serialize(permissionSetAssignments, true)
      ); // Pass to a future method.
    }
  }
  @future
  public static void insertPermissionSetAssignments(
    String jsonPermissionSetAssignments
  ) {
    List<PermissionSetAssignment> a = (List<PermissionSetAssignment>) JSON.deserialize(
      jsonPermissionSetAssignments,
      List<PermissionSetAssignment>.class
    );
    insert a;
  }

  public static List<PermissionSetAssignment> newPermissionSetGroupAssignments(
    List<User> users,
    Id permissionSetGroupId
  ) {
    List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
    for (User u : users) {
      if (u.IsActive) {
        // Can only assign permission sets and groups to active users.
        psa.add(
          new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetGroupId = permissionSetGroupId
          )
        );
      }
    }
    return psa;
  }

  public static List<PermissionSetAssignment> newPermissionSetAssignments(
    List<User> users,
    Id permissionSetId
  ) {
    List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
    for (User u : users) {
      if (u.IsActive) {
        // Can only assign permission sets and groups to active users.
        psa.add(
          new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = permissionSetId
          )
        );
      }
    }
    return psa;
  }

  public static List<User> create(Integer count, User template) {
    List<User> users = new List<User>();
    for (Integer i = 0; i < count; i++) {
      users.add(create(template));
    }
    return users;
  }
  public static List<User> create(List<Contact> contacts, User template) {
    List<User> users = new List<User>();
    Integer i = 0;
    for (Contact contact : contacts) {
      users.add(create(contact, template));
    }
    return users;
  }

  public static List<User> create(List<Contact> contacts, List<User> template) {
    List<User> users = new List<User>();
    Integer i = 0;
    for (Contact contact : contacts) {
      users.add(
        create(
          contact,
          template == null ? null : template[Math.mod(i, template.size())]
        )
      );
      i++;
    }
    return users;
  }

  @future
  public static void updateUsersToActive(List<Id> userIds) {
    List<User> toUpdate = [SELECT IsActive FROM User WHERE Id IN :userIds];

    for (User u : toUpdate) {
      u.IsActive = true;
    }
    update toUpdate;
  }

  @future
  public static void updateUsersToInactive(List<Id> userIds) {
    List<User> toUpdate = [SELECT IsActive FROM User WHERE Id IN :userIds];

    for (User u : toUpdate) {
      u.IsActive = false;
    }
    update toUpdate;
  }

  public List<User> supplierUsers;
  public List<User> supplierAdminUsers;
  public List<User> supplierStdUsers;
  public List<User> facilityAdminUsers;
  public List<User> facilityStdUsers;
  public List<User> facilityUsers;
  public List<User> brandAdminUsers;
  public List<User> brandStdUsers;
  public List<User> brandUsers;
  public List<PermissionSetAssignment> supplierUserAssignments;
  public List<PermissionSetAssignment> facilityUserAssignments;
  public List<PermissionSetAssignment> brandUserAssignments;
  public List<PermissionSetAssignment> permissionSetAssignments;
  public List<PermissionSetAssignment> accessPermissionSetAssignments;

  public void insertPermissionSetAssignments() {
    insertPermissionSetAssignments(permissionSetAssignments);
  }

  /**
   * TC_TestDataFactory_Users Query for all active users typically created by
   * the constructor following this one.
   */
  public TC_TestDataFactory_Users() {
    supplierAdminUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
    supplierStdUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
    facilityAdminUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Facility'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
    facilityStdUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Facility'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
    brandAdminUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
    brandStdUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
  }

  /**
   * TC_TestDataFactory_Users Query for all active users typically created by
   * the constructor following this one.
   */
  public TC_TestDataFactory_Users(Set<Id> accountIds) {
    supplierAdminUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.AccountId IN :accountIds
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
    supplierStdUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.AccountId IN :accountIds
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
    facilityAdminUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.AccountId IN :accountIds
        AND Contact.Account.ToxClear_Account_Type__c = 'Facility'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
    facilityStdUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.AccountId IN :accountIds
        AND Contact.Account.ToxClear_Account_Type__c = 'Facility'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
    brandAdminUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.AccountId IN :accountIds
        AND Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
    brandStdUsers = [
      SELECT Id, ContactId, Contact.AccountId, Username, ZDHC_User_Access_Key__c
      FROM User
      WHERE
        Contact.AccountId IN :accountIds
        AND Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
        AND IsActive = TRUE
      ORDER BY FirstName ASC
      LIMIT 25
    ];
  }

  /**
   * TC_TestDataFactory_Users Construct and insert a list of users for contacts.
   *
   * @param tdfc (TC_TestDataFactory_Contacts): The object which knows the
   * story about creating Contacts.
   */
  public TC_TestDataFactory_Users(
    TC_TestDataFactory_Contacts tdfc,
    Boolean isActiveDefaultValue
  ) {
    // Limited licenses in a scratch org means the initial templates are of users who
    // are not active, unless Test.isRunningTest.
    List<User> adminUserTemplate = new List<User>{
      new User(
        ProfileId = adminMemberId,
        ZDHC_User_Access_Key__c = 'D5545F4B0AEC4277E0530100007F4C7B',
        IsActive = isActiveDefaultValue
      ),
      new User(
        ProfileId = adminLoginId,
        ZDHC_User_Access_Key__c = 'D5545F4B0AEC4277E0530100007F4C7B',
        IsActive = isActiveDefaultValue
      )
    };
    List<User> stdUserTemplate = new List<User>{
      new User(
        ProfileId = standardMemberId,
        ZDHC_User_Access_Key__c = 'D5545F4B0AEC4277E0530100007F4C7B',
        IsActive = isActiveDefaultValue
      ),
      new User(
        ProfileId = standardLoginId,
        ZDHC_User_Access_Key__c = 'D5545F4B0AEC4277E0530100007F4C7B',
        IsActive = isActiveDefaultValue
      )
    };

    supplierAdminUsers = create(tdfc.supplierAdminContacts, adminUserTemplate);
    supplierStdUsers = create(tdfc.supplierStdContacts, stdUserTemplate);
    facilityAdminUsers = create(tdfc.facilityAdminContacts, adminUserTemplate);
    facilityStdUsers = create(tdfc.facilityStdContacts, stdUserTemplate);
    brandAdminUsers = create(tdfc.brandAdminContacts, adminUserTemplate);
    brandStdUsers = create(tdfc.brandStdContacts, stdUserTemplate);

    // When used in a scratch org, use licenses on the first four users.
    if (isActiveDefaultValue == false) {
      supplierAdminUsers[0].IsActive = true;
      //supplierStdUsers[0].IsActive = true;
      //facilityAdminUsers[0].IsActive = true;
      facilityStdUsers[0].IsActive = true;
      brandAdminUsers[0].IsActive = true;
      brandStdUsers[0].IsActive = true;
    }

    insert supplierAdminUsers;
    insert supplierStdUsers;
    insert facilityAdminUsers;
    insert facilityStdUsers;
    insert brandAdminUsers;
    insert brandStdUsers;

    supplierUsers = new List<User>();
    supplierUsers.addAll(supplierAdminUsers);
    supplierUsers.addAll(supplierStdUsers);
    facilityUsers = new List<User>();
    facilityUsers.addAll(facilityAdminUsers);
    facilityUsers.addAll(facilityStdUsers);
    brandUsers = new List<User>();
    brandUsers.addAll(brandAdminUsers);
    brandUsers.addAll(brandStdUsers);

    // After inserting Users (setup objects),
    // a transaction needs to complete before
    // regular objects can be inserted.
    //
    // Perform the insert in the test method:
    //   System.runAs(new User(Id = UserInfo.getUserId())) {
    //     insert tdfu.permissionSetAssignments;
    //   }
    // Or continue in future method, by calling:
    //   tdfu.insertPermissionSetAssignments();
    supplierUserAssignments = newPermissionSetGroupAssignments(
      supplierAdminUsers,
      TC_ExperienceCloud.SUPPLIER_ADMINISTRATOR_PSGID
    );
    supplierUserAssignments.addAll(
      newPermissionSetGroupAssignments(
        supplierStdUsers,
        TC_ExperienceCloud.SUPPLIER_STANDARD_USER_PSGID
      )
    );

    facilityUserAssignments = newPermissionSetGroupAssignments(
      facilityAdminUsers,
      TC_ExperienceCloud.SUPPLIER_ADMINISTRATOR_PSGID
    );
    facilityUserAssignments.addAll(
      newPermissionSetGroupAssignments(
        facilityStdUsers,
        TC_ExperienceCloud.SUPPLIER_STANDARD_USER_PSGID
      )
    );

    brandUserAssignments = newPermissionSetGroupAssignments(
      brandAdminUsers,
      TC_ExperienceCloud.BRAND_ADMINISTRATOR_PSGID
    );
    brandUserAssignments.addAll(
      newPermissionSetGroupAssignments(
        brandStdUsers,
        TC_ExperienceCloud.BRAND_STANDARD_USER_PSGID
      )
    );

    // Although ACCESS_PSID is in the PermissionSetGroups PSGID,
    // presently the cloud experience security permits users by PermissionSet.
    permissionSetAssignments = new List<PermissionSetAssignment>();
    permissionSetAssignments.addAll(supplierUserAssignments);
    permissionSetAssignments.addAll(facilityUserAssignments);
    permissionSetAssignments.addAll(brandUserAssignments);

    // Also assign Experience Cloud Access
    List<User> allUsers = new List<User>();
    allUsers.addAll(supplierUsers);
    allUsers.addAll(facilityUsers);
    allUsers.addAll(brandUsers);
    accessPermissionSetAssignments = newPermissionSetAssignments(
      allUsers,
      TC_ExperienceCloud.ACCESS_PSID
    );

    TC_TriggeredSharing.processNewOrUpdatedUsers(
      new List<Id>(new Map<Id, User>(allUsers).keySet())
    );
  }
}