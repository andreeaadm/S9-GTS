/**
 * @author Kaspars Rezgalis <kaspars.rezgalis@cloudshiftgroup.com>
 * @date 2022-09-28
 * @group CloudShiftGroup
 * @description Helper class to fetch cases for GMA portal listview
 *
 * Date          Author             Change Description
 * -----------------------------------------------------------------------------------
 * 28/09/2022    Kaspars Rezgalis   Created Class
*/
public with sharing class GMAHLSLCasesListviewController {

    public class caseItem {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String caseNumber;
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String timestamp;
    }

    @AuraEnabled(cacheable=false)
    public static List<caseItem> getCaseRecords(String daysCount){
        List<caseItem> casesToView = new List<caseItem>();

        User runningUser = GmaPortalHelper.getCurrentUser();

        if (String.isNotBlank(runningUser.ContactId) && String.isNotBlank(runningUser.Contact.AccountId)) {
            Id accId = runningUser.Contact.AccountId;
            String queryString = 'SELECT Id, Subject, CaseNumber, Case_Type__c, ';
            queryString += ' Status, CreatedDate ';
            queryString += ' FROM Case';
            if(daysCount?.isNumeric()){
                queryString += ' WHERE CreatedDate = LAST_N_DAYS:' + daysCount;
            }

            queryString += (queryString.contains(' WHERE ') ? ' AND ' : ' WHERE ');
            queryString += ' AccountId=:accId ';
            queryString += ' ORDER BY CreatedDate DESC';
            for (Case c : Database.query(queryString)) {
                caseItem w = new caseItem();
                w.key = c.Id;
                w.caseNumber = c.CaseNumber;
                w.type = c.Case_Type__c;
                w.subject = c.Subject;
                w.status = c.Status;
                w.timestamp = GmaPortalHelper.prettifyTimestamp(c.CreatedDate);
                casesToView.add(w);
            }
        }
        return casesToView;
    }
}