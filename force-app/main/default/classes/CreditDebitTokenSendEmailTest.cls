@IsTest
public class CreditDebitTokenSendEmailTest {
    
    private static testMethod void sendEmailsTest() {
        CreditDebitTokenSendEmail.Request request = new CreditDebitTokenSendEmail.Request();
        request.subject = 'Test Credit Token';
        request.body = '50 Tokens Credited';
        request.recipientAddressCollection = new List<String>{'totest@noreply.com'};
        request.senderEmailAddress = 'fromtest@noreply.com';
        Test.startTest();
        List<CreditDebitTokenSendEmail.Result> results = CreditDebitTokenSendEmail.sendEmails(new List<CreditDebitTokenSendEmail.Request>{request});
        Test.stopTest();
        System.assertEquals(true, results[0].isSuccess);
    }
}