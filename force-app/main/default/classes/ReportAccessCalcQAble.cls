public with sharing class ReportAccessCalcQAble implements Queueable {
  private Set<Id> reportIdsLeft = new Set<Id>();
  private Set<Id> reportIds = new Set<Id>();

  public ReportAccessCalcQAble(Set<Id> reportIdsToEvaluate) {
    reportIdsLeft = reportIdsToEvaluate.clone();
    Integer count = 0;
    for (Id assetId : reportIdsLeft) {
      count += 1;
      if (count <= 200) {
        reportIds.add(assetId);
      } else {
        break;
      }
    }
    reportIdsLeft.removeAll(reportIds);
  }
  public void execute(QueueableContext context) {
    ReportAccessUtil.calculateAccess(reportIds);
    if (!reportIdsLeft.isEmpty()) {
      System.enqueueJob(new ReportAccessCalcQAble(reportIdsLeft));
    }
  }
}