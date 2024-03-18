/*
* @author       Globant
* @created      23-Nov-2023
* @description  Class contains logic to create Lead (Send a request)
*/
public with sharing class SendARequestFormController {

    @AuraEnabled
    public static Map<String, Object> getData(){

        try {

            List<Map<String, String>> countries = retrievePicklist('IConnect_Lead__c', 'INTK_Address__CountryCode__s');
            Map<String, Object> countriesByContinent = GMAEL_AccessPassportPortalController.getCountriesListView();
            List<GMAEL_Portal__mdt> gMAELPortalData = [SELECT Id, Services__c FROM GMAEL_Portal__mdt WHERE MasterLabel = 'Services'];

            Map<String, Object> data = new Map<String, Object> {
                'countries' => countries,
                'countriesByContinent' => countriesByContinent,
                'services' => (gMAELPortalData.size() > 0 ? gMAELPortalData.get(0)?.Services__c?.split(',') : new List<String>()),
                'iConnectLead' => new IConnect_Lead__c(
                    INTK_Subject__c = 'Intertek Access Services',
                    INTK_Source__c = 'Web',
                    INTK_Source_Application_Name__c = 'GMA EL',
                    RecordTypeId = Schema.SObjectType.IConnect_Lead__c.getRecordTypeInfosByName().get('GMA EL').getRecordTypeId()
                )
            };            
            
            return data;
        } catch (Exception e) {
            
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void createIConnectLead(IConnect_Lead__c lead){

        try {

            insert lead;
        } catch (Exception e) {
            
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
    * Method to return picklist values or label for Object picklist field.
    */
   @TestVisible
   private static List<Map<String, String>> retrievePicklist(String objectAPIName, String fieldAPIName){
        
        List<Map<String, String>> picklist = new List<Map<String, String>>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectAPIName) ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldAPIName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        
        String picklistStr = '';
        for( Schema.PicklistEntry pickListVal : ple){
            
            picklist.add(new Map<String,String>{'value' => pickListVal.getLabel(), 'key' => pickListVal.getValue()});
        }

        return picklist;
    }
}