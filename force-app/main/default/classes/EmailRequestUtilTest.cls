@isTest
public with sharing class EmailRequestUtilTest {
  @TestSetup
  static void createData() {
    TestDataFactory.ISTEST_FOR_MTC = true;
    Account a = TestDataFactory.createAccount();
    TestDataFactory.createCommunityUser('MTC Admin Login', a.Id);
    TestDataFactory.createCommunityUser('MTC Standard Login', a.Id);

    AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE AccountId = :a.Id LIMIT 1];
    acr.MTC_Role__c = 'Admin';
    update acr;
  }

  // insert a new Access__c which should trigger an email to the user who the Access__c relates to
  @isTest
  private static void Test_1_1() {
    ReportAccessUtil.disableSharingProcessing();
    User standard = [
      SELECT ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Account a = [SELECT Id FROM Account LIMIT 1];
    Contact_Group__c cg = TestDataFactory.createContactGroup(a.Id);
    Asset asset = TestDataFactory.createReportForAccount(a.Id, true);
    Group_Membership__c gm = TestDataFactory.createGroupMembership(
      standard.ContactId,
      cg.Id,
      true
    );
    Test.startTest();
    Access__c ass = TestDataFactory.createAccess(cg.Id, asset.Id);
    Test.stopTest();
  }

  // insert an Access__c which should trigger an email to many users who the Access__c records relate to
  @isTest
  private static void Test_1_2() {
    ReportAccessUtil.disableSharingProcessing();
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Contact_Group__c cg = TestDataFactory.createContactGroup(acc.Id);
    List<Contact> contacts = TestDataFactory.createContacts(50, true, acc.Id);
    List<Id> contactIds = new List<Id>();
    for (
      User u : TestDataFactory.createCommunityUsers(
        'MTC Standard Login',
        contacts
      )
    ) {
      contactIds.add(u.ContactId);
    }
    Asset a = TestDataFactory.createReportForAccount(acc.Id, true);
    TestDataFactory.createGroupMemberships(contactIds, cg.Id, true);
    Test.startTest();
    Access__c access = TestDataFactory.createAccess(cg.Id, a.Id);
    Test.stopTest();
  }

  // insert a Group Membership record, where an Access links the group to a Report, which should trigger an email to that user
  @isTest
  private static void Test_2_1() {
    ReportAccessUtil.disableSharingProcessing();
    User standard = [
      SELECT ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    User admin = [
      SELECT ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Account a = [SELECT Id FROM Account LIMIT 1];
    Contact_Group__c cg = TestDataFactory.createContactGroup(a.Id);
    Asset asset = TestDataFactory.createReportForAccount(a.Id, true);
    Access__c access = TestDataFactory.createAccess(cg.Id, asset.Id);
    Test.startTest();
    Group_Membership__c gm = TestDataFactory.createGroupMembership(
      standard.ContactId,
      cg.Id,
      true
    );
    Test.stopTest();
  }

  // insert a new Email Request relating to a User
  @isTest
  private static void Test_3_1() {
    ReportAccessUtil.disableSharingProcessing();
    User standard = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Test.startTest();
    EventBus.publish(
      new Email_Request__e(
        Email_Template_Name__c = 'MTC_User_Expires_Soon',
        RecordId__c = standard.Id
      )
    );
    Test.stopTest();
  }

  // insert a new Asset__c for an Account with no contact groups, which should trigger an email to ACRs on the Account
  @isTest
  private static void Test_4_1() {
    ReportAccessUtil.disableSharingProcessing();
    Account a = [SELECT Id FROM Account LIMIT 1];
    Test.startTest();
    Asset asset = TestDataFactory.createReportForAccount(a.Id, true);
    Test.stopTest();
  }

  // update an Asset__c for an Account with 1 contact group, which should trigger an email to ACRs on the Account
  @isTest
  private static void Test_4_2() {
    ReportAccessUtil.disableSharingProcessing();
    User standard = [
      SELECT Contact.AccountId, ContactId, Id
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Account a = [SELECT Id FROM Account LIMIT 1];
    Contact_Group__c cg = TestDataFactory.createContactGroup(a.Id);
    Asset asset = TestDataFactory.createReportForAccount(a.Id, true);
    Access__c access = TestDataFactory.createAccess(cg.Id, asset.Id);
    Group_Membership__c gm = TestDataFactory.createGroupMembership(
      standard.ContactId,
      cg.Id,
      true
    );
    Test.startTest();
    asset.Date_Revised__c = date.today().addDays(2);
    update asset;
    Test.stopTest();
  }

  // insert a Case as a community user, which should trigger an email to the current user
  @isTest
  private static void Test_5_1() {
    ReportAccessUtil.disableSharingProcessing();
    User standard = [
      SELECT Id, Contact.AccountId
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Test.startTest();
    System.runAs(standard) {
      insert new Case(
        Subject = 'Test',
        Description = 'Test',
        AccountId = standard.Contact.AccountId
      );
    }
    Test.stopTest();
  }

  // add a CaseComment as a community user, which should trigger an email to the MTC queue
  @isTest
  private static void Test_5_2() {
    ReportAccessUtil.disableSharingProcessing();
    User standard = [
      SELECT Id, Contact.AccountId
      FROM User
      WHERE Profile.Name = 'MTC Standard Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    Case c;
    System.runAs(standard) {
      c = new Case(
        Subject = 'Test',
        Description = 'Test',
        AccountId = standard.Contact.AccountId
      );
      insert c;
    }
    Test.startTest();
    System.runAs(standard) {
      CaseComment cc = new CaseComment(ParentId = c.Id, CommentBody = 'Test');
      insert cc;
    }
    Test.stopTest();
  }

  // change the CGA_Id__c on Account, which should trigger an email to all relevant ACRs
  @isTest
  private static void Test_6_1() {
    ReportAccessUtil.disableSharingProcessing();
    Account a = [SELECT Id FROM Account LIMIT 1];
    User newAdmin = TestDataFactory.createCommunityUser(
      'MTC Admin Login',
      a.Id
    );
    TestDataFactory.updateAccountContactRelation(
      a.Id,
      newAdmin.ContactId,
      'CGA'
    );
    Test.startTest();
    a.CGA_Id__c = newAdmin.ContactId;
    update a;
    Test.stopTest();
  }

  @isTest
  private static void cga_receiving_access_approval_request() {
    ReportAccessUtil.disableSharingProcessing();
    User cgaUser = [
      SELECT ContactId, AccountId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      cgaUser.AccountId,
      cgaUser.ContactId,
      'CGA'
    );

    Test.startTest();
    AccountContactRelation acr = [
      SELECT MTC_Role__c
      FROM AccountContactRelation
      WHERE ContactId != :cgaUser.ContactId AND AccountId = :cgaUser.AccountId
    ];
    acr.MTC_Role__c = 'Pending Approval';
    update acr;
    Test.stopTest();
  }

  @isTest
  private static void contact_receiving_request_approved_email() {
    ReportAccessUtil.disableSharingProcessing();
    User cgaUser = [
      SELECT ContactId, AccountId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      cgaUser.AccountId,
      cgaUser.ContactId,
      'CGA'
    );

    Test.startTest();
    Contact con = [
      SELECT Approval_Status__c
      FROM Contact
      WHERE Id != :cgaUser.ContactId AND AccountId = :cgaUser.AccountId
    ];
    con.Approval_Status__c = Label.MTC_Approval_ApprovedStatus;
    update con;
    Test.stopTest();
  }

  @isTest
  private static void contact_receiving_request_declined_email() {
    ReportAccessUtil.disableSharingProcessing();
    User cgaUser = [
      SELECT ContactId, AccountId
      FROM User
      WHERE Profile.Name = 'MTC Admin Login' AND Account.Name = 'Test'
      LIMIT 1
    ];
    TestDataFactory.updateAccountContactRelation(
      cgaUser.AccountId,
      cgaUser.ContactId,
      'CGA'
    );

    Test.startTest();
    Contact con = [
      SELECT Approval_Status__c
      FROM Contact
      WHERE Id != :cgaUser.ContactId AND AccountId = :cgaUser.AccountId
    ];
    con.Approval_Status__c = Label.MTC_Approval_DeclinedStatus;
    update con;
  }
  // Insert a Brand_Supplier_Connection__c from a Supplier user, to trigger an email to Brand admins
  @isTest
  private static void Test_7_1() {
    TC_TestDataFactory_SupplierFacilityBrand baseTestData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    User supplierAdmin = [
      SELECT Id, ContactId
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    Account supplierAccount = [
      SELECT Id
      FROM Account
      WHERE
        Is_ToxClear_Account__c = TRUE
        AND ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    Account brandAccount = [
      SELECT Id
      FROM Account
      WHERE Is_ToxClear_Account__c = TRUE AND ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];

    Test.startTest();
    insert new Brand_Supplier_Connection__c(
      Brand_Account__c = brandAccount.Id,
      Supplier_Account__c = supplierAccount.Id,
      Requestor_Contact__c = supplierAdmin.ContactId
    );
    Test.stopTest();
  }

  // Insert a Brand_Supplier_Connection__c from a Brand user, to trigger an email to Supplier admins
  @isTest
  private static void Test_7_2() {
    TC_TestDataFactory_SupplierFacilityBrand baseTestData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    User brandAdmin = [
      SELECT Id, ContactId
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];
    Account supplierAccount = [
      SELECT Id
      FROM Account
      WHERE
        Is_ToxClear_Account__c = TRUE
        AND ToxClear_Account_Type__c = 'Supplier'
    ];
    Account brandAccount = [
      SELECT Id
      FROM Account
      WHERE Is_ToxClear_Account__c = TRUE AND ToxClear_Account_Type__c = 'Brand'
    ];

    Test.startTest();
    insert new Brand_Supplier_Connection__c(
      Brand_Account__c = brandAccount.Id,
      Supplier_Account__c = supplierAccount.Id,
      Requestor_Contact__c = brandAdmin.ContactId
    );
    Test.stopTest();
  }

  // Send Bulletin email to suppliers from Intertek
  @isTest
  private static void Test_8_1() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    testData.facilityUsers[0].Bulletin_Notifications__c = true;
    testData.supplierUsers[0].Bulletin_Notifications__c = true;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      update new List<User>{
        testData.facilityUsers[0],
        testData.supplierUsers[0]
      };
    }
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      testData.permissionSetAssignments
    );
    insert TC_TestDataFactory_Connections.create(
      testData.brand.Id,
      testdata.supplier.Id,
      testData.brandContacts[0].Id,
      'Approved'
    );
    Test.startTest();
    Bulletin__c b = new Bulletin__c(
      Active__c = true,
      Target_Audience__c = 'Suppliers',
      Sent_Date__c = DateTime.now(),
      Subject__c = 'Test'
    );
    insert b;
    Test.stopTest();
    // It's very hard to assert anything here, because Platform Events aren't queryable and the emails are sent asyncronously
  }

  // Send Bulletin email to suppliers from a Brand
  @isTest
  private static void Test_8_2() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    testData.facilityUsers[0].Bulletin_Notifications__c = true;
    testData.supplierUsers[0].Bulletin_Notifications__c = true;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      update new List<User>{
        testData.facilityUsers[0],
        testData.supplierUsers[0]
      };
    }
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      testData.permissionSetAssignments
    );
    insert TC_TestDataFactory_Connections.create(
      testData.brand.Id,
      testdata.supplier.Id,
      testData.brandContacts[0].Id,
      'Approved'
    );
    Test.startTest();
    System.runAs(testData.brandUsers[0]) {
      Bulletin__c b = new Bulletin__c(
        Sent_From_Owner_Account__c = testData.brand.Id,
        Active__c = true,
        Target_Audience__c = 'Suppliers',
        Sent_Date__c = DateTime.now(),
        Subject__c = 'Test'
      );
      insert b;
    }
    Test.stopTest();
    // It's very hard to assert anything here, because Platform Events aren't queryable and the emails are sent asyncronously
  }

  // Send Bulletin email to brands
  @isTest
  private static void Test_8_3() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    testData.facilityUsers[0].Bulletin_Notifications__c = true;
    testData.supplierUsers[0].Bulletin_Notifications__c = true;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      update new List<User>{
        testData.facilityUsers[0],
        testData.supplierUsers[0]
      };
    }
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      testData.permissionSetAssignments
    );
    insert TC_TestDataFactory_Connections.create(
      testData.brand.Id,
      testdata.supplier.Id,
      testData.brandContacts[0].Id,
      'Approved'
    );
    Test.startTest();
    Bulletin__c b = new Bulletin__c(
      Active__c = true,
      Target_Audience__c = 'Brands',
      Sent_Date__c = DateTime.now(),
      Subject__c = 'Test'
    );
    insert b;
    Test.stopTest();
    // It's very hard to assert anything here, because Platform Events aren't queryable and the emails are sent asyncronously
  }

  // Send Bulletin email to Intertek internal staff
  @isTest
  private static void Test_8_4() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    testData.facilityUsers[0].Bulletin_Notifications__c = true;
    testData.supplierUsers[0].Bulletin_Notifications__c = true;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      update new List<User>{
        testData.facilityUsers[0],
        testData.supplierUsers[0]
      };
    }
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      testData.permissionSetAssignments
    );
    insert TC_TestDataFactory_Connections.create(
      testData.brand.Id,
      testdata.supplier.Id,
      testData.brandContacts[0].Id,
      'Approved'
    );
    Test.startTest();
    Bulletin__c b = new Bulletin__c(
      Active__c = true,
      Target_Audience__c = 'Intertek',
      Sent_Date__c = DateTime.now(),
      Subject__c = 'Test'
    );
    insert b;
    Test.stopTest();
    // It's very hard to assert anything here, because Platform Events aren't queryable and the emails are sent asyncronously
  }

  // Update a Brand_Supplier_Connection__c to Active, to trigger an email to the requester contact
  @isTest
  private static void Test_9_1() {
    TC_TestDataFactory_SupplierFacilityBrand baseTestData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    User supplierAdmin = [
      SELECT Id, ContactId
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    Account supplierAccount = [
      SELECT Id
      FROM Account
      WHERE
        Is_ToxClear_Account__c = TRUE
        AND ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    Account brandAccount = [
      SELECT Id
      FROM Account
      WHERE Is_ToxClear_Account__c = TRUE AND ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];
    Brand_Supplier_Connection__c bsc = new Brand_Supplier_Connection__c(
      Brand_Account__c = brandAccount.Id,
      Supplier_Account__c = supplierAccount.Id,
      Requestor_Contact__c = supplierAdmin.ContactId,
      Active__c = true
    );
    insert bsc;

    Test.startTest();
    bsc.Status__c = 'Approved';
    update bsc;
    Test.stopTest();
    // It's very hard to assert anything here, because Platform Events aren't queryable and the emails are sent asyncronously
  }

  // Update a Brand_Supplier_Connection__c to rejected, to trigger an email to the requester user
  @isTest
  private static void Test_9_2() {
    TC_TestDataFactory_SupplierFacilityBrand baseTestData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    User supplierAdmin = [
      SELECT Id, ContactId
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    Account supplierAccount = [
      SELECT Id
      FROM Account
      WHERE
        Is_ToxClear_Account__c = TRUE
        AND ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    Account brandAccount = [
      SELECT Id
      FROM Account
      WHERE Is_ToxClear_Account__c = TRUE AND ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];
    Brand_Supplier_Connection__c bsc = new Brand_Supplier_Connection__c(
      Brand_Account__c = brandAccount.Id,
      Supplier_Account__c = supplierAccount.Id,
      Requestor_Contact__c = supplierAdmin.ContactId,
      Active__c = true
    );
    insert bsc;

    Test.startTest();
    bsc.Status__c = 'Rejected';
    update bsc;
    Test.stopTest();
    // It's very hard to assert anything here, because Platform Events aren't queryable and the emails are sent asyncronously
  }

  // Update a Brand_Supplier_Connection__c to disconnected as a Brand admin, to trigger an email to Supplier admins
  @isTest
  private static void Test_9_3() {
    TC_TestDataFactory_SupplierFacilityBrand baseTestData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    User supplierAdmin = [
      SELECT Id, ContactId
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    User brandAdmin = [
      SELECT Id, ContactId
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];
    Account supplierAccount = [
      SELECT Id
      FROM Account
      WHERE
        Is_ToxClear_Account__c = TRUE
        AND ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    Account brandAccount = [
      SELECT Id
      FROM Account
      WHERE Is_ToxClear_Account__c = TRUE AND ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];
    Brand_Supplier_Connection__c bsc = new Brand_Supplier_Connection__c(
      Brand_Account__c = brandAccount.Id,
      Supplier_Account__c = supplierAccount.Id,
      Requestor_Contact__c = supplierAdmin.ContactId,
      Active__c = true
    );
    insert bsc;

    Test.startTest();
    bsc.Status__c = 'Disconnected';
    bsc.Disconnected_By__c = brandAdmin.ContactId;
    update bsc;
    Test.stopTest();
    // It's very hard to assert anything here, because Platform Events aren't queryable and the emails are sent asyncronously
  }

  // Update a Brand_Supplier_Connection__c to disconnected as a Supplier admin, to trigger an email to Brand admins
  @isTest
  private static void Test_9_4() {
    TC_TestDataFactory_SupplierFacilityBrand baseTestData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    User supplierAdmin = [
      SELECT Id, ContactId
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    Account supplierAccount = [
      SELECT Id
      FROM Account
      WHERE
        Is_ToxClear_Account__c = TRUE
        AND ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    Account brandAccount = [
      SELECT Id
      FROM Account
      WHERE Is_ToxClear_Account__c = TRUE AND ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];
    Brand_Supplier_Connection__c bsc = new Brand_Supplier_Connection__c(
      Brand_Account__c = brandAccount.Id,
      Supplier_Account__c = supplierAccount.Id,
      Requestor_Contact__c = supplierAdmin.ContactId,
      Active__c = true
    );
    insert bsc;

    Test.startTest();
    bsc.Status__c = 'Disconnected';
    bsc.Disconnected_By__c = supplierAdmin.ContactId;
    update bsc;
    Test.stopTest();
    // It's very hard to assert anything here, because Platform Events aren't queryable and the emails are sent asyncronously
  }

  // Send email request to EmailRequestUtil to simulate the batch running
  @isTest
  private static void test_10_1() {
    TC_TestDataFactory_SupplierFacilityBrand baseTestData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    List<Inventory__c> invs = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      baseTestData.facility.Id,
      1,
      Date.today().addDays(-28),
      'Delivery',
      2,
      2,
      'kg',
      5.00,
      30.00,
      6.00
    );

    baseTestData.supplier.Monthly_Inventory_Due__c = invs[0]
      .Inventory_Date__c.daysBetween(
        Date.today()
          .addDays(Integer.valueOf(Label.TC_Inventory_Notification_Days))
      );
    update baseTestData.supplier;

    for (Contact c : baseTestData.facilityContacts) {
      c.Main_Facility__c = baseTestData.facility.Id;
    }
    update baseTestData.facilityContacts;

    System.runAs(new User(Id = UserInfo.getUserId())) {
      for (User u : baseTestData.facilityUsers) {
        u.Inventory_Report_Reminder_Notifications__c = true;
      }
      update baseTestData.facilityUsers;
    }

    Test.startTest();
    EmailRequestUtil.newEmailRequests(
      new List<Email_Request__e>{
        new Email_Request__e(
          Email_Template_Name__c = 'ToxClear_Facility_Inventory_Due',
          RecordId__c = invs[0].Id
        )
      }
    );
  }
}