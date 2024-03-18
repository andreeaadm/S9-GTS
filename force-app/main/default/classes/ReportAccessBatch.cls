public with sharing class ReportAccessBatch implements Database.Batchable<sObject> {
  private Set<Id> reportIdsToProcess;
  public ReportAccessBatch() {
  }
  public ReportAccessBatch(Set<Id> seeds) {
    reportIdsToProcess = seeds;
  }
  public Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(buildQuery());
  }

  public void execute(Database.BatchableContext BC, List<Asset> scope) {
    ReportAccessUtil.calculateAccess(new Map<Id, Asset>(scope));

    if (reportIdsToProcess == null) {
      List<Asset> updateLastBatchSharingProcess = new List<Asset>();
      Datetime now = Datetime.now();

      for (Asset a : scope) {
        updateLastBatchSharingProcess.add(
          new Asset(Id = a.Id, LastBatchSharingProcess__c = now)
        );
      }
      update updateLastBatchSharingProcess;
    }
  }

  public void finish(Database.BatchableContext BC) {
  }

  public String buildQuery() {
    SchemaUtil.RecordType reportRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Report'
    );
    SchemaUtil.RecordType deliverableRT = SchemaUtil.getRecordType(
      'Asset',
      'MTC_Deliverable'
    );
    // prettier-ignore
    String q =
      'SELECT ' +
      ' Id,' +
      ' AccountId,' +
      ' RecordTypeId,' +
      ' Name,' +
      ' Type__c,' +
      ' (' +
      '   SELECT' +
      '     Id,' +
      '     AccountId,' +
      '     RecordTypeId,' +
      '     Name,' +
      '     Type__c' +
      '   FROM ChildAssets' +
      '   WHERE RecordTypeId = \'' + deliverableRT.recordId + '\' ' +
      ' )' +
      ' FROM Asset' +
      ' WHERE RecordTypeId = \'' + reportRT.recordId + '\'';
    if (reportIdsToProcess != null && !reportIdsToProcess.isEmpty()) {
      q =
        q +
        ' AND Id IN (\'' +
        String.join(new List<Id>(reportIdsToProcess), '\',\'') +
        '\')';
    } else {
      // when not given a list of reportIds (seeds) we rely on the LastBatchSharingProcess__c field
      q += ' AND LastBatchSharingProcess__c = null LIMIT 5000';
    }
    return q;
  }
}