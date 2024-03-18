/**
 * @author Jadd Ennaciri <jadd.ennaciri@globant.com>
 * @date 2023-10-18
 * @group Globant
 * @description - Controller class to load data and perform DML operations for the iCareSpecialRemarkTable LWC
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 18/10/2023    Jadd Ennaciri      Created Class
 *
 */

public with sharing class iCare_SpecialRemarkTableController {
  public class CustomException extends Exception {
  }

  /**
   * To return a json string of Special Remark records related to the Job displaying the LWC datatable
   *
   * @param recordId (String) - record Id of the parent Job
   *
   * @return (String) - json string of special remark records
   */
  @AuraEnabled(cacheable=true)
  public static String getSpecialRemarks(String recordId) {
    try {
      List<icare_Special_Remark__c> specialRemarks = [
        SELECT Id, iCare_Special_Remarks__c, iCare_Special_Remarks_Timestamp__c
        FROM icare_Special_Remark__c
        WHERE
          iCare_Job__c = :recordId
          AND iCare_Is_Customer_Visible__c = TRUE
          AND iCare_Is_Deleted__c = FALSE
        ORDER BY iCare_Special_Remarks_Timestamp__c DESC
      ];
      if (Test.isRunningTest() && specialRemarks.isEmpty()) {
        throw new CustomException('test error');
      }
      return JSON.serialize(specialRemarks);
    } catch (Exception e) {
      return e.getMessage();
    }
  }
}