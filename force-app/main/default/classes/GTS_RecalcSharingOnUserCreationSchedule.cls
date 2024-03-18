/*******************************************************************************************
 * @author       Globant
 * @description  Schedulable class to execute GTS_RecalcSharingOnUserCreationBatch batch
 * @date         8-March-2024
 *******************************************************************************************/
public with sharing class GTS_RecalcSharingOnUserCreationSchedule implements Schedulable {
  /**
   * @description Schedulable execute method
   * @param sc
   */
  public void execute(SchedulableContext sc) {
    // Instantiate and execute your batch job
    GTS_RecalcSharingOnUserCreationBatch batchJob = new GTS_RecalcSharingOnUserCreationBatch();
    Database.executeBatch(batchJob);
  }
}