@IsTest
public with sharing class TC_UserDetailControllerTest {
  // test with valid (current) user id and invalid

  @IsTest
  static void getUserDetails_valid() {
    User thisUser = [
      SELECT FirstName, LastName, Title
      FROM User
      WHERE Id = :System.UserInfo.getUserId()
      LIMIT 1
    ];

    Map<String, String> returnedUser = TC_UserDetailController.getUserDetails(
      System.UserInfo.getUserId()
    );

    System.assertEquals(thisUser.FirstName, returnedUser.get('FirstName'));
    System.assertEquals(thisUser.LastName, returnedUser.get('LastName'));
    System.assertEquals(thisUser.Title, returnedUser.get('Title'));
  }

  @IsTest
  static void getUserDetails_invalid() {
    Account newAccount = TC_TestDataFactory_Accounts.create(
      TC_TestDataFactory_Accounts.facilityTemplate
    );
    insert newAccount;

    Boolean threwException = false;

    try {
      TC_UserDetailController.getUserDetails(newAccount.Id);
    } catch (AuraHandledException e) {
      threwException = true;
    }

    System.assert(threwException);
  }
}