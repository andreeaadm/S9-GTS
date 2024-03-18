/*******************************************************************************************
 * @Name         iCare_GTSJobUtil
 * @Test Class : iCare_JobTriggerHandlerTest
 * @Author       Michael Thomas
 * @Description  This acts as a utility class to the iCare_JobTriggerHandler handler for GTS records
 *******************************************************************************************/
public with sharing class iCare_GTSJobUtil implements iCare_JobId_Interface {
  private static String GTS_PREFIX = 'GTS-';
  private final String NAME_FOR_PORTAL_URL = 'iCareGTS';

  public static String generateJobNumber(Integer currentNumber) {
    String jobNumber = '';

    String jobCount = String.valueOf(currentNumber);
    Integer numberOfZeros = 9 - jobCount.length();
    for (Integer i = 0; i < numberOfZeros; i++) {
      jobNumber += '0';
    }
    jobNumber += jobCount;
    return jobNumber;
  }

  public static void setJobIds(List<iCare_Job__c> jobRecords) {
    List<iCare_Job_Identifier__c> latestJobId = [
      SELECT iCare_ID_Number__c
      FROM iCare_Job_Identifier__c
      WHERE iCare_ID_Number__c LIKE 'GTS-%'
      ORDER BY iCare_ID_Number__c DESC
      LIMIT 1
    ];

    Integer newJobNumber = 0;

    //Assumption: Jobs will not be deleted and restored causing duplicate issues (as the Job ID field is unique)
    if (latestJobId.size() > 0) {
      //Extract number
      String latestJobNumberString = latestJobId[0]
        .iCare_ID_Number__c.split('-')[1];
      Integer latestJobNumber = Integer.valueOf(latestJobNumberString);
      for (Integer i = 1; i <= jobRecords.size(); i++) {
        jobRecords[i - 1].iCare_Job_ID__c =
          GTS_PREFIX + generateJobNumber(latestJobNumber + i);
        if (i + 1 > jobRecords.size()) {
          newJobNumber = latestJobNumber + i;
        }
      }
      //Update job id record with latest GTS number
      latestJobId[0].iCare_ID_Number__c =
        GTS_PREFIX + generateJobNumber(newJobNumber);
      update latestJobId;
    } else {
      for (Integer i = 1; i <= jobRecords.size(); i++) {
        jobRecords[i - 1].iCare_Job_ID__c = GTS_PREFIX + generateJobNumber(i);
        if (i + 1 > jobRecords.size()) {
          newJobNumber = i;
        }
      }

      //Create new Job Id record with latest GTS number
      iCare_Job_Identifier__c newJobIdentifier = new iCare_Job_Identifier__c();
      newJobIdentifier.iCare_ID_Number__c =
        GTS_PREFIX + generateJobNumber(newJobNumber);
      newJobIdentifier.iCare_Country__c = 'IND';
      newJobIdentifier.iCare_Lab_Country_Code__c = 'MUM';
      insert newJobIdentifier;
    }
  }

  public void setiCarePortalURL(List<iCare_Job__c> jobs) {
    GTS_Portal portal = new GTS_Portal(NAME_FOR_PORTAL_URL);
    String portalURL = portal.getiCarePortalBaseUrl();
    for (iCare_Job__c job : jobs) {
      job.iCare_Portal_URL__c = portalURL;
    }
  }

  public void updatePortalStatusValues(
    List<iCare_Job__c> newJobs,
    Map<Id, iCare_Job__c> oldJobs
  ) {
  }
  public string translateLabelValue(
    String labelToTranslate,
    String languageToTranslateTo
  ) {
    String translatedLabel = System.Label.get(
      '',
      labelToTranslate,
      languageToTranslateTo
    );
    return translatedLabel;
  }
}