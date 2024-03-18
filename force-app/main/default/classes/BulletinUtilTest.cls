@isTest
public class BulletinUtilTest {
  @TestSetup
  static void makeData() {
    TC_TestDataFactory_SupplierFacilityBrand testData = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );

    TC_TestDataFactory_Users.insertPermissionSetAssignments(
      testData.permissionSetAssignments
    );

    Brand_Supplier_Connection__c conn = TC_TestDataFactory_Connections.create(
      testData.brand,
      testData.supplier,
      testData.brandContacts[0],
      'Approved'
    );
    insert conn;

    new TC_TestDataFactory_Bulletins(testData.brandUsers[0]);
  }

  @isTest
  static void SupplierStandard_Pinned_ReturnsData() {
    User suppStd = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
      LIMIT 1
    ];

    System.runAs(suppStd) {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        null,
        BulletinUtil.pinnedType
      );
      System.assertEquals(8, returnedList.size());
      System.assert(returnedList[0].Active__c);
      System.assert(returnedList[0].Pinned__c);
      System.assert(
        returnedList[0]
          .Target_Audience__c.contains(
            TC_TestDataFactory_Bulletins.supplierAudience
          )
      );
    }

    test.startTest();
    List<Brand_Supplier_Connection__c> connections = [
      SELECT Brand_Account__c, Supplier_Account__c
      FROM Brand_Supplier_Connection__c
    ];

    for (Brand_Supplier_Connection__c conn : connections) {
      conn.Status__c = 'Disconnected';
    }
    update connections;
    test.stopTest();

    System.runAs(suppStd) {
      List<Bulletin__c> returnedListAfter = BulletinUtil.getBulletins(
        null,
        BulletinUtil.pinnedType
      );
      System.assertEquals(4, returnedListAfter.size());
    }
  }

  @isTest
  static void SupplierAdmin_Pinned_ReturnsData() {
    User suppAdm = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
      LIMIT 1
    ];

    System.runAs(suppAdm) {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        null,
        BulletinUtil.pinnedType
      );
      System.assertEquals(8, returnedList.size());
      System.assert(returnedList[0].Active__c);
      System.assert(returnedList[0].Pinned__c);
      System.assert(
        returnedList[0]
          .Target_Audience__c.contains(
            TC_TestDataFactory_Bulletins.supplierAudience
          )
      );
    }

    test.startTest();
    List<Brand_Supplier_Connection__c> connections = [
      SELECT Brand_Account__c, Supplier_Account__c
      FROM Brand_Supplier_Connection__c
    ];

    for (Brand_Supplier_Connection__c conn : connections) {
      conn.Status__c = 'Disconnected';
    }
    update connections;
    test.stopTest();

    System.runAs(suppAdm) {
      List<Bulletin__c> returnedListAfter = BulletinUtil.getBulletins(
        null,
        BulletinUtil.pinnedType
      );
      System.assertEquals(4, returnedListAfter.size());
    }
  }

  @isTest
  static void BrandStandard_Pinned_ReturnsData() {
    User brandStd = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
      LIMIT 1
    ];

    System.runAs(brandStd) {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        null,
        BulletinUtil.pinnedType
      );
      System.assertEquals(16, returnedList.size());
      System.assert(returnedList[0].Pinned__c);
      System.assert(
        returnedList[0]
          .Target_Audience__c.contains(
            TC_TestDataFactory_Bulletins.brandAudience
          )
      );
    }
  }

  @isTest
  static void BrandAdmin_Pinned_ReturnsData() {
    User brandAdm = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
      LIMIT 1
    ];

    System.runAs(brandAdm) {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        null,
        BulletinUtil.pinnedType
      );
      System.assertEquals(16, returnedList.size());
      System.assert(returnedList[0].Pinned__c);
      System.assert(
        returnedList[0]
          .Target_Audience__c.contains(
            TC_TestDataFactory_Bulletins.brandAudience
          )
      );
    }
  }

  @isTest
  static void SupplierStandard_Unpinned_ReturnsData() {
    User suppStd = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
      LIMIT 1
    ];

    System.runAs(suppStd) {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        50,
        BulletinUtil.unpinnedType
      );
      System.assertEquals(8, returnedList.size());
      System.assert(returnedList[0].Active__c);
      System.assert(!returnedList[0].Pinned__c);
      System.assert(
        returnedList[0]
          .Target_Audience__c.contains(
            TC_TestDataFactory_Bulletins.supplierAudience
          )
      );
    }

    test.startTest();
    List<Brand_Supplier_Connection__c> connections = [
      SELECT Brand_Account__c, Supplier_Account__c
      FROM Brand_Supplier_Connection__c
    ];

    for (Brand_Supplier_Connection__c conn : connections) {
      conn.Status__c = 'Disconnected';
    }
    update connections;
    test.stopTest();

    System.runAs(suppStd) {
      List<Bulletin__c> returnedListAfter = BulletinUtil.getBulletins(
        50,
        BulletinUtil.unpinnedType
      );
      System.assertEquals(4, returnedListAfter.size());

      List<Bulletin__c> returnedListLimited = BulletinUtil.getBulletins(
        2,
        BulletinUtil.unpinnedType
      );
      System.assertEquals(2, returnedListLimited.size());
    }
  }

  @isTest
  static void SupplierAdmin_Unpinned_ReturnsData() {
    User suppAdm = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
      LIMIT 1
    ];

    System.runAs(suppAdm) {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        50,
        BulletinUtil.unpinnedType
      );
      System.assertEquals(8, returnedList.size());
      System.assertEquals(8, returnedList.size());
      System.assert(returnedList[0].Active__c);
      System.assert(!returnedList[0].Pinned__c);
      System.assert(
        returnedList[0]
          .Target_Audience__c.contains(
            TC_TestDataFactory_Bulletins.supplierAudience
          )
      );
    }

    test.startTest();
    List<Brand_Supplier_Connection__c> connections = [
      SELECT Brand_Account__c, Supplier_Account__c
      FROM Brand_Supplier_Connection__c
    ];

    for (Brand_Supplier_Connection__c conn : connections) {
      conn.Status__c = 'Disconnected';
    }
    update connections;
    test.stopTest();

    System.runAs(suppAdm) {
      List<Bulletin__c> returnedListAfter = BulletinUtil.getBulletins(
        50,
        BulletinUtil.unpinnedType
      );
      System.assertEquals(4, returnedListAfter.size());

      List<Bulletin__c> returnedListLimited = BulletinUtil.getBulletins(
        2,
        BulletinUtil.unpinnedType
      );
      System.assertEquals(2, returnedListLimited.size());
    }
  }

  @isTest
  static void BrandStandard_Unpinned_ReturnsData() {
    User brandStd = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
      LIMIT 1
    ];

    System.runAs(brandStd) {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        50,
        BulletinUtil.unpinnedType
      );
      System.assertEquals(16, returnedList.size());
      System.assert(!returnedList[0].Pinned__c);
      System.assert(
        returnedList[0]
          .Target_Audience__c.contains(
            TC_TestDataFactory_Bulletins.brandAudience
          )
      );
    }
  }

  @isTest
  static void BrandAdmin_Unpinned_ReturnsData() {
    User brandAdm = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
      LIMIT 1
    ];

    System.runAs(brandAdm) {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        50,
        BulletinUtil.unpinnedType
      );
      System.assertEquals(16, returnedList.size());
      System.assert(!returnedList[0].Pinned__c);
      System.assert(
        returnedList[0]
          .Target_Audience__c.contains(
            TC_TestDataFactory_Bulletins.brandAudience
          )
      );
    }
  }

  @isTest
  static void SupplierStandard_SentBulletins_Error() {
    User suppStd = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
      LIMIT 1
    ];

    System.runAs(suppStd) {
      Boolean threwException = false;

      try {
        List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
          50,
          BulletinUtil.sentType
        );
      } catch (BulletinUtil.BulletinTypeNotFoundException e) {
        threwException = true;
      }
      System.assert(threwException);
    }
  }

  @isTest
  static void SupplierAdmin_SentBulletins_Error() {
    User suppAdm = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
      LIMIT 1
    ];

    System.runAs(suppAdm) {
      Boolean threwException = false;

      try {
        List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
          50,
          BulletinUtil.sentType
        );
      } catch (BulletinUtil.BulletinTypeNotFoundException e) {
        threwException = true;
      }
      System.assert(threwException);
    }
  }

  @isTest
  static void BrandStandard_SentBulletins_ReturnsData() {
    User brandStd = [
      SELECT Id, Contact.AccountId
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Standard User'
      LIMIT 1
    ];

    System.runAs(brandStd) {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        50,
        BulletinUtil.sentType
      );
      System.assertEquals(14, returnedList.size());
      System.assert(returnedList[0].Active__c);
      System.assert(!returnedList[0].Sent_by_Intertek__c);
      System.assertEquals(
        brandStd.Contact.AccountId,
        returnedList[0].Sent_From_Owner_Account__c
      );

      List<Bulletin__c> returnedListLimited = BulletinUtil.getBulletins(
        5,
        BulletinUtil.sentType
      );
      System.assertEquals(5, returnedListLimited.size());
    }
  }

  @isTest
  static void BrandAdmin_SentBulletins_ReturnsData() {
    User brandAdm = [
      SELECT Id, Contact.AccountId
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
      LIMIT 1
    ];

    System.runAs(brandAdm) {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        50,
        BulletinUtil.sentType
      );
      System.assertEquals(14, returnedList.size());
      System.assert(returnedList[0].Active__c);
      System.assert(!returnedList[0].Sent_by_Intertek__c);
      System.assertEquals(
        brandAdm.Contact.AccountId,
        returnedList[0].Sent_From_Owner_Account__c
      );

      List<Bulletin__c> returnedListLimited = BulletinUtil.getBulletins(
        5,
        BulletinUtil.sentType
      );
      System.assertEquals(5, returnedListLimited.size());
    }
  }

  @isTest
  static void NonTCUser_Error() {
    Boolean threwException = false;
    try {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        50,
        BulletinUtil.pinnedType
      );
    } catch (BulletinUtil.BulletinTypeNotFoundException e) {
      threwException = true;
    }
    System.assert(threwException);
    threwException = false;

    try {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        50,
        BulletinUtil.unpinnedType
      );
    } catch (BulletinUtil.BulletinTypeNotFoundException e) {
      threwException = true;
    }
    System.assert(threwException);
    threwException = false;

    try {
      List<Bulletin__c> returnedList = BulletinUtil.getBulletins(
        50,
        BulletinUtil.sentType
      );
    } catch (BulletinUtil.BulletinTypeNotFoundException e) {
      threwException = true;
    }
    System.assert(threwException);
  }
}