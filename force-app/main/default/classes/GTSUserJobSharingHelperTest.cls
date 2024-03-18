/*
 * @author       Globant
 * @created      8-March-2024
 * @description  Test class to verify the functionality of GTSUserJobSharingHelper
 */
@IsTest
private class GTSUserJobSharingHelperTest {
  @TestSetup
  static void setupData() {
    Account parentAccount = GTSTestDataFactory.createAccount(
      'ParentAccount',
      true
    );
    Account customerAccount = GTSTestDataFactory.createAccount(
      'CustomerAccount',
      false
    );
    customerAccount.ParentId = parentAccount.Id;
    insert customerAccount;

    List<String> gtsJobRecordTypes = new List<String>{
      'GTS_Certificate_of_Conformity',
      'GTS_Registration_License_Product_Certificate',
      'GTS_Commercial_Service'
    };
    List<RecordType> jobRecordTypes = [
      SELECT Id
      FROM RecordType
      WHERE DeveloperName IN :gtsJobRecordTypes AND SobjectType = 'iCare_Job__c'
    ];
    List<iCare_Job__c> jobs = new List<iCare_Job__c>();
    for (RecordType recordType : jobRecordTypes) {
      jobs.add(
        GTSTestDataFactory.createJob(recordType.Id, customerAccount.Id, false)
      );
    }
    insert jobs;
  }

  @IsTest
  private static void shareJobRecordsWithManagersTest() {
    Account customerAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'CustomerAccount'
    ];
    List<User> usersToProcess = createUsers(
      'GTS_Portal_Manager',
      customerAccount.Id
    );
    List<Id> usersToProcessIds = new List<Id>{
      usersToProcess[0].Id,
      usersToProcess[1].Id
    };

    Test.startTest();
    GTSUserJobSharingHelper.shareJobRecordsWithManagers(usersToProcessIds);
    Test.stopTest();

    List<iCare_Job__Share> jobShares = [
      SELECT Id
      FROM iCare_Job__Share
      WHERE UserOrGroupId IN :usersToProcessIds
    ];
    System.assert(jobShares != null && !jobShares.isEmpty());
    //3 jobs shared with 2 users
    System.assert(jobShares.size() == 6);
  }
  @IsTest
  private static void shareJobRecordsWithGroupManagersTest() {
    Account customerAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'CustomerAccount'
    ];
    List<User> usersToProcess = createUsers(
      'GTS_Portal_Group_Manager',
      customerAccount.Id
    );
    List<Id> usersToProcessIds = new List<Id>{
      usersToProcess[0].Id,
      usersToProcess[1].Id
    };

    Test.startTest();
    GTSUserJobSharingHelper.shareJobRecordsWithManagersGroup(usersToProcessIds);
    Test.stopTest();

    List<iCare_Job__Share> jobShares = [
      SELECT Id
      FROM iCare_Job__Share
      WHERE UserOrGroupId IN :usersToProcessIds
    ];
    System.assert(jobShares != null && !jobShares.isEmpty());
    //3 jobs shared with 2 users
    System.assert(jobShares.size() == 6);
  }

  @IsTest
  private static void shareJobRecordsWithGroupManagersParentAccountTest() {
    Account parentAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'ParentAccount'
    ];

    List<User> usersToProcess = createUsers(
      'GTS_Portal_Group_Manager',
      parentAccount.Id
    );
    List<Id> usersToProcessIds = new List<Id>{
      usersToProcess[0].Id,
      usersToProcess[1].Id
    };

    Test.startTest();
    GTSUserJobSharingHelper.shareJobRecordsWithManagersGroup(usersToProcessIds);
    Test.stopTest();

    List<iCare_Job__Share> jobShares = [
      SELECT Id
      FROM iCare_Job__Share
      WHERE UserOrGroupId IN :usersToProcessIds
    ];
    System.assert(jobShares != null && !jobShares.isEmpty());
    //3 jobs shared with 2 users
    System.assert(jobShares.size() == 6);
  }

  private static List<User> createUsers(
    String permissionSetName,
    Id accountId
  ) {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Id customerProfileId = [
      SELECT Id
      FROM Profile
      WHERE Name = 'iCare External Standard User'
      LIMIT 1
    ]
    .Id;
    List<User> users = new List<User>();
    //Using system.runAs to avoid mixed DML errors
    System.runAs(currentUser) {
      List<Contact> contacts = new List<Contact>();
      for (Integer i = 0; i < 2; i++) {
        contacts.add(
          GTSTestDataFactory.createContact('ContName' + i, accountId, false)
        );
      }
      insert contacts;

      users = new List<User>();
      for (Contact contact : contacts) {
        users.add(
          GTSTestDataFactory.createUser(
            contact.LastName,
            customerProfileId,
            contact.Id,
            false
          )
        );
      }
      insert users;

      PermissionSetGroup psg = [
        SELECT Id, DeveloperName
        FROM PermissionSetGroup
        WHERE DeveloperName = :permissionSetName
      ];
      List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();

      for (User user : users) {
        permissionSetAssignments.add(
          new PermissionSetAssignment(
            AssigneeId = user.Id,
            PermissionSetGroupId = psg.Id
          )
        );
      }
      insert permissionSetAssignments;
    }
    return users;
  }
}