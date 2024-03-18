/*
* ________________________________________________________________________________________________
* Controller class for Tbs Filters Table LWC component of iCare Portal
* Component to show the list of Jobs with different filters
* ________________________________________________________________________________________________
* @author       Andres Morales
* @created      2023-05-01
* ________________________________________________________________________________________________
* @changes

* ________________________________________________________________________________________________
*/
public with sharing class iCare_TabsFiltersTableController {
  @AuraEnabled(cacheable=true)
  public static List<iCare_Job__c> getJobs(
    Integer daysToSearch,
    Date startDate,
    Date endDate
  ) {
    String strDatesFilter;

    if (startDate != null || endDate != null) {
      if (startDate != null && endDate != null) {
        strDatesFilter = 'WHERE iCare_Date_Time__c >= :startDate AND iCare_Date_Time__c <= :endDate ';
      } else if (startDate != null) {
        strDatesFilter = 'WHERE iCare_Date_Time__c >= :startDate ';
      } else if (endDate != null) {
        strDatesFilter = 'WHERE iCare_Date_Time__c <= :endDate ';
      }
    } else if (daysToSearch != 0) {
      strDatesFilter = 'WHERE iCare_Date_Time__c = LAST_N_DAYS:' + daysToSearch;
    } else {
      strDatesFilter = '';
    }

    List<iCare_Job__c> lstJobs = Database.query(
      'SELECT iCare_Job_Hyperlink__c, iCare_Buyer_Program_formula__c, iCare_Sample_Description__c, ' +
      'iCare_Date_Time__c, iCare_Job_Pending__c, iCare_Model_Style_Number__c,iCare_Product_Type__c, ' +
      'iCare_Agency_Name__c, iCare_Order_Number__c, iCare_Applicant_Contact_Person_Name__c, ' +
      'toLabel(iCare_Job_Status_Portal__c) jobStatusLabel, iCare_Job_Status_Portal__c ' +
      'FROM iCare_Job__c ' +
      strDatesFilter +
      'ORDER BY iCare_Date_Time__c DESC'
    );
    system.debug('*****AM-lstJobs: ' + lstJobs);
    return lstJobs;
  }
}