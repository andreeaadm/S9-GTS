/********************************************************************************************
 * @Name         GTSJobLifecycle_Test
 * @Author       Globant
 * @Created      04-Mar-2024
 * @Description  Test class for GTSJobLifecycle.
 *
 *********************************************************************************************/
@isTest
public class GTSJobLifecycle_Test {
  @TestSetup
  static void createData() {
    Id certConfRecordTypeId = Schema.SObjectType.iCare_Job__c.getRecordTypeInfosByDeveloperName()
      .get('GTS_Certificate_of_Conformity')
      .getRecordTypeId();
    // Create a test job
    iCare_Job__c objJob = new iCare_Job__c();
    objJob.GTS_Request_for_Inspection_Number__c = 'TestInspectionNumber';
    objJob.RecordtypeId = CertConfRecordTypeId;
    insert objJob;

    // Create Job Timestamps
    icare_Job_Timestamp__c objJobTS = new icare_Job_Timestamp__c();
    objJobTS.iCare_Job__c = objJob.Id;
    objJobTS.iCare_External_Id__c = '123';
    objJobTS.iCare_Job_Status__c = System.Label.GTS_Cancelled;
    objJobTS.iCare_Job_Timestamp__c = datetime.now();
    insert objJobTS;
  }

  @isTest
  static void jobInspectionNumberTest() {
    List<iCare_Job__c> lstJob = [SELECT Id FROM iCare_Job__c LIMIT 1];

    Test.startTest();
    String strInsNum = GTSJobLifecycle.getJobInspectionNumber(lstJob.get(0).Id);
    Test.stopTest();

    System.assertEquals(
      'TestInspectionNumber',
      strInsNum,
      'The returned request for inspection number should be TestInspectionNumber.'
    );
  }

  @isTest
  static void jobStatusPathTest() {
    List<iCare_Job__c> lstJob = [SELECT Id FROM iCare_Job__c LIMIT 1];

    Test.startTest();
    String strStatusPath = GTSJobLifecycle.getJobStatusPath(lstJob.get(0).Id);

    icare_Job_Timestamp__c objJobTSUpdate = [
      SELECT Id, iCare_Job_Status__c
      FROM icare_Job_Timestamp__c
      LIMIT 1
    ];

    objJobTSUpdate.iCare_Job_Status__c = 'Sample Received';
    update objJobTSUpdate;

    strStatusPath = GTSJobLifecycle.getJobStatusPath(lstJob.get(0).Id);
    Test.stopTest();

    System.assertNotEquals(
      null,
      strStatusPath,
      'The returned status path should not be null.'
    );
  }
}