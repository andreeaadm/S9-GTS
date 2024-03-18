@isTest
global class TC_SynchroniseProductsTest {
  @TestSetup
  static void setup() {
    // 4 Supplers (1 inactive), first supplier to have 10 facilities, second 3 facilities, third 1 facility, 7 brands (3 inactive)
    TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
      4,
      1, // inactive
      new List<Integer>{ 10, 3, 1 },
      new List<Integer>{ 1, 1, 1 }, // inactive
      7,
      3 // inactive
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
    TC_TestDataFactory_Formulators tdff = new TC_TestDataFactory_Formulators(
      tdfa.facilities
    );
    
    TC_TestDataFactory_Chemicals chemical = new TC_TestDataFactory_Chemicals(
      tdff,
      75
    );
    // Setup inventories for these facilities.
    TC_TestDataFactory_Inventories inv1 = new TC_TestDataFactory_Inventories(
      new List<Account>{
        tdfa.facilities[0],
        tdfa.facilities[1],
        tdfa.facilities[2],
        tdfa.facilities[11]
      },
      new List<Integer>{ 3 },
      Date.today()
    );
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(tdfc, true);
    tdfu.insertPermissionSetAssignments();
    
    TCSynchroniseProductsLogging__c TCSyncLog = new TCSynchroniseProductsLogging__c();
      TCSyncLog.updated__c = 0;
      TCSyncLog.notChanged__c = 0;
      TCSyncLog.deactivated__c = 0;
      TCSyncLog.notFound__c = 0;
      TCSyncLog.Result_Size__c = 0;
      TCSyncLog.formulatorChanged__c = 0;
      TCSyncLog.formulatorNameUpdated__c = 0;
      TCSyncLog.inventoryLineItemUpdates__c = 0;
      TCSyncLog.errors__c = null;
      insert TCSyncLog;  
  }

  @isTest
  static void synchronise() {
    ZDHCGatewayMockResponseGenerator mock = new ZDHCGatewayMockResponseGenerator();
    Test.setMock(HttpCalloutMock.class, mock);
	
    TC_SynchroniseProducts tcsp = new TC_SynchroniseProducts(true);
    List<Chemical_Product__c> scope1 = [
      SELECT
        Id,
        Origin__c,
        ZDHC_Product_GUID__c,
        Chemical_Product_Name__c,
        Product_Trade_Name_Other_Name__c,
        ZDHC_Product_Code__c,
        ZDHC_PID__c,
        Product_Status__c,
        Registered__c,
        ZDHC_Product_Id__c,
        Last_Verified_Date__c,
        ZDHC_Certification_JSON__c,
        Other_Certifications__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_MRSL_Version__c,
        ZDHC_Formulator_GUID__c,
        Formulator__c,
        Formulator__r.Name,
        Formulator__r.Created_By__r.Facility_Manager__c,
        (
          SELECT
            Id,
            Origin__c,
            ZDHC_MRSL_v2_0__c,
            ZDHC_MRSL_Version__c,
            Other_Certifications__c,
            ZDHC_Certification_JSON__c,
            ZDHC_Product_GUID__c,
            ZDHC_Product_Id__c
          FROM Inventory_Line_Items__r
          WHERE
            Inventory__r.Status__c = 'Pending'
            AND (Inventory__r.Inventory_Date__c = LAST_MONTH
            OR Inventory__r.Inventory_Date__c = THIS_MONTH)
        )
      FROM Chemical_Product__c
      WHERE
        ZDHC_Product_GUID__c != NULL
        AND Formulator__r.Created_By__r.Facility_Manager__c != NULL
      LIMIT 75
      OFFSET 0
    ];
    List<Chemical_Product__c> scope2 = [
      SELECT
        Id,
        Origin__c,
        ZDHC_Product_GUID__c,
        Chemical_Product_Name__c,
        Product_Trade_Name_Other_Name__c,
        ZDHC_Product_Code__c,
        ZDHC_PID__c,
        Product_Status__c,
        Registered__c,
        ZDHC_Product_Id__c,
        Last_Verified_Date__c,
        ZDHC_Certification_JSON__c,
        Other_Certifications__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_MRSL_Version__c,
        ZDHC_Formulator_GUID__c,
        Formulator__c,
        Formulator__r.Name,
        Formulator__r.Created_By__r.Facility_Manager__c,
        (
          SELECT
            Id,
            Origin__c,
            ZDHC_MRSL_v2_0__c,
            ZDHC_MRSL_Version__c,
            Other_Certifications__c,
            ZDHC_Certification_JSON__c,
            ZDHC_Product_GUID__c,
            ZDHC_Product_Id__c
          FROM Inventory_Line_Items__r
          WHERE
            Inventory__r.Status__c = 'Pending'
            AND (Inventory__r.Inventory_Date__c = LAST_MONTH
            OR Inventory__r.Inventory_Date__c = THIS_MONTH)
        )
      FROM Chemical_Product__c
      WHERE
        ZDHC_Product_GUID__c != NULL
        AND Formulator__r.Created_By__r.Facility_Manager__c != NULL
      LIMIT 75
      OFFSET 75
    ];

    Test.StartTest();
    tcsp.synchronise(scope1);
    tcsp.synchronise(scope2);
    Test.StopTest();
  }

  @isTest
  public static void executeBatch() {
    ZDHCGatewayMockResponseGenerator mock = new ZDHCGatewayMockResponseGenerator();
    Test.setMock(HttpCalloutMock.class, mock);
    
    Test.StartTest();
    TC_SynchroniseProducts tcsp = new TC_SynchroniseProducts(true);
    Id batchId = Database.executeBatch(tcsp);
    Test.StopTest();
  }

  @isTest
  public static void schedule() {
    ZDHCGatewayMockResponseGenerator mock = new ZDHCGatewayMockResponseGenerator();
    Test.setMock(HttpCalloutMock.class, mock);
      
    Test.StartTest();
    String jobId = System.schedule(
      'TC_SynchroniseProducts TEST SCHEDULE',
      TC_SynchroniseProducts.CRON_EXPRESSION,
      new TC_SynchroniseProducts(true)
    );

    CronTrigger before = [
      SELECT Id, CronExpression, TimesTriggered, NextFireTime
      FROM CronTrigger
      WHERE id = :jobId
    ];
	
    System.assertEquals(
      TC_SynchroniseProducts.CRON_EXPRESSION,
      before.CronExpression
    );

    System.assertEquals(0, before.TimesTriggered);

    Test.StopTest();
  }

  @isTest
  static void SynchronisationResult_pull() {
    List<Chemical_Product__c> scope = [
      SELECT
        Id,
        Origin__c,
        ZDHC_Product_GUID__c,
        Chemical_Product_Name__c,
        Product_Trade_Name_Other_Name__c,
        ZDHC_Product_Code__c,
        ZDHC_PID__c,
        Product_Status__c,
        Registered__c,
        ZDHC_Product_Id__c,
        Last_Verified_Date__c,
        ZDHC_Certification_JSON__c,
        Other_Certifications__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_MRSL_Version__c,
        ZDHC_Formulator_GUID__c,
        Formulator__c,
        Formulator__r.Name,
        Formulator__r.Created_By__r.Facility_Manager__c,
        (
          SELECT
            Id,
            Origin__c,
            ZDHC_MRSL_v2_0__c,
            ZDHC_MRSL_Version__c,
            Other_Certifications__c,
            ZDHC_Certification_JSON__c,
            ZDHC_Product_GUID__c,
            ZDHC_Product_Id__c
          FROM Inventory_Line_Items__r
          WHERE
            Inventory__r.Status__c = 'Pending'
            AND (Inventory__r.Inventory_Date__c = LAST_MONTH
            OR Inventory__r.Inventory_Date__c = THIS_MONTH)
        )
      FROM Chemical_Product__c
      WHERE
        ZDHC_Product_GUID__c != NULL
        AND Formulator__r.Created_By__r.Facility_Manager__c != NULL
      LIMIT 5
    ];
    List<Chemical_Product__c> before = scope.deepClone(true, true, true);

    Integer count = 0;
    Map<String, ZDHCGetProductsResponseData> remote = new Map<String, ZDHCGetProductsResponseData>();
    for (Chemical_Product__c p : scope) {
      ZDHCGetProductsResponseData data = new ZDHCGetProductsResponseData();
      data.productName = p.Chemical_Product_Name__c + '1';
      data.OtherName = p.Product_Trade_Name_Other_Name__c + '7';
      data.formulatorName = p.Formulator__r.Name + (count == 3 ? '3' : '');
      data.OrganizationCountry = '4';
      data.formulatorGUID = p.ZDHC_Formulator_GUID__c + (count == 4 ? '5' : '');
      data.productCode = String.isNotBlank(p.ZDHC_Product_Code__c)
        ? p.ZDHC_Product_Code__c.replaceAll('A', 'B')
        : 'B1234567';
      data.zdhcPID = String.isNotBlank(p.ZDHC_PID__c)
        ? p.ZDHC_PID__c.replaceAll('P', 'R')
        : 'P1234567';
      data.zdhcAID = '8';
      data.registered = p.Registered__c + '9';
      data.ProductID = p.ZDHC_Product_Id__c + '10';
      data.ProductCertifications = new List<ZDHCGetProductsResponseCertifications>();
       
      if (count == 1) {
        data.ProductCertifications.addAll(getMockMrslCert());
      }
      if (count == 2) {
        data.ProductCertifications.addAll(getMockOtherCerts());
      }
      if (count == 3) {
        data.ProductCertifications.addAll(getMockMrslCert());
        data.ProductCertifications.addAll(getMockOtherCerts());
      }
      remote.put(p.ZDHC_Product_GUID__c, data);
      count++;
    }

    TC_SynchroniseProducts.SynchronisationResult result = new TC_SynchroniseProducts.SynchronisationResult();

    Test.StartTest();
    result.pull(scope, remote);
    update result.updated;
    update result.deactivated;
    Test.StopTest();

    Map<Id, Chemical_Product__c> m = new Map<Id, Chemical_Product__c>(scope);

    count = 0;
    for (Chemical_Product__c p : before) {
      System.assertEquals(
        p.Chemical_Product_Name__c + '1',
        m.get(p.Id).Chemical_Product_Name__c,
        'check field updated'
      );
      System.assertEquals(
        p.Product_Trade_Name_Other_Name__c + '7',
        m.get(p.Id).Product_Trade_Name_Other_Name__c,
        'check field updated'
      );
      System.assertEquals(
        p.Registered__c + '9',
        m.get(p.Id).Registered__c,
        'check field updated'
      );
      System.assertEquals(
        p.ZDHC_Product_Id__c + '10',
        m.get(p.Id).ZDHC_Product_Id__c,
        'check field updated'
      );
      count++;
    }
  }

  @IsTest
  public static void updateRelatedLineItems_withDifferences() {
    Account facility = [
      SELECT Id
      FROM Account
      WHERE ToxClear_Account_Type__c = 'Facility'
      LIMIT 1
    ];
    List<Chemical_Product__c> products = [
      SELECT
        Id,
        Origin__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_MRSL_Version__c,
        ZDHC_Product_Id__c,
        ZDHC_Product_GUID__c,
        Other_Certifications__c,
        ZDHC_Certification_JSON__c,
        (
          SELECT
            Id,
            Origin__c,
            ZDHC_MRSL_v2_0__c,
            ZDHC_MRSL_Version__c,
            ZDHC_Product_Id__c,
            ZDHC_Product_GUID__c,
            Other_Certifications__c,
            ZDHC_Certification_JSON__c
          FROM Inventory_Line_Items__r
        )
      FROM Chemical_Product__c
    ];
    List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
      facility.Id,
      3,
      Date.today(),
      'Delivery',
      products,
      'KG',
      1,
      1,
      1
    );
    products[0].ZDHC_MRSL_v2_0__c = 'Level 3';
    update products[0];
    products = [
      SELECT
        Id,
        Origin__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_MRSL_Version__c,
        ZDHC_Product_Id__c,
        ZDHC_Product_GUID__c,
        Other_Certifications__c,
        ZDHC_Certification_JSON__c,
        (
          SELECT
            Id,
            Origin__c,
            ZDHC_MRSL_v2_0__c,
            ZDHC_MRSL_Version__c,
            ZDHC_Product_Id__c,
            ZDHC_Product_GUID__c,
            Other_Certifications__c,
            ZDHC_Certification_JSON__c
          FROM Inventory_Line_Items__r
        )
      FROM Chemical_Product__c
    ];
    Test.startTest();
    TC_SynchroniseProducts.SynchronisationResult result = new TC_SynchroniseProducts.SynchronisationResult();
    result.updateRelatedLineItems(products);
    Test.stopTest();
    Inventory_Line_Item__c ili = [
      SELECT
        Origin__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_MRSL_Version__c,
        ZDHC_Product_Id__c,
        ZDHC_Product_GUID__c,
        Other_Certifications__c,
        ZDHC_Certification_JSON__c
      FROM Inventory_Line_Item__c
      WHERE Chemical_Product__c = :products[0].Id
      LIMIT 1
    ];
    System.assertEquals(products[0].ZDHC_MRSL_v2_0__c, ili.ZDHC_MRSL_v2_0__c);
    System.assertEquals(products[0].ZDHC_Product_Id__c, ili.ZDHC_Product_Id__c);
    System.assertEquals(
      products[0].ZDHC_Product_GUID__c,
      ili.ZDHC_Product_GUID__c
    );
    System.assertEquals(
      products[0].Other_Certifications__c,
      ili.Other_Certifications__c
    );
  }

  private static List<ZDHCGetProductsResponseCertifications> getMockMrslCert() {
   	List<ZDHCGetProductsResponseCertifications> mrslCert2and3 = new List<ZDHCGetProductsResponseCertifications>();
    ZDHCGetProductsResponseCertifications mrslCert2 = new ZDHCGetProductsResponseCertifications();
    mrslCert2.certificationId = '86';
    mrslCert2.certification = 'ZDHC MRSL v2.0';
    mrslCert2.certificationResult = 'Level 3';
    mrslCert2and3.add(mrslCert2);
    
    ZDHCGetProductsResponseCertifications mrslCert3 = new ZDHCGetProductsResponseCertifications();
    mrslCert3.certificationId = '186';
    mrslCert3.certification = 'ZDHC MRSL v3.1';
    mrslCert3.certificationResult = 'Level 2';
    mrslCert2and3.add(mrslCert3);
    return mrslCert2and3;
  }

  private static List<ZDHCGetProductsResponseCertifications> getMockOtherCerts() {
    List<ZDHCGetProductsResponseCertifications> otherCerts = new List<ZDHCGetProductsResponseCertifications>();
    ZDHCGetProductsResponseCertifications otherCertOne = new ZDHCGetProductsResponseCertifications();
    otherCertOne.certificationId = '6';
    otherCertOne.certification = 'Control Union Level 3';
    otherCertOne.certificationResult = 'Passed';
    otherCerts.add(otherCertOne);
    ZDHCGetProductsResponseCertifications otherCertTwo = new ZDHCGetProductsResponseCertifications();
    otherCertTwo.certificationId = '6';
    otherCertTwo.certification = 'Control Union Level 4';
    otherCertTwo.certificationResult = 'Failed';
    otherCerts.ADD(otherCertTwo);
    return otherCerts;
  }
}