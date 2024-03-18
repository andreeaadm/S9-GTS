/********************************************************************************************
 * @Name         GTSCustomLookupController_Test
 * @Author       Globant
 * @Created      29-Feb-2024
 * @Description  Test class for GTSCustomLookupController.
 *
 *********************************************************************************************/
@isTest
public class GTSCustomLookupController_Test {
  @TestSetup
  static void createData() {
    Account a = TestDataFactory.createAccount();
  }

  @isTest
  static void lookupDataTest() {
    List<Account> lstAcc = [SELECT Id, Name FROM Account LIMIT 1];

    String searchKey = lstAcc.get(0).Name;
    String sObjectApiName = 'Account';
    String fieldsApiNameWithValueMap = '{"Id":' + '"' + lstAcc.get(0).Id + '"}';
    String labelApiName = 'Name';
    String valueApiName = 'Id';
    Test.startTest();
    List<GTSCustomLookupController.ResponseWrapper> lstResponse = GTSCustomLookupController.fetchLookupData(
      searchKey,
      sObjectApiName,
      fieldsApiNameWithValueMap,
      labelApiName,
      valueApiName
    );
    Test.stopTest();
    System.assertEquals(
      1,
      lstResponse.size(),
      'The response wrapper should contain the account record.'
    );
  }

  @isTest
  static void defaultRecordTest() {
    List<Account> lstAcc = [SELECT Id, Name FROM Account LIMIT 1];

    String recordId = lstAcc.get(0).Id;
    String sObjectApiName = 'Account';
    String fieldsApiNameWithValueMap = '{"Id":' + '"' + lstAcc.get(0).Id + '"}';
    String labelApiName = 'Name';
    String valueApiName = 'Id';
    Test.startTest();
    GTSCustomLookupController.ResponseWrapper recordResponse = GTSCustomLookupController.fetchDefaultRecord(
      recordId,
      sObjectApiName,
      fieldsApiNameWithValueMap,
      labelApiName,
      valueApiName
    );
    Test.stopTest();
    System.assertNotEquals(
      null,
      recordResponse,
      'The response wrapper should contain the account record.'
    );
  }
}