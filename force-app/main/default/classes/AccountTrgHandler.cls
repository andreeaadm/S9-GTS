public with sharing class AccountTrgHandler extends TriggerHandler {
  public override void beforeInsert() {
    List<Account> newAccounts = (List<Account>) Trigger.new;

    // set the Is_MTC_Account field
    for (Account acc : newAccounts) {
      if (!String.isBlank(acc.TruTesta_ID__c)) {
        acc.Is_MTC_Account__c = true;
      }
    }
  }
  public override void afterInsert() {
    List<Account> newAccounts = (List<Account>) Trigger.new;
    DefaultGroupUtil.createDefaultGroups(Trigger.newMap.keySet());
    TC_TriggeredSharing.processNewOrUpdatedAccounts(newAccounts);
  }
  public override void afterUpdate() {
    List<Account> newAccounts = (List<Account>) Trigger.new;
    Map<Id, Account> oldAccounts = (Map<Id, Account>) Trigger.oldMap;
    // AccountUtil.onSimplifiedSharingChanged(newAccounts, oldAccounts);
    AccountUtil.onAccountDeactivated(newAccounts, oldAccounts);
    TC_TriggeredSharing.processNewOrUpdatedAccounts(newAccounts);
    gtsProcessSharingLogic(
      (List<Account>) Trigger.new,
      (Map<Id, Account>) Trigger.oldMap
    );
  }

  private static void gtsProcessSharingLogic(
    List<Account> accounts,
    Map<Id, Account> oldAccountsMap
  ) {
    RecordType recordType = [
      SELECT Id
      FROM RecordType
      WHERE DeveloperName = 'GTS_Customer'
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];

    List<Account> newAccountInserted = new List<Account>();
    List<Account> newAccountUpdated = new List<Account>();
    List<Account> oldAccounts = new List<Account>();

    for (Account account : accounts) {
      if (account.RecordTypeId == recordType.Id) {
        Account oldAccount = oldAccountsMap.get(account.Id);
        if (oldAccount == null) {
          continue;
        }

        if (account.ParentId != oldAccount.ParentId) {
          if (oldAccount.ParentId == null) {
            newAccountInserted.add(account);
          } else {
            if (account.ParentId != null) {
              newAccountUpdated.add(account);
            }
            oldAccounts.add(oldAccount);
          }
        }
      }
    }
    if (!newAccountInserted.isEmpty()) {
      GTSJobSharingEngineQueueable jobSharingEngineQueueable = new GTSJobSharingEngineQueueable(
        newAccountInserted,
        null,
        GTSJobSharingEngineQueueable.OPERATION_TYPE.EXPORTER_NEW_PARENT
      );
      System.enqueueJob(jobSharingEngineQueueable);
    }
    if (!oldAccounts.isEmpty()) {
      GTSJobSharingEngineQueueable jobSharingEngineQueueable = new GTSJobSharingEngineQueueable(
        newAccountUpdated,
        oldAccounts,
        GTSJobSharingEngineQueueable.OPERATION_TYPE.EXPORTER_UPDATED_PARENT
      );
      System.enqueueJob(jobSharingEngineQueueable);
    }
  }
}