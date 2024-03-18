/*
 * @author       Globant
 * @created      8-March-2024
 * @description  Test class to verify the functionality of GTSAccountHistorySharingHelper
 */
@IsTest
private class GTSAccountHistorySharingHelperTest {
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
        'ExporterAccount',
        true
      );
      Account newExporterAccount = GTSTestDataFactory.createAccount(
        'NewExporter',
        true
      );
      Contact groupManagerContact = GTSTestDataFactory.createContact(
        'GroupManager',
        customerAccount.Id,
        true
      );
      Contact managerContact = GTSTestDataFactory.createContact(
        'Manager',
        customerAccount.Id,
        true
      );
      Contact standardContact = GTSTestDataFactory.createContact(
        'Standard',
        customerAccount.Id,
        true
      );
      Contact newStandardContact = GTSTestDataFactory.createContact(
        'NewStandard',
        newExporterAccount.Id,
        true
      );
      User groupManagerUser = GTSTestDataFactory.createUser(
        groupManagerContact.LastName,
        customerProfileId,
        groupManagerContact.Id,
        true
      );
      User managerUser = GTSTestDataFactory.createUser(
        managerContact.LastName,
        customerProfileId,
        managerContact.Id,
        true
      );
      User standardUser = GTSTestDataFactory.createUser(
        standardContact.LastName,
        customerProfileId,
        standardContact.Id,
        true
      );
      User newStandardUser = GTSTestDataFactory.createUser(
        newStandardContact.LastName,
        customerProfileId,
        newStandardContact.Id,
        true
      );

      Account importerAccount = GTSTestDataFactory.createAccount(
        'ImporterAccount',
        false
      );
      Account payerAccount = GTSTestDataFactory.createAccount(
        'PayerAccount',
        false
      );
      Account inspectionAccount = GTSTestDataFactory.createAccount(
        'InspectionAccount',
        false
      );
      insert new List<Account>{
        importerAccount,
        payerAccount,
        inspectionAccount
      };

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
              AssigneeId = managerUser.Id,
              PermissionSetGroupId = psg.Id
            )
          );
        } else if (psg.DeveloperName == permissionSetGroupDeveloperNames[1]) {
          permissionSetAssignments.add(
            new PermissionSetAssignment(
              AssigneeId = groupManagerUser.Id,
              PermissionSetGroupId = psg.Id
            )
          );
        } else if (psg.DeveloperName == permissionSetGroupDeveloperNames[2]) {
          permissionSetAssignments.add(
            new PermissionSetAssignment(
              AssigneeId = standardUser.Id,
              PermissionSetGroupId = psg.Id
            )
          );
          permissionSetAssignments.add(
            new PermissionSetAssignment(
              AssigneeId = newStandardUser.Id,
              PermissionSetGroupId = psg.Id
            )
          );
        }
      }

      insert permissionSetAssignments;
    }
  }

  @IsTest
  static void shareAccountsTest() {
    Account exporter = [SELECT Id FROM Account WHERE Name = 'ExporterAccount'];
    List<String> childAccountNames = new List<String>{
      'ImporterAccount',
      'PayerAccount',
      'InspectionAccount'
    };
    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE Name IN :childAccountNames
    ];

    List<GTS_Account_Relationship_History__c> newAccountRelationshipHistoryToProcess = createAccountRelationshipHistories(
      exporter.Id,
      accounts
    );

    Test.startTest();
    insert newAccountRelationshipHistoryToProcess;
    Test.stopTest();

    Map<Id, User> usersToShareWith = new Map<Id, User>(
      [SELECT Id FROM User WHERE AccountId = :exporter.Id]
    );
    List<AccountShare> accountShares = [
      SELECT Id
      FROM AccountShare
      WHERE
        AccountId IN :accounts
        AND UserOrGroupId IN :usersToShareWith.keySet()
    ];

    System.assert(accountShares != null && !accountShares.isEmpty());
    //3 Accounts shared with 3 users
    System.assert(accountShares.size() == 9);
  }
  @IsTest
  static void updateAccountRecordsSharingWithUsersTest() {
    Account exporter = [SELECT Id FROM Account WHERE Name = 'ExporterAccount'];
    List<String> childAccountNames = new List<String>{
      'ImporterAccount',
      'PayerAccount',
      'InspectionAccount'
    };
    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE Name IN :childAccountNames
    ];

    List<GTS_Account_Relationship_History__c> accountRelationshipHistories = createAccountRelationshipHistories(
      exporter.Id,
      accounts
    );
    insert accountRelationshipHistories;

    Account newExporter = [SELECT Id FROM Account WHERE Name = 'NewExporter'];
    Test.startTest();
    for (
      GTS_Account_Relationship_History__c accountRelationshipHistory : accountRelationshipHistories
    ) {
      accountRelationshipHistory.GTS_Account__c = newExporter.Id;
    }
    update accountRelationshipHistories;
    Test.stopTest();

    Map<Id, User> usersToShareWith = new Map<Id, User>(
      [SELECT Id FROM User WHERE AccountId = :newExporter.Id]
    );
    List<AccountShare> accountShares = [
      SELECT Id
      FROM AccountShare
      WHERE
        AccountId IN :accounts
        AND UserOrGroupId IN :usersToShareWith.keySet()
    ];

    System.assert(accountShares != null && !accountShares.isEmpty());
    //3 Accounts shared with 1 users
    System.assert(accountShares.size() == 3);

    Map<Id, User> usersToRemoveAccess = new Map<Id, User>(
      [SELECT Id FROM User WHERE AccountId = :exporter.Id]
    );
    List<AccountShare> deletedAccountShares = [
      SELECT Id
      FROM AccountShare
      WHERE
        AccountId IN :accounts
        AND UserOrGroupId IN :usersToRemoveAccess.keySet()
    ];

    System.assert(deletedAccountShares.isEmpty());
  }
  @IsTest
  static void deleteAccountRelationshipTest() {
    Account exporter = [SELECT Id FROM Account WHERE Name = 'ExporterAccount'];
    List<String> childAccountNames = new List<String>{
      'ImporterAccount',
      'PayerAccount',
      'InspectionAccount'
    };
    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE Name IN :childAccountNames
    ];

    List<GTS_Account_Relationship_History__c> accountRelationshipHistories = createAccountRelationshipHistories(
      exporter.Id,
      accounts
    );
    insert accountRelationshipHistories;

    Account newExporter = [SELECT Id FROM Account WHERE Name = 'NewExporter'];
    Test.startTest();
    delete accountRelationshipHistories;
    Test.stopTest();

    Map<Id, User> usersToRemoveAccess = new Map<Id, User>(
      [SELECT Id FROM User WHERE AccountId = :exporter.Id]
    );
    List<AccountShare> deletedAccountShares = [
      SELECT Id
      FROM AccountShare
      WHERE
        AccountId IN :accounts
        AND UserOrGroupId IN :usersToRemoveAccess.keySet()
    ];

    System.assert(deletedAccountShares.isEmpty());
  }
  @IsTest
  static void newUserTest() {
    Account exporter = [SELECT Id FROM Account WHERE Name = 'ExporterAccount'];
    List<String> childAccountNames = new List<String>{
      'ImporterAccount',
      'PayerAccount',
      'InspectionAccount'
    };
    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE Name IN :childAccountNames
    ];

    List<GTS_Account_Relationship_History__c> accountRelationshipHistories = createAccountRelationshipHistories(
      exporter.Id,
      accounts
    );
    insert accountRelationshipHistories;

    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Id customerProfileId = [
      SELECT Id
      FROM Profile
      WHERE Name = 'iCare External Standard User'
      LIMIT 1
    ]
    .Id;

    User newUser;
    Test.startTest();
    System.runAs(currentUser) {
      Contact newContact = GTSTestDataFactory.createContact(
        'NewUser',
        exporter.Id,
        true
      );
      newUser = GTSTestDataFactory.createUser(
        newContact.LastName,
        customerProfileId,
        newContact.Id,
        true
      );
      PermissionSetGroup psg = [
        SELECT Id, DeveloperName
        FROM PermissionSetGroup
        WHERE DeveloperName = 'GTS_Standard_User'
      ];
      insert new PermissionSetAssignment(
        AssigneeId = newUser.Id,
        PermissionSetGroupId = psg.Id
      );
    }
    GTS_RecalcSharingOnUserCreationBatch batchClassInstance = new GTS_RecalcSharingOnUserCreationBatch();
    Database.executeBatch(batchClassInstance);
    Test.stopTest();

    List<AccountShare> accountShares = [
      SELECT Id
      FROM AccountShare
      WHERE AccountId IN :accounts AND UserOrGroupId = :newUser.Id
    ];

    System.assert(accountShares != null && !accountShares.isEmpty());
    //3 Accounts shared with 1 users
    System.assert(accountShares.size() == 3);
  }

  private static List<GTS_Account_Relationship_History__c> createAccountRelationshipHistories(
    Id exporterId,
    List<Account> accounts
  ) {
    List<GTS_Account_Relationship_History__c> newAccountRelationshipHistoryToProcess = new List<GTS_Account_Relationship_History__c>();
    for (Account account : accounts) {
      newAccountRelationshipHistoryToProcess.add(
        new GTS_Account_Relationship_History__c(
          GTS_Account__c = exporterId,
          GTS_Associated_Account__c = account.Id
        )
      );
    }
    return newAccountRelationshipHistoryToProcess;
  }
}