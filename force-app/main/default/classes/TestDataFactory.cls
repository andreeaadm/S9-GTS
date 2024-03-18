////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// Description: a data factory for Apex unit tests
////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
@isTest
public class TestDataFactory {
  // Set this flag to false to not create user when setting ACR.MTC_Role
  public static Boolean CONTACTS_USER_REQD_FLAG = true;
  public static Boolean ISTEST_FOR_MTC = false;
  public static Boolean ISTEST_FOR_TOXCLEAR = false;

  public static User createCommunityUser() {
    return createCommunityUser('Customer Community User', null, null);
  }

  public static User createCommunityUser(String profileName) {
    return createCommunityUser(profileName, null, null);
  }

  public static User createCommunityUser(String profileName, Id accountId) {
    return createCommunityUser(profileName, accountId, null);
  }

  // Creates multiple community users at once with customisable profile
  public static List<User> createCommunityUsers(
    List<String> profileNames,
    List<Contact> contacts
  ) {
    if (profileNames.isEmpty() || (profileNames.size() != contacts.size())) {
      System.assert(
        false,
        'Both lists must contain the same number of entries'
      );
    }
    String randomString = StringUtil.random(5);

    List<User> customerUsers = new List<User>();
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Map<String, Profile> mtcProfilesByName = MTCUserUtil.mtcProfilesByName;

      for (Integer i = 0; i < contacts.size(); i++) {
        Contact con = contacts[i];
        customerUsers.add(
          new User(
            LastName = 'CustTest',
            FirstName = 'CustTest',
            Alias = 'CustTest',
            Phone = StringUtil.random(12, '0123456789'),
            Email = con.Email,
            Username = 'cust' + randomString + (i + 1) + '@oegen.co.uk',
            ProfileId = mtcProfilesByName.get(profileNames[i].toLowerCase()).Id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            ContactId = con.Id,
            Street = 'Test',
            City = 'Test',
            //State = 'Test',
            PostalCode = 'Test',
            //Country = 'Test',
            isActive = true,
		Source__c =  'Self-Registration'
          )
        );
      }
      for (Integer i = 0; i <= 20; i++) {
        try {
          insert customerUsers;
          break;
        } catch (Exception e) {
          if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW') || i >= 20) {
            throw e;
          }
          Long start = System.currentTimeMillis();
          while (System.currentTimeMillis() < start + 100 + 10 * i) {
            // Throw away CPU cycles
          }
        }
      }
    }
    return customerUsers;
  }

  public static List<User> createCommunityUsers(
    String profileName,
    List<Contact> contacts
  ) {
    String randomString = StringUtil.random(5);

    List<User> customerUsers = new List<User>();
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Profile customerProfile = [
        SELECT Id, Name
        FROM Profile
        WHERE Name LIKE :profileName
        LIMIT 1
      ];
      Integer idx = 0;
      for (Contact con : contacts) {
        idx = idx + 1;
        customerUsers.add(
          new User(
            LastName = 'CustTest',
            FirstName = 'CustTest',
            Alias = 'CustTest',
            Phone = StringUtil.random(12, '0123456789'),
            Email = con.Email,
            Username = 'cust' + randomString + idx + '@oegen.co.uk',
            ProfileId = customerProfile.Id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            ContactId = con.Id,
            Street = 'Test',
            City = 'Test',
            //State = 'Test',
            PostalCode = 'Test',
            //Country = 'Test',
            isActive = true,
		Source__c =  'Self-Registration'
          )
        );
      }
      for (Integer i = 0; i <= 20; i++) {
        try {
          insert customerUsers;
          break;
        } catch (Exception e) {
          if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW') || i >= 20) {
            throw e;
          }
          Long start = System.currentTimeMillis();
          while (System.currentTimeMillis() < start + 100 + 10 * i) {
            // Throw away CPU cycles
          }
        }
      }
    }
    return customerUsers;
  }

  public static User createCommunityUser(
    String profileName,
    Id accountId,
    Id customerContactId
  ) {
    String randomString = StringUtil.random(5);

    User customerUser;
    Account customerAccount;
    Contact customerContact;

    if (accountId == null) {
      customerAccount = new Account(
        Name = 'Test',
        Is_MTC_Account__c = ISTEST_FOR_MTC,
        Is_ToxClear_Account__c = ISTEST_FOR_TOXCLEAR
      );
      insert customerAccount;
    } else {
      customerAccount = new Account(Id = accountId);
    }
    if (customerContactId == null) {
      customerContact = new Contact(
        AccountId = customerAccount.Id,
        LastName = 'Test ' + randomString,
        FirstName = 'Test',
        Phone = StringUtil.random(12, '0123456789'),
        Email = 'cust' + randomString + '@oegen.co.uk'
      );
      insert customerContact;
    } else {
      customerContact = [
        SELECT Id, FirstName, LastName, AccountId, Email, Phone
        FROM Contact
        WHERE Id = :customerContactId
        FOR UPDATE
      ];
    }

    Id customerProfileId = [
      SELECT Id
      FROM Profile
      WHERE Name LIKE :profileName
      LIMIT 1
    ]
    .Id;
    customerUser = new User(
      LastName = 'CustTest',
      FirstName = 'CustTest',
      Alias = 'CustTest',
      Phone = customerContact.Phone,
      Email = customerContact.Email,
      Username = 'cust' + randomString + '@oegen.co.uk',
      ProfileId = customerProfileId,
      TimeZoneSidKey = 'GMT',
      LanguageLocaleKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LocaleSidKey = 'en_US',
      ContactId = customerContact.Id,
      Street = 'Test',
      City = 'Test',
      //State = 'Test',
      PostalCode = 'Test',
      //Country = 'Test',
      isActive = true,
	Source__c =  'Self-Registration'
    );

    System.runAs(new User(Id = UserInfo.getUserId())) {
      for (Integer i = 0; i < 100; i++) {
        try {
          insert customerUser;
          break;
        } catch (Exception e) {
          if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
            throw e;
          }
          System.debug('Hit lock ' + i);
          Long start = System.currentTimeMillis();
          while (System.currentTimeMillis() < start + 100) {
            // Throw away CPU cycles
          }
        }
      }
    }
    return customerUser;
  }

  public static User createAdminUser() {
    return createAdminUser(null);
  }

  public static User createAdminUser(String permissionSetGroupName) {
    Profile ownerProfile = [
      SELECT Id, Name
      FROM Profile
      WHERE Name = 'System Administrator'
      LIMIT 1
    ];

    UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Automation'];

    User customerUser;
    Account customerAccount;
    Contact customerContact;
    User adminUser = new User(
      LastName = 'Test',
      FirstName = 'Test',
      Alias = 'Test',
      Phone = StringUtil.random(12, '0123456789'),
      Email = 'admin@oegen.co.uk',
      Username = 'admin' + StringUtil.random(5) + '@oegen.co.uk',
      ProfileId = ownerProfile.Id,
      TimeZoneSidKey = 'GMT',
      LanguageLocaleKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LocaleSidKey = 'en_US',
      UserRoleId = role.Id,
      Street = 'Test',
      City = 'Test',
      //State = 'Test',
      PostalCode = 'Test'
      //Country = 'Test'
    );

    insert adminUser;
    if (permissionSetGroupName != null) {
      PermissionSetGroup permSetGroup = [
        SELECT Id, Status
        FROM PermissionSetGroup
        WHERE DeveloperName = :permissionSetGroupName
        LIMIT 1
      ];
      if (permSetGroup.Status != 'Updated' && Test.isRunningTest()) {
        Test.calculatePermissionSetGroup(new List<Id>{ permSetGroup.Id });
      }
      insert new PermissionSetAssignment(
        AssigneeId = adminUser.Id,
        PermissionSetGroupId = permSetGroup.Id
      );
    }
    return adminUser;
  }
  
    public static User createSupplierCommunityUser(
    String profileName,
    Contact customerContact,
    String permissionSetGroupName
  ) {
    String randomString = StringUtil.random(5);

    User customerUser;

    Id customerProfileId = [
      SELECT Id
      FROM Profile
      WHERE Name LIKE :profileName
      LIMIT 1
    ]
    .Id;
    customerUser = new User(
      LastName = 'CustTest',
      FirstName = 'CustTest',
      Alias = 'CustTest',
      Phone = customerContact.Phone,
      Email = customerContact.Email,
      Username = 'cust' + randomString + '@oegen.co.uk',
      ProfileId = customerProfileId,
      TimeZoneSidKey = 'GMT',
      LanguageLocaleKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LocaleSidKey = 'en_US',
      ContactId = customerContact.Id,
      Street = 'Test',
      City = 'Test',
      //State = 'Test',
      PostalCode = 'Test',
      //Country = 'Test',
      isActive = true
    );
	insert customerUser;
    
      if (permissionSetGroupName != null) {
      PermissionSetGroup permSetGroup = [
        SELECT Id, Status
        FROM PermissionSetGroup
        WHERE DeveloperName = :permissionSetGroupName
        LIMIT 1
      ];
      if (permSetGroup.Status != 'Updated' && Test.isRunningTest()) {
        Test.calculatePermissionSetGroup(new List<Id>{ permSetGroup.Id });
      }
      insert new PermissionSetAssignment(
        AssigneeId = customerUser.Id,
        PermissionSetGroupId = permSetGroup.Id
      );
    }
    return customerUser;
  }

  /**
   * Create a single Account record.
   *
   * @return Account
   */
  public static Account createAccount() {
    Account a = new Account(
      Name = 'Test',
      Is_MTC_Account__c = ISTEST_FOR_MTC,
      Is_ToxClear_Account__c = ISTEST_FOR_TOXCLEAR
    );
    insert a;
    return a;
  }

  /**
   * Create a List of Account records.
   *
   * @param  Integer  count
   * @return List<Account>
   */
  public static List<Account> createAccounts(Integer count) {
    return TestDataFactory.createAccounts(count, false);
  }

  /**
   * Create a List of Account records.
   *
   * @param  Integer  count
   * @param  Boolean  store
   * @return List<Account>
   */
  public static List<Account> createAccounts(Integer count, Boolean store) {
    List<Account> accountList = new List<Account>();

    for (Integer i = 1; i <= count; i++) {
      accountList.add(
        new Account(
          Name = 'Account ' + i,
          Is_MTC_Account__c = ISTEST_FOR_MTC,
          Is_ToxClear_Account__c = ISTEST_FOR_TOXCLEAR
        )
      );
    }

    if (store) {
      insert accountList;
    }

    return accountList;
  }

  /**
   * Create a List of Account records with a List of Contact records.
   *
   * @param  List<Account>  accountList
   * @param  Integer  contactCount
   * @return List<Account>
   */
  public static List<Account> createAccountsWithContacts(
    List<Account> accountList,
    Integer contactCount
  ) {
    return TestDataFactory.createAccountsWithContacts(
      accountList,
      TestDataFactory.createContacts((accountList.size() * contactCount), true)
    );
  }

  /**
   * Create a List of Account records with a List of Contact records.
   *
   * @param  List<Account>  accountList
   * @param  List<Contact>  contactList
   * @return List<Account>
   */
  public static List<Account> createAccountsWithContacts(
    List<Account> accountList,
    List<Contact> contactList
  ) {
    for (Integer a = 0; a < accountList.size(); a++) {
      Account account = accountList[a];

      for (Integer c = 0; c < (contactList.size() / accountList.size()); c++) {
        Contact contact = contactList[
          (a * (contactList.size() / accountList.size())) + c
        ];

        contact.AccountId = account.Id;
      }
    }

    update contactList;

    return accountList;
  }

  /*
    |--------------------------------------------------------------------------
    | Contact
    |--------------------------------------------------------------------------
    |
    | The methods described below deliver utility function
    | specifically for create, read, edit & deletion of
    | Contact records while working with unit tests.
    |
    */

  /**
   * Create a List of Contact records.
   *
   * @param  Integer  count
   * @return List<Contact>
   */
  public static List<Contact> createContacts(Integer count) {
    return TestDataFactory.createContacts(count, false);
  }

  /**
   * Create a List of Contact records.
   *
   * @param  Integer  count
   * @param  Boolean  store
   * @return List<Contact>
   */
  public static List<Contact> createContacts(Integer count, Boolean store) {
    return createContacts(count, store, null);
  }
  public static List<Contact> createContacts(
    Integer count,
    Boolean store,
    Id accountId
  ) {
    List<Contact> contactList = new List<Contact>();

    for (Integer i = 0; i < count; i++) {
      Contact newContact = new Contact(
        Email = StringUtil.random(5) + 'test@oegen.co.uk',
        Phone = StringUtil.random(12, '0123456789'),
        FirstName = 'Test',
        LastName = 'Contact ' + i,
        Is_User_Required__c = CONTACTS_USER_REQD_FLAG
      );
      if (accountId != null) {
        newContact.AccountId = accountId;
      }
      contactList.add(newContact);
    }

    if (store) {
      insert contactList;
    }

    return contactList;
  }

  public static List<Contact> createContacts2(
    Integer count,
    Boolean store,
    Id accountId,
    String email
  ) {
    List<Contact> contactList = new List<Contact>();

    for (Integer i = 0; i < count; i++) {
      Contact newContact = new Contact(
        Email = email,
        Phone = StringUtil.random(12, '0123456789'),
        FirstName = 'Test' + i,
        LastName = 'Contact ' + i,
        Is_User_Required__c = CONTACTS_USER_REQD_FLAG
      );
      if (accountId != null) {
        newContact.AccountId = accountId;
      }
      contactList.add(newContact);
    }

    if (store) {
      insert contactList;
    }

    return contactList;
  }

  public static List<Contact> createBulkContacts(Integer quantity) {
    List<Contact> contactsToInsert = new List<Contact>();
    for (integer i = 0; i < quantity; i++) {
      Contact c = new Contact(
        LastName = 'Test' + i,
        FirstName = 'Test' + i,
        Email = StringUtil.random(5) + 'test@oegen.co.uk',
        Phone = StringUtil.random(12, '0123456789'),
        Is_User_Required__c = CONTACTS_USER_REQD_FLAG
      );
      contactsToInsert.add(c);
    }

    insert contactsToInsert;
    return contactsToInsert;
  }

  public static List<Asset> createReportForAccounts(
    List<Account> accounts,
    Boolean store
  ) {
    List<Asset> reports = new List<Asset>();
    Integer idx = 0;
    for (Account acc : accounts) {
      idx = idx + 1;
      reports.add(createReportForAccount(acc.Id, false, idx));
    }
    if (store) {
      insert reports;
    }
    return reports;
  }

  /*** Intertek ***/

  public static Contact_Group__c createContactGroup(Id accountId) {
    return createContactGroup(accountId, null);
  }

  public static Contact_Group__c createContactGroup(Id accountId, Date expiry) {
    Contact_Group__c cg = new Contact_Group__c(
      Account__c = accountId,
      Expiry__c = expiry,
      Group_Name__c = 'Test'
    );
    insert cg;
    return cg;
  }

  public static Contact_Group__c createContactGroup(
    Id accountId,
    Date expiry,
    String name,
    Boolean store
  ) {
    Contact_Group__c cg = new Contact_Group__c(
      Account__c = accountId,
      Expiry__c = expiry,
      Group_Name__c = name
    );
    if (store) {
      insert cg;
    }
    return cg;
  }

  public static Group_Membership__c createGroupMembership(
    Id contactId,
    Id contactGroupId
  ) {
    return createGroupMembership(contactId, contactGroupId, true);
  }

  public static Group_Membership__c createGroupMembership(
    Id contactId,
    Id contactGroupId,
    Boolean store
  ) {
    Group_Membership__c gm = new Group_Membership__c(
      Contact__c = contactId,
      Contact_Group__c = contactGroupId,
      DupCheck__c = String.valueOf(contactId) + String.valueOf(contactGroupId)
    );
    if (store) {
      insert gm;
    }
    return gm;
  }

  public static List<Group_Membership__c> createGroupMemberships(
    List<Id> contactIds,
    Id contactGroupId,
    Boolean store
  ) {
    List<Group_Membership__c> memberships = new List<Group_Membership__c>();
    for (Id i : contactIds) {
      memberships.add(createGroupMembership(i, contactGroupId, false));
    }
    if (store) {
      insert memberships;
    }
    return memberships;
  }

  public static AccountContactRelation createAccountContactRelation(
    Id accountId,
    Id contactId,
    String mtcRole
  ) {
    AccountContactRelation acr = new AccountContactRelation(
      AccountId = accountId,
      ContactId = contactId,
      MTC_Role__c = mtcRole
    );
    insert acr;
    return acr;
  }

  public static void updateAccountContactRelation(
    Id accountId,
    Id contactId,
    String mtcRole
  ) {
    List<AccountContactRelation> acr = new List<AccountContactRelation>(
      [
        SELECT Id
        FROM AccountContactRelation
        WHERE AccountId = :accountId AND ContactId = :contactId
      ]
    );
    if (!acr.isEmpty()) {
      acr[0].MTC_Role__c = mtcRole;
      update acr[0];
    }
  }

  public static Asset createReportForAccount(Id accountId, Boolean store) {
    return createReportForAccount(accountId, store, 1);
  }
  public static Asset createReportForAccount(
    Id accountId,
    Boolean store,
    Integer idx
  ) {
    Schema.DescribeSObjectResult assetDescr = Asset.SObjectType.getDescribe();
    Map<String, Schema.RecordTypeInfo> rtMapByDevName = assetDescr.getRecordTypeInfosByDeveloperName();
    Asset report = new Asset(
      AccountId = accountId,
      RecordTypeId = rtMapByDevName.get('MTC_Report').getRecordTypeId(),
      Name = 'Report ' + idx,
      Type__c = 'Report',
      MTC_Status__c = 'Official',
      Date_Issued__c = Date.today(),
      Date_Revised__c = Date.today()
    );
    if (store) {
      insert new List<Asset>{ report };
    }
    return report;
  }

  public static Asset createDeliverableForReport(Asset report, Boolean store) {
    Schema.DescribeSObjectResult assetDescr = Asset.SObjectType.getDescribe();
    Map<String, Schema.RecordTypeInfo> rtMapByDevName = assetDescr.getRecordTypeInfosByDeveloperName();
    Asset deliverable = new Asset(
      AccountId = report.AccountId,
      ParentId = report.Id,
      RecordTypeId = rtMapByDevName.get('MTC_Deliverable').getRecordTypeId(),
      Name = 'Deliverable',
      Type__c = 'Deliverable'
    );
    if (store) {
      insert new List<Asset>{ deliverable };
    }
    return deliverable;
  }

  public static List<Asset> createDeliverableForReports(
    List<Asset> reports,
    Boolean store
  ) {
    List<Asset> deliverables = new List<Asset>();
    for (Asset report : reports) {
      deliverables.add(createDeliverableForReport(report, false));
    }
    if (store) {
      insert deliverables;
    }
    return deliverables;
  }

  public static MTC_Project__c createProject(Id accountId, Boolean store) {
    MTC_Project__c p = new MTC_Project__c(
      Account__c = accountId,
      Name = 'Test',
      Status__c = 'In Process',
      Scheduled_Start_Date__c = Date.today(),
      Schedule_Complete__c = Date.today()
    );
    if (store) {
      insert p;
    }
    return p;
  }

  public static Access__c createAccess(Id contactGroupId, Id reportId) {
    Access__c a = new Access__c(
      Contact_Group__c = contactGroupId,
      Report_Asset__c = reportId,
      DupCheck__c = String.valueOf(contactGroupId) + String.valueOf(reportId)
    );
    insert a;
    return a;
  }
  
  public static Regulation__c createRegulation(String productName, String marketName, String materialName, String ageRange, Boolean store ) {
    Regulation__c reg = new Regulation__c(
      Product__c = productName,
      Legal_Regulation_Name__c = productName,
      Market__c = marketName,
      Material__c = materialName,
      Age_Range__c = ageRange,
      Name = 'Test Regulation',
      Category__c = 'Accessories'
    );
    if(store){
      insert reg;
    }
    return reg;
  }

  public static Test_Item_Equivalency__c createTestEquivalency(Id testItem1,Id testItem2, Boolean store) {
    Test_Item_Equivalency__c testItemEquivalency = new Test_Item_Equivalency__c(
      Test_Item_1__c = testItem1,
      Test_Item_2__c = testItem2,
      Name = 'Test Item Equivalency'
    );
    if(store){
      insert testItemEquivalency;
    }
    return testItemEquivalency;
  }

  public static Test_Item__c createTestItem(Id regulationId,String productName, String marketName, String materialName, String ageRange, Boolean store) {
    Test_Item__c testItem = new Test_Item__c(
      Product__c = productName,
      Market__c = marketName,
      Material__c = materialName,
      Age_Range__c = ageRange,
      Name = 'Test Item ',
      Category__c = 'Accessories',
      Regulation__c = regulationId
    );
    if(store){
      insert testItem;
    }
    return testItem;
  }

  public static Recall__c createRecall(String productName, String marketName, String riskType) {
    Date recallPublishedDate = Date.newInstance(2022,06,06);
    Recall__c recall = new Recall__c(
      Product__c = productName,
      Market__c = marketName,
      Risk_Type__c	 = riskType,
      Recall_Date__c = recallPublishedDate,
      Name = 'Test Recall '
    );
    insert recall;
    return recall;
  }

  public static void triggerPermissionsetUpdateForGmaPortal() {
    String PORTAL_USER_PERMSET_GROUP = 'GMA_Portal_User';
    PermissionSetGroup portalGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName=:PORTAL_USER_PERMSET_GROUP];
    Test.calculatePermissionSetGroup(portalGroup.Id);
  }  
}