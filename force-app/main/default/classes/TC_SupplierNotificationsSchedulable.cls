public with sharing class TC_SupplierNotificationsSchedulable implements Schedulable {
  public void execute(SchedulableContext sc) {
    Database.executeBatch(new TC_SupplierNotificationsBatchable(), 200);
  }
}