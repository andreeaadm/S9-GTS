public class CreditDebitTokenSendEmail {
    
    @InvocableMethod(label='Credit/Debit Token Send Email Action')
    public static List<Result> sendEmails(List<Request> requests) {
        List<Result> results = new List<Result>();
        for(Request request : requests){
            results.add(sendEmail(request));
        }
        return results;
    }
    
    public static Result sendEmail(Request request) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject(request.subject);
        mail.setHtmlBody(request.body);
        mail.setToAddresses(request.recipientAddressCollection);
        mail.setOrgWideEmailAddressId(getOrgWideEmailAddressId(request.senderEmailAddress));
        
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        messages.add(mail);
        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        Result sendResult = new Result();
        for(Messaging.SendEmailResult result :results) {
            sendResult.isSuccess = result.IsSuccess();
            if(!result.IsSuccess()) break;
        }
        return sendResult;
    }
    
    private static Id getOrgWideEmailAddressId(String senderEmailAddress) {
        List<OrgWideEmailAddress> orgWideEmailAddresses = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :senderEmailAddress];
        if (!orgWideEmailAddresses.isEmpty()){
            return orgWideEmailAddresses[0].Id;
        }
        return null;
    }
    
    public class Result {
        @InvocableVariable
        public Boolean isSuccess;
        
        @InvocableVariable
        public String errorMessage;
    }
    
    public class Request {
        @InvocableVariable(
            label = 'Subject'
            description = 'The subject of the email'
            required=true
        )
        public String subject;
        
        @InvocableVariable(
            label = 'Body'
            description = 'The body of the email'
            required=true
        )
        public String body;
        
        @InvocableVariable(
            label = 'Sender Email Address'
            description = 'The organization-wide email address thats used to send the email'
            required=true
        )
        public String senderEmailAddress;
        
        @InvocableVariable(
            label = 'Recipient Address Collection'
            description = 'A collection of the recipients email addresses'
            required=true
        )
        public List<String> recipientAddressCollection;
    }
}