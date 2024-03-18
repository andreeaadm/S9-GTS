/*
 * @author       Globant
 * @created      8-March-2024
 * @description  Test class to verify the functionality of GTSAccountJobSharingHelper
 */
@IsTest
private class GTSAccountJobSharingHelperTest {
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
        'CustomerAccount',
        true
      );
      Account childAccount = GTSTestDataFactory.createAccount(
        'ChildAccount',
        false
      );
      childAccount.ParentId = customerAccount.Id;
      insert childAccount;
      Account newParent = GTSTestDataFactory.createAccount(
        'NewParentAccount',
        true
      );

      Contact customerContact = GTSTestDataFactory.createContact(
        'ContName',
        customerAccount.Id,
        true
      );
      Contact newCustomerContact = GTSTestDataFactory.createContact(
        'NewContName',
        newParent.Id,
        true
      );

      User customerUser = GTSTestDataFactory.createUser(
        customerContact.LastName,
        customerProfileId,
        customerContact.Id,
        true
      );
      User newCustomerUser = GTSTestDataFactory.createUser(
        newCustomerContact.LastName,
        customerProfileId,
        newCustomerContact.Id,
        true
      );

      PermissionSetGroup groupManagerPermissionSet = [
        SELECT Id, DeveloperName
        FROM PermissionSetGroup
        WHERE DeveloperName = :'GTS_Portal_Group_Manager'
      ];
      List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
      permissionSetAssignments.add(
        new PermissionSetAssignment(
          AssigneeId = customerUser.Id,
          PermissionSetGroupId = groupManagerPermissionSet.Id
        )
      );
      permissionSetAssignments.add(
        new PermissionSetAssignment(
          AssigneeId = newCustomerUser.Id,
          PermissionSetGroupId = groupManagerPermissionSet.Id
        )
      );

      insert permissionSetAssignments;

      List<String> gtsJobRecordTypes = new List<String>{
        'GTS_Certificate_of_Conformity',
        'GTS_Registration_License_Product_Certificate',
        'GTS_Commercial_Service'
      };

      List<RecordType> jobRecordTypes = [
        SELECT Id
        FROM RecordType
        WHERE
          DeveloperName IN :gtsJobRecordTypes
          AND SobjectType = 'iCare_Job__c'
      ];

      List<iCare_Job__c> jobs = new List<iCare_Job__c>();
      for (RecordType recordType : jobRecordTypes) {
        jobs.add(
          GTSTestDataFactory.createJob(recordType.Id, childAccount.Id, false)
        );
        jobs.add(
          GTSTestDataFactory.createJob(recordType.Id, customerAccount.Id, false)
        );
      }
      insert jobs;
    }
  }

  @IsTest
  static void newExporterParent() {
    Account customerAccount = [
      SELECT Id, (SELECT Id FROM Jobs__r)
      FROM Account
      WHERE Name = 'CustomerAccount'
      LIMIT 1
    ];
    Account newParent = [
      SELECT Id
      FROM Account
      WHERE Name = 'NewParentAccount'
      LIMIT 1
    ];
    Test.startTest();
    update new Account(Id = customerAccount.Id, ParentId = newParent.Id);
    Test.stopTest();

    Map<Id, User> usersToShareWith = new Map<Id, User>(
      [SELECT Id FROM User WHERE AccountId = :newParent.Id]
    );

    List<iCare_Job__Share> jobShares = [
      SELECT Id
      FROM iCare_Job__Share
      WHERE
        UserOrGroupId IN :usersToShareWith.keySet()
        AND Parent.iCare_Supplier__c = :customerAccount.Id
    ];
    System.assert(jobShares != null && !jobShares.isEmpty());
    System.assert(jobShares.size() == customerAccount.Jobs__r.size());
  }
  @IsTest
  static void updatedExporterParentTest() {
    Account childAccount = [
      SELECT Id, ParentId, (SELECT Id FROM Jobs__r)
      FROM Account
      WHERE Name = 'ChildAccount'
      LIMIT 1
    ];
    Id oldParentAccountId = childAccount.ParentId;
    Account newParent = [
      SELECT Id
      FROM Account
      WHERE Name = 'NewParentAccount'
      LIMIT 1
    ];
    Test.startTest();
    update new Account(Id = childAccount.Id, ParentId = newParent.Id);
    Test.stopTest();

    Map<Id, User> usersToShareWith = new Map<Id, User>(
      [SELECT Id FROM User WHERE AccountId = :newParent.Id]
    );

    List<iCare_Job__Share> jobShares = [
      SELECT Id
      FROM iCare_Job__Share
      WHERE
        UserOrGroupId IN :usersToShareWith.keySet()
        AND Parent.iCare_Supplier__c = :childAccount.Id
    ];

    System.assert(jobShares != null && !jobShares.isEmpty());
    System.assert(jobShares.size() == childAccount.Jobs__r.size());

    Map<Id, User> userToRemoveAccess = new Map<Id, User>(
      [SELECT Id FROM User WHERE AccountId = :oldParentAccountId]
    );
    List<iCare_Job__Share> deletedJobShares = [
      SELECT Id
      FROM iCare_Job__Share
      WHERE
        UserOrGroupId IN :userToRemoveAccess.keySet()
        AND Parent.iCare_Supplier__c = :childAccount.Id
    ];
    System.assert(deletedJobShares.isEmpty());
  }
  @IsTest
  static void updatedNoExporterParentTest() {
    Account childAccount = [
      SELECT Id, ParentId, (SELECT Id FROM Jobs__r)
      FROM Account
      WHERE Name = 'ChildAccount'
      LIMIT 1
    ];
    Id oldParentAccountId = childAccount.ParentId;
    Test.startTest();
    update new Account(Id = childAccount.Id, ParentId = null);
    Test.stopTest();

    Map<Id, User> userToRemoveAccess = new Map<Id, User>(
      [SELECT Id FROM User WHERE AccountId = :oldParentAccountId]
    );
    List<iCare_Job__Share> deletedJobShares = [
      SELECT Id
      FROM iCare_Job__Share
      WHERE
        UserOrGroupId IN :userToRemoveAccess.keySet()
        AND Parent.iCare_Supplier__c = :childAccount.Id
    ];
    System.assert(deletedJobShares.isEmpty());
  }
}