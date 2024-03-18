@isTest
public class TC_MergeZdhcAndMasterChemicalsTest {
  @TestSetup
  static void setup() {
    TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
      4, // active suppliers
      1, // inactive suppliers
      new List<Integer>{ 3, 1, 1, 0, 0 }, // active facilities for each supplier
      new List<Integer>{ 1, 1, 0, 0, 0 }, // inactive facilities for each supplier
      2,
      1 // inactive
    );
    TC_TestDataFactory_Contacts tdfc = new TC_TestDataFactory_Contacts(
      tdfa,
      'unittest@example.com',
      new List<Integer>{ 1 }, // supplier admin users for each supplier
      new List<Integer>{ 0 }, // supplier standard users for each supplier
      new List<Integer>{ 0 }, // supplier admin users for each facility
      new List<Integer>{ 1 }, // supplier standard users for each facility
      new List<Integer>{ 1 }, // brand admin users for each brand
      new List<Integer>{ 1 } // brand standard users for each brand
    );
    TC_TestDataFactory_Formulators tdff = new TC_TestDataFactory_Formulators(
      tdfa.facilities
    );
    TC_TestDataFactory_Chemicals chemical = new TC_TestDataFactory_Chemicals(
      tdff,
      null
    );
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(tdfc, true);
    tdfu.insertPermissionSetAssignments();
  }

  @isTest
  static void mergeProductData_and_getProductCategory() {
    TC_MergeZdhcAndMasterChemicals mergeData = new TC_MergeZdhcAndMasterChemicals();

    List<TC_CombinedChemicalProduct> result;
    // mergeProductData(List<ZDHCGetProductsResponseData>, Boolean)
    List<ZDHCGetProductsResponseData> zdhcProducts = getData();
    Boolean setProductCategory = true;

    Test.startTest();
    result = mergeData.mergeProductData(zdhcProducts, setProductCategory);
    for (TC_CombinedChemicalProduct product : result) {
      mergeData.getProductCategory(product);
    }
    Test.stopTest();

    System.assertNotEquals(null, result, 'Check there is a result');
    System.assertNotEquals(0, result.size(), 'Check there are items');
    System.assertEquals(11, result.size(), 'Check list size matches test data');
  }

  @isTest
  static void buildProductsMap_zdhcProducts() {
    TC_MergeZdhcAndMasterChemicals mergeData = new TC_MergeZdhcAndMasterChemicals();

    Map<String, ZDHCGetProductsResponseData> result;
    // buildProductsMap(List<ZDHCGetProductsResponseData>)
    List<ZDHCGetProductsResponseData> zdhcProducts = getData();

    Test.startTest();
    result = mergeData.buildProductsMap(zdhcProducts);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Check there is a result');
    System.assertNotEquals(0, result.size(), 'Check there are items');
    System.assertEquals(11, result.size(), 'Check list size matches test data');
  }

  @isTest
  static void getChemicalProductsMap_productGuids() {
    TC_MergeZdhcAndMasterChemicals mergeData = new TC_MergeZdhcAndMasterChemicals();

    Map<String, Chemical_Product__c> result;
    // getChemicalProductsMap(Set<String>)
    Set<String> productGuids = getProductGuids();

    Test.startTest();
    result = mergeData.getChemicalProductsMap(productGuids);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Check there is a result');
  }

  @isTest
  static void getChemicalProducts_productGuids() {
    TC_MergeZdhcAndMasterChemicals mergeData = new TC_MergeZdhcAndMasterChemicals();

    List<Chemical_Product__c> result;
    // getChemicalProducts(Set<String>)
    Set<String> productGuids = getProductGuids();

    Test.startTest();
    result = mergeData.getChemicalProducts(productGuids);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Check there is a result');
  }

  private static Set<String> getProductGuids() {
    return new Set<String>{
      'D77D2CB25ABE5BABE0530100007F44A5',
      '930697241BD24032E0530100007F7E1A',
      '517D678FBE2256F5E0530100007F7511',
      '8C0A267891C474F8E0530100007FF04F',
      '901DE67BE2E91820E0530100007F194F',
      'B8EC9F31520C1F35E0530100007FE899',
      'B8C84B4343673709E0530100007F6BC5',
      'B8C89432B58F5091E0530100007F3A28',
      'B8C8CE44C936658EE0530100007F5172',
      'B8C97533C60D1BA5E0530100007F4534',
      'A10CCFD137A31C43E0530100007FDC9A'
    };
  }

  private static List<ZDHCGetProductsResponseData> getData() {
    List<ZDHCGetProductsResponseData> data = new List<ZDHCGetProductsResponseData>();
    data.add(new ZDHCGetProductsResponseData());
    data[0].productName = 'A test product 567123';
    data[0].OtherName = 'EFR 3456';
    data[0].productGUID = 'D77D2CB25ABE5BABE0530100007F44A5';
    data[0].formulatorName = 'A new new form Updated';
    data[0].OrganizationCountry = 'Bulgaria';
    data[0].formulatorGUID = 'D77D2CB25ABB5BABE0530100007F44A5';
    data[0].zdhcPID = 'P650EK25';
    data[0].zdhcAID = 'Another name';
    data[0].registered = 'Intertek';
    data[0].ProductID = '190290';
    data.add(new ZDHCGetProductsResponseData());
    data[1].productName = 'ACETIC ACID';
    data[1].productGUID = '930697241BD24032E0530100007F7E1A';
    data[1].formulatorName = 'Zhangjiagang Hongda Additive Chemicals Co., Ltd.';
    data[1].OrganizationCountry = 'China';
    data[1].formulatorGUID = '9281631729E67F0CE0530100007FFD4B';
    data[1].registered = 'CleanChain';
    data[1].ProductID = '120250';
    data.add(new ZDHCGetProductsResponseData());
    data[2].productName = 'ACETONE';
    data[2].productGUID = '517D678FBE2256F5E0530100007F7511';
    data[2].formulatorName = 'Son Hong Ngan Chemical Co., Ltd. Updated';
    data[2].OrganizationCountry = 'South Korea';
    data[2].formulatorGUID = '4CDE5F6F15E1416FE0530100007F256A';
    data[2].registered = 'CleanChain';
    data[2].ProductID = '38432';
    data.add(new ZDHCGetProductsResponseData());
    data[3].productName = 'ACRO conc';
    data[3].productGUID = '8C0A267891C474F8E0530100007FF04F';
    data[3].formulatorName = 'Arjyot Chemicals Private Limited';
    data[3].OrganizationCountry = 'India';
    data[3].formulatorGUID = '6F731E04E38F6BFBE0530100007F90C8';
    data[3].registered = 'CleanChain';
    data[3].ProductID = '98927';
    data.add(new ZDHCGetProductsResponseData());
    data[4].productName = 'ACTIVE ARMY BLUE FW-B H/C';
    data[4].productGUID = '901DE67BE2E91820E0530100007F194F';
    data[4]
      .formulatorName = 'Foshan Jinshengda Chemical Dyestuff Co., Ltd. Updated Updated';
    data[4].OrganizationCountry = 'China';
    data[4].formulatorGUID = '9010B9336CB85B14E0530100007FA3D9';
    data[4].registered = 'CleanChain';
    data[4].ProductID = '108548';
    data.add(new ZDHCGetProductsResponseData());
    data[5].productName = 'ALCOBOND 8585';
    data[5].OtherName = '10124806';
    data[5].productGUID = 'B8EC9F31520C1F35E0530100007FE899';
    data[5].formulatorName = 'Alcover Quimica SL';
    data[5].OrganizationCountry = 'Spain';
    data[5].formulatorGUID = '896197B6C7CD0B67E0530100007F7CF4';
    data[5].productCode = 'A927FN15';
    data[5].zdhcPID = 'P359DS61';
    data[5].registered = 'ZDHC Gateway';
    data[5].ProductID = '186407';
    data[5]
      .ProductCertifications = new List<ZDHCGetProductsResponseCertifications>();
    data[5]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[5].ProductCertifications[0].certificationId = '2';
    data[5].ProductCertifications[0].certification = 'BLC Chem Map - Level 3';
    data[5].ProductCertifications[0].certificationResult = 'Passed';
    data[5]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[5].ProductCertifications[1].certificationId = '86';
    data[5].ProductCertifications[1].certification = 'ZDHC MRSL v2.0';
    data[5].ProductCertifications[1].certificationResult = 'Level 3';
    data.add(new ZDHCGetProductsResponseData());
    data[6].productName = 'ALCOFAT CD';
    data[6].OtherName = '10056503';
    data[6].productGUID = 'B8C84B4343673709E0530100007F6BC5';
    data[6].formulatorName = 'Alcover Quimica SL Updated';
    data[6].OrganizationCountry = 'Spain';
    data[6].formulatorGUID = '896197B6C7CD0B67E0530100007F7CF4';
    data[6].productCode = 'A927FN15';
    data[6].zdhcPID = 'P571LI41';
    data[6].registered = 'ZDHC Gateway';
    data[6].ProductID = '186276';
    data[6]
      .ProductCertifications = new List<ZDHCGetProductsResponseCertifications>();
    data[6]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[6].ProductCertifications[0].certificationId = '2';
    data[6].ProductCertifications[0].certification = 'BLC Chem Map - Level 3';
    data[6].ProductCertifications[0].certificationResult = 'Passed';
    data[6]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[6].ProductCertifications[1].certificationId = '86';
    data[6].ProductCertifications[1].certification = 'ZDHC MRSL v2.0';
    data[6].ProductCertifications[1].certificationResult = 'Level 3';
    data.add(new ZDHCGetProductsResponseData());
    data[7].productName = 'ALCOFAT LW';
    data[7].OtherName = '10189301';
    data[7].productGUID = 'B8C89432B58F5091E0530100007F3A28';
    data[7].formulatorName = 'Alcover Quimica SL';
    data[7].OrganizationCountry = 'Spain';
    data[7].formulatorGUID = '896197B6C7CD0B67E0530100007F7CF4';
    data[7].productCode = 'A927FN15';
    data[7].zdhcPID = 'P258XL54';
    data[7].registered = 'ZDHC Gateway';
    data[7].ProductID = '186278';
    data[7]
      .ProductCertifications = new List<ZDHCGetProductsResponseCertifications>();
    data[7]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[7].ProductCertifications[0].certificationId = '2';
    data[7].ProductCertifications[0].certification = 'BLC Chem Map - Level 3';
    data[7].ProductCertifications[0].certificationResult = 'Passed';
    data[7]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[7].ProductCertifications[1].certificationId = '86';
    data[7].ProductCertifications[1].certification = 'ZDHC MRSL v2.0';
    data[7].ProductCertifications[1].certificationResult = 'Level 3';
    data.add(new ZDHCGetProductsResponseData());
    data[8].productName = 'ALCOFAT SF 3';
    data[8].OtherName = '38510006';
    data[8].productGUID = 'B8C8CE44C936658EE0530100007F5172';
    data[8].formulatorName = 'Alcover Quimica SL Updated';
    data[8].OrganizationCountry = 'Spain';
    data[8].formulatorGUID = '896197B6C7CD0B67E0530100007F7CF4';
    data[8].productCode = 'A927FN15';
    data[8].zdhcPID = 'P496SN43';
    data[8].registered = 'ZDHC Gateway';
    data[8].ProductID = '186279';
    data[8]
      .ProductCertifications = new List<ZDHCGetProductsResponseCertifications>();
    data[8]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[8].ProductCertifications[0].certificationId = '2';
    data[8].ProductCertifications[0].certification = 'BLC Chem Map - Level 3';
    data[8].ProductCertifications[0].certificationResult = 'Passed';
    data[8]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[8].ProductCertifications[1].certificationId = '86';
    data[8].ProductCertifications[1].certification = 'ZDHC MRSL v2.0';
    data[8].ProductCertifications[1].certificationResult = 'Level 3';
    data.add(new ZDHCGetProductsResponseData());
    data[9].productName = 'ALCOLIP LAF';
    data[9].OtherName = '54860005';
    data[9].productGUID = 'B8C97533C60D1BA5E0530100007F4534';
    data[9].formulatorName = 'Alcover Quimica SL';
    data[9].OrganizationCountry = 'Spain';
    data[9].formulatorGUID = '896197B6C7CD0B67E0530100007F7CF4';
    data[9].productCode = 'A927FN15';
    data[9].zdhcPID = 'P522IH34';
    data[9].registered = 'ZDHC Gateway';
    data[9].ProductID = '186283';
    data[9]
      .ProductCertifications = new List<ZDHCGetProductsResponseCertifications>();
    data[9]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[9].ProductCertifications[0].certificationId = '2';
    data[9].ProductCertifications[0].certification = 'BLC Chem Map - Level 3';
    data[9].ProductCertifications[0].certificationResult = 'Passed';
    data[9]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[9].ProductCertifications[1].certificationId = '86';
    data[9].ProductCertifications[1].certification = 'ZDHC MRSL v2.0';
    data[9].ProductCertifications[1].certificationResult = 'Level 3';
    data.add(new ZDHCGetProductsResponseData());
    data[10].productName = 'ALCOPLEX RV';
    data[10].OtherName = '54880006';
    data[10].productGUID = 'A10CCFD137A31C43E0530100007FDC9A';
    data[10].formulatorName = 'Alcover Quimica SL Updated';
    data[10].OrganizationCountry = 'Spain';
    data[10].formulatorGUID = '896197B6C7CD0B67E0530100007F7CF4';
    data[10].productCode = 'A927FN15';
    data[10].zdhcPID = 'P432OX37';
    data[10].registered = 'ZDHC Gateway';
    data[10].ProductID = '150844';
    data[10]
      .ProductCertifications = new List<ZDHCGetProductsResponseCertifications>();
    data[10]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[10].ProductCertifications[0].certificationId = '2';
    data[10].ProductCertifications[0].certification = 'BLC Chem Map - Level 3';
    data[10].ProductCertifications[0].certificationResult = 'Passed';
    data[10]
      .ProductCertifications.add(new ZDHCGetProductsResponseCertifications());
    data[10].ProductCertifications[1].certificationId = '86';
    data[10].ProductCertifications[1].certification = 'ZDHC MRSL v2.0';
    data[10].ProductCertifications[1].certificationResult = 'Level 3';
    return data;
  }
}