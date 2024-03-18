/**
 * @author Jadd Ennaciri <jadd.ennaciri@globant.com>
 * @date 2023-12-08
 * @group Globant
 * @description - Controller class to load data and perform DML operations for the iCareInspectionTable LWC
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 08/12/2023    Jadd Ennaciri      Created Class
 *
 */

public with sharing class iCare_InspectionTableController {
  /**
   * To return a json string of Inspection records related to the Job displaying the LWC datatable
   *
   * @param recordId (String) - record Id of the parent Job
   *
   * @return (String) - json string of inspection records
   */
  @AuraEnabled(cacheable=true)
  public static String getInspections(String recordId) {
    List<GTS_Inspection__c> specialRemarks = [
      SELECT
        Id,
        GTS_Job__c,
        GTS_IRN__c,
        GTS_Status__c,
        GTS_Inspector__c,
        GTS_Scheduled_For__c,
        GTS_Completed__c,
        GTS_Results__c
      FROM GTS_Inspection__c
      WHERE GTS_Job__c = :recordId
    ];
    return JSON.serialize(specialRemarks);
  }
}