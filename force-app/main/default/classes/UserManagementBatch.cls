public with sharing class UserManagementBatch implements Database.Batchable<sObject> {
  private Set<Id> contactIdsToProcess;
  public UserManagementBatch() {
  }
  public UserManagementBatch(Set<Id> seeds) {
    contactIdsToProcess = seeds;
  }
  public Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(buildQuery());
  }

  public void execute(
    Database.BatchableContext BC,
    List<AccountContactRelation> scope
  ) {
    MTCUserUtil.updatedRelationship(
      scope,
      new Map<Id, AccountContactRelation>()
    );
  }

  public void finish(Database.BatchableContext BC) {
  }

  public String buildQuery() {
    String q =
      'SELECT Id, ContactId, MTC_Role__c' +
      ' FROM AccountContactRelation' +
      ' WHERE Contact.Is_User_Required__c = TRUE';
    if (contactIdsToProcess != null && !contactIdsToProcess.isEmpty()) {
      q =
        q +
        ' AND ContactId IN (\'' +
        String.join(new List<Id>(contactIdsToProcess), '\',\'') +
        '\')';
    }
    return q;
  }
}