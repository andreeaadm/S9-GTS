public with sharing class EmailRequestTrgHandler extends TriggerHandler {
    public override void afterInsert() {
        List<Email_Request__e> newEmailRequests = (List<Email_Request__e>) Trigger.new;
        EmailRequestUtil.newEmailRequests(newEmailRequests);
      }
}