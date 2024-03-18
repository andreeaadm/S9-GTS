public with sharing class GTS_DocumentNotificationQueueable implements Queueable, Database.AllowsCallouts {
  List<String> notificationList;

  public GTS_DocumentNotificationQueueable(List<String> notificationList) {
    this.notificationList = notificationList;
  }

  public void execute(QueueableContext context) {
    // You can also pass input variables to the flow like this:
    Map<String, Object> inputVariables = new Map<String, Object>();
    inputVariables.put('cInspectionList', this.notificationList);
    Flow.Interview myFlow = new Flow.Interview.GTS_Send_Document_Upload_Emails_and_Notifications(
      inputVariables
    );
    myFlow.start();
  }
}