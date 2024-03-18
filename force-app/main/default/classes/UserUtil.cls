public with sharing class UserUtil {
  public static User getUserDetails(Id userId) {
    Id userIdForQuery = userId != null ? userId : UserInfo.getUserId();
    try {
      return [
        SELECT
          Id,
          Username,
          Date_Expires__c,
          ContactId,
          Contact.Approval_Status__c,
          Contact.AccountId,
          Hidden_Report_IDs_JSON__c,
          Profile.Name
        FROM User
        WHERE Id = :userIdForQuery
        LIMIT 1
      ];
    } catch (Exception e) {
      return null;
    }
  }

  public static void setEmailVisibilityNoDML(List<User> users) {
    for (User u : users) {
      u.UserPreferencesShowEmailToExternalUsers = true;
    }
  }
}