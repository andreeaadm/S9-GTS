@isTest
public with sharing class TC_ExperienceCloud_Test {
  @isTest
  public static void construction() {
    User u = TC_TestDataFactory_Users.create(
      new User(
        ProfileId = [
          SELECT Id
          FROM Profile
          WHERE Name = 'System Administrator'
          LIMIT 1
        ]
        .Id
      )
    );
    insert u;
    System.runAs(u) {
      TC_ExperienceCloud current = new TC_ExperienceCloud();
      // It's the plain test user so none should match.
      System.assertEquals(
        false,
        current.isSupplierAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isStandardUser,
        'User should not match this state.'
      );

      // bitwise: 0=none, 1=admin, 2=standard, 4=supplier, 8=brand
      //          9=brand|admin, 10=brand|standard,
      //          5=supplier|admin, 6=supplier|standard
      System.assertEquals(0, current.userType, 'User type should be zero.');

      // Also check statics:
      System.assertEquals(
        true,
        TC_ExperienceCloud.SUPPLIER_ADMINISTRATOR_PSGID != null,
        'PermissionSet not found for ToxClear Supplier Administrator.'
      );
      System.assertEquals(
        true,
        TC_ExperienceCloud.SUPPLIER_STANDARD_USER_PSGID != null,
        'PermissionSet not found for ToxClear Supplier Standard User.'
      );
      System.assertEquals(
        true,
        TC_ExperienceCloud.BRAND_ADMINISTRATOR_PSGID != null,
        'PermissionSet not found for ToxClear Brand Administrator.'
      );
      System.assertEquals(
        true,
        TC_ExperienceCloud.BRAND_STANDARD_USER_PSGID != null,
        'PermissionSet not found for ToxClear Brand Standard User.'
      );
    }
  }

  @isTest
  public static void isSupplierAdminUser_asLoginProfile() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.adminLoginId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_ADMINISTRATOR_PSGID
    );

    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      TC_ExperienceCloud current = new TC_ExperienceCloud();
      System.assertEquals(
        true,
        current.isSupplierAdminUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isSupplierUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isAdminUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        false,
        current.isStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandUser,
        'User should not match this state.'
      );
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_SUPPLIER |
        TC_ExperienceCloud.USERTYPE_ADMIN,
        current.userType,
        'User type does not match.'
      );
      System.assertEquals(
        true,
        current.user.Email.startsWith('test'),
        'User should have this Email'
      );
      System.assertEquals(
        true,
        current.user.Email.endsWith('@example.com'),
        'User should have this Email'
      );
      System.assertEquals(
        TC_TestDataFactory_Users.adminLoginId,
        current.user.ProfileId,
        'User should have this ProfileId'
      );
    }
  }
  @isTest
  public static void isBrandAdminUser_asLoginProfile() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.adminLoginId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.BRAND_ADMINISTRATOR_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      TC_ExperienceCloud current = new TC_ExperienceCloud();
      System.assertEquals(
        true,
        current.isBrandAdminUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isBrandUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isAdminUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        false,
        current.isStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierUser,
        'User should not match this state.'
      );
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_BRAND | TC_ExperienceCloud.USERTYPE_ADMIN,
        current.userType,
        'User type does not match.'
      );
      System.assertEquals(
        true,
        current.user.Email.startsWith('test'),
        'User should have this Email'
      );
      System.assertEquals(
        true,
        current.user.Email.endsWith('@example.com'),
        'User should have this Email'
      );
      System.assertEquals(
        TC_TestDataFactory_Users.adminLoginId,
        current.user.ProfileId,
        'User should have this ProfileId'
      );
    }
  }
  @isTest
  public static void isSupplierStandardUser_asLoginProfile() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.standardLoginId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_STANDARD_USER_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      TC_ExperienceCloud current = new TC_ExperienceCloud();
      System.assertEquals(
        true,
        current.isSupplierStandardUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isSupplierUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isStandardUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        false,
        current.isAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandUser,
        'User should not match this state.'
      );
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_SUPPLIER |
        TC_ExperienceCloud.USERTYPE_STANDARD,
        current.userType,
        'User type does not match.'
      );
      System.assertEquals(
        true,
        current.user.Email.startsWith('test'),
        'User should have this Email'
      );
      System.assertEquals(
        true,
        current.user.Email.endsWith('@example.com'),
        'User should have this Email'
      );
      System.assertEquals(
        TC_TestDataFactory_Users.standardLoginId,
        current.user.ProfileId,
        'User should have this ProfileId'
      );
    }
  }
  @isTest
  public static void isBrandStandardUser_asLoginProfile() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.standardLoginId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.BRAND_STANDARD_USER_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      TC_ExperienceCloud current = new TC_ExperienceCloud();
      System.assertEquals(
        true,
        current.isBrandStandardUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isBrandUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isStandardUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        false,
        current.isBrandAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierUser,
        'User should not match this state.'
      );
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_BRAND |
        TC_ExperienceCloud.USERTYPE_STANDARD,
        current.userType,
        'User type does not match.'
      );
      System.assertEquals(
        true,
        current.user.Email.startsWith('test'),
        'User should have this Email'
      );
      System.assertEquals(
        true,
        current.user.Email.endsWith('@example.com'),
        'User should have this Email'
      );
      System.assertEquals(
        TC_TestDataFactory_Users.standardLoginId,
        current.user.ProfileId,
        'User should have this ProfileId'
      );
    }
  }

  @isTest
  public static void isSupplierAdminUser_asMemberProfile() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.adminMemberId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_ADMINISTRATOR_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      TC_ExperienceCloud current = new TC_ExperienceCloud();
      System.assertEquals(
        true,
        current.isSupplierAdminUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isSupplierUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isAdminUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        false,
        current.isStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandUser,
        'User should not match this state.'
      );
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_SUPPLIER |
        TC_ExperienceCloud.USERTYPE_ADMIN,
        current.userType,
        'User type does not match.'
      );
      System.assertEquals(
        true,
        current.user.Email.startsWith('test'),
        'User should have this Email'
      );
      System.assertEquals(
        true,
        current.user.Email.endsWith('@example.com'),
        'User should have this Email'
      );
      System.assertEquals(
        TC_TestDataFactory_Users.adminMemberId,
        current.user.ProfileId,
        'User should have this ProfileId'
      );
    }
  }
  @isTest
  public static void isBrandAdminUser_asMemberProfile() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.adminMemberId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.BRAND_ADMINISTRATOR_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      TC_ExperienceCloud current = new TC_ExperienceCloud();
      System.assertEquals(
        true,
        current.isBrandAdminUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isBrandUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isAdminUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        false,
        current.isStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierUser,
        'User should not match this state.'
      );
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_BRAND | TC_ExperienceCloud.USERTYPE_ADMIN,
        current.userType,
        'User type does not match.'
      );
      System.assertEquals(
        true,
        current.user.Email.startsWith('test'),
        'User should have this Email'
      );
      System.assertEquals(
        true,
        current.user.Email.endsWith('@example.com'),
        'User should have this Email'
      );
      System.assertEquals(
        TC_TestDataFactory_Users.adminMemberId,
        current.user.ProfileId,
        'User should have this ProfileId'
      );
    }
  }
  @isTest
  public static void isSupplierStandardUser_asMemberProfile() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.standardMemberId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_STANDARD_USER_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      TC_ExperienceCloud current = new TC_ExperienceCloud();
      System.assertEquals(
        true,
        current.isSupplierStandardUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isSupplierUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isStandardUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        false,
        current.isAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isBrandUser,
        'User should not match this state.'
      );
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_SUPPLIER |
        TC_ExperienceCloud.USERTYPE_STANDARD,
        current.userType,
        'User type does not match.'
      );
      System.assertEquals(
        true,
        current.user.Email.startsWith('test'),
        'User should have this Email'
      );
      System.assertEquals(
        true,
        current.user.Email.endsWith('@example.com'),
        'User should have this Email'
      );
      System.assertEquals(
        TC_TestDataFactory_Users.standardMemberId,
        current.user.ProfileId,
        'User should have this ProfileId'
      );
    }
  }
  @isTest
  public static void isBrandStandardUser_asMemberProfile() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.standardMemberId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.BRAND_STANDARD_USER_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      TC_ExperienceCloud current = new TC_ExperienceCloud();
      System.assertEquals(
        true,
        current.isBrandStandardUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isBrandUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        true,
        current.isStandardUser,
        'User failed to match the permission set assigned.'
      );
      System.assertEquals(
        false,
        current.isBrandAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierAdminUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierStandardUser,
        'User should not match this state.'
      );
      System.assertEquals(
        false,
        current.isSupplierUser,
        'User should not match this state.'
      );
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_BRAND |
        TC_ExperienceCloud.USERTYPE_STANDARD,
        current.userType,
        'User type does not match.'
      );
      System.assertEquals(
        true,
        current.user.Email.startsWith('test'),
        'User should have this Email'
      );
      System.assertEquals(
        true,
        current.user.Email.endsWith('@example.com'),
        'User should have this Email'
      );
      System.assertEquals(
        TC_TestDataFactory_Users.standardMemberId,
        current.user.ProfileId,
        'User should have this ProfileId'
      );
    }
  }

  @isTest
  public static void getUserType() {
    User u = TC_TestDataFactory_Users.create(
      new User(
        ProfileId = [
          SELECT Id
          FROM Profile
          WHERE Name = 'System Administrator'
          LIMIT 1
        ]
        .Id
      )
    );
    insert u;
    System.runAs(u) {
      System.assertEquals(
        0,
        TC_ExperienceCloud.getUserType(),
        'User type must be zero when user is not assigned relevant PermissionSetGroup.'
      );
    }
  }
  @isTest
  public static void getUserType_for_SupplierAdmin() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.adminLoginId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_ADMINISTRATOR_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_SUPPLIER |
        TC_ExperienceCloud.USERTYPE_ADMIN,
        TC_ExperienceCloud.getUserType(),
        'User type does not match.'
      );
    }
  }
  @isTest
  public static void getUserType_for_BrandAdmin() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.adminLoginId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.BRAND_ADMINISTRATOR_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_BRAND | TC_ExperienceCloud.USERTYPE_ADMIN,
        TC_ExperienceCloud.getUserType(),
        'User type does not match.'
      );
    }
  }
  @isTest
  public static void getUserType_for_SupplierStandard() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.standardLoginId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_STANDARD_USER_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_SUPPLIER |
        TC_ExperienceCloud.USERTYPE_STANDARD,
        TC_ExperienceCloud.getUserType(),
        'User type does not match.'
      );
    }
  }
  @isTest
  public static void getUserType_for_BrandStandard() {
    Account brand = TC_TestDataFactory_Accounts.create(null);
    insert brand;
    Contact c = TC_TestDataFactory_Contacts.create(
      new Contact(AccountId = brand.Id, Email = 'test@example.com')
    );
    insert c;
    User u = TC_TestDataFactory_Users.create(
      c,
      new User(ProfileId = TC_TestDataFactory_Users.standardLoginId)
    );
    insert u;

    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = TC_ExperienceCloud.BRAND_STANDARD_USER_PSGID
    );
    Test.startTest();
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      new List<PermissionSetAssignment>{ psa }
    );
    Test.stopTest();

    System.runAs(u) {
      // Run as the actual user:
      System.assertEquals(
        TC_ExperienceCloud.USERTYPE_BRAND |
        TC_ExperienceCloud.USERTYPE_STANDARD,
        TC_ExperienceCloud.getUserType(),
        'User type does not match.'
      );
    }
  }
}