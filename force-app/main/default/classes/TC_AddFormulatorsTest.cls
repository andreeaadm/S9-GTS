@isTest
public with sharing class TC_AddFormulatorsTest {
  @TestSetup
  static void createData() {
    insert new Formulator__c(
      Name = 'default_formulator',
      ZDHC_Formulator_GUID__c = 'default_formulator_guid',
      Address_from_ZDHC__c = 'default_formulator_address',
      ZDHC_Supplier_AID__c = 'default_formulator_supplier_aid'
    );
  }

  @isTest
  static void whenCalledThenFormulatorSaved() {
    System.Test.startTest();
    TC_AddFormulators.addFormulator(
      'Test Formulator 1',
      'test-formulator-guid',
      'test-formulator-address',
      'test-formulator-supplier-aid'
    );
    System.Test.stopTest();

    List<Formulator__c> formulators = [SELECT Id FROM Formulator__c];
    System.assertEquals(
      2,
      formulators.size(),
      'There should be only 2 formulators.'
    );
  }

  @isTest
  static void whenCalledWithDuplicateThenFormulatorNotSaved() {
    System.Test.startTest();
    TC_AddFormulators.addFormulator(
      'default_formulator',
      'default_formulator_guid',
      'default_formulator_address',
      'default_formulator_supplier_aid'
    );
    System.Test.stopTest();

    List<Formulator__c> formulators = [SELECT Id FROM Formulator__c];
    System.assertEquals(
      1,
      formulators.size(),
      'There should be only 1 formulator.'
    );
  }
}