/*
* ________________________________________________________________________________________________
* Controller class for Tbs Filters Table LWC component of iCare Portal
* Component to show the list of Jobs with different filters
* ________________________________________________________________________________________________
* @author       Mo
* @created      2023-06-28
* ________________________________________________________________________________________________
* @new

* ________________________________________________________________________________________________
*/
public with sharing class iCare_HomeTableController {
    
    @AuraEnabled(cacheable=true)
    public static List<iCare_Job__c> getJobs(Integer recordLimit, Boolean isReport) {
        String strStatusFilter;

        if (isReport) {
            strStatusFilter = 'WHERE iCare_Job_Status__c = \'Test Report Issued\' ';
        } else {
            strStatusFilter = 'WHERE iCare_Job_Status__c != \'Test Report Issued\' ';
        }

        List<iCare_Job__c> lstJobs = Database.query(    'SELECT iCare_Job_Hyperlink__c, iCare_Buyer_Program_formula__c, iCare_Sample_Description__c, ' +
                                                        'iCare_Date_Time__c, toLabel(iCare_Job_Status_Portal__c) iCare_Job_Status_Portal__c, iCare_Job_Pending__c ' +
                                                        'FROM iCare_Job__c ' +
                                                        strStatusFilter +
                                                        'ORDER BY iCare_Date_Time__c DESC LIMIT ' + recordLimit);

        return lstJobs;
    }

    @AuraEnabled
    public static Integer totalRecords(Boolean isReport){
        return getJobs(50000, isReport) != null ? getJobs(50000, isReport)?.size() : 0;
    }

    @AuraEnabled(cacheable=true)
    public static List<iCare_Job__c> getJobList(Integer v_Offset, Integer v_pagesize, Boolean isReport){
        String strStatusFilter;

        if (isReport) {
            strStatusFilter = 'WHERE iCare_Job_Status__c = \'Test Report Issued\' ';
        } else {
            strStatusFilter = 'WHERE iCare_Job_Status__c != \'Test Report Issued\' ';
        }
        
        List<iCare_Job__c> lstJobs = Database.query(    'SELECT iCare_Job_Hyperlink__c, iCare_Buyer_Program_formula__c, iCare_Sample_Description__c, ' +
                                                        'iCare_Date_Time__c, toLabel(iCare_Job_Status_Portal__c) iCare_Job_Status_Portal__c, iCare_Job_Pending__c ' +
                                                        'FROM iCare_Job__c ' +
                                                        strStatusFilter +
                                                        'ORDER BY iCare_Date_Time__c DESC LIMIT ' + v_pagesize + 'OFFSET ' + v_Offset);

        return lstJobs;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getNext(Integer v_Offset, Integer v_pagesize){
        v_Offset += v_pagesize;
        return v_Offset;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getPrevious(Integer v_Offset, Integer v_pagesize){
        v_Offset -= v_pagesize;
        return v_Offset;
    }
}