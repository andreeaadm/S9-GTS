/*******************************************************************************************
 * @Name         iCare_JobTestReport
 * @Test Class :  iCare_JobTestReportTest
 * @Author       Praveen Kumar R
 * @Description  This acts as the class to fetch the job test report.
 *******************************************************************************************/
public with sharing class iCare_JobTestReport {
  @AuraEnabled
  public static String getJobTestReport(String jobId) {
    try {
      JobTestWrapper wrapper = new JobTestWrapper();
      Map<String, String> headersMap = new Map<String, String>();

      // get the integration details from the metadata
      iCare_Integration_Details__mdt fetchReport = iCare_Integration_Details__mdt.getInstance(
        'Fetch_Test_Report_Nasuni'
      );
      String endpoint_service_url = Test.isRunningTest()
        ? iCare_CallOutUtilityClass.ENDPOINT_SERVICE_URL_FETCH_REPORT
        : fetchReport.Endpoint_Service_Url__c;
      String method = Test.isRunningTest()
        ? iCare_CallOutUtilityClass.GET_METHOD
        : fetchReport.Http_Method__c;
      String client_Id = Test.isRunningTest()
        ? iCare_CallOutUtilityClass.CLIENT_ID
        : fetchReport.Client_Id__c;
      String client_Secret = Test.isRunningTest()
        ? iCare_CallOutUtilityClass.CLIENT_SECRET
        : fetchReport.Client_Secret__c;
      String namedCredentials = Test.isRunningTest()
        ? iCare_CallOutUtilityClass.NAMED_CREDENTIALS
        : fetchReport.Named_Credentials__c;

      headersMap.put('client_id', client_Id);
      headersMap.put('client_secret', client_Secret);

      if (!Test.isRunningTest() && !fetchReport.Is_Active__c) {
        return Label.iCare_JobTestReport_Error_Msg;
      }

      iCare_Job__c jobRec = [
        SELECT Id, iCare_Document_URL__c
        FROM iCare_Job__c
        WHERE Id = :jobId
      ];
      String str = EncodingUtil.urlEncode(
        jobRec.iCare_Document_URL__c,
        'UTF-8'
      );

      // form the query params
      String serviceURL =
        endpoint_service_url +
        '?folderPath=' +
        str +
        '&downloadLimit=' +
        Label.iCare_JobTestReport_downloadLimit +
        '&minutes=' +
        Label.iCare_JobTestReport_minutes;

      // callout
      String response = iCare_CallOutUtilityClass.basicAuthCallout(
        serviceURL,
        null,
        method,
        headersMap,
        namedCredentials
      );
      Integer intStatusCode = Integer.valueOf(
        response.substringBefore(':responseBody:')
      );

      // insert audit log
      insert new iCare_Integration_Audit_Log__c(
        iCare_Request_Payload__c = serviceURL,
        iCare_Response_Payload__c = response.substringAfter(':responseBody:'),
        iCare_Integration_Reference__c = Label.iCare_JobTestReport_Integ_Ref,
        iCare_Job__c = jobRec.Id,
        iCare_Sync_Status__c = intStatusCode == 200 ? 'Success' : 'Failure'
      );
      if (intStatusCode == 200) {
        // return the filepath url
        wrapper = (JobTestWrapper) JSON.deserialize(
          response.substringAfter(':responseBody:'),
          JobTestWrapper.class
        );
        return wrapper.filePath;
      } else {
        iCare_CustomExceptionData data = new iCare_CustomExceptionData(
          Label.iCare_JobTestReport_Error_Msg2,
          Label.iCare_JobTestReport_Error_Msg,
          0
        );
        throw new AuraHandledException(JSON.serialize(data));
        //return Label.iCare_JobTestReport_Error_Msg;
      }
    } catch (Exception ex) {
      System.debug(ex.getMessage());
      iCare_CustomExceptionData data = new iCare_CustomExceptionData(
        Label.iCare_JobTestReport_Error_Msg2,
        Label.iCare_JobTestReport_Error_Msg,
        0
      );
      throw new AuraHandledException(JSON.serialize(data));
      //return ex.getMessage();
    }
  }

  public class JobTestWrapper {
    public String filePath;
  }
}