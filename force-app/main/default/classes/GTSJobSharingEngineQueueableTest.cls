/*
 * @author       Globant
 * @created      8-March-2024
 * @description  Test class to verify the functionality of GTSJobSharingEngineQueueable
 */
@IsTest
private class GTSJobSharingEngineQueueableTest {
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
      Account childAccount = GTSTestDataFactory.createAccount(
        'ChildAccount',
        true
      );
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
      GTSTestDataFactory.createUser(
        customerContact.LastName,
        customerProfileId,
        customerContact.Id,
        true
      );
      GTSTestDataFactory.createUser(
        newCustomerContact.LastName,
        customerProfileId,
        newCustomerContact.Id,
        true
      );
    }
  }

  @IsTest
  static void newJobQueue() {
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

    Account parentAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'ParentAccount'
    ];

    List<iCare_Job__c> jobs = new List<iCare_Job__c>();
    for (RecordType recordType : jobRecordTypes) {
      jobs.add(
        GTSTestDataFactory.createJob(recordType.Id, parentAccount.Id, false)
      );
    }

    Test.startTest();
    insert jobs;
    Test.stopTest();

    // Query AsyncApexJob to check if a job was enqueued
    Integer jobCount = [
      SELECT COUNT()
      FROM AsyncApexJob
      WHERE ApexClass.Name = 'GTSJobSharingEngineQueueable'
    ];

    // Assert that at least one job was enqueued
    System.assertNotEquals(0, jobCount, 'No job was enqueued');
  }
  @IsTest
  static void newExporterParent() {
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

    Account childAccount = [SELECT Id FROM Account WHERE Name = 'ChildAccount'];

    List<iCare_Job__c> jobs = new List<iCare_Job__c>();
    for (RecordType recordType : jobRecordTypes) {
      jobs.add(
        GTSTestDataFactory.createJob(recordType.Id, childAccount.Id, false)
      );
    }
    insert jobs;

    Account parentAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'ParentAccount'
    ];
    Test.startTest();
    update new Account(Id = childAccount.Id, ParentId = parentAccount.Id);
    Test.stopTest();

    // Query AsyncApexJob to check if a job was enqueued
    Integer jobCount = [
      SELECT COUNT()
      FROM AsyncApexJob
      WHERE ApexClass.Name = 'GTSJobSharingEngineQueueable'
    ];

    // Assert that at least one job was enqueued
    System.assertNotEquals(0, jobCount, 'No job was enqueued');
  }
  @IsTest
  static void updatedExporterParent() {
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

    Account childAccount = [SELECT Id FROM Account WHERE Name = 'ChildAccount'];
    Account parentAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'ParentAccount'
    ];
    update new Account(Id = childAccount.Id, ParentId = parentAccount.Id);

    List<iCare_Job__c> jobs = new List<iCare_Job__c>();
    for (RecordType recordType : jobRecordTypes) {
      jobs.add(
        GTSTestDataFactory.createJob(recordType.Id, childAccount.Id, false)
      );
    }
    insert jobs;

    Account newParentAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'NewParentAccount'
    ];
    Test.startTest();
    update new Account(Id = childAccount.Id, ParentId = newParentAccount.Id);
    Test.stopTest();

    // Query AsyncApexJob to check if a job was enqueued
    Integer jobCount = [
      SELECT COUNT()
      FROM AsyncApexJob
      WHERE ApexClass.Name = 'GTSJobSharingEngineQueueable'
    ];

    // Assert that at least one job was enqueued
    System.assertNotEquals(0, jobCount, 'No job was enqueued');
  }
}