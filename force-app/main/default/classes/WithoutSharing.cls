// perform action without sharing
public without sharing class WithoutSharing {
  public static void insertRecords(List<SObject> recordsToInsert) {
    insert recordsToInsert;
  }
  public static void insertRecordsFailSilently(List<SObject> recordsToInsert) {
    Database.insert(recordsToInsert, false);
  }
  public static void updateRecords(List<SObject> recordsToUpdate) {
    update recordsToUpdate;
  }
  public static void updateRecordsFailSilently(List<SObject> recordsToUpdate) {
    Database.update(recordsToUpdate, false);
  }

  public static void updateRecordsFuture(List<SObject> recordsToUpdate) {
    updateRecordsFuture(JSON.serialize(recordsToUpdate));
  }

  @future
  static void updateRecordsFuture(String serializedRecordsToUpdate) {
    List<SObject> recordsToUpdate = (List<SObject>) JSON.deserialize(
      serializedRecordsToUpdate,
      List<SObject>.class
    );
    update recordsToUpdate;
  }

  public static void updateRecord(SObject recordToUpdate) {
    update recordToUpdate;
  }
  public static void updateUser(
    Id userId,
    Boolean toActivate,
    Boolean clearExpiry
  ) {
    MTCUserUtil.activateDeactivateUserFuture(userId, toActivate, clearExpiry);
  }

  public static List<List<SObject>> getAccessesWithNotifications(
    user currentUser,
    DateTime notificationsCutoff,
    Integer rowLimit
  ) {
    Set<Id> myContactGroupIds;
    Map<Id, Contact_Group__c> myCGs = new Map<Id, Contact_Group__c>(
      [
        SELECT Id
        FROM Contact_Group__c
        WHERE
          (Expiry__c = NULL
          OR Expiry__c >= :Date.today())
          AND Id IN (
            SELECT Contact_Group__c
            FROM Group_Membership__c
            WHERE Contact__c = :currentUser.ContactId
          )
      ]
    );
    myContactGroupIds = myCGs.keySet();

    List<Access__c> accesses = [
      SELECT
        Id,
        Report_Asset__c,
        Report_Asset__r.Name,
        Last_Notification_Date__c,
        Last_Notification_Reason__c
      FROM Access__c
      WHERE
        Contact_Group__c IN :myContactGroupIds
        AND Last_Notification_Date__c != NULL
        AND Last_Notification_Date__c >= :notificationsCutoff
      ORDER BY Last_Notification_Date__c DESC
      LIMIT :rowLimit
    ];
    return new List<List<SObject>>{ accesses };
  }

  public static APIResponse createUpdateAccountContactRelation(
    String mtcRole,
    String userParam
  ) {
    Contact newContactUser = (Contact) JSON.deserialize(
      userParam,
      SObject.class
    );
    User existingUser;
    List<User> dupeUsers = [
      SELECT Id, ContactId, IsActive, IsPortalEnabled, UserType, Profile.Name
      FROM User
      WHERE Username = :newContactUser.Email AND Profile.Name != NULL
    ];
    Boolean hasDupeUser = false;
    if (!dupeUsers.isEmpty()) {
      hasDupeUser = true;
      existingUser = dupeUsers[0];
    }
    // check and throw error if user is *not* a community user (internal user, for example)
    String VALIDUSERTYPE = 'PowerCustomerSuccess';
    if (hasDupeUser && (existingUser.UserType != VALIDUSERTYPE)) {
      return new APIResponse(
        'Bad Request',
        400,
        'There is already a user with that email. Please try again with a different email address.'
      );
    }
    if (
      hasDupeUser &&
      existingUser.ContactId != null &&
      !MTCUserUtil.PROFILE2PERMISSIONSETGROUP.containsKey(
        existingUser.Profile.Name.toLowerCase()
      )
    ) {
      return new APIResponse(
        'Bad Request',
        400,
        'Another application owns a user with that email. Please try again with a different email address or contact support.'
      );
    }
    // Maybe there is an existing contact with the same email address
    List<Contact> existingContacts = [
      SELECT
        Id,
        Email,
        Is_User_Required__c,
        AccountId,
        (
          SELECT Id, AccountId, MTC_Role__c
          FROM AccountContactRelations
          WHERE AccountId = :newContactUser.AccountId
        )
      FROM Contact
      WHERE Email = :newContactUser.Email
    ];

    Contact existingContact;
    List<AccountContactRelation> existingACRs = new List<AccountContactRelation>();
    if (!existingContacts.isEmpty()) {
      existingContact = existingContacts[0];
      existingACRs = existingContact.AccountContactRelations;
    }

    if (existingACRs.isEmpty()) {
      Id customerContactId;
      AccountContactRelation[] existingRelations;

      if (!hasDupeUser) {
        Contact customerContact;
        if (existingContact == null) {
          customerContact = new Contact(
            AccountId = newContactUser.AccountId,
            LastName = newContactUser.LastName,
            FirstName = newContactUser.FirstName,
            Email = newContactUser.Email,
            Phone = newContactUser.Phone,
            Is_User_Required__c = true
          );
          insert customerContact;
          customerContactId = customerContact.Id;
        } else {
          customerContactId = existingContact.Id;
        }

        existingRelations = [
          SELECT Id, MTC_Role__c
          FROM AccountContactRelation
          WHERE
            ContactId = :customerContactId
            AND AccountId = :newContactUser.AccountId
          LIMIT 1
        ];
      } else {
        customerContactId = existingUser.ContactId;
        existingRelations = new List<AccountContactRelation>{};
      }

      if (existingRelations.isEmpty()) {
        AccountContactRelation newAcr = new AccountContactRelation(
          AccountId = newContactUser.AccountId,
          ContactId = customerContactId,
          MTC_Role__c = mtcRole
        );
        insert newAcr;
      } else {
        if (existingRelations[0].MTC_Role__c != mtcRole) {
          existingRelations[0].MTC_Role__c = mtcRole;
          update existingRelations;
        }
      }
    } else {
      if (!existingContact.Is_User_Required__c) {
        // Existing ACR, we just need to update the Contact record and the ACR record
        update new Contact(Id = existingContact.Id, Is_User_Required__c = true);
      }
      update new AccountContactRelation(
        Id = existingACRs[0].Id,
        MTC_Role__c = mtcRole
      );
    }
    return new APIResponse('OK', 200);
  }

  public static Map<Id, List<AccountContactRelation>> getAllACRsRelatedToUsers(
    Set<Id> userIds
  ) {
    Map<Id, Id> conId2userId = new Map<Id, Id>();
    for (User u : [SELECT ContactId FROM User WHERE Id IN :userIds]) {
      conId2userId.put(u.ContactId, u.Id);
    }
    Map<Id, List<AccountContactRelation>> usrId2acrs = new Map<Id, List<AccountContactRelation>>();
    for (AccountContactRelation acr : [
      SELECT ContactId, AccountId, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId IN :conId2userId.keySet()
    ]) {
      Id userId = conId2userId.get(acr.ContactId);
      List<AccountContactRelation> acrs4contact = usrId2acrs.get(userId);
      if (acrs4contact == null) {
        usrId2acrs.put(userId, new List<AccountContactRelation>{ acr });
      } else {
        acrs4contact.add(acr);
      }
    }
    return usrId2acrs;
  }
}