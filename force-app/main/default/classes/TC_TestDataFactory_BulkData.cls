/**
 * BulkData data scenario is used to construct and insert
 * hundreds or thousands of each user type with their accounts,
 * retaining all objects inserted as public properties.
 */
@isTest
public with sharing class TC_TestDataFactory_BulkData {
  public List<Account> supplierAccounts;
  public List<Account> facilityAccounts;
  public List<Account> brandAccounts;
  public List<Account> suppliersAndFacilities;
  public List<Contact> supplierAndFacilityAdminContacts;
  public List<Contact> supplierAndFacilityStandardContacts;
  public List<Contact> brandAdminContacts;
  public List<Contact> brandStandardContacts;
  public List<User> supplierAndFacilityAdminUsers;
  public List<User> supplierAndFacilityStandardUsers;
  public List<User> brandAdminUsers;
  public List<User> brandStandardUsers;
  public List<PermissionSetAssignment> permissionSetAssignments;

  /**
   * BulkData
   * Construct and insert hundreds or thousands of records.
   *
   *    new BulkData(10,4,20,1,10);  // 10 suppliers each with 4 facilities, 20 brands,
   *                                 // 1 admin and 10 standard users for each supplier, facility, and brand.
   *
   * @param supplierCount (Integer): How many suppliers to insert.
   * @param facilitiesCountPerSupplier (Integer): How many facilities to insert for each supplier.
   * @param brandsCount (Integer): How many brands to insert.
   * @param adminUserCount (Integer): How many admin users for each account.
   * @param standardUserCount (Integer): How many standard users for each account
   */
  public TC_TestDataFactory_BulkData(
    Integer supplierCount,
    Integer facilitiesCountPerSupplier,
    Integer brandsCount,
    Integer adminUserCount,
    Integer standardUserCount
  ) {
    // Create bulk random data for testing component sizes/alignment, Load More, etc..
    supplierAccounts = TC_TestDataFactory_Accounts.create(
      supplierCount,
      new Account(
        Name = ' Supplier',
        Country__c = 'United States of America',
        ToxClear_Account_Type__c = 'Supplier',
        Is_ToxClear_Account__c = true,
        ToxClear_Subscription_Status__c = 'Active'
      )
    );
    insert supplierAccounts;

    facilityAccounts = new List<Account>();
    for (Account sup : supplierAccounts) {
      facilityAccounts.addAll(
        TC_TestDataFactory_Accounts.create(
          facilitiesCountPerSupplier,
          new Account(
            Name = ' Facility',
            Country__c = 'United States of America',
            ToxClear_Account_Type__c = 'Facility',
            Is_ToxClear_Account__c = true,
            ToxClear_Subscription_Status__c = 'Active',
            ParentId = sup.Id
          )
        )
      );
    }
    insert facilityAccounts;

    brandAccounts = TC_TestDataFactory_Accounts.create(
      brandsCount,
      new Account(
        Name = ' Brand',
        Country__c = 'United States of America',
        ToxClear_Account_Type__c = 'Brand',
        Is_ToxClear_Account__c = true,
        ToxClear_Subscription_Status__c = 'Active'
      )
    );
    insert brandAccounts;

    suppliersAndFacilities = new List<Account>();
    suppliersAndFacilities.addAll(supplierAccounts);
    suppliersAndFacilities.addAll(facilityAccounts);
    // Either zero or one contact for admin, and zero to at most standardUserCountMax for standard users.
    supplierAndFacilityAdminContacts = TC_TestDataFactory_Contacts.createForEachAccount(
      adminUserCount,
      suppliersAndFacilities,
      null
    );
    supplierAndFacilityStandardContacts = TC_TestDataFactory_Contacts.createForEachAccount(
      standardUserCount,
      suppliersAndFacilities,
      null
    );
    brandAdminContacts = TC_TestDataFactory_Contacts.createForEachAccount(
      adminUserCount,
      brandAccounts,
      null
    );
    brandStandardContacts = TC_TestDataFactory_Contacts.createForEachAccount(
      standardUserCount,
      brandAccounts,
      null
    );
    insert supplierAndFacilityAdminContacts;
    insert supplierAndFacilityStandardContacts;
    insert brandAdminContacts;
    insert brandStandardContacts;

    User adminUserTemplate = new User(
      ProfileId = TC_TestDataFactory_Users.adminLoginId,
      IsActive = false
    );
    User standardUserTemplate = new User(
      ProfileId = TC_TestDataFactory_Users.standardLoginId,
      IsActive = false
    );
    supplierAndFacilityAdminUsers = TC_TestDataFactory_Users.create(
      supplierAndFacilityAdminContacts,
      adminUserTemplate
    );
    supplierAndFacilityStandardUsers = TC_TestDataFactory_Users.create(
      supplierAndFacilityStandardContacts,
      standardUserTemplate
    );
    brandAdminUsers = TC_TestDataFactory_Users.create(
      brandAdminContacts,
      adminUserTemplate
    );
    brandStandardUsers = TC_TestDataFactory_Users.create(
      brandStandardContacts,
      standardUserTemplate
    );
    insert supplierAndFacilityAdminUsers;
    insert supplierAndFacilityStandardUsers;
    insert brandAdminUsers;
    insert brandStandardUsers;

    permissionSetAssignments = new List<PermissionSetAssignment>();
    permissionSetAssignments.addAll(
      TC_TestDataFactory_Users.newPermissionSetGroupAssignments(
        supplierAndFacilityAdminUsers,
        TC_ExperienceCloud.SUPPLIER_ADMINISTRATOR_PSGID
      )
    );
    permissionSetAssignments.addAll(
      TC_TestDataFactory_Users.newPermissionSetGroupAssignments(
        supplierAndFacilityStandardUsers,
        TC_ExperienceCloud.SUPPLIER_STANDARD_USER_PSGID
      )
    );
    permissionSetAssignments.addAll(
      TC_TestDataFactory_Users.newPermissionSetGroupAssignments(
        brandAdminUsers,
        TC_ExperienceCloud.BRAND_ADMINISTRATOR_PSGID
      )
    );
    permissionSetAssignments.addAll(
      TC_TestDataFactory_Users.newPermissionSetGroupAssignments(
        brandStandardUsers,
        TC_ExperienceCloud.BRAND_STANDARD_USER_PSGID
      )
    );

    List<User> allUsers = new List<User>();
    allUsers.addAll(supplierAndFacilityAdminUsers);
    allUsers.addAll(supplierAndFacilityStandardUsers);
    allUsers.addAll(brandAdminUsers);
    allUsers.addAll(brandStandardUsers);
    permissionSetAssignments.addAll(
      TC_TestDataFactory_Users.newPermissionSetAssignments(
        allUsers,
        TC_TestDataFactory_Users.accessPermissionSetId
      )
    );

    // Inserts in a future method if any users were IsActive=true
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      permissionSetAssignments
    );
  }
}