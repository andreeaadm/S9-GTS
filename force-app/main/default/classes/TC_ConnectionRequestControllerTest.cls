@IsTest
private class TC_ConnectionRequestControllerTest {
  @TestSetup
  static void setupData() {
    TC_TestDataFactory_SupplierFacilityBrand baseTestData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    User supplierAdmin = [
      SELECT Id
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    User brandAdmin = [
      SELECT Id
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];
    List<PermissionSetAssignment> assignmentList = new List<PermissionSetAssignment>();
    assignmentList.add(
      new PermissionSetAssignment(
        AssigneeId = supplierAdmin.Id,
        PermissionSetGroupId = TC_ExperienceCloud.SUPPLIER_ADMINISTRATOR_PSGID
      )
    );
    assignmentList.add(
      new PermissionSetAssignment(
        AssigneeId = brandAdmin.Id,
        PermissionSetGroupId = TC_ExperienceCloud.BRAND_ADMINISTRATOR_PSGID
      )
    );
    TC_TestDataFactory_Users.insertPermissionSetAssignments(assignmentList);
  }

  @IsTest
  private static void getUserType_Supplier() {
    User supplierUser = [
      SELECT Id
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];

    String returnString = '';
    Test.startTest();
    System.runAs(supplierUser) {
      returnString = TC_ConnectionRequestController.getUserType();
    }
    Test.stopTest();

    System.assertEquals('supplier', returnString);
  }

  @IsTest
  private static void getUserType_Brand() {
    User brandUser = [
      SELECT Id
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];

    String returnString = '';
    Test.startTest();
    System.runAs(brandUser) {
      returnString = TC_ConnectionRequestController.getUserType();
    }
    Test.stopTest();

    System.assertEquals('brand', returnString);
  }

  @IsTest
  private static void getUserType_Other() {
    String returnString = '';
    Test.startTest();
    returnString = TC_ConnectionRequestController.getUserType();
    Test.stopTest();

    System.assertEquals('', returnString);
  }

  @IsTest
  private static void getSearchTable_Supplier() {
    User supplierUser = [
      SELECT Id
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];

    TC_ConnectionsListController.ConnectionListWrapper returnWrapper;

    Test.startTest();
    System.runAs(supplierUser) {
      returnWrapper = TC_ConnectionRequestController.getSearchTable(
        'supplier',
        10,
        '',
        'Unit'
      );
    }
    Test.stopTest();

    System.assertEquals(1, returnWrapper.totalCount);
    System.assertEquals(1, returnWrapper.table.rows.size());
    System.assertEquals(3, returnWrapper.table.rows[0].rowCells.size());
  }

  @IsTest
  private static void getSearchTable_Brand() {
    User brandUser = [
      SELECT Id
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];

    TC_ConnectionsListController.ConnectionListWrapper returnWrapper;

    Test.startTest();
    System.runAs(brandUser) {
      returnWrapper = TC_ConnectionRequestController.getSearchTable(
        'brand',
        10,
        '',
        'Unit'
      );
    }
    Test.stopTest();

    System.assertEquals(1, returnWrapper.totalCount);
    System.assertEquals(1, returnWrapper.table.rows.size());
    System.assertEquals(3, returnWrapper.table.rows[0].rowCells.size());
  }

  @IsTest
  private static void createConnection_Supplier() {
    User supplierUser = [
      SELECT Id, Contact.AccountId
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];
    Account brandAccount = [
      SELECT Id
      FROM Account
      WHERE ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];

    String returnString = '';
    Test.startTest();
    System.runAs(supplierUser) {
      returnString = TC_ConnectionRequestController.createConnection(
        'supplier',
        String.valueOf(brandAccount.Id)
      );
    }
    Test.stopTest();

    Brand_Supplier_Connection__c newConnection = [
      SELECT Id, Supplier_Account__c, Brand_Account__c
      FROM Brand_Supplier_Connection__c
      LIMIT 1
    ];

    System.assertEquals('success', returnString);
    System.assertEquals(
      supplierUser.Contact.AccountId,
      newConnection.Supplier_Account__c
    );
    System.assertEquals(brandAccount.Id, newConnection.Brand_Account__c);
  }

  @IsTest
  private static void createConnection_Brand() {
    User brandUser = [
      SELECT Id, Contact.AccountId
      FROM User
      WHERE
        Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
        AND Contact.Account.ToxClear_Account_Type__c = 'Brand'
      LIMIT 1
    ];
    Account supplierAccount = [
      SELECT Id
      FROM Account
      WHERE ToxClear_Account_Type__c = 'Supplier'
      LIMIT 1
    ];

    String returnString = '';
    Test.startTest();
    System.runAs(brandUser) {
      returnString = TC_ConnectionRequestController.createConnection(
        'brand',
        String.valueOf(supplierAccount.Id)
      );
    }
    Test.stopTest();

    Brand_Supplier_Connection__c newConnection = [
      SELECT Id, Supplier_Account__c, Brand_Account__c
      FROM Brand_Supplier_Connection__c
      LIMIT 1
    ];

    System.assertEquals('success', returnString);
    System.assertEquals(
      brandUser.Contact.AccountId,
      newConnection.Brand_Account__c
    );
    System.assertEquals(supplierAccount.Id, newConnection.Supplier_Account__c);
  }
}