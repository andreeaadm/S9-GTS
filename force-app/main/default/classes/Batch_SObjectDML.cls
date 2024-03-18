/*
┌──────────────────────────────────────────────────────────────────────┐
	TestClass: Batch_SObjectDML_Test.cls
	- Written by -ℌ𝔍🌵- 2020.08.20 -
	Description:
	Ported from an earlier version.
	This can be used to object agnostically insert or update 
	objects using a generic batchable utility class.
└─────────────────────────────────────────────────────────────────┄ℌ𝔍┄┘
 * >>- Changelog -<<
 * date - author - description
 */
 
public without sharing class Batch_SObjectDML implements Database.Batchable<sObject>, Database.Stateful {
    
    public List<SObject> records;
    public String operation;
    
    List<Database.SaveResult> results = new List<Database.SaveResult>();
    List<String> failedUsers = new List<String>();
    public Set<String> errors = new Set<String>();
    public Integer successes = 0;
    public Integer failures = 0;
    public Map<String,String> contactIdToEmailMap = new Map<String,String>();
    public Set<Id> failureIds = new Set<Id>();
    
	public Batch_SObjectDML(List<SObject> records, String operation, Boolean allOrNone) {
		if(allOrNone==null){
			allOrNone=false;
		}
		this.records = records;
        this.operation = operation;
        if(!records.isEmpty() && String.valueOf(records[0].getSObjectType()) == 'Contact') {
            try {
                for(SObject s : records) {
                    contactIdToEmailMap.put(String.valueOf(s.get('id')), String.valueOf(s.get('email')));
                }
            } catch(Exception e) {
                // Do nothing - there probably wasn't an email set for this Contact
            }
        }
	}
	
	public Iterable<SObject> start(Database.BatchableContext BC) {
		return records;
	}

    public void execute(Database.BatchableContext BC, List<SObject> scope) {       
        records = new List<SObject>();

        try {
            
            if(operation == 'insert') {
                //Allow partial success
                results.addAll(Database.insert(scope, false));
                
            } else if (operation == 'update') {
                //Allow partial success
                results.addAll(Database.update(scope, false));
                
            }
            
        } catch (Exception e) {
            errors.add('An error occurred: ' + e.getMessage());
            
        }
        
        for(Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results[i];
            SObject origContact = scope[i];
            if(!sr.isSuccess()) {
                failures++;
                for(Database.Error e : sr.getErrors()) {
                    errors.add('Record Id: ' + origContact.get('id') + '. ' + e.getMessage() + '.');
                    failureIds.add(String.valueOf(origContact.get('id')));

                    if (!String.isBlank((String)origContact.get('FirstName')) && !String.isBlank((String)origContact.get('LastName'))) {
                        failedUsers.add(origContact.get('FirstName') + ' ' + origContact.get('LastName'));
                    }
                }

            } else {
                successes++;

            }
        }
        
    }
	
	public void finish(Database.BatchableContext BC) {
        if (failures > 0 && failedUsers.size() > 0) {
            // Do something like send an email
            /*
            String html = '<ul>';
            for (String s : failedUsers) {
                html += '<li>' + s + '</li>';
            }
			html += '</ul>';
			
            OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'customer@customer.com'];

            EmailTemplate emailTemplate = [SELECT HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = 'Email_Template_Name'];
            emailTemplate.HtmlValue = emailTemplate.HtmlValue.replace('{#MERGE_FIELD#}', html);
            System.debug(emailTemplate.HtmlValue);

            List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
            message.setSubject(emailTemplate.Subject);
            message.setHtmlBody(emailTemplate.HtmlValue);
            message.setOrgWideEmailAddressId(address.Id);
            messageList.add(message);

            if (!Test.isRunningTest()) {
                Messaging.sendEmail(messageList);
            }
            */
        }

	}
}