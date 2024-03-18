public with sharing class ManageCompaniesPanelController {
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getData() {
    Map<String, Object> returnData = new Map<String, Object>{
      'isCga' => false,
      'isAdmin' => false,
      'message' => ''
    };
    try {
      User u = [
        SELECT ContactId, Contact.AccountId
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
      ];
      for (AccountContactRelation acr : [
        SELECT ContactId, Contact.Name, Contact.Email, MTC_Role__c
        FROM AccountContactRelation
        WHERE
          AccountId = :u.Contact.AccountId
          AND (ContactId = :u.ContactId
          OR MTC_Role__c = 'CGA')
      ]) {
        // is the loop contact the current user's contact?
        if (acr.ContactId == u.ContactId) {
          // is the current user the CGA?
          if (acr.MTC_Role__c == 'CGA') {
            returnData.put('isCga', true);
            returnData.put('isAdmin', true);
            // if not, are they an admin?
          } else if (acr.MTC_Role__c == 'Admin') {
            returnData.put('isCga', false);
            returnData.put('isAdmin', true);
          } else {
            returnData.put('isCga', false);
            returnData.put('isAdmin', false);
          }

          // is the loop contact *not* the current user's contact, and are they a CGA?
        } else if (acr.MTC_Role__c == 'CGA') {
          returnData.put(
            'message',
            'If you require access to specific reports, please email ' +
            acr.Contact.Name +
            ', ' +
            acr.Contact.Email +
            '.'
          );
        }
      }
      return returnData;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }
}