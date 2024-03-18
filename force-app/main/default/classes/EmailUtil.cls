public with sharing class EmailUtil {
  public class Email {
    public Set<sObject> recipients;
    public Id recordId;
    public String templateName;
    public String orgWideEmailAddress;
    public Email(
      List<sObject> recipients,
      Id recordId,
      String templateName,
      String orgWideEmailAddress
    ) {
      this.recipients = new Set<sObject>(recipients);
      this.recordId = recordId;
      this.templateName = templateName;
      this.orgWideEmailAddress = orgWideEmailAddress;
    }
  }

  public static void sendEmails(List<Email> emails) {
    // split the emails out so that there are no more than 10 recipients per List<Email>
    // if emailBatches size ends up being greater than 1, farm out to doSendFuture
    List<List<Email>> emailBatches = new List<List<Email>>();
    List<Email> currentBatch = new List<Email>();
    Integer currentBatchRecipientCount = 0;
    for (Email e : emails) {
      Email tempEmail = new Email(
        new List<sObject>(),
        e.recordId,
        e.templateName,
        e.orgWideEmailAddress
      );
      for (sObject so : e.recipients) {
        // Add another recipient to the current Email
        tempEmail.recipients.add(so);
        currentBatchRecipientCount++;
        // When we reach 10 recipients on the Email...
        if (
          tempEmail.recipients.size() == 10 ||
          currentBatchRecipientCount == 10
        ) {
          // Add the Email to the currentBatch. Clone it so that we can re-use tempEmail again
          // Clone changed to creation of a new Email object to ensure the recipients list isn't shared between tempEmail and currentBatch
          List<sObject> tempEmailRecipients = new List<sObject>();
          for(sObject s : tempEmail.recipients) {
            tempEmailRecipients.add(s);
          }
          currentBatch.add(new Email(
            tempEmailRecipients,
            tempEmail.recordId,
            tempEmail.templateName,
            tempEmail.orgWideEmailAddress
          ));
          // Add the currentBatch to the list of emailBatches. Clone it so that we can re-use currentBatch again
          emailBatches.add(currentBatch.clone());
          // Empty currentBatch so that we can start to fill a new one
          currentBatch.clear();
          // Zero the currentBatch recipient counter
          currentBatchRecipientCount = 0;
          // Empty tempEmail's recipients list so that we can start from 0 again
          tempEmail.recipients.clear();
        }
      }
      if (tempEmail.recipients.size() != 0) {
        // If after looping through an Email's recipients we have recipients in tempEmail, make sure we add it to currentBatch
        currentBatch.add(tempEmail.clone());
      }
    }
    if (!currentBatch.isEmpty()) {
      // If after looping through all Emails currentBatch isn't empty, make sure we add currentBatch to emailBatches
      emailBatches.add(currentBatch.clone());
    }
    if (emailBatches.size() > 1) {
      for (List<Email> emailBatch : emailBatches) {
        doSendFuture(JSON.serialize(emailBatch));
      }
    } else if (emailBatches.size() == 1) {
      doSend(emailBatches[0]);
    }
  }

  @future
  static void doSendFuture(String emailString) {
    doSend(
      (List<Email>) JSON.deserializeStrict(emailString, List<Email>.class)
    );
  }

  static void doSend(List<Email> emails) {
    Map<String, Id> templateNameToTemplateIdMap = getTemplateMap(emails);
    Map<String, Id> orgWideAddressToOrgWideIdMap = getOrgWideAddressMap(emails);
    List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
    for (Email e : emails) {
      if (
        e.recipients != null &&
        !e.recipients.isEmpty() &&
        e.templateName != null &&
        e.recordId != null
      ) {
        try {
          for (sObject so : e.recipients) {
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(
              templateNameToTemplateIdMap.get(e.templateName),
              so.Id,
              e.recordId
            );
            email.setTemplateId(
              templateNameToTemplateIdMap.get(e.templateName)
            );
            if (
              e.orgWideEmailAddress != null &&
              orgWideAddressToOrgWideIdMap.get(e.orgWideEmailAddress) != null
            ) {
              email.setOrgWideEmailAddressId(
                orgWideAddressToOrgWideIdMap.get(e.orgWideEmailAddress)
              );
            }
            email.setTargetObjectId(so.Id);
            // email.setSubject(email.getSubject());
            // email.sethtmlBody(email.gethtmlBody());
            email.saveAsActivity = false;
            messages.add(email);
          }
        } catch (Exception ex) {
          System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
      }
    }
    try {
      if (!messages.isEmpty()) {
        Messaging.sendEmail(messages);
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
  }

  static Map<String, Id> getTemplateMap(List<Email> emails) {
    Map<String, Id> templateNameToTemplateIdMap = new Map<String, Id>();
    Set<String> templateNames = new Set<String>();
    for (Email e : emails) {
      templateNames.add(e.templateName);
    }
    for (EmailTemplate et : [
      SELECT Id, DeveloperName
      FROM EmailTemplate
      WHERE DeveloperName IN :templateNames
    ]) {
      templateNameToTemplateIdMap.put(et.DeveloperName, et.Id);
    }
    return templateNameToTemplateIdMap;
  }

  static Map<String, Id> getOrgWideAddressMap(List<Email> emails) {
    Map<String, Id> orgWideAddressToOrgWideIdMap = new Map<String, Id>();
    Set<String> orgWideEmailAddresses = new Set<String>();
    for (Email e : emails) {
      orgWideEmailAddresses.add(e.orgWideEmailAddress);
    }
    for (OrgWideEmailAddress owa : [
      SELECT Id, Address
      FROM OrgWideEmailAddress
      WHERE Address IN :orgWideEmailAddresses
    ]) {
      orgWideAddressToOrgWideIdMap.put(owa.Address, owa.Id);
    }
    return orgWideAddressToOrgWideIdMap;
  }
}