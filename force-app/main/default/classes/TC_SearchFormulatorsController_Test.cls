@isTest
public class TC_SearchFormulatorsController_Test {
  @TestSetup
  static void setup() {
    TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
      1,
      1, // inactive
      new List<Integer>{ 3 },
      new List<Integer>{ 1 }, // inactive
      1,
      1 // inactive
    );
    TC_TestDataFactory_Contacts tdfc = new TC_TestDataFactory_Contacts(
      tdfa,
      TC_TestDataFactory.random(12, '0123456789') +
      'intertek.salesforce@oegen.co.uk',
      new List<Integer>{ 1 },
      new List<Integer>{ 1 },
      new List<Integer>{ 1 },
      new List<Integer>{ 1 },
      new List<Integer>{ 1 },
      new List<Integer>{ 1 }
    );
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(tdfc, true);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      tdfu.insertPermissionSetAssignments();
    }
  }

  @isTest
  static void getFormulatorsReturnData() {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'formulators';
    zdhcRequest.method = 'GET';
    zdhcRequest.userAccessKey = 'userAccessKey';

    StaticResourceMockResponseGenerator.setMock(
      'GetFormulatorsResponse',
      200,
      'OK',
      null
    );

    Test.startTest();
    TC_SearchFormulatorsResponse formulatorsResponse = TC_SearchFormulatorsController.getFormulators(
      'userAccessKey',
      'a'
    );
    Test.stopTest();

    System.assertNotEquals(null, formulatorsResponse);
    System.assert(formulatorsResponse.isSuccess);
    System.assertNotEquals(null, formulatorsResponse.formulatorsResponseData);
  }

  // Using a static mock which represents the respone from an
  // ZDHCGatewayUnexpectedResponse, check that the body property
  // in the embedded json is not empty
  @isTest
  static void getFormulatorsReturnUnexpectedResponse() {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'formulators';
    zdhcRequest.method = 'GET';
    zdhcRequest.userAccessKey = 'userAccessKey';

    StaticResourceMockResponseGenerator.setMock(
      'UnexpectedResponse',
      200,
      'OK',
      null
    );

    Test.startTest();
    TC_SearchFormulatorsResponse formulatorsResponse = TC_SearchFormulatorsController.getFormulators(
      'userAccessKey',
      'a'
    );
    Test.stopTest();

    try {
      // errors is an array, so pick up the first one
      // and cast it to a string before deserialising
      String errorJson = (String) formulatorsResponse.errors[0];

      Map<String, Object> errorMap = (Map<String, Object>) JSON.deserializeUntyped(
        errorJson
      );

      System.assert(
        String.isNotBlank((String) errorMap.get('body')),
        'The body text should not be empty.'
      );
    } catch (Exception ex) {
      System.debug(
        'Something went wrong deserialising the json string from the errors.  Handle this more elegantly'
      );
    }

    System.assertNotEquals(null, formulatorsResponse);
    System.assert(!formulatorsResponse.isSuccess);
    System.assertEquals(null, formulatorsResponse.formulatorsResponseData);
  }

  @isTest
  static void getFormulatorId_formulatorGUID_notFound() {
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    ZDHCGatewayMockResponseGenerator mock = new ZDHCGatewayMockResponseGenerator();
    Test.setMock(HttpCalloutMock.class, mock);

    String result0AsFacilityStdUser;

    // getFormulatorId(String, String)

    Boolean didThrowAuraHandledException = false;
    Test.startTest();
    System.runAs(tdfu.facilityStdUsers[0]) {
      try {
        result0AsFacilityStdUser = TC_SearchFormulatorsController.getFormulatorId(
          tdfu.facilityStdUsers[0].ZDHC_User_Access_Key__c,
          '00009700C7000B070053010000007C00'
        );
      } catch (AuraHandledException e) {
        didThrowAuraHandledException = true;
      }
    }
    Test.stopTest();
    System.assertEquals(
      true,
      didThrowAuraHandledException,
      'exception thrown for 0 result'
    );
  }

  @isTest
  static void getFormulatorId_formulatorGUID_create() {
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    ZDHCGatewayMockResponseGenerator mock = new ZDHCGatewayMockResponseGenerator();
    Test.setMock(HttpCalloutMock.class, mock);

    String resultAsFacilityStdUser;

    // getFormulatorId(String, String)

    Test.startTest();
    List<Formulator__c> before = [
      SELECT Id
      FROM Formulator__c
      WHERE ZDHC_Formulator_GUID__c = '896197B6C7CD0B67E0530100007F7CF4'
    ];
    System.runAs(tdfu.facilityStdUsers[0]) {
      resultAsFacilityStdUser = TC_SearchFormulatorsController.getFormulatorId(
        tdfu.facilityStdUsers[0].ZDHC_User_Access_Key__c,
        '896197B6C7CD0B67E0530100007F7CF4'
      );
    }
    List<Formulator__c> after = [
      SELECT Id
      FROM Formulator__c
      WHERE ZDHC_Formulator_GUID__c = '896197B6C7CD0B67E0530100007F7CF4'
    ];
    Test.stopTest();

    System.assertEquals(0, before.size(), 'Ensure no existing formulator');
    System.assertNotEquals(null, resultAsFacilityStdUser, 'Check null result');
    System.assertEquals(1, after.size(), 'Check Formulator was created');
    System.assertEquals(
      resultAsFacilityStdUser,
      after[0].Id,
      'request returns same SObject Id'
    );
  }

  @isTest
  static void getFormulatorId_formulatorGUID_update() {
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();

    ZDHCGatewayMockResponseGenerator mock = new ZDHCGatewayMockResponseGenerator();
    Test.setMock(HttpCalloutMock.class, mock);

    // getFormulatorId(String, String)

    insert new Formulator__c(
      ZDHC_Formulator_GUID__c = '896197B6C7CD0B67E0530100007F7CF4',
      Name = 'Test',
      Address_from_ZDHC__c = 'Test',
      ZDHC_Supplier_AID__c = 'Test'
    );

    Test.startTest();
    List<Formulator__c> before = [
      SELECT Id, Name, Address_from_ZDHC__c, ZDHC_Supplier_AID__c
      FROM Formulator__c
      WHERE ZDHC_Formulator_GUID__c = '896197B6C7CD0B67E0530100007F7CF4'
    ];
    String result = TC_SearchFormulatorsController.getFormulatorId(
      tdfu.facilityStdUsers[0].ZDHC_User_Access_Key__c,
      '896197B6C7CD0B67E0530100007F7CF4'
    );
    List<Formulator__c> after = [
      SELECT Id, Name, Address_from_ZDHC__c, ZDHC_Supplier_AID__c
      FROM Formulator__c
      WHERE ZDHC_Formulator_GUID__c = '896197B6C7CD0B67E0530100007F7CF4'
    ];
    Test.stopTest();
    System.assertEquals(1, before.size(), 'Ensure existing formulator');
    System.assertNotEquals(null, result, 'Check null result');
    System.assertEquals(1, after.size(), 'Check Formulator was not deleted');
    System.assertEquals(result, after[0].Id, 'request returns same SObject Id');
    System.assertEquals('Test', before[0].Name);
    System.assertEquals('Test', before[0].Address_from_ZDHC__c);
    System.assertEquals('Test', before[0].ZDHC_Supplier_AID__c);
    System.assertEquals('Alcover Quimica SL', after[0].Name);
    System.assertEquals(
      'Ctra. de Alcover a Montblanc, km 2,4\r\n43460 Alcover (Tarragona)',
      after[0].Address_from_ZDHC__c
    );
    System.assertEquals('A927FN15', after[0].ZDHC_Supplier_AID__c);
  }

  @isTest
  static void createZDHCFormulator_formulatorId() {
    List<Formulator__c> formulator;
    TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts();
    TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();
    System.runAs(tdfu.facilityStdUsers[0]) {
      formulator = new List<Formulator__c>{
        new Formulator__c(
          Name = 'Washy Foams',
          Address__c = 'Street',
          City_Town__c = 'City',
          Contact_Email__c = 'washy@example.com',
          Contact_Name__c = 'Mr Washy',
          Country__c = 'United States of America',
          Created_By__c = tdfa.facilities[0].Id,
          Origin__c = 'Supplier',
          Phone__c = '0987654321',
          State_Province__c = 'Province',
          Zip_Postal_Code__c = 'Zpi123'
        )
      };
      insert formulator;
    }
    ZDHCGatewayMockResponseGenerator mock = new ZDHCGatewayMockResponseGenerator();
    Test.setMock(HttpCalloutMock.class, mock);

    Formulator__c result1AsFacilityStdUser;

    // createZDHCFormulator(String)

    Test.startTest();
    System.runAs(tdfu.facilityStdUsers[0]) {
      result1AsFacilityStdUser = TC_SearchFormulatorsController.createZDHCFormulator(
        tdfu.facilityStdUsers[0].ZDHC_User_Access_Key__c,
        formulator[0].Id
      );
    }
    Test.stopTest();

    System.assertNotEquals(
      null,
      result1AsFacilityStdUser.ZDHC_Formulator_GUID__c,
      'Test formulator has GUID'
    );
    System.assertEquals(
      32,
      result1AsFacilityStdUser.ZDHC_Formulator_GUID__c.length(),
      'Test formulator has GUID'
    );
  }
}