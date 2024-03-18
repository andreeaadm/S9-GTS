public with sharing class GTS_Job_Invocable {
  @InvocableMethod(
    label='Method to Call Queueable Class to send jobrquests through-out api'
  )
  public static void processJobRequest(
    List<iCare_Job_Request__c> jobRecProcessList
  ) {
    System.debug('Trigger****' + jobRecProcessList);
    GTS_QueueJob queue = new GTS_QueueJob();
    System.debug('GTS_QueueJob****' + queue);
    queue.enqueueJobRequest(jobRecProcessList);
  }
}