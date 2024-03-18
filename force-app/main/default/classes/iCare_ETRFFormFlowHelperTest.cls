/**
 *  @author  Globant
 *  @since   October 2023
 *  @description ETRF Form Flow Helper class to support any generic flow actions (e.g. flow custom error mesage handling)
 **/

@isTest
public with sharing class iCare_ETRFFormFlowHelperTest {
  /*
   * @description Test method to verify the outputs (error messages produced) of a basic job request record
   */
  @isTest
  private static void validActionCheckRequiredFields() {
    icare_Job_Request__c jobRequestRecord = new icare_Job_Request__c();
    jobRequestRecord.iCare_Colourfastness__c = 'Dry Cleaning';
    jobRequestRecord.iCare_Form_Version__c = 'IN';
    jobRequestRecord.iCare_Appearance__c = 'After Washing';
    jobRequestRecord.iCare_Applicant_Contact_Person_Name__c = 'An';
    jobRequestRecord.iCare_Applicant_Telephone_External__c = '1';
    jobRequestRecord.iCare_Agency_Telephone_External__c = '1';
    jobRequestRecord.iCare_Invoiced_Co_Contact_Person_Name__c = 'An';
    jobRequestRecord.iCare_Agency_Contact_Person_Name__c = 'An';
    jobRequestRecord.iCare_Invoiced_Co_Telephone_External__c = '55';
    insert jobRequestRecord;

    List<iCare_ETRFFormFlowHelper.ETRFFormFlowHelperResponse> responses = new List<iCare_ETRFFormFlowHelper.ETRFFormFlowHelperResponse>();
    List<iCare_ETRFFormFlowHelper.ETRFFormFlowHelperRequest> requests = new List<iCare_ETRFFormFlowHelper.ETRFFormFlowHelperRequest>();
    iCare_ETRFFormFlowHelper.ETRFFormFlowHelperRequest request = new iCare_ETRFFormFlowHelper.ETRFFormFlowHelperRequest();
    request.action = 'check-required-fields-are-populated';
    request.jobRequest = jobRequestRecord;
    request.userRegion = jobRequestRecord.iCare_Form_Version__c;
    requests.add(request);

    Test.startTest();
    responses = iCare_ETRFFormFlowHelper.process(requests);
    Test.stopTest();

    System.assertEquals(
      null,
      responses[0].errorMessage,
      'An apex error message should not have been returned'
    );
    System.assertNotEquals(
      null,
      responses[0].serviceTermErrorMessage,
      'An unpopulated field in the India service term field set should have returned an error'
    );
    System.assertNotEquals(
      null,
      responses[0].applicantInformationErrorMessage,
      'An unpopulated field in the India applicant information field set should have returned an error'
    );
    System.assertNotEquals(
      null,
      responses[0].invoicingInformationErrorMessage,
      'An unpopulated field in the India invoicing information field set should have returned an error'
    );
    System.assertNotEquals(
      null,
      responses[0].sampleAndReportInformationErrorMessage,
      'An unpopulated field in the India sample and report information field set should have returned an error'
    );
  }

  /*
   * @description Test method to verify an apex error message is returned when an unrecognised action is passed to the flow helper
   */
  @isTest
  private static void invalidAction() {
    List<iCare_ETRFFormFlowHelper.ETRFFormFlowHelperResponse> responses = new List<iCare_ETRFFormFlowHelper.ETRFFormFlowHelperResponse>();
    List<iCare_ETRFFormFlowHelper.ETRFFormFlowHelperRequest> requests = new List<iCare_ETRFFormFlowHelper.ETRFFormFlowHelperRequest>();
    iCare_ETRFFormFlowHelper.ETRFFormFlowHelperRequest request = new iCare_ETRFFormFlowHelper.ETRFFormFlowHelperRequest();
    request.action = 'invalid-action';
    request.jobRequest = new icare_Job_Request__c();
    request.userRegion = 'India';
    requests.add(request);

    Test.startTest();
    responses = iCare_ETRFFormFlowHelper.process(requests);
    Test.stopTest();

    System.assertNotEquals(
      null,
      responses[0].errorMessage,
      'An apex error message should have been thrown'
    );
  }
}