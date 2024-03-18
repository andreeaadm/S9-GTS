/**
 * SupplierFacilityBrand data scenario is used to construct and insert
 * three different accounts, each with admin and standard user
 * contacts and their user objjcts, with PermissionSetAssignments,
 * retaining all objects inserted as public properties.
 */
@isTest
public with sharing class TC_TestDataFactory_SupplierFacilityBrand {
  public Account supplier;
  public Account facility;
  public Account facility2;
  public Account brand;
  public List<Contact> supplierContacts;
  public List<Contact> facilityContacts;
  public List<Contact> brandContacts;
  public List<User> supplierUsers;
  public List<User> facilityUsers;
  public List<User> brandUsers;
  public List<PermissionSetAssignment> supplierUserAssignments;
  public List<PermissionSetAssignment> facilityUserAssignments;
  public List<PermissionSetAssignment> brandUserAssignments;
  public List<PermissionSetAssignment> permissionSetAssignments;

  /**
   * SupplierFacilityBrand Construct and insert records with real email
   * addresses.
   * @param email (String): Specify a email address to use when forming
   *        distinct addresses using +suffix standard notation.
   */
  public TC_TestDataFactory_SupplierFacilityBrand(String email) {
    supplier = TC_TestDataFactory_Accounts.create(
      TC_TestDataFactory_Accounts.supplierTemplate
    );
    insert supplier;
    facility = TC_TestDataFactory_Accounts.create(
      TC_TestDataFactory_Accounts.facilityTemplate
    );
  
    facility.ParentId = supplier.Id;
    insert facility;

    facility2 = TC_TestDataFactory_Accounts.create(
      'Second',
      TC_TestDataFactory_Accounts.facilityTemplate
    );
    facility2.ParentId = supplier.Id;
    insert facility2;

    brand = TC_TestDataFactory_Accounts.create(
      TC_TestDataFactory_Accounts.brandTemplate
    );
    insert brand;

    supplierContacts = new List<Contact>{
      TC_TestDataFactory_Contacts.create(
        new Contact(
          AccountId = supplier.Id,
          FirstName = supplier.Name + TC_TestDataFactory.randomWord(10),
          LastName = 'Admin' + TC_TestDataFactory.randomWord(20),
          Email =  email,
          ToxClear_User_Type__c = 'ToxClear Administrator'
        )
      ),
      TC_TestDataFactory_Contacts.create(
        new Contact(
          AccountId = supplier.Id,
          FirstName = supplier.Name + TC_TestDataFactory.randomWord(10),
          LastName = 'Standard' + TC_TestDataFactory.randomWord(20),
          Email =email,
          ToxClear_User_Type__c = 'ToxClear Standard User'
        )
      )
    };
    insert supplierContacts;


    facilityContacts = new List<Contact>{
      TC_TestDataFactory_Contacts.create(
        new Contact(
          AccountId = facility.Id,
          FirstName = facility.Name + TC_TestDataFactory.randomWord(10),
          LastName = 'Admin' + TC_TestDataFactory.randomWord(20),
          Email = email,
          ToxClear_User_Type__c = 'ToxClear Administrator',
          Title = TC_TestDataFactory.titles[1]
        )
      ),
      TC_TestDataFactory_Contacts.create(
        new Contact(
          AccountId = facility.Id,
          FirstName = facility.Name + TC_TestDataFactory.randomWord(10),
          LastName = 'Standard' + TC_TestDataFactory.randomWord(20),
          Email = email,
          ToxClear_User_Type__c = 'ToxClear Standard User',
          Title = TC_TestDataFactory.titles[2]
        )
      ),
      TC_TestDataFactory_Contacts.create(
        new Contact(
          AccountId = facility2.Id,
          FirstName = facility2.Name + TC_TestDataFactory.randomWord(10),
          LastName = 'Admin' + TC_TestDataFactory.randomWord(20),
          Email =  email,
          ToxClear_User_Type__c = 'ToxClear Administrator',
          Title = TC_TestDataFactory.titles[3]
        )
      ),
      TC_TestDataFactory_Contacts.create(
        new Contact(
          AccountId = facility2.Id,
          FirstName = facility2.Name + TC_TestDataFactory.randomWord(10),
          LastName = 'Standard' + TC_TestDataFactory.randomWord(20),
          Email = email,
          ToxClear_User_Type__c = 'ToxClear Standard User',
          Title = TC_TestDataFactory.titles[4]
        )
      )
    };
    insert facilityContacts;
    brandContacts = new List<Contact>{
      TC_TestDataFactory_Contacts.create(
        new Contact(
          AccountId = brand.Id,
          FirstName = brand.Name + TC_TestDataFactory.randomWord(10),
          LastName = 'Admin' + TC_TestDataFactory.randomWord(20),
          Email = email,
          ToxClear_User_Type__c = 'ToxClear Administrator'
        )
      ),
      TC_TestDataFactory_Contacts.create(
        new Contact(
          AccountId = brand.Id,
          FirstName = brand.Name + TC_TestDataFactory.randomWord(10),
          LastName = 'Standard' + TC_TestDataFactory.randomWord(20),
          Email = email,
          ToxClear_User_Type__c = 'ToxClear Standard User'
        )
      )
    };
    insert brandContacts;

    supplierUsers = new List<User>{
      TC_TestDataFactory_Users.create(
        supplierContacts[0],
        new User(ProfileId = TC_TestDataFactory_Users.adminMemberId)
      ),
      TC_TestDataFactory_Users.create(
        supplierContacts[1],
        new User(ProfileId = TC_TestDataFactory_Users.standardLoginId)
      )
    };
    insert supplierUsers;

    facilityUsers = new List<User>{
      TC_TestDataFactory_Users.create(
        facilityContacts[0],
        new User(ProfileId = TC_TestDataFactory_Users.adminMemberId)
      ),
      TC_TestDataFactory_Users.create(
        facilityContacts[1],
        new User(ProfileId = TC_TestDataFactory_Users.standardLoginId)
      )
    };
    insert facilityUsers;

    brandUsers = new List<User>{
      TC_TestDataFactory_Users.create(
        brandContacts[0],
        new User(ProfileId = TC_TestDataFactory_Users.adminMemberId)
      ),
      TC_TestDataFactory_Users.create(
        brandContacts[1],
        new User(ProfileId = TC_TestDataFactory_Users.standardMemberId)
      )
    };
    insert brandUsers;

    // After inserting Users (setup objects),
    // a transaction needs to complete before
    // regular objects can be inserted.
    // Continue in assignPermissionSets method.
    supplierUserAssignments = new List<PermissionSetAssignment>{
      new PermissionSetAssignment(
        AssigneeId = supplierUsers[0].Id,
        PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_ADMINISTRATOR_PSGID
      ),
      new PermissionSetAssignment(
        AssigneeId = supplierUsers[1].Id,
        PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_ADMINISTRATOR_PSGID
      )
    };
    facilityUserAssignments = new List<PermissionSetAssignment>{
      new PermissionSetAssignment(
        AssigneeId = facilityUsers[0].Id,
        PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_STANDARD_USER_PSGID
      ),
      new PermissionSetAssignment(
        AssigneeId = facilityUsers[1].Id,
        PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_STANDARD_USER_PSGID
      )
    };
    brandUserAssignments = new List<PermissionSetAssignment>{
      new PermissionSetAssignment(
        AssigneeId = brandUsers[0].Id,
        PermissionSetGroupId = TC_ExperienceCloud.BRAND_ADMINISTRATOR_PSGID
      ),
      new PermissionSetAssignment(
        AssigneeId = brandUsers[1].Id,
        PermissionSetGroupId = TC_ExperienceCloud.BRAND_STANDARD_USER_PSGID
      )
    };
    permissionSetAssignments = new List<PermissionSetAssignment>();
    permissionSetAssignments.addAll(supplierUserAssignments);
    permissionSetAssignments.addAll(facilityUserAssignments);
    permissionSetAssignments.addAll(brandUserAssignments);

    // Also assign Cloud Experience Access
    List<User> allUsers = new List<User>();
    allUsers.addAll(supplierUsers);
    allUsers.addAll(facilityUsers);
    allUsers.addAll(brandUsers);
    permissionSetAssignments.addAll(
      TC_TestDataFactory_Users.newPermissionSetAssignments(
        allUsers,
        TC_TestDataFactory_Users.accessPermissionSetId
      )
    );
  }
}