/**
* @author Buddy Winter <buddy.winter@cloudshiftgroup.com>
* @date 2022-04-21
* @group CloudShiftGroup
* @description Class for generation of scheduled Recall Digest email for GMA HLSL portal users.
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 21/04/2022        Buddy Winter        Created Class
* 30/05/2022        Viorel Pascu        Changed Regional_Account_Manager references to Account.Owner
*/
public without sharing class RecallDigestProcessor {

    public static Map<String, List<Recall__c>> recallMap = new Map<String, List<Recall__c>>();
    @TestVisible private static List<Messaging.SingleEmailMessage> emailsToSend;
    private static Date emailStartDate;
    private static Date emailEndDate;
    private static EmailTemplate emailTemplate;
    private static Boolean useOrgWideEmail;
    private static Id emailSenderId;
    private static final String CONTENT_TAG = '[CONTENT]';
    private static final String AM_NAME_TAG = '[AM_NAME]';
    private static final String AM_EMAIL_TAG = '[AM_EMAIL]';
    private static final String AM_NUMBER_TAG = '[AM_NUMBER]';
    private static final String MULTIPICKLIST_SPLIT_CHAR = ';';

    @testVisible private static String ACCOUNT_RECORDTYPE_DEVNAME = GMA_Variable__mdt.getInstance('GMA_Customer_RecordType').Variable_Value__c;
    private static String EMAIL_TEMPLATE_NAME = GMA_Variable__mdt.getInstance('Recall_Digest_Email_Template').Variable_Value__c;
    private static String EMAIL_SENDER = GMA_Variable__mdt.getInstance('Recall_Digest_Email_Sender').Variable_Value__c;

    /**
     * Creates and sends emails to active GMA HL SL accounts with details of recalls for a given timeframe
     *
     * @param  startDate    Date start date for time period of recalls to summarise
     * @param  endDate      Date end date for time period of recalls to summarise
     *
     * @see                 RecallDigestSchedulable
     */
    public static void generateEmails(Date startDate, Date endDate){
        emailStartDate = startDate;
        emailEndDate = endDate;
        emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = :EMAIL_TEMPLATE_NAME];

        List<OrgWideEmailAddress> orgAddresses = new List<OrgWideEmailAddress>([SELECT Id FROM OrgWideEmailAddress WHERE Address =:EMAIL_SENDER LIMIT 1]);
        useOrgWideEmail = (!orgAddresses.isEmpty());
        emailSenderId = (useOrgWideEmail ? orgAddresses.get(0).Id : null);

        // Get Map of HLSL Recalls in the timeframe
        List<Recall__c> recalls = [SELECT Id, Name, Product__c, Market__c, Category__c, 
                                    Risk_Type__c, Material__c, Age_Range__c, Description__c,
                                    Recall_Date__c, Source__c
                                    FROM Recall__c
                                    WHERE Recall_Date__c > :startDate
                                    AND Recall_Date__c <= :endDate];
        generateRecallMap(recalls);

        // Get list of active GMA HLSL Portal Accounts
        Map<Id, Account> portalAccounts = new Map<Id, Account>([SELECT Id, Name, Owner.Name,
                                        Owner.Email, Owner.Phone,
                                        (SELECT Id, Product__c, Market__c FROM Search__r),
                                        (SELECT Id FROM Contacts WHERE Is_GMA_HL_SL_User__c = true AND Opt_In_Recall_Digest__c = true)
                                        FROM Account
                                        WHERE RecordType.DeveloperName=:ACCOUNT_RECORDTYPE_DEVNAME]);

        //establish if account has searches for recalled stuff
        Set<Id> relevantAccountIds = new Set<Id>();
        for(Account acc : portalAccounts.values()){
            Boolean contactsWithOptInExist = (acc.Contacts != null && !acc.Contacts.isEmpty());
            if (contactsWithOptInExist) {
                for (Search__c search : acc.Search__r) {
                    Boolean dataPresent = (String.isNotBlank(search.Market__c) && String.isNotBlank(search.Product__c));

                    if (dataPresent) {
                        List<String> allMarkets = search.Market__c.split(MULTIPICKLIST_SPLIT_CHAR);
                        List<String> allProducts = search.Product__c.split(MULTIPICKLIST_SPLIT_CHAR);
                        for (String market : allMarkets) {
                            for (String product : allProducts) {
                                String keyToFind = generateRecallRecordKey(market, product);
                                if (recallMap.containsKey(keyToFind)) {
                                    relevantAccountIds.add(acc.Id);
                                    break;
                                }
                            }
                            if (relevantAccountIds.contains(acc.Id)) {
                                break;
                            }
                        }
                    }
                }
            }
        }

        // Generate list of emailMessages to send
        emailsToSend = new List<Messaging.SingleEmailMessage>();
        for(Id accId : relevantAccountIds){
            Account acc = portalAccounts.get(accId);
            emailsToSend.add(generateEmailMessage(acc));
        }

        // Send Emails
        Messaging.sendEmail(emailsToSend, false);
    }

    /**
     * Generate a map of Recalls found for the given time period, with a key of the criteria the Recall matches (Product,Market)
     *
     * @param  recalls      List<Recall__c> Recalls found published in the timeframe for this batch
     */
    private static void generateRecallMap(List<Recall__c> recalls){
        for(Recall__c recall : recalls){
            Boolean dataPresent = (String.isNotBlank(recall.Market__c) && String.isNotBlank(recall.Product__c));

            if (dataPresent) {
                List<String> allMarkets = recall.Market__c.split(MULTIPICKLIST_SPLIT_CHAR);
                List<String> allProducts = recall.Product__c.split(MULTIPICKLIST_SPLIT_CHAR);
                for (String market : allMarkets) {
                    for (String product : allProducts) {
                        String recallKey = generateRecallRecordKey(market, product);
                        List<Recall__c> tmpList = (recallMap.containsKey(recallKey) ? recallMap.get(recallKey) : new List<Recall__c>());
                        tmpList.add(recall);
                        recallMap.put(recallKey, tmpList);
                    }
                }
            }
        }
    }

    /**
     * To handle upsertion (insert or update) of an Event record.
     *
     * @param  acc          Account containing one active GMA HLSL Account to generate a bespoke email for
     * @return              Messaging.SingleEmailMessage Email message object to send to this Account alone
     */
    private static Messaging.SingleEmailMessage generateEmailMessage(Account acc){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{};
        for(Contact con : acc.Contacts){
            toAddresses.add(con.Id);
        }

        if (useOrgWideEmail) {
            email.setOrgWideEmailAddressId(emailSenderId);
        }

        email.setToAddresses(toAddresses);
        email.subject = emailTemplate.Subject;
        String htmlBody = generateHtmlBody(acc);
        String txtBody = htmlBody.stripHtmlTags().stripHtmlTags();
        email.setHtmlBody(htmlBody);
        email.setPlainTextBody(txtBody);
        return email;
    }

    /**
     * Generate the HTML Body for an email to send to a given account record.
     *
     * @param  acc          Account containing one active GMA HLSL Account to generate a bespoke email for
     * @return              String containing the HTML body for the email to send to this Account
     */
    private static String generateHtmlBody(Account acc){
        String htmlBody = emailTemplate.HtmlValue;
        // Merge Fields
        htmlBody = htmlBody.replace(AM_NAME_TAG, acc.Owner?.Name != null ? acc.Owner?.Name : '');
        htmlBody = htmlBody.replace(AM_EMAIL_TAG, acc.Owner?.Email != null ? acc.Owner?.Email : '');
        htmlBody = htmlBody.replace(AM_NUMBER_TAG, acc.Owner?.Phone != null ? acc.Owner?.Phone : '');

        // Content table. Find Recalls where Product + Market matches any of the Account's Searches
        Set<Recall__c> recalls = new Set<Recall__c>();
        for(Search__c search : acc.Search__r){
            Boolean dataPresent = (String.isNotBlank(search.Market__c) && String.isNotBlank(search.Product__c));
            if (dataPresent) {
                List<String> allMarkets = search.Market__c.split(MULTIPICKLIST_SPLIT_CHAR);
                List<String> allProducts = search.Product__c.split(MULTIPICKLIST_SPLIT_CHAR);
                for (String market : allMarkets) {
                    for (String product : allProducts) {
                        String keyToGet = generateRecallRecordKey(market, product);
                        List<Recall__c> matchedRecalls = (recallMap.containsKey(keyToGet) ? recallMap.get(keyToGet) : new List<Recall__c>());
                        recalls.addAll(matchedRecalls);
                    }
                }
            }
        }
        String bodyContent = '';
        bodyContent += '<table class="Table" style="max-width: 100%; width: 100%; border-collapse:collapse" width="100%">' +
            '<tbody>' +
                '<tr>' +
                    '<td style="border-bottom: none; width: 30%; padding: 0cm 7px; background-color: rgb(255, 192, 0); border-top: 1px solid black; border-right: 1px solid black; border-left: 1px solid black;"><span style="font-size:11pt"><span style="line-height:107%"><span style="font-family:arial"><b><span lang="EN-US" style="font-size:12.0pt"><span style="line-height:107%"><span style="font-family:arial"><span style="color:black">&nbsp;Product</span></span></span></span></b></span></span></span></td>' +
                    '<td style="border-bottom: none; width: 40%; padding: 0cm 7px; background-color: rgb(255, 192, 0); border-top: 1px solid black; border-right: 1px solid black; border-left: none;"><span style="font-size:11pt"><span style="line-height:107%"><span style="font-family:arial"><b><span lang="EN-US" style="font-size:12.0pt"><span style="line-height:107%"><span style="font-family:arial"><span style="color:black">Market</span></span></span></span></b></span></span></span></td>' +
                    '<td style="border-bottom: none; width: 30%; padding: 0cm 7px; background-color: rgb(255, 192, 0); border-top: 1px solid black; border-right: 1px solid black; border-left: none;"><span style="font-size:11pt"><span style="line-height:107%"><span style="font-family:arial"><b><span lang="EN-US" style="font-size:12.0pt"><span style="line-height:107%"><span style="font-family:arial"><span style="color:black">Risk Type</span></span></span></span></b></span></span></span></td>' +
                '</tr>';
        for(Recall__c recall : recalls){
            String risk = (String.isBlank(recall.Risk_Type__c) ? '' : recall.Risk_Type__c).replace(';', '; ');
            bodyContent += '<tr>' +
                '<td style="border-bottom:1px solid black; width: 30%; padding:0cm 7px 0cm 7px; border-top:none; border-right:1px solid black; border-left:1px solid black" valign="top"><span style="font-family:arial">' + recall.Product__c + '</span></td>' +
                '<td style="border-bottom:1px solid black; width: 40%; padding:0cm 7px 0cm 7px; border-top:none; border-right:1px solid black; border-left:none" valign="top"><span style="font-family:arial">' + recall.Market__c + '</span></td>' +
                '<td style="word-break: break-word; border-bottom: 1px solid black; width: 30%; padding: 0cm 7px; border-top: none; border-right: 1px solid black; border-left: none;" valign="top"><span style="font-family:arial">' + risk + '</span></td>' +
            '</tr>';
        }
        bodyContent += '</tbody>' +
            '</table>';
        htmlBody = htmlBody.replace(CONTENT_TAG, bodyContent);
        return htmlBody;
    }

    /**
     * Generate unique key that can be used to match searches and recalls
     *
     * @param  market       Market name from record (search or recall)
     * @param  product      Product name from record (search or recall)
     * @return              String concatenated value of market and product
     *     */
    private static String generateRecallRecordKey(String market, String product) {
        return product + '###' + market;
    }
}