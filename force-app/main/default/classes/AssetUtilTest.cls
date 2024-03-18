@isTest
public with sharing class AssetUtilTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    ReportAccessUtil.disableSharingProcessing();
    ReportAccessUtil.bypassQueueable = true;

    List<Account> accounts = TestDataFactory.createAccounts(2, true);

    TestDataFactory.createAccountsWithContacts(accounts, 2);
    List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
      Contact newContact = new Contact(
        Email = 'test@oegen.co.uk',
        Phone = '0123456789',
        FirstName = 'Test',
        LastName = 'Contact ',
        Is_User_Required__c = true,
        AccountId = accounts[0].Id
      );
    List<Asset> reports = TestDataFactory.createReportForAccounts(
      accounts,
      false
    );
    reports[0].ContactId = newContact.id;//contacts[0].Id;
    insert reports;

    ReportAccessUtil.enableSharingProcessing();
  }

  @isTest
  static void cleanUpContactOnTransfer() {
    List<Asset> reports = [
      SELECT Name, ContactId, AccountId, Contact.Name, Contact.Email
      FROM Asset
      WHERE Account.Name = 'Account 1'
    ];
    Asset report = reports[0];
    String priorContact =
      report.Contact.Name +
      ' (' +
      report.Contact.Email +
      ')';
    List<Asset> delivs = TestDataFactory.createDeliverableForReports(
      reports,
      true
    );

    Account acc2 = [SELECT Id FROM Account WHERE Name = 'Account 2'];

    Test.startTest();

    report.AccountId = acc2.Id;
    update reports;

    Test.stopTest();

    report = [
      SELECT
        Name,
        ContactId,
        Prior_ReportContact__c,
        AccountId,
        (SELECT ContactId, AccountId FROM ChildAssets)
      FROM Asset
      WHERE Id = :report.Id
    ];
    System.assertEquals(null, report.ContactId);
   // System.assertEquals(priorContact, report.Prior_ReportContact__c);
    for (Asset child : report.ChildAssets) {
      System.assertEquals(null, report.ContactId);
    }
  }

  @isTest
  static void cleanUpAccessOnTransfer() {
    List<Asset> reports = [
      SELECT Name, ContactId, AccountId
      FROM Asset
      WHERE Account.Name = 'Account 1'
    ];
    Asset report = reports[0];

    Contact_Group__c groupG = new Contact_Group__c(
      Account__c = report.AccountId,
      Group_Name__c = 'group-g'
    );
    insert groupG;
    ContactGroupUtil.linkGroupToReport(groupG, report, true);

    Account acc2 = [SELECT Id FROM Account WHERE Name = 'Account 2'];

    Test.startTest();

    report.AccountId = acc2.Id;
    update reports;

    Test.stopTest();

    List<Access__c> accesses = [
      SELECT Contact_Group__c
      FROM Access__c
      WHERE
        Report_Asset__c = :report.Id
        AND Contact_Group__r.Account__r.Name = 'Account 1'
    ];
    System.assertEquals(0, accesses.size());
  }

  @isTest
  static void setDeliverableContactIdOnCreate() {
    Asset report = [
      SELECT Id, AccountId, ContactId
      FROM Asset
      WHERE Account.Name = 'Account 1'
    ];
    List<Asset> deliverables = TestDataFactory.createDeliverableForReports(
      new List<Asset>{ report },
      true
    );
    Asset deliv = [
      SELECT Id, ContactId, AccountId
      FROM Asset
      WHERE ParentId = :report.Id
    ];
    System.assertEquals(report.ContactId, deliv.ContactId);
    System.assertEquals(report.AccountId, deliv.AccountId);
  }
  @isTest
  static void whenNoContactIdOnParentOnCreate() {
    Asset report = [
      SELECT Id, AccountId, ContactId
      FROM Asset
      WHERE Account.Name = 'Account 2'
    ];
    List<Asset> deliverables = TestDataFactory.createDeliverableForReports(
      new List<Asset>{ report },
      true
    );
    Asset deliv = [
      SELECT Id, ContactId, AccountId
      FROM Asset
      WHERE ParentId = :report.Id
    ];
    System.assertEquals(null, deliv.ContactId);
    System.assertEquals(report.AccountId, deliv.AccountId);
  }

  @isTest
  static void setDeliverableContactIdOnUpdate() {
    Asset report = [
      SELECT Id, AccountId, ContactId
      FROM Asset
      WHERE Account.Name = 'Account 1'
    ];
    List<Asset> deliverables = TestDataFactory.createDeliverableForReports(
      new List<Asset>{ report },
      true
    );
    Contact con2 = [
      SELECT Id
      FROM Contact
      WHERE Id != :report.ContactId AND AccountId = :report.AccountId limit 1
    ];
    Test.startTest();
    report.ContactId = con2.Id; 
    update report;
    Test.stopTest();

    Asset deliv = [
      SELECT Id, ContactId, AccountId, Parent.ContactId
      FROM Asset
      WHERE ParentId = :report.Id
    ];
    System.assertEquals(con2.Id, deliv.Parent.ContactId);
    System.assertEquals(con2.Id, deliv.ContactId);
    System.assertEquals(report.AccountId, deliv.AccountId);
  }
  @isTest
  static void checkTokenizerOnInsert() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Asset ass = new Asset(
      AccountId = acc.Id,
      Name = 'my asset 1',
      Products_Covered__c = 'this,that thot,thut'
    );

    Test.startTest();

    insert ass;
    ass = [
      SELECT Id, Products_Covered__c, Tokenized_Products_Covered__c
      FROM Asset
      WHERE Id = :ass.Id
    ];

    Test.stopTest();

    System.assertEquals(
      ass.Products_Covered__c,
      ass.Tokenized_Products_Covered__c
    );
  }
  @isTest
  static void checkTokenizerOnUpdate() {
    Asset ass = [SELECT Id, Products_Covered__c FROM Asset LIMIT 1];

    Test.startTest();

    ass.Products_Covered__c = 'this,that thot,thut';
    update ass;

    Test.stopTest();

    ass = [
      SELECT Id, Products_Covered__c, Tokenized_Products_Covered__c
      FROM Asset
      WHERE Id = :ass.Id
    ];
    System.assertEquals(
      ass.Products_Covered__c,
      ass.Tokenized_Products_Covered__c
    );
  }

  @isTest
  static void checkTokenizerLargeInput() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    String largeInput = '';
    while (largeInput.length() <= 2000) {
      largeInput += StringUtil.random(40) + StringUtil.random(1, ', -;\n');
    }
    Asset ass = new Asset(
      AccountId = acc.Id,
      Name = 'my asset 1',
      Products_Covered__c = largeInput
    );

    Test.startTest();

    insert ass;
    ass = [
      SELECT Id, Tokenized_Products_Covered__c
      FROM Asset
      WHERE Id = :ass.Id
    ];

    Test.stopTest();

    System.assertEquals(
      false,
      String.isEmpty(ass.Tokenized_Products_Covered__c)
    );
  }
    
    @isTest static void checkDateIssuedChanges(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Asset ass = new Asset(
            AccountId = acc.Id,
            Name = 'my asset 1',
            Date_Revised__c = system.today() + 1,
            Date_Issued__c = system.today()
        );
        insert ass;
        Test.startTest();
        ass.Date_Issued__c = system.today() + 4;
        update ass;
        Test.stopTest();
        
        Asset ast = [Select Id,Last_Activity_Date__c,Date_Issued__c,Date_Revised__c from Asset Where Id=:ass.Id];
        //system.assertEquals(ast.Last_Activity_Date__c, ast.Date_Issued__c);
    }
    
    @isTest static void checkDateRevisedChanges(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Asset ass = new Asset(
            AccountId = acc.Id,
            Name = 'my asset 1',
            Date_Revised__c = system.today() + 1,
            Date_Issued__c = system.today()
        );
        insert ass;
        Test.startTest();
        ass.Date_Revised__c = system.today() + 4;
        update ass;
        Test.stopTest();
        
        Asset ast = [Select Id,Last_Activity_Date__c,Date_Issued__c,Date_Revised__c from Asset Where Id=:ass.Id];
        //system.assertEquals(ast.Last_Activity_Date__c, ast.Date_Revised__c);
    }
}