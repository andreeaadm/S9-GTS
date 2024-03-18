/*******************************************************************************************
 * @Name         iCare_JobId_Interface
 * @Test Class : iCare_JobTriggerHandlerTest
 * @Author       Michael Thomas
 * @Description  An interface to define common methods for GTS & iCare job classes
 *******************************************************************************************/
public interface iCare_JobId_Interface {
  void setJobIds(List<iCare_Job__c> jobRecords);
  String generateJobNumber(Integer totalJobCount);
  void updatePortalStatusValues(
    List<iCare_Job__c> newJobs,
    Map<Id, iCare_Job__c> oldJobs
  );
  void setiCarePortalURL(List<iCare_Job__c> jobs);
}