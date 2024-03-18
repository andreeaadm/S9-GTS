public without sharing class TC_UserDetailController {
  @AuraEnabled(cacheable=true)
  public static Map<String, String> getUserDetails(Id recordId) {
    try {
      User detailUser = [
        SELECT FirstName, LastName, Title
        FROM User
        WHERE Id = :recordId
      ];
      return new Map<String, String>{
        'FirstName' => detailUser.FirstName,
        'LastName' => detailUser.LastName,
        'Title' => detailUser.Title
      };
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}