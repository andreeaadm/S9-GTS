/*
 * @author       Globant
 * @created      8-March-2024
 * @description  Test class to verify the functionality of GTSJobSharingHelper
 */
@IsTest
private class GTSJobSharingHelperTest {
  @TestSetup
  static void setupData() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Id customerProfileId = [
      SELECT Id
      FROM Profile
      WHERE Name = 'iCare External Standard User'
      LIMIT 1
    ]
    .Id;

    //Using system.runAs to avoid mixed DML errors
    System.runAs(currentUser) {
      Account customerAccount = GTSTestDataFactory.createAccount(
        'ParentAccount',
        true
      );

      List<Contact> contacts = new List<Contact>();
      for (Integer i = 0; i < 2; i++) {
        contacts.add(
          GTSTestDataFactory.createContact(
            'ContName' + i,
            customerAccount.Id,
            false
          )
        );
      }
      insert contacts;

      List<User> users = new List<User>();
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

      List<String> permissionSetGroupDeveloperNames = new List<String>{
        'GTS_Portal_Manager',
        'GTS_Portal_Group_Manager'
      };

      List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
      for (PermissionSetGroup psg : [
        SELECT Id, DeveloperName
        FROM PermissionSetGroup
        WHERE DeveloperName IN :permissionSetGroupDeveloperNames
      ]) {
        if (psg.DeveloperName == permissionSetGroupDeveloperNames[0]) {
          permissionSetAssignments.add(
            new PermissionSetAssignment(
              AssigneeId = users[0].Id,
              PermissionSetGroupId = psg.Id
            )
          );
        } else if (psg.DeveloperName == permissionSetGroupDeveloperNames[1]) {
          permissionSetAssignments.add(
            new PermissionSetAssignment(
              AssigneeId = users[1].Id,
              PermissionSetGroupId = psg.Id
            )
          );
        }
      }

      insert permissionSetAssignments;
    }
  }
  @IsTest
  private static void createJobShareRecordsTest() {
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

    List<User> users = [
      SELECT Id, AccountId, UserType
      FROM User
      WHERE Account.Name = 'ParentAccount'
    ];

    List<iCare_Job__c> jobs = new List<iCare_Job__c>();
    for (RecordType recordType : jobRecordTypes) {
      jobs.add(
        GTSTestDataFactory.createJob(recordType.Id, users[0].AccountId, false)
      );
    }
    insert jobs;

    List<Id> jobsToProcessIds = new List<Id>();
    for (iCare_Job__c job : jobs) {
      jobsToProcessIds.add(job.Id);
    }

    List<String> permissionSetGroupDeveloperNames = new List<String>{
      'GTS_Portal_Manager',
      'GTS_Portal_Group_Manager'
    };
    List<PermissionSetGroup> permissionSetGroups = [
      SELECT Id, DeveloperName
      FROM PermissionSetGroup
      WHERE DeveloperName = :permissionSetGroupDeveloperNames
      ORDER BY DeveloperName
    ];
    Test.startTest();
    GTSJobSharingHelper.createJobShareRecords(
      jobsToProcessIds,
      permissionSetGroups[0].Id,
      permissionSetGroups[1].Id
    );
    Test.stopTest();

    List<iCare_Job__Share> jobShares = [
      SELECT Id, ParentId, UserOrGroupId
      FROM iCare_Job__Share
      WHERE ParentID IN :jobs AND UserOrGroupId IN :users
    ];
    System.assert(jobShares != null && !jobShares.isEmpty());
    System.assert(jobShares.size() == 6);
  }

  @IsTest
  private static void createJobShareRecords_ParentAccountTest() {
    Account parentAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'ParentAccount'
    ];
    Account childAccount = GTSTestDataFactory.createAccount(
      'ChildAccount',
      false
    );
    childAccount.ParentId = parentAccount.Id;
    insert childAccount;

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

    List<User> users = [
      SELECT
        Id,
        AccountId,
        UserType,
        Name,
        (
          SELECT Id, PermissionSetGroup.DeveloperName
          FROM PermissionSetAssignments
        )
      FROM User
      WHERE AccountId = :parentAccount.Id
    ];

    List<iCare_Job__c> jobs = new List<iCare_Job__c>();
    for (RecordType recordType : jobRecordTypes) {
      jobs.add(
        GTSTestDataFactory.createJob(recordType.Id, childAccount.Id, false)
      );
    }
    insert jobs;

    List<Id> jobsToProcessIds = new List<Id>();
    for (iCare_Job__c job : jobs) {
      jobsToProcessIds.add(job.Id);
    }

    Test.startTest();
    PermissionSetGroup portalManagerGroupRecordType = [
      SELECT Id, DeveloperName
      FROM PermissionSetGroup
      WHERE DeveloperName = 'GTS_Portal_Group_Manager'
    ];

    GTSJobSharingHelper.createJobShareRecords(
      jobsToProcessIds,
      null,
      portalManagerGroupRecordType.Id
    );
    Test.stopTest();

    List<iCare_Job__Share> jobShares = [
      SELECT Id, UserOrGroupId, ParentId
      FROM iCare_Job__Share
      WHERE ParentID IN :jobs AND UserOrGroupId IN :users
    ];
    System.assert(jobShares != null && !jobShares.isEmpty());
    System.assert(jobShares.size() == 3);
  }
}