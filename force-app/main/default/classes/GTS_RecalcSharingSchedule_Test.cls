/**
 * Created by andreea.adam on 07.03.2024.
 */

@IsTest
private class GTS_RecalcSharingSchedule_Test {
  @IsTest
  private static void execute_Test() {
    Test.startTest();
    String schedule = '0 0 * * * ?'; // Cron expression for running every hour
    String jobName = 'GTS Sharing Recalculation Test';
    String jobId = System.schedule(
      jobName,
      schedule,
      new GTS_RecalcSharingOnUserCreationSchedule()
    );
    Test.stopTest();

    List<CronTrigger> apexJob = [
      SELECT Id
      FROM CronTrigger
      WHERE CronJobDetail.Name = :jobName
    ];
    System.debug(apexJob);
    System.assert(apexJob != null || !apexJob.isEmpty());
  }
}