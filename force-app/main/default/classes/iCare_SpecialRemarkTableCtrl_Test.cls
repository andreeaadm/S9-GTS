/**
 * @author Jadd Ennaciri <jadd.ennaciri@globant.com>
 * @date 2023-10-20
 * @group Globant
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 20/10/2023    Jadd Ennaciri      Created Class
 *
 */

@IsTest
private without sharing class iCare_SpecialRemarkTableCtrl_Test {
  @TestSetup
  private static void setup() {
    iCare_Job__c job = new iCare_Job__c(
      iCare_Job_ID__c = 'TUR-IST-2405000',
      iCare_Job_Description__c = 'Test Job Description'
    );
    insert job;

    List<icare_Special_Remark__c> specialRemarks = new List<icare_Special_Remark__c>();

    for (Integer i = 0; i < 10; i++) {
      specialRemarks.add(
        new icare_Special_Remark__c(
          iCare_Special_Remarks_Timestamp__c = Datetime.now(),
          iCare_Special_Remarks__c = 'Test Remark ' + i,
          iCare_Job__c = job.Id,
          iCare_Is_Customer_Visible__c = true,
          iCare_External_Id__c = '' + i
        )
      );
    }
    insert specialRemarks;
  }

  @IsTest
  private static void testGetSpecialRemarkSuccess() {
    List<iCare_Job__c> jobs = [SELECT Id FROM iCare_Job__c];
    Test.startTest();
    String data = iCare_SpecialRemarkTableController.getSpecialRemarks(
      jobs[0].Id
    );
    Test.stopTest();

    List<icare_Special_Remark__c> specialRemarks = (List<icare_Special_Remark__c>) JSON.deserialize(
      data,
      List<icare_Special_Remark__c>.class
    );
    System.assertEquals(
      10,
      specialRemarks.size(),
      'Failed to retrieve Special Remarks.'
    );
  }

  @IsTest
  private static void testGetSpecialRemarkError() {
    String jobId = null;
    Test.startTest();
    String error = iCare_SpecialRemarkTableController.getSpecialRemarks(jobId);
    Test.stopTest();
    System.debug(error);
    System.assertEquals('test error', error, 'test error');
  }
}