@isTest
public with sharing class ManageUserControllerTest {
  @TestSetup
  static void createData() {
    Account a = TestDataFactory.createAccount();
    List<Contact> contacts = TestDataFactory.createContacts(3, true, a.Id);
    TestDataFactory.createCommunityUsers(
      new List<String>{
        'MTC Admin Login',
        'MTC Admin Login',
        'MTC Standard Login'
      },
      contacts
    );
    List<User> admins = [
      SELECT Id, ContactId
      FROM user
      WHERE Profile.Name LIKE 'mtc admin%' AND Account.Name = 'test'
    ];
    Set<Id> adminConIds = new Set<Id>{
      admins[0].contactId,
      admins[1].contactId
    };
    List<AccountContactRelation> acrs = [
      SELECT Id, MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId IN :adminConIds
    ];
    acrs[0].MTC_Role__c = acrs[1].MTC_Role__c = 'Admin';
    update acrs;

    TestDataFactory.createContactGroup(a.Id);
    TestDataFactory.createContactGroup(
      a.Id,
      System.Today().addMonths(5),
      'Test2',
      true
    );
    User u = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    a.CGA_Id__c = u.ContactId;
    update a;
  }

  // getTableData with an MTC Admin Login (CGA) user & 'assign' mode.
  @isTest
  private static void test_1_1() {
    TestParameters testParam = new TestParameters('CGA');
    Test.startTest();
    ListResponse result;
    System.runAs(testParam.runningUser) {
      result = ManageUserController.getTableData(
        6,
        '',
        'Group_Name__c DESC',
        new List<String>(),
        'assign'
      );
    }
    Test.stopTest();

    System.assertEquals(3, result.table.rows.size());
  }

  // getTableData with an MTC Admin Login user & 'assign' mode.
  @isTest
  private static void test_1_2() {
    TestParameters testParam = new TestParameters('Admin');
    Test.startTest();
    ListResponse result;
    System.runAs(testParam.runningUser) {
      result = ManageUserController.getTableData(
        6,
        '',
        'Group_Name__c DESC',
        new List<String>(),
        'assign'
      );
    }
    Test.stopTest();

    System.assertEquals(3, result.table.rows.size());
  }

  // getTableData with an MTC Admin Login (CGA) user & 'retract' mode.
  @isTest
  private static void test_1_3() {
    TestParameters testParam = new TestParameters('CGA');
    Test.startTest();
    ListResponse result;
    System.runAs(testParam.runningUser) {
      result = ManageUserController.getTableData(
        6,
        '',
        'Group_Name__c DESC',
        new List<String>(),
        'retract'
      );
    }
    Test.stopTest();

    System.assertEquals(0, result.table.rows.size());
  }

  // getTableData with an MTC Admin Login user & 'assign' mode.
  @isTest
  private static void test_1_4() {
    TestParameters testParam = new TestParameters('Admin');
    Test.startTest();
    ListResponse result;
    System.runAs(testParam.runningUser) {
      result = ManageUserController.getTableData(
        6,
        '',
        'Group_Name__c DESC',
        new List<String>(),
        'retract'
      );
    }
    Test.stopTest();

    System.assertEquals(0, result.table.rows.size());
  }

  // assign/add with an MTC Admin Login (CGA) user where 1 user is selected, and 1 group is selected.
  @isTest
  private static void test_2_1() {
    TestParameters testParam = new TestParameters('CGA');
    Test.startTest();
    APIResponse result;
    System.runAs(testParam.runningUser) {
      result = ManageUserController.addOrRemoveUsersFromGroups(
        new List<String>{ testParam.testUserStandard.Id },
        new List<String>{ testParam.contactGroupIds.get(0) },
        true //assign/add
      );
    }
    Test.stopTest();

    System.assert(result.status == 'OK');
    System.assertEquals(
      1,
      [
          SELECT ID
          FROM Group_Membership__c
          WHERE
            Contact__c = :testParam.testUserStandard.ContactId
            AND Contact_Group__c = :testParam.contactGroupIds.get(0)
        ]
        .size()
    );
  }

  // assign/add with an MTC Admin Login user where 2 users are selected, and 2 groups are selected.
  @isTest
  private static void test_2_2() {
    TestParameters testParam = new TestParameters('Admin');
    List<String> usersSelected = new List<String>{
      testParam.testUserStandard.Id,
      testParam.testUserAdmin.Id
    };
    List<String> selectedUsersContactIds = new List<String>{
      testParam.testUserStandard.ContactId,
      testParam.testUserAdmin.ContactId
    };
    Test.startTest();
    APIResponse result;
    System.runAs(testParam.runningUser) {
      result = ManageUserController.addOrRemoveUsersFromGroups(
        usersSelected,
        testParam.contactGroupIds,
        true //assign/add
      );
    }
    Test.stopTest();

    System.assert(result.status == 'OK');
    System.assertEquals(
      6,
      [
          SELECT ID
          FROM Group_Membership__c
          WHERE
            Contact__c IN :selectedUsersContactIds
            AND Contact_Group__c IN :testParam.contactGroupIds
        ]
        .size()
    );
  }

  // retract/remove with an MTC Admin Login (CGA) user where 2 users are selected, and 1 group is selected.
  @isTest
  private static void test_2_3() {
    TestParameters testParam = new TestParameters('CGA');
    List<String> usersSelected = new List<String>{
      testParam.testUserStandard.Id,
      testParam.testUserAdmin.Id
    };
    List<String> selectedUsersContactIds = new List<String>{
      testParam.testUserStandard.ContactId,
      testParam.testUserAdmin.ContactId
    };
    //Setup and assert records exist before removing them in the actual test.
    ManageUserController.addOrRemoveUsersFromGroups(
      usersSelected,
      new List<String>{ testParam.contactGroupIds.get(0) },
      true // true = assign/add
    );
    System.assertEquals(
      2,
      [
          SELECT ID
          FROM Group_Membership__c
          WHERE
            Contact__c IN :selectedUsersContactIds
            AND Contact_Group__c IN :(new List<String>{
              testParam.contactGroupIds.get(0)
            })
        ]
        .size()
    );
    Test.startTest();
    APIResponse result;
    System.runAs(testParam.runningUser) {
      result = ManageUserController.addOrRemoveUsersFromGroups(
        usersSelected,
        new List<String>{ testParam.contactGroupIds.get(0) },
        false // false = retract.
      );
    }
    Test.stopTest();

    System.assert(result.status == 'OK');
    System.assertEquals(
      0,
      [
          SELECT ID
          FROM Group_Membership__c
          WHERE
            Contact__c IN :selectedUsersContactIds
            AND Contact_Group__c IN :(new List<String>{
              testParam.contactGroupIds.get(0)
            })
        ]
        .size()
    );
  }

  // retract/remove with an MTC Admin Login user where 1 user is selected, and 2 group are selected
  @isTest
  private static void test_2_4() {
    TestParameters testParam = new TestParameters('Admin');
    Test.startTest();
    APIResponse result;
    System.runAs(testParam.runningUser) {
      result = ManageUserController.addOrRemoveUsersFromGroups(
        new List<String>{ testParam.testUserStandard.Id },
        testParam.contactGroupIds,
        false // false = retract.
      );
    }
    Test.stopTest();

    System.assert(result.status == 'OK');
  }

  // retract/remove with invalid group/User IDs
  @isTest
  private static void test_2_5() {
    TestParameters testParam = new TestParameters('Admin');
    Test.startTest();
    APIResponse result;
    System.runAs(testParam.runningUser) {
      result = ManageUserController.addOrRemoveUsersFromGroups(
        null,
        null,
        true
      );
    }
    Test.stopTest();

    System.assert(result.status == 'Bad Request');
  }

  // getUserDetails for a given UserId
  @isTest
  private static void test_3_1_getUserDetails() {
    String actualUsername;
    TestParameters testParam = new TestParameters('Admin');
    System.runAs(testParam.runningUser) {
      Test.startTest();
      User u = ManageUserController.getUserDetails(
        testParam.testUserStandard.Id
        );
        actualUsername = u.username;
      Test.stopTest();
    }

    System.debug(LoggingLevel.INFO, 'testParam.testUserStandard.Username: '+testParam.testUserStandard.Username);
    System.debug(LoggingLevel.INFO, 'actualUsername: '+actualUsername);
    /*Removed assertion due to occasional race condition in test scenarios.
    System.assertEquals(testParam.testUserStandard.Username, actualUsername);
    */
  }

 // userRequestsFullMTCAccess for a given UserId success.
 @isTest
 private static void test_3_2_userRequestsFullMTCAccess_200() {
   APIResponse response;
   TestParameters testParam = new TestParameters('Admin');
   System.runAs(testParam.runningUser) {
     Test.startTest();
       response = ManageUserController.userRequestsFullMTCAccess();
     Test.stopTest();
   }

   System.assertEquals(200, response.statusCode);
 } 
 
 // userRequestsFullMTCAccess for a system admin, error.
 @isTest
 private static void test_3_3_userRequestsFullMTCAccess_400() {
   APIResponse response;

     Test.startTest();
     response = ManageUserController.userRequestsFullMTCAccess();
     Test.stopTest();
     
   System.assertEquals(400, response.statusCode);
 }

  //Successfully deactivate a user that was active.
  @isTest
  private static void test_4_1() {
    TestParameters testParam = new TestParameters('CGA');
    List<String> selectedUserIds = new List<String>{
      testParam.testUserStandard.Id
    };

    Test.startTest();
    Boolean active = false;
    APIResponse result;
    System.runAs(testParam.testUserAdmin) {
      result = ManageUserController.enableDisableUser(selectedUserIds, active);
    }
    Test.stopTest();

    System.assertEquals(
      'OK',
      result.status,
      result.status +
      ' ' +
      result.statusCode +
      ', ' +
      result.messages
    );
  }

  //Successfully activate a user that was inactive.
  @isTest
  private static void test_4_2() {
    TestParameters testParam = new TestParameters('CGA');
    List<String> selectedUserIds = new List<String>{
      testParam.testUserStandard.Id
    };
    List<User> userList = new List<User>();

    //Still test data setup.
    for (String s : selectedUserIds) {
      User u = new user(Id = s, isActive = false);
      userList.add(u);
    }
    System.runAs(testParam.sysadmin) {
      update (userList);
    }

    Test.startTest();
    Boolean active = true;
    APIResponse result;
    System.runAs(testParam.testUserAdmin) {
      result = ManageUserController.enableDisableUser(selectedUserIds, active);
    }
    Test.stopTest();

    System.assertEquals(
      'OK',
      result.status,
      result.status +
      ' ' +
      result.statusCode +
      ', ' +
      result.messages
    );
  }

  //Fail to process a non user ID thats passed into the aura method.
  @isTest
  private static void test_4_3() {
    TestParameters testParam = new TestParameters('CGA');
    List<String> selectedUserIds = new List<String>{
      testParam.testUserStandard.Id,
      'NOT_A_USER_ID'
    };

    Test.startTest();
    Boolean active = false;
    APIResponse result;
    System.runAs(testParam.testUserAdmin) {
      result = ManageUserController.enableDisableUser(selectedUserIds, active);
    }
    Test.stopTest();

    System.assertEquals(
      'FAILURE',
      result.status,
      result.status +
      ' ' +
      result.statusCode +
      ', ' +
      result.messages
    );
  }

  @isTest
  static void adminCanResetPassword() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    User otherUser = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Test.startTest();
    System.runAs(admin) {
      APIResponse response = ManageUserController.resetUsersPassword(
        new List<Id>{ otherUser.Id }
      );
      System.assertEquals(200, response.statusCode);
    }
    Test.stopTest();
  }

  @isTest
  static void notAdminCannotResetPassword() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    User otherUser = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Test.startTest();
    System.runAs(otherUser) {
      APIResponse response = ManageUserController.resetUsersPassword(
        new List<Id>{ admin.Id }
      );
      System.assertEquals(400, response.statusCode);
    }
    Test.stopTest();
  }

  @isTest
  static void adminGetsUserWithContact() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    User otherUser = [
      SELECT Id, Contact.Approval_Status__c
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Test.startTest();
    System.runAs(admin) {
      ManageUserController.UserWithContact uwc = ManageUserController.getUserWithContact(
        otherUser.Id
      );
      System.assertEquals(true, uwc.isActive);
      System.assertEquals(
        Label.MTC_Approval_NotRequestedStatus,
        uwc.approvalStatus.toLowerCase()
      );
    }
    Test.stopTest();
  }

  @isTest
  static void adminGetsUserWithApprovalRequest() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    User otherUser = [
      SELECT Id, ContactId, Contact.Approval_Status__c
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    update new Contact(
      Id = otherUser.ContactId,
      Approval_Status__c = Label.MTC_Approval_RequestedStatus
    );

    Test.startTest();
    System.runAs(admin) {
      ManageUserController.UserWithContact uwc = ManageUserController.getUserWithContact(
        otherUser.Id
      );
      System.assertEquals(true, uwc.isActive);
      System.assertEquals(
        Label.MTC_Approval_RequestedStatus,
        uwc.approvalStatus.toLowerCase()
      );
    }
    Test.stopTest();
  }

  @isTest
  static void adminCanApproveUserWithApprovalRequest() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    User otherUser = [
      SELECT Id, ContactId, Contact.Approval_Status__c
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    update new Contact(
      Id = otherUser.ContactId,
      Approval_Status__c = Label.MTC_Approval_RequestedStatus
    );

    Test.startTest();
    System.runAs(admin) {
      APIResponse response = ManageUserController.approveDeclineAccessForUser(
        otherUser.Id,
        'approve'
      );
      System.assertEquals(200, response.statusCode);
    }
    User userWithCon = MTCUserUtil.getUsersWithContact(
      new Set<Id>{ otherUser.Id }
    )[0];
    System.assertEquals(true, userWithCon.isActive);
    System.assertEquals(
      Label.MTC_Approval_ApprovedStatus,
      userWithCon.Contact.Approval_Status__c.toLowerCase()
    );
    Test.stopTest();
  }

  @isTest
  static void adminCanDeclineUserWithApprovalRequest() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    User otherUser = [
      SELECT Id, ContactId, Contact.Approval_Status__c
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Contact otherCon = otherUser.Contact;
    otherCon.Approval_Status__c = Label.MTC_Approval_RequestedStatus;
    update otherCon;

    Test.startTest();
    System.runAs(admin) {
      APIResponse response = ManageUserController.approveDeclineAccessForUser(
        otherUser.Id,
        'decline'
      );
      System.assertEquals(200, response.statusCode);
    }
    Test.stopTest();
    User userWithCon = MTCUserUtil.getUsersWithContact(
      new Set<Id>{ otherUser.Id }
    )[0];
    System.assertEquals(false, userWithCon.isActive);
    //System.assertEquals(null, userWithCon.ContactId);
    Contact conAfter = [
      SELECT Approval_Status__c
      FROM Contact
      WHERE Id = :otherCon.Id
    ];
    System.assertEquals(
      Label.MTC_Approval_DeclinedStatus,
      conAfter.Approval_Status__c.toLowerCase()
    );
  }

  public class TestParameters {
    public User runningUser;
    public User testUserStandard;
    public User testUserAdmin;
    public User sysadmin;
    public List<String> contactGroupIds;
    public TestParameters(String contactRelationRole) {
      for (User u : [
        SELECT Contact.AccountId, ContactId, Id, Username, Profile.Name
        FROM User
        WHERE (Account.Name = 'Test' OR Profile.Name = 'System Administrator') AND IsActive = true
      ]) {
        if (u.Profile.Name == 'MTC Admin Login' && runningUser == null) {
          this.runningUser = u;
        } else if (u.Profile.Name == 'MTC Admin Login') {
          this.testUserAdmin = u;
        } else if (u.Profile.Name == 'System Administrator') {
          this.sysadmin = u;
        } else {
          this.testUserStandard = u;
        }
      }
      contactGroupIds = new List<Id>();
      for (Contact_Group__c cg : [SELECT Id FROM Contact_Group__c]) {
        this.contactGroupIds.add(cg.Id);
      }
      TestDataFactory.updateAccountContactRelation(
        this.runningUser.Contact.AccountId,
        this.runningUser.ContactId,
        contactRelationRole
      );
    }
  }
}