@isTest
public with sharing class NotificationObjWrapperTest {
  @isTest
  static void comparisons() {
    Case c1 = new Case(Last_Notification_Date__c = Datetime.now());
    Case c2 = new Case(Last_Notification_Date__c = Datetime.now().addDays(1));
    NotificationObjWrapper c1w = new NotificationObjWrapper(c1);
    NotificationObjWrapper c2w = new NotificationObjWrapper(c2);

    List<NotificationObjWrapper> mergedRecordList = new List<NotificationObjWrapper>{
      c1w,
      c2w
    };
    mergedRecordList.sort();

    System.assertEquals(c1w, mergedRecordList[0]);
    System.assertEquals(c2w, mergedRecordList[1]);

    c1.Last_Notification_Date__c = Datetime.now();
    c2.Last_Notification_Date__c = null;
    mergedRecordList.sort();
    // null first expected
    System.assertEquals(c2w, mergedRecordList[0]);
    System.assertEquals(c1w, mergedRecordList[1]);

    c1.Last_Notification_Date__c = null;
    c2.Last_Notification_Date__c = Datetime.now();

    mergedRecordList.sort();
    // null first expected
    System.assertEquals(c1w, mergedRecordList[0]);
    System.assertEquals(c2w, mergedRecordList[1]);

    c1.Last_Notification_Date__c = Datetime.now().addDays(1);
    c2.Last_Notification_Date__c = Datetime.now();

    mergedRecordList.sort();
    // null first expected
    System.assertEquals(c2w, mergedRecordList[0]);
    System.assertEquals(c1w, mergedRecordList[1]);
  }
}