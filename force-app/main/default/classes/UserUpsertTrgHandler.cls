public without sharing class UserUpsertTrgHandler {
  public static Boolean triggerHasRun = false;
  private static final String TCStr = 'ToxClear';
  private static final String MTCStr = 'MTC';

  static List<String> userEditableFields = new List<String>();
  static List<String> contactEditableFields = new List<String>();
  static List<String> possibleEditableFields = new List<String>{
    'FirstName',
    'LastName',
    'Email',
    'Phone',
    'Street',
    'City',
    'State',
    'PostalCode',
    'Country',
    'MailingStreet',
    'MailingCity',
    'MailingState',
    'MailingPostalCode',
    'MailingCountry'
  };

  static {
    // - Users
    Map<String, Schema.SObjectField> userFields = Schema.getGlobalDescribe()
      .get('User')
      .getDescribe()
      .fields.getMap();
    for (Schema.SObjectField field : userFields.values()) {
      Schema.DescribeFieldResult fieldResult = field.getDescribe();
      String fieldName = fieldResult.getname();
      if (possibleEditableFields.contains(fieldName)) {
        userEditableFields.add(fieldName);
      }
    }

    // - Contacts
    Map<String, Schema.SObjectField> contactFields = Schema.getGlobalDescribe()
      .get('Contact')
      .getDescribe()
      .fields.getMap();
    for (Schema.SObjectField field : contactFields.values()) {
      Schema.DescribeFieldResult fieldResult = field.getDescribe();
      String fieldName = fieldResult.getname();
      if (possibleEditableFields.contains(fieldName)) {
        contactEditableFields.add(fieldName);
      }
    }
  }

  @InvocableMethod(label='After User Upsert Event')
  public static void afterInsert(List<User_Upsert__e> upsertEvents) {
    List<Id> userIds = new List<Id>();
    List<Id> newUserIds = new List<Id>();

    for (User_Upsert__e evt : upsertEvents) {
      userIds.addAll(
        (List<Id>) JSON.deserialize(evt.User_Ids__c, List<Id>.class)
      );

      if (evt.Is_Insert__c) {
        newUserIds.addAll(
          (List<Id>) JSON.deserialize(evt.User_Ids__c, List<Id>.class)
        );
      }
    }

    String userQuery = 'SELECT Id ';

    for (String s : userEditableFields) {
      userQuery = userQuery + ',' + s;
    }
    if (!userQuery.containsIgnoreCase('ContactId')) {
      userQuery = userQuery + ',' + 'ContactId';
    }
    if (!userQuery.containsIgnoreCase('AccountId')) {
      userQuery = userQuery + ',' + 'AccountId';
    }
    if (!userQuery.containsIgnoreCase('IsActive')) {
      userQuery = userQuery + ',' + 'IsActive';
    }
    if (!userQuery.containsIgnoreCase('Contact.Account.Is_MTC_Account__c')) {
      userQuery = userQuery + ',' + 'Contact.Account.Is_MTC_Account__c';
    }
    if (
      !userQuery.containsIgnoreCase('Contact.Account.Is_ToxClear_Account__c')
    ) {
      userQuery = userQuery + ',' + 'Contact.Account.Is_ToxClear_Account__c';
    }
    userQuery = userQuery + ' FROM User WHERE Id IN :userIds';

    List<User> users = Database.query(userQuery);

    ReportAccessUtil.newUser(users);
    MTCUserUtil.userDeactivatedUpdateMTCACRs(users);
    TC_TriggeredSharing.processNewOrUpdatedUsers(userIds);
    UserAccessUtil.createMissingUserShares(users);
    GroupAccessUtil.newUser(users);
    syncUserWithContact(users, newUserIds);
  }

  static void syncUserWithContact(List<User> newRecords, List<Id> newUserIds) {
    if (!triggerHasRun) {
      triggerHasRun = true;
      List<Contact> contactsToUpdate = new List<Contact>();
      Set<Id> contactIds = new Set<Id>();

      for (User u : newRecords) {
        contactIds.add(u.ContactId);
      }

      String contactQuery = 'SELECT Id ';

      for (String s : contactEditableFields) {
        contactQuery = contactQuery + ',' + s;
      }

      contactQuery =
        contactQuery +
        ', (SELECT Id FROM Users) FROM Contact WHERE Id IN :contactIds';

      Map<Id, Contact> userIdToContactMap = new Map<Id, Contact>();
      for (Contact c : (List<Contact>) Database.query(contactQuery)) {
        for (User u : c.Users) {
          userIdToContactMap.put(u.Id, c);
        }
      }

      for (User u : newRecords) {
        Boolean contactUpdatePerformed = false;

        if (userIdToContactMap.get(u.Id) != null) {
          Contact c = userIdToContactMap.get(u.Id);

          if (newUserIds.contains(u.Id)) {
            if (u.Contact.Account.Is_MTC_Account__c) {
              c.Community_User_Type__c = MTCStr;
              contactUpdatePerformed = true;
            } else if (u.Contact.Account.Is_ToxClear_Account__c) {
              c.Community_User_Type__c = TCStr;
              contactUpdatePerformed = true;
            }
          }

          for (String f : contactEditableFields) {
            String userFieldName = f;

            if (
              f == 'MailingStreet' ||
              f == 'MailingCity' ||
              f == 'MailingState' ||
              f == 'MailingPostalCode' ||
              f == 'MailingCountry'
            ) {
              userFieldName = userFieldName.remove('Mailing');
            }

            if (userEditableFields.contains(userFieldName)) {
              if (u.get(userFieldName) != c.get(f)) {
                c.put(f, u.get(userFieldName));
                contactUpdatePerformed = true;
              }
            }
          }
          if (contactUpdatePerformed) {
            contactsToUpdate.add(c);
          }
        }
      }

      if (!contactsToUpdate.isEmpty()) {
        try {
          update contactsToUpdate;
        } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, e.getMessage());
        }
      }
    }
  }
}