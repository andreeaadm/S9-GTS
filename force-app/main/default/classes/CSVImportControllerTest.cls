@isTest
public with sharing class CSVImportControllerTest {
  @TestSetup
  static void setupAndGetAdminUser() {
    TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
      TC_TestDataFactory.randomWord(10) +
      '@' +
      TC_TestDataFactory.randomWord(10) +
      '.com'
    );
    TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      accounts.facility.Id,
      30,
      Date.today().addMonths(-1),
      'Delivery',
      2,
      2,
      'kg',
      5.00,
      30.00,
      6.00
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      TestDataFactory.createAdminUser(
        'ToxClear_Intertek_Back_Office_Administrator'
      );
    }
  }
  // Get the default value for the CSV Import Setting targetConfig attribute
  @isTest
  private static void test_getDefaultValue() {
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow response;
    Test.startTest();
    response = csv.getDefaultValue();
    Test.stopTest();
    System.assert(response != null);
  }
  // Get all options for the CSV Import Setting targetConfig attribute
  @isTest
  private static void test_getValues() {
    CSVImportController csv = new CSVImportController();
    VisualEditor.DynamicPickListRows response;
    Test.startTest();
    response = csv.getValues();
    Test.stopTest();
    System.assert(response.size() > 0);
  }
  // getTemplateColumns with a valid setting name
  @isTest
  private static void test_getTemplateColumns_valid() {
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    List<String> response;
    Test.startTest();
    response = CSVImportController.getTemplateColumns(
      String.valueOf(defaultSetting.getValue())
    );
    Test.stopTest();
    System.assert(!response.isEmpty());
  }
  // getTemplateColumns with an invalid setting name
  @isTest
  private static void test_getTemplateColumns_invalid() {
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    List<String> response;
    Test.startTest();
    response = CSVImportController.getTemplateColumns(
      'FileImportControllerTest_Invalid'
    );
    Test.stopTest();
    System.assert(response.isEmpty());
  }
  // doImport with a valid base64 string and valid parentId
  @isTest
  private static void test_doImport_valid() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,test_doImport_valid,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      response = CSVImportController.doImport(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
    }
    Test.stopTest();
    System.assertEquals(
      1,
      [
          SELECT Id
          FROM Inventory_Line_Item__c
          WHERE ZDHC_Product_GUID__c = 'test_doImport_valid'
        ]
        .size()
    );
    System.assertEquals('OK', response.status);
    System.assertEquals(200, response.statusCode);
  }
  // doImport with a valid base64 string (which needs some cleaning up) but no parentId
  @isTest
  private static void test_doImport_validBase64_noParent() {
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      '"Test","Test,1234,KG,1,2,3,Nottingham",1,2022-02-23\n' +
      'Test,Test,4321,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    response = CSVImportController.doImport(
      String.valueOf(defaultSetting.getValue()),
      EncodingUtil.base64Encode(csvData),
      null
    );
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with an invalid base64 string and no parentId
  @isTest
  private static void test_doImport_invalidBase64() {
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    APIResponse response;
    Test.startTest();
    response = CSVImportController.doImport(
      String.valueOf(defaultSetting.getValue()),
      'invalidBase64',
      null
    );
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, but a null objType
  @isTest
  private static void test_doImport_invalidObjectName() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,test_doImport_valid,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.sObjType = null;
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, and a recordTypeOverrideId has been set but is invalid for the user
  @isTest
  private static void test_doImport_recordTypeOverrideIdInvalidForUser() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,test_doImport_valid,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.recordTypeOverrideId = '012000000000000AAA';
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, but an invalid recordTypeOverride
  @isTest
  private static void test_doImport_invalidRecordTypeOverride() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,test_doImport_valid,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.setting.RecordTypeOverride__c = 'invalid';
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, and try to write to formula field
  @isTest
  private static void test_doImport_inaccessibleField() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,test_doImport_valid,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.setting.CSV_Import_Columns__r[0].TemplateOnly__c = false;
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, but invalid field name in csv import configuration
  @isTest
  private static void test_doImport_invalidFieldInConfig() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,test_doImport_valid,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      String columnLabel = csvFile.importColumnIndexToLabelMap.get(2);
      csvFile.masterLabelToColumnDefinitionMap.get(columnLabel)
        .FieldName__c = 'invalid';
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, with an extra column that is a formula field
  @isTest
  private static void test_doImport_extraColumnInaccessibleField() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date,Formulator_Name__c\n' +
      'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23,invalid\n' +
      'Test,Test,test_doImport_valid,LB,1,2,3,London,1,2022-01-01,invalid'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.setting.AllowExtraColumns__c = true;
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, with an extra column that is an invalid field name
  @isTest
  private static void test_doImport_extraColumnInvalidField() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date,Invalid__c\n' +
      'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23,invalid\n' +
      'Test,Test,test_doImport_valid,LB,1,2,3,London,1,2022-01-01,invalid'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.setting.AllowExtraColumns__c = true;
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, with an extra column that is a valid field name
  @isTest
  private static void test_doImport_extraColumnValidField() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date,Other_Certifications__c\n' +
      'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23,test\n' +
      'Test,Test,test_doImport_valid,LB,1,2,3,London,1,2022-01-01,test'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.setting.AllowExtraColumns__c = true;
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('OK', response.status);
    System.assertEquals(200, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, with an extra column that is not expected
  @isTest
  private static void test_doImport_extraColumnNotExpected() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date,Invalid__c\n' +
      'Test,Test,1234,KG,1,2,3,Nottingham,1,2022-02-23,invalid\n' +
      'Test,Test,test_doImport_valid,LB,1,2,3,London,1,2022-01-01,invalid'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.setting.AllowExtraColumns__c = false;
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, where a required field is blank in the CSV
  @isTest
  private static void test_doImport_requiredFieldIsBlank() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      String columnLabel = csvFile.importColumnIndexToLabelMap.get(2);
      csvFile.masterLabelToColumnDefinitionMap.get(columnLabel)
        .Required__c = true;
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, where a required field is blank in the CSV but a default value is set in the import config
  @isTest
  private static void test_doImport_requiredFieldWithDefaultValue() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      String columnLabel = csvFile.importColumnIndexToLabelMap.get(2);
      csvFile.masterLabelToColumnDefinitionMap.get(columnLabel)
        .Required__c = true;
      csvFile.masterLabelToColumnDefinitionMap.get(columnLabel)
        .DefaultValue__c = 'default';
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('OK', response.status);
    System.assertEquals(200, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, where invalid data has been entered in a cell
  @isTest
  private static void test_doImport_invalidCellValue() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,Test,KG,1,2,3,Nottingham,1,invalid\n' +
      'Test,Test,Test,LB,1,2,3,London,1,invalid'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, where a hidden field has a default value, and extra columns aren't allowed
  @isTest
  private static void test_doImport_hiddenRequiredFieldNotPopulatedExtraColumnsNotAllowed() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,LB,1,2,3,London,1,2022-02-23'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.masterLabelToColumnDefinitionMap.get('Product GUID')
        .Hidden__c = true;
      csvFile.masterLabelToColumnDefinitionMap.get('Product GUID')
        .DefaultValue__c = 'default';
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('OK', response.status);
    System.assertEquals(200, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, where a hidden field has a default value, and extra columns are allowed but user hasn't populated it
  @isTest
  private static void test_doImport_hiddenRequiredFieldNotPopulatedExtraColumnsAllowed() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.setting.AllowExtraColumns__c = true;
      csvFile.masterLabelToColumnDefinitionMap.get('Product GUID')
        .Hidden__c = true;
      csvFile.masterLabelToColumnDefinitionMap.get('Product GUID')
        .DefaultValue__c = 'default';
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('OK', response.status);
    System.assertEquals(200, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, where a hidden field has a default value, extra columns are allowed, and user HAS populated it
  @isTest
  private static void test_doImport_hiddenRequiredFieldPopulatedExtraColumnsAllowed() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,Test,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,Test,LB,1,2,3,test_doImport_hiddenRequiredFieldPopulatedExtraColumnsAllowed,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.setting.AllowExtraColumns__c = true;
      csvFile.masterLabelToColumnDefinitionMap.get('Product GUID')
        .Hidden__c = true;
      csvFile.masterLabelToColumnDefinitionMap.get('Product GUID')
        .DefaultValue__c = 'default';
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Inventory_Line_Item__c
        WHERE
          Storage_Location__c = 'test_doImport_hiddenRequiredFieldPopulatedExtraColumnsAllowed'
      ]
    );
    System.assertEquals('OK', response.status);
    System.assertEquals(200, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, where no rows have been populated
  @isTest
  private static void test_doImport_noRows() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
  // doImport with a valid base64 string and valid parentId, but invalid DML Statement in the CSV import setting
  @isTest
  private static void test_doImport_invalidDMLStatement() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'admin@oegen.co.uk'
      LIMIT 1
    ];
    CSVImportController csv = new CSVImportController();
    VisualEditor.DataRow defaultSetting = csv.getDefaultValue();
    Blob csvData = Blob.valueOf(
      'Formulator Name,Chemical Product Name,Product GUID,Unit,Stock Take - Month Begin,Delivered Stock This Month,Stock Take - Month End,Storage Location,Lot Number,Expiry Date\n' +
      'Test,Test,Test,KG,1,2,3,Nottingham,1,2022-02-23\n' +
      'Test,Test,Test,LB,1,2,3,London,1,2022-01-01'
    );
    APIResponse response;
    Test.startTest();
    System.runAs(admin) {
      CSVFile csvFile = new CSVFile(
        String.valueOf(defaultSetting.getValue()),
        EncodingUtil.base64Encode(csvData),
        [SELECT Id FROM Inventory__c LIMIT 1]
        .Id
      );
      csvFile.setting.DMLStatement__c = 'invalid';
      response = csvFile.import();
    }
    Test.stopTest();
    System.assertEquals('Bad Request', response.status);
    System.assertEquals(400, response.statusCode);
  }
}