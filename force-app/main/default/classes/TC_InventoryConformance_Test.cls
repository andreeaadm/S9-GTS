@isTest
public with sharing class TC_InventoryConformance_Test {
  @testSetup
  static void setup() {
    TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
      1,
      0, // inactive
      new List<Integer>{ 1 },
      new List<Integer>{ 0 }, // inactive
      1,
      0 // inactive
    );
    TC_TestDataFactory_Contacts tdfc = new TC_TestDataFactory_Contacts(
      tdfa,
      'unittest@example.com',
      new List<Integer>{ 1 },
      new List<Integer>{ 1 },
      new List<Integer>{ 1 },
      new List<Integer>{ 1 },
      new List<Integer>{ 1 },
      new List<Integer>{ 1 }
    );
    TC_TestDataFactory_Connections bsc = new TC_TestDataFactory_Connections(
      tdfa,
      tdfc
    );

    TC_TestDataFactory_Formulators tdff = new TC_TestDataFactory_Formulators(
      tdfa.facilities
    );
    TC_TestDataFactory_Chemicals chemical = new TC_TestDataFactory_Chemicals(
      tdff,
      null
    );
    TC_TestDataFactory_Inventories inventory = new TC_TestDataFactory_Inventories(
      tdfa.facilities,
      new List<Integer>{ 3 },
      Date.today()
    );

    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(tdfc, true);
    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      tdfu.permissionSetAssignments
    );
  }

  /** Incase the user doesn't show up first in the list.
   *  Find the user with this AccountId. */
  static private User findUser(List<User> users, Id accountId) {
    for (User u : users) {
      if (u.Contact.AccountId == accountId) {
        return u;
      }
    }
    return null;
  }

  // prettier-ignore
  @isTest
  static void getSuppliersForBrand_brandAccountId(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    Set<Id> supplierAdminUsersResult;
    Set<Id> supplierStdUsersResult;
    Set<Id> facilityAdminUsersResult;
    Set<Id> facilityStdUsersResult;
    Set<Id> brandAdminUsersResult;
    Set<Id> brandStdUsersResult;

    // getSuppliersForBrand(Id)

    Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      supplierAdminUsersResult = context.getSuppliersForBrand(context.user.Contact.AccountId);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      supplierStdUsersResult = context.getSuppliersForBrand(context.user.Contact.AccountId);
    }
    System.runAs(tdfu.facilityAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      facilityAdminUsersResult = context.getSuppliersForBrand(context.user.Contact.AccountId);
    }
    System.runAs(tdfu.facilityStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      facilityStdUsersResult = context.getSuppliersForBrand(context.user.Contact.AccountId);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      brandAdminUsersResult = context.getSuppliersForBrand(context.user.Contact.AccountId);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      brandStdUsersResult = context.getSuppliersForBrand(context.user.Contact.AccountId);
    }
    Test.stopTest();

    System.assertNotEquals(null, supplierAdminUsersResult, 'Set<Id> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'Set<Id> supplierStdUsersResult should not be null.');
    System.assertNotEquals(null, facilityAdminUsersResult, 'Set<Id> facilityAdminUsersResult should not be null.');
    System.assertNotEquals(null, facilityStdUsersResult, 'Set<Id> facilityStdUsersResult should not be null.');
    System.assertNotEquals(null, brandAdminUsersResult, 'Set<Id> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'Set<Id> brandStdUsersResult should not be null.');

    System.assertEquals(0, supplierAdminUsersResult.size(),'size should be 0');
    System.assertEquals(0, supplierStdUsersResult.size(),'size should be 0');
    System.assertEquals(0, facilityAdminUsersResult.size(),'size should be 0');
    System.assertEquals(0, facilityStdUsersResult.size(),'size should be 0');
    System.assertNotEquals(0, brandAdminUsersResult.size(),'size should not be 0');
    System.assertNotEquals(0, brandStdUsersResult.size(),'size should not be 0');
  }
  // prettier-ignore
  @isTest
  static void getSuppliersSet(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    Set<Id> supplierAdminUsersResult;
    Set<Id> supplierStdUsersResult;
    Set<Id> facilityAdminUsersResult;
    Set<Id> facilityStdUsersResult;
    Set<Id> brandAdminUsersResult;
    Set<Id> brandStdUsersResult;

    Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      supplierAdminUsersResult = context.getSuppliersSet();
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      supplierStdUsersResult = context.getSuppliersSet();
    }
    System.runAs(tdfu.facilityAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      facilityAdminUsersResult = context.getSuppliersSet();
    }
    System.runAs(tdfu.facilityStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      facilityStdUsersResult = context.getSuppliersSet();
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      brandAdminUsersResult = context.getSuppliersSet();
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      brandStdUsersResult = context.getSuppliersSet();
    }
    Test.stopTest();

    System.assertNotEquals(null, supplierAdminUsersResult, 'Set<Id> supplierAdminUsersResult should not be null.');
    System.assertEquals(null, supplierStdUsersResult, 'Set<Id> supplierStdUsersResult should be null.');
    System.assertEquals(null, facilityAdminUsersResult, 'Set<Id> facilityAdminUsersResult should be null.');
    System.assertEquals(null, facilityStdUsersResult, 'Set<Id> facilityStdUsersResult should be null.');
    System.assertNotEquals(null, brandAdminUsersResult, 'Set<Id> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'Set<Id> brandStdUsersResult should not be null.');

    System.assertEquals(1, supplierAdminUsersResult.size(),'size should be 1');
    System.assertNotEquals(0, brandAdminUsersResult.size(),'size should not be 0');
    System.assertNotEquals(0, brandStdUsersResult.size(),'size should not be 0');
  }
  // prettier-ignore
  @isTest
  static void getSuppliers(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Account> supplierAdminUsersResult;
    List<Account> supplierStdUsersResult;
    List<Account> facilityAdminUsersResult;
    List<Account> facilityStdUsersResult;
    List<Account> brandAdminUsersResult;
    List<Account> brandStdUsersResult;

    Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      supplierAdminUsersResult = context.getSuppliers();
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      supplierStdUsersResult = context.getSuppliers();
    }
    System.runAs(tdfu.facilityAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      facilityAdminUsersResult = context.getSuppliers();
    }
    System.runAs(tdfu.facilityStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      facilityStdUsersResult = context.getSuppliers();
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      brandAdminUsersResult = context.getSuppliers();
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      brandStdUsersResult = context.getSuppliers();
    }
    Test.stopTest();

    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Account> supplierAdminUsersResult should not be null.');
    System.assertEquals(null, supplierStdUsersResult, 'Set<Id> supplierStdUsersResult should be null.');
    System.assertEquals(null, facilityAdminUsersResult, 'Set<Id> facilityAdminUsersResult should be null.');
    System.assertEquals(null, facilityStdUsersResult, 'Set<Id> facilityStdUsersResult should be null.');
    System.assertNotEquals(null, brandAdminUsersResult, 'List<Account> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Account> brandStdUsersResult should not be null.');

    System.assertEquals(1, supplierAdminUsersResult.size(),'size should be 1');
    System.assertNotEquals(0, brandAdminUsersResult.size(),'size should not be 0');
    System.assertNotEquals(0, brandStdUsersResult.size(),'size should not be 0');
  }
  // prettier-ignore
  @isTest
  static void getFacilities_filterBySupplier_suppliers(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Account> supplierAdminUsersResult;
    List<Account> supplierStdUsersResult;
    List<Account> facilityAdminUsersResult;
    List<Account> facilityStdUsersResult;
    List<Account> brandAdminUsersResult;
    List<Account> brandStdUsersResult;

    // getFacilities(String, Set<Id>)

    Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      supplierAdminUsersResult = context.getFacilities(null, context.getSuppliersSet(),null,null);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      supplierStdUsersResult = context.getFacilities(null, context.getSuppliersSet(),null,null);
    }
    System.runAs(tdfu.facilityAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      facilityAdminUsersResult = context.getFacilities(null, context.getSuppliersSet(),null,null);
    }
    System.runAs(tdfu.facilityStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      facilityStdUsersResult = context.getFacilities(null, context.getSuppliersSet(),null,null);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      brandAdminUsersResult = context.getFacilities(null, context.getSuppliersSet(),null,null);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      brandStdUsersResult = context.getFacilities(null, context.getSuppliersSet(),null,null);
    }
    Test.stopTest();

    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Account> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'List<Account> supplierStdUsersResult should not be null.');
    System.assertNotEquals(null, facilityAdminUsersResult, 'List<Account> facilityAdminUsersResult should not be null.');
    System.assertNotEquals(null, facilityStdUsersResult, 'List<Account> facilityStdUsersResult should not be null.');
    System.assertNotEquals(null, brandAdminUsersResult, 'List<Account> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Account> brandStdUsersResult should not be null.');

    System.assertNotEquals(0, supplierAdminUsersResult.size(),'size should not be 0');
    System.assertEquals(0, supplierStdUsersResult.size(),'size should be 0');
    System.assertEquals(0, facilityAdminUsersResult.size(),'size should be 0');
    System.assertNotEquals(0, facilityStdUsersResult.size(),'size should not be 0');
    System.assertNotEquals(0, brandAdminUsersResult.size(),'size should not be 0');
    System.assertNotEquals(0, brandStdUsersResult.size(),'size should not be 0');
  }
  // prettier-ignore
  @isTest
  static void getInventories_facilities_startingFrom_until(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Inventory__c> supplierAdminUsersResult;
    List<Inventory__c> supplierStdUsersResult;
    List<Inventory__c> facilityAdminUsersResult;
    List<Inventory__c> facilityStdUsersResult;
    List<Inventory__c> brandAdminUsersResult;
    List<Inventory__c> brandStdUsersResult;

    // getInventories(Set<Id>, Date, Date)
    final Date startOfMonth = Date.today().toStartOfMonth();
    final Date until = startOfMonth.addMonths(1);
    final Date startingFrom = startOfMonth.addMonths(-23);


    Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      supplierAdminUsersResult = context.getInventories(facilities.keySet(), startingFrom, until);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      supplierStdUsersResult = context.getInventories(facilities.keySet(), startingFrom, until);
    }
    System.runAs(tdfu.facilityAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      facilityAdminUsersResult = context.getInventories(facilities.keySet(), startingFrom, until);
    }
    System.runAs(tdfu.facilityStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      facilityStdUsersResult = context.getInventories(facilities.keySet(), startingFrom, until);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      brandAdminUsersResult = context.getInventories(facilities.keySet(), startingFrom, until);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      brandStdUsersResult = context.getInventories(facilities.keySet(), startingFrom, until);
    }
    Test.stopTest();

    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Inventory__c> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'List<Inventory__c> supplierStdUsersResult should not be null.');
    System.assertNotEquals(null, facilityAdminUsersResult, 'List<Inventory__c> facilityAdminUsersResult should not be null.');
    System.assertNotEquals(null, facilityStdUsersResult, 'List<Inventory__c> facilityStdUsersResult should not be null.');
    System.assertNotEquals(null, brandAdminUsersResult, 'List<Inventory__c> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Inventory__c> brandStdUsersResult should not be null.');

    System.assertNotEquals(0, supplierAdminUsersResult.size(),'size should not be 0');
    System.assertEquals(0, supplierStdUsersResult.size(),'size should be 0');
    System.assertEquals(0, facilityAdminUsersResult.size(),'size should be 0');
    System.assertNotEquals(0, facilityStdUsersResult.size(),'size should not be 0');
    System.assertNotEquals(0, brandAdminUsersResult.size(),'size should not be 0');
    System.assertNotEquals(0, brandStdUsersResult.size(),'size should not be 0');
  }
  // prettier-ignore
  @isTest
  static void getCounts_facilities_month(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Integer> supplierAdminUsersResult;
    List<Integer> supplierStdUsersResult;
    List<Integer> facilityAdminUsersResult;
    List<Integer> facilityStdUsersResult;
    List<Integer> brandAdminUsersResult;
    List<Integer> brandStdUsersResult;

    // getCounts(Set<Id>, Integer)
    Integer month = 0;
    String location = null;
    String suppType = null;
    String invType = null;
    String confType = null;
    String classfType = null;

    Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      supplierAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      supplierStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.facilityAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      facilityAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.facilityStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      facilityStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      brandAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),null,null));
      brandStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    Test.stopTest();

    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Integer> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'List<Integer> supplierStdUsersResult should not be null.');
    System.assertNotEquals(null, facilityAdminUsersResult, 'List<Integer> facilityAdminUsersResult should not be null.');
    System.assertNotEquals(null, facilityStdUsersResult, 'List<Integer> facilityStdUsersResult should not be null.');
    System.assertNotEquals(null, brandAdminUsersResult, 'List<Integer> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Integer> brandStdUsersResult should not be null.');

    System.assertNotEquals(0, (Integer)supplierAdminUsersResult[0] + (Integer)supplierAdminUsersResult[1],'Should not total 0');
    System.assertEquals(  0, (Integer)supplierStdUsersResult[0] + (Integer)supplierStdUsersResult[1],'Should total 0');
    System.assertEquals(  0, (Integer)facilityAdminUsersResult[0] + (Integer)facilityAdminUsersResult[1],'Should total 0');
    System.assertNotEquals(0, (Integer)facilityStdUsersResult[0] + (Integer)facilityStdUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandAdminUsersResult[0] + (Integer)brandAdminUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandStdUsersResult[0] + (Integer)brandStdUsersResult[1],'Should not total 0');
  }
  // prettier-ignore
  @isTest
  static void getCounts_accountId_month(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Integer> supplierAdminUsersResult;
    List<Integer> supplierStdUsersResult;
    List<Integer> facilityAdminUsersResult;
    List<Integer> facilityStdUsersResult;
    List<Integer> brandAdminUsersResult;
    List<Integer> brandStdUsersResult;

    // getCounts(String, Integer)
    String accountId = null;
    Integer month = 0;
    String location = null;
    String suppType = null;
    String invType = null;
    String confType = null;
    String classfType = null;

    Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      supplierAdminUsersResult = context.getCounts(accountId, month, location, suppType, invType, confType, classfType);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      supplierStdUsersResult = context.getCounts(accountId, month, location, suppType, invType, confType, classfType);
    }
    System.runAs(tdfu.facilityAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      facilityAdminUsersResult = context.getCounts(accountId, month, location, suppType, invType, confType, classfType);
    }
    System.runAs(tdfu.facilityStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      facilityStdUsersResult = context.getCounts(accountId, month, location, suppType, invType, confType, classfType);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      brandAdminUsersResult = context.getCounts(accountId, month, location, suppType, invType, confType, classfType);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      brandStdUsersResult = context.getCounts(accountId, month, location, suppType, invType, confType, classfType);
    }
    Test.stopTest();

    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Integer> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'List<Integer> supplierStdUsersResult should not be null.');
    System.assertNotEquals(null, facilityAdminUsersResult, 'List<Integer> facilityAdminUsersResult should not be null.');
    System.assertNotEquals(null, facilityStdUsersResult, 'List<Integer> facilityStdUsersResult should not be null.');
    System.assertNotEquals(null, brandAdminUsersResult, 'List<Integer> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Integer> brandStdUsersResult should not be null.');

    System.assertNotEquals(0, (Integer)supplierAdminUsersResult[0] + (Integer)supplierAdminUsersResult[1],'Should not total 0');
    System.assertEquals(  0, (Integer)supplierStdUsersResult[0] + (Integer)supplierStdUsersResult[1],'Should total 0');
    System.assertEquals(  0, (Integer)facilityAdminUsersResult[0] + (Integer)facilityAdminUsersResult[1],'Should total 0');
    System.assertNotEquals(0, (Integer)facilityStdUsersResult[0] + (Integer)facilityStdUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandAdminUsersResult[0] + (Integer)brandAdminUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandStdUsersResult[0] + (Integer)brandStdUsersResult[1],'Should not total 0');
  }
    
  @isTest
  static void getCounts_location_suppType_invType(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Integer> supplierAdminUsersResult;
    List<Integer> supplierStdUsersResult;
    List<Integer> facilityAdminUsersResult;
    List<Integer> facilityStdUsersResult;
    List<Integer> brandAdminUsersResult;
    List<Integer> brandStdUsersResult;

    // getCounts(Set<Id>, Integer)
    Integer month = 0;
    String location = 'United States of America';
    String suppType = 'Fabric Mills';
    String invType = 'Usage_Inventory_Line_Item';
    String confType = null;
    String classfType = null;

    Test.startTest();
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    Test.stopTest();

    System.assertNotEquals(null, brandAdminUsersResult, 'List<Integer> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Integer> brandStdUsersResult should not be null.');

    System.assertNotEquals(0, (Integer)brandAdminUsersResult[0] + (Integer)brandAdminUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandStdUsersResult[0] + (Integer)brandStdUsersResult[1],'Should not total 0');
  }
    
  @isTest
  static void getCounts_invType_confType_classfType_Babies(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Integer> supplierAdminUsersResult;
    List<Integer> supplierStdUsersResult;
    List<Integer> facilityAdminUsersResult;
    List<Integer> facilityStdUsersResult;
    List<Integer> brandAdminUsersResult;
    List<Integer> brandStdUsersResult;

    // getCounts(Set<Id>, Integer)
    Integer month = 0;
    String location = 'United States of America';
    String suppType = 'Fabric Mills';
    String invType = 'Usage_Inventory_Line_Item';
    String confType = 'Inditex The List';
    String classfType = 'Babies';

     Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    Test.stopTest();

    System.assertNotEquals(null, brandAdminUsersResult, 'List<Integer> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Integer> brandStdUsersResult should not be null.');
    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Integer> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'List<Integer> supplierStdUsersResult should not be null.');

    System.assertNotEquals(0, (Integer)brandAdminUsersResult[0] + (Integer)brandAdminUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandStdUsersResult[0] + (Integer)brandStdUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)supplierAdminUsersResult[0] + (Integer)supplierAdminUsersResult[1],'Should not total 0');
    System.assertEquals(  0, (Integer)supplierStdUsersResult[0] + (Integer)supplierStdUsersResult[1],'Should total 0');
  }
  @isTest
  static void getCounts_invType_confType_classfType_ChildAdults(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Integer> supplierAdminUsersResult;
    List<Integer> supplierStdUsersResult;
    List<Integer> facilityAdminUsersResult;
    List<Integer> facilityStdUsersResult;
    List<Integer> brandAdminUsersResult;
    List<Integer> brandStdUsersResult;

    // getCounts(Set<Id>, Integer)
    Integer month = 0;
    String location = 'United States of America';
    String suppType = 'Fabric Mills';
    String invType = 'Usage_Inventory_Line_Item';
    String confType = 'Inditex The List';
    String classfType = 'Children & Adults';

     Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    Test.stopTest();

    System.assertNotEquals(null, brandAdminUsersResult, 'List<Integer> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Integer> brandStdUsersResult should not be null.');
    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Integer> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'List<Integer> supplierStdUsersResult should not be null.');

    System.assertNotEquals(0, (Integer)brandAdminUsersResult[0] + (Integer)brandAdminUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandStdUsersResult[0] + (Integer)brandStdUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)supplierAdminUsersResult[0] + (Integer)supplierAdminUsersResult[1],'Should not total 0');
    System.assertEquals(  0, (Integer)supplierStdUsersResult[0] + (Integer)supplierStdUsersResult[1],'Should total 0');
  }
  @isTest
  static void getCounts_invType_confType_classfType_allTypes(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Integer> supplierAdminUsersResult;
    List<Integer> supplierStdUsersResult;
    List<Integer> facilityAdminUsersResult;
    List<Integer> facilityStdUsersResult;
    List<Integer> brandAdminUsersResult;
    List<Integer> brandStdUsersResult;

    // getCounts(Set<Id>, Integer)
    Integer month = 0;
    String location = 'United States of America';
    String suppType = 'Fabric Mills';
    String invType = 'Usage_Inventory_Line_Item';
    String confType = 'Inditex The List';
    String classfType = 'All Types';

     Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    Test.stopTest();

    System.assertNotEquals(null, brandAdminUsersResult, 'List<Integer> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Integer> brandStdUsersResult should not be null.');
    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Integer> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'List<Integer> supplierStdUsersResult should not be null.');

    System.assertNotEquals(0, (Integer)brandAdminUsersResult[0] + (Integer)brandAdminUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandStdUsersResult[0] + (Integer)brandStdUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)supplierAdminUsersResult[0] + (Integer)supplierAdminUsersResult[1],'Should not total 0');
    System.assertEquals(  0, (Integer)supplierStdUsersResult[0] + (Integer)supplierStdUsersResult[1],'Should total 0');
  }
  @isTest
  static void getCounts_invType_confType_classfType_childAdult_withoutInvType(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Integer> supplierAdminUsersResult;
    List<Integer> supplierStdUsersResult;
    List<Integer> facilityAdminUsersResult;
    List<Integer> facilityStdUsersResult;
    List<Integer> brandAdminUsersResult;
    List<Integer> brandStdUsersResult;

    // getCounts(Set<Id>, Integer)
    Integer month = 0;
    String location = 'United States of America';
    String suppType = 'Fabric Mills';
    String invType = null;
    String confType = 'Inditex The List';
    String classfType = 'Children & Adults';

     Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    Test.stopTest();

    System.assertNotEquals(null, brandAdminUsersResult, 'List<Integer> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Integer> brandStdUsersResult should not be null.');
    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Integer> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'List<Integer> supplierStdUsersResult should not be null.');

    System.assertNotEquals(0, (Integer)brandAdminUsersResult[0] + (Integer)brandAdminUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandStdUsersResult[0] + (Integer)brandStdUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)supplierAdminUsersResult[0] + (Integer)supplierAdminUsersResult[1],'Should not total 0');
    System.assertEquals(  0, (Integer)supplierStdUsersResult[0] + (Integer)supplierStdUsersResult[1],'Should total 0');
  }
  @isTest
  static void getCounts_invType_confType_classfType_babies_withoutInvType(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Integer> supplierAdminUsersResult;
    List<Integer> supplierStdUsersResult;
    List<Integer> facilityAdminUsersResult;
    List<Integer> facilityStdUsersResult;
    List<Integer> brandAdminUsersResult;
    List<Integer> brandStdUsersResult;

    // getCounts(Set<Id>, Integer)
    Integer month = 0;
    String location = 'United States of America';
    String suppType = 'Fabric Mills';
    String invType = null;
    String confType = 'Inditex The List';
    String classfType = 'Babies';

     Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    Test.stopTest();

    System.assertNotEquals(null, brandAdminUsersResult, 'List<Integer> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Integer> brandStdUsersResult should not be null.');
    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Integer> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'List<Integer> supplierStdUsersResult should not be null.');

    System.assertNotEquals(0, (Integer)brandAdminUsersResult[0] + (Integer)brandAdminUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandStdUsersResult[0] + (Integer)brandStdUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)supplierAdminUsersResult[0] + (Integer)supplierAdminUsersResult[1],'Should not total 0');
    System.assertEquals(  0, (Integer)supplierStdUsersResult[0] + (Integer)supplierStdUsersResult[1],'Should total 0');
  }
  @isTest
  static void getCounts_invType_confType_classfType_allTypes_withoutInvType(){
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    List<Integer> supplierAdminUsersResult;
    List<Integer> supplierStdUsersResult;
    List<Integer> facilityAdminUsersResult;
    List<Integer> facilityStdUsersResult;
    List<Integer> brandAdminUsersResult;
    List<Integer> brandStdUsersResult;

    // getCounts(Set<Id>, Integer)
    Integer month = 0;
    String location = 'United States of America';
    String suppType = 'Fabric Mills';
    String invType = null;
    String confType = 'Inditex The List';
    String classfType = 'All Types';

     Test.startTest();
    System.runAs(tdfu.supplierAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.supplierStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      supplierStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandAdminUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandAdminUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    System.runAs(tdfu.brandStdUsers[0]){
      TC_InventoryConformance context = new TC_InventoryConformance();
      Map<Id, Account> facilities = new Map<Id, Account>(context.getFacilities(null, context.getSuppliersSet(),location,suppType));
      brandStdUsersResult = context.getCounts(facilities.keySet(), month, invType, confType, classfType);
    }
    Test.stopTest();

    System.assertNotEquals(null, brandAdminUsersResult, 'List<Integer> brandAdminUsersResult should not be null.');
    System.assertNotEquals(null, brandStdUsersResult, 'List<Integer> brandStdUsersResult should not be null.');
    System.assertNotEquals(null, supplierAdminUsersResult, 'List<Integer> supplierAdminUsersResult should not be null.');
    System.assertNotEquals(null, supplierStdUsersResult, 'List<Integer> supplierStdUsersResult should not be null.');

    System.assertNotEquals(0, (Integer)brandAdminUsersResult[0] + (Integer)brandAdminUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)brandStdUsersResult[0] + (Integer)brandStdUsersResult[1],'Should not total 0');
    System.assertNotEquals(0, (Integer)supplierAdminUsersResult[0] + (Integer)supplierAdminUsersResult[1],'Should not total 0');
    System.assertEquals(  0, (Integer)supplierStdUsersResult[0] + (Integer)supplierStdUsersResult[1],'Should total 0');
  }
}