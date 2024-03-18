@isTest
public with sharing class BulletinListControllerTest {
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
  static void getBulletins_supplierPinned_returnsCorrect() {
    User suppAdm = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Supplier'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
      LIMIT 1
    ];

    System.runAs(suppAdm) {
      ListResponse returnVal = BulletinListController.getBulletins(
        4,
        BulletinUtil.pinnedType
      );
      System.assertEquals(4, returnVal.table.columns.size());
      System.assertEquals(8, returnVal.table.rows.size());
      System.assertEquals(8, returnVal.totalRows);
    }
  }

  @isTest
  static void getBulletins_brandSent_returnsCorrect() {
    User brandAdm = [
      SELECT Id
      FROM User
      WHERE
        Contact.Account.ToxClear_Account_Type__c = 'Brand'
        AND Contact.ToxClear_User_Type__c = 'ToxClear Administrator'
      LIMIT 1
    ];

    System.runAs(brandAdm) {
      ListResponse returnVal = BulletinListController.getBulletins(
        5,
        BulletinUtil.sentType
      );
      System.assertEquals(4, returnVal.table.columns.size());
      System.assertEquals(5, returnVal.table.rows.size());
      System.assertEquals(5, returnVal.totalRows);
    }
  }

  @isTest
  static void getBulletins_handlesError() {
    Boolean threwException;
    try {
      ListResponse returnVal = BulletinListController.getBulletins(
        5,
        BulletinUtil.unpinnedType
      );
    } catch (AuraHandledException e) {
      threwException = true;
    }
    System.assert(threwException);
  }

  @isTest
  static void getColumns_returnsCorrect() {
    List<DataTable.Column> returnVal = BulletinListController.getColumns();
    System.assertEquals(4, returnVal.size());
    System.assertEquals(Label.TC_Date_Sent, returnVal[0].label);
    System.assertEquals(Label.Subject, returnVal[1].label);
    System.assertEquals(Label.From.capitalize(), returnVal[2].label);
    System.assertEquals('', returnVal[3].label);
  }

  @isTest
  static void getRows_returnsCorrect() {
    List<Bulletin__c> bulletins = [
      SELECT Sent_Date__c, Subject__c, Description__c, From__c
      FROM Bulletin__c
      WHERE
        Active__c = TRUE
        AND Pinned__c = TRUE
        AND Sent_by_Intertek__c = TRUE
        AND Target_Audience__c = 'Intertek'
    ];
    System.assertEquals(1, bulletins.size());

    List<DataTable.Row> returnVal = BulletinListController.getRows(bulletins);
    System.assertEquals(1, returnval.size());
    System.assertEquals(
      String.valueOf(bulletins[0].Sent_Date__c.format()),
      returnVal[0].rowCells[0].value
    );
    System.assertEquals(
      bulletins[0].Subject__c,
      returnVal[0].rowCells[1].value
    );
    System.assertEquals(bulletins[0].From__c, returnVal[0].rowCells[2].value);
    System.assertEquals(Label.View, returnVal[0].rowCells[3].value);
    System.assertEquals(
      bulletins[0].Id,
      ((Map<String, Object>) returnVal[0]
          .rowCells[3]
          .navMixinPageRef.get('attributes'))
        .get('recordId')
    );
    System.assertEquals(bulletins[0].Id, returnVal[0].rowId);
  }
}