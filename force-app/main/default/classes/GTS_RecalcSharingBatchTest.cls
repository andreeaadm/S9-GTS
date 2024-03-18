/*
 * @author       Globant
 * @created      8-March-2024
 * @description  Test class to verify the functionality of GTS_RecalcSharingOnUserCreationBatch
 */
@isTest
public class GTS_RecalcSharingBatchTest {
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
    Account customerAccount = GTSTestDataFactory.createAccount(
      'CustomerAccount',
      true
    );
    //Using system.runAs to avoid mixed DML errors
    System.runAs(currentUser) {
      List<Contact> contacts = new List<Contact>();
      for (Integer i = 0; i < 3; i++) {
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
        'GTS_Portal_Group_Manager',
        'GTS_Standard_User'
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
        } else if (psg.DeveloperName == permissionSetGroupDeveloperNames[2]) {
          permissionSetAssignments.add(
            new PermissionSetAssignment(
              AssigneeId = users[2].Id,
              PermissionSetGroupId = psg.Id
            )
          );
        }
      }

      insert permissionSetAssignments;
    }

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
  private static void executeTest() {
    Test.startTest();
    GTS_RecalcSharingOnUserCreationBatch batchClassInstance = new GTS_RecalcSharingOnUserCreationBatch();
    Database.executeBatch(batchClassInstance);
    Test.stopTest();

    Map<Id, iCare_Job__c> jobsByIds = new Map<Id, iCare_Job__c>(
      [
        SELECT Id, OwnerId
        FROM iCare_Job__c
        WHERE iCare_Supplier__r.Name = 'CustomerAccount'
      ]
    );

    List<iCare_Job__Share> jobShares = [
      SELECT Id, UserOrGroupId, ParentId, RowCause
      FROM iCare_Job__Share
      WHERE
        ParentId IN :jobsByIds.keySet()
        AND UserOrGroupId != :UserInfo.getUserId()
    ];
    System.assert(jobShares != null && !jobShares.isEmpty());
    System.assert(jobShares.size() == 6);
  }
}