public with sharing class ContactTrgHandler extends TriggerHandler {
  public static Boolean triggerHasRun = false;

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
      if (fieldResult.isUpdateable()) {
        String fieldName = fieldResult.getname();
        if (possibleEditableFields.contains(fieldName)) {
          userEditableFields.add(fieldName);
        }
      }
    }

    // - Contacts
    Map<String, Schema.SObjectField> contactFields = Schema.getGlobalDescribe()
      .get('Contact')
      .getDescribe()
      .fields.getMap();
    for (Schema.SObjectField field : contactFields.values()) {
      Schema.DescribeFieldResult fieldResult = field.getDescribe();
      if (fieldResult.isUpdateable()) {
        String fieldName = fieldResult.getname();
        if (possibleEditableFields.contains(fieldName)) {
          contactEditableFields.add(fieldName);
        }
      }
    }
  }

  public override void afterUpdate() {
    if (!triggerHasRun && !UserUpsertTrgHandler.triggerHasRun) {
      List<Contact> newContacts = (List<Contact>) Trigger.new;
      TC_TriggeredSharing.processUpdatedContacts(newContacts);

      syncContactWithUser(newContacts);
    }
  }

  static void syncContactWithUser(List<Contact> newRecords) {
    triggerHasRun = true;
    List<User> usersToUpdate = new List<User>();
    Set<Id> contactIdList = new Set<Id>();
    Map<String, User> contactIdToUserMap = new Map<String, User>();

    for (Contact c : newRecords) {
      contactIdList.add(c.Id);
    }

    String userQuery = 'SELECT Id ';

    for (String s : userEditableFields) {
      userQuery = userQuery + ',' + s;
    }

    if (!userQuery.containsIgnoreCase('ContactId')) {
      userQuery = userQuery + ',' + 'ContactId';
    }

    userQuery = userQuery + ' FROM User WHERE ContactId IN :contactIdList';

    for (User u : (List<User>) Database.query(userQuery)) {
      contactIdToUserMap.put(u.ContactId, u);
    }

    for (Contact c : newRecords) {
      Boolean userUpdatePerformed = false;

      if (contactIdToUserMap.get(c.Id) != null) {
        User u = contactIdToUserMap.get(c.Id);

        for (String f : userEditableFields) {
          String contactFieldName = f;

          if (
            f == 'Street' ||
            f == 'City' ||
            f == 'State' ||
            f == 'PostalCode' ||
            f == 'Country'
          ) {
            contactFieldName = 'Mailing' + f;
          }

          if (contactEditableFields.contains(contactFieldName)) {
            if (c.get(contactFieldName) != u.get(f)) {
              u.put(f, c.get(contactFieldName));
              userUpdatePerformed = true;
            }
          }
        }
        if (userUpdatePerformed) {
          usersToUpdate.add(u);
        }
      }
    }
    if (!usersToUpdate.isEmpty()) {
      try {
        update usersToUpdate;
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
      }
    }
  }
}