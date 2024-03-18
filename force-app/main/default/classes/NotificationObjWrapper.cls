public class NotificationObjWrapper implements Comparable {
  public SObject sObj;

  // Constructor
  public NotificationObjWrapper(SObject sObj) {
    this.sObj = sObj;
  }

  // Compare SObjects based on their Last_Notification_Date__c DateTime field
  public Integer compareTo(Object compareTo) {
    // Cast argument to NotificationObjWrapper
    NotificationObjWrapper compareToSObj = (NotificationObjWrapper) compareTo;

    // The return value of 0 indicates that both elements are equal.
    Integer returnValue = 0;
    if (
      (DateTime) sObj.get('Last_Notification_Date__c') >
      (DateTime) compareToSObj.sObj.get('Last_Notification_Date__c')
    ) {
      // Set return value to a positive value.
      returnValue = 1;
    } else if (
      (DateTime) sObj.get('Last_Notification_Date__c') <
      (DateTime) compareToSObj.sObj.get('Last_Notification_Date__c')
    ) {
      // Set return value to a negative value.
      returnValue = -1;
    } else if (
      (DateTime) (sObj.get('Last_Notification_Date__c')) == null &&
      (DateTime) (compareToSObj.sObj.get('Last_Notification_Date__c')) != null
    ) {
      // nulls-first implementation
      returnValue = -1;
    } else if (
      (DateTime) (sObj.get('Last_Notification_Date__c')) != null &&
      (DateTime) (compareToSObj.sObj.get('Last_Notification_Date__c')) == null
    ) {
      // nulls-first implementation
      returnValue = 1;
    }
    return returnValue;
  }
}