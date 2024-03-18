/*
* @author       Globant
* @created      23-Nov-2023
* @description  Class contains logic to create Lead (Send a request)
*/
public with sharing class GMAEL_SendARequestFormController {

    @AuraEnabled
    public static Map<String, Object> getData(){

        try {

            List<Map<String, String>> countries = retrievePicklist('IConnect_Lead__c', 'INTK_Address__CountryCode__s');
            List<Map<String, String>> industries = retrievePicklist('IConnect_Lead__c', 'INTK_Industry__c');
            Map<String, Object> countriesByContinent = GMAEL_AccessPassportPortalController.getCountriesListView();
            List<GMAEL_Portal__mdt> gMAELPortalData = [SELECT Id, Services__c FROM GMAEL_Portal__mdt WHERE MasterLabel = 'Services'];
            iCare_Integration_Details__mdt createLeadMdtObj = iCare_Integration_Details__mdt.getInstance('GMAEL_IConnect_Lead_Create');

            Map<String, Object> data = new Map<String, Object> {
                'countries' => countries,
                'industries' => industries,
                'states' => getChildPicklistValues(),
                'countriesByContinent' => countriesByContinent,
                'services' => (gMAELPortalData.size() > 0 ? gMAELPortalData.get(0)?.Services__c?.split(',') : new List<String>()),
                'iConnectLead' => new IConnect_Lead__c(
                    INTK_Subject__c = 'Intertek Access Services',
                    INTK_Source__c = 'Web',
                    INTK_Source_Application_Name__c = 'GMA EL',
                    RecordTypeId = Schema.SObjectType.IConnect_Lead__c.getRecordTypeInfosByName().get('GMA EL').getRecordTypeId(),
                    INTK_Campaign_Id__c = (createLeadMdtObj != null ? createLeadMdtObj.Campaign_Id__c : null)
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

    @AuraEnabled(cacheable=true)
    public static Map<String,List<Map<String,String>>> getChildPicklistValues() {

        return getDependentPicklistValues();
    }

    @TestVisible
    private static Map<String,List<Map<String,String>>> getDependentPicklistValues() {
        
        Schema.sObjectField dependentFieldToken = IConnect_Lead__c.INTK_Address__StateCode__s.getDescribe().getSObjectField();
        
        Map<String,List<Map<String,String>>> fieldDependentPicklistValues = new Map<String,List<Map<String,String>>>();  // Key : ControllingField Picklist Value Label ; Value : List of all DependentField Picklist Value Labels
        Map<String, String> controllingFieldAPIValueVSLabel = new Map<String,String>();   //Key : Picklist Value API Name ; Value = Picklist Value Label
        Map<String, String> dependentFieldAPIValueVSLabel = new Map<String,String>();   //Key : Picklist Value API Name ; Value = Picklist Value Label
        
        String base64Map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Schema.DescribeFieldResult dependentField = dependentFieldToken.getDescribe();  //Fetch Dependent Field DescribeFieldResult from Schema
        Schema.sObjectField controllingFieldToken = dependentField.getController();
        
        if (controllingFieldToken == null) {
            
            return new Map<String,List<Map<String,String>>>();
        } 

        Schema.DescribeFieldResult controllingField = controllingFieldToken.getDescribe(); //Fetch Controlling Field DescribeFieldResult from Schema
        
        List<Schema.PicklistEntry> controllingFieldPicklistValueEntries;
        Boolean isControllingFieldPicklistType = false;
        
        if (controllingField.getType() != Schema.DisplayType.Boolean) {  //Controlling Field can be either a Checkbox(Boolean) or a Picklist
            
            isControllingFieldPicklistType = true;
            controllingFieldPicklistValueEntries = controllingField.getPicklistValues();            
        }
        
        for (Schema.PicklistEntry entry : dependentField.getPicklistValues()) {

            if (entry.isActive() && String.isNotEmpty(String.valueOf( ((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor') ))) {
                
                System.debug('DependencyMatrix for entry  :'+entry+'   :   ' +String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')));
                List<String> base64charsOfDependencyMatrix = String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                Integer controllingValuesSize =  (isControllingFieldPicklistType==true && controllingFieldPicklistValueEntries != null) ? controllingFieldPicklistValueEntries.size() : 2;
                
                for (Integer index = 0; index < controllingValuesSize; index++) {

                    Object controlValue = (controllingFieldPicklistValueEntries == null ? (Object) (index == 1)
                        : (Object) (controllingFieldPicklistValueEntries[index].isActive() ? controllingFieldPicklistValueEntries[index].getValue() : null)
                    );
                    Integer bitIndex = index / 6; //Base 64 bit index
                    if (bitIndex > base64charsOfDependencyMatrix.size() - 1) {
                        
                        break;
                    }
                    
                    Integer bitShift = 5 - Math.mod(index, 6);  //Move forward by 6 bits
                    if  (controlValue == null || (base64Map.indexOf( base64charsOfDependencyMatrix[bitIndex] ) & (1 << bitShift)) == 0)
                        continue; //Do not generate the Map entry, if the Controlling field's Picklist value is an Inactive Picklist value
                    if (!fieldDependentPicklistValues.containsKey((String)controlValue)) {
                        fieldDependentPicklistValues.put((String) controlValue, new List<Map<String,String>>());
                    }

                    fieldDependentPicklistValues.get((String)controlValue).add(new Map<String,String>{'value' => entry.getLabel(), 'key' => entry.getValue()});
                }
            }
        }
        
        if (isControllingFieldPicklistType) {

            for (Schema.PicklistEntry entry : controllingField.getPicklistValues()) {

                if (entry.isActive() ) controllingFieldAPIValueVSLabel.put(entry.getValue(), entry.getLabel());            
            }
        }else{

            controllingFieldAPIValueVSLabel.put('true','true'); //Added only true, as code above contains following check : controllingFieldPicklistValueEntries[index].isActive()
        }
        
        
        for (Schema.PicklistEntry entry : dependentField.getPicklistValues()) {

            if (entry.isActive()) dependentFieldAPIValueVSLabel.put(entry.getValue(), entry.getLabel());            
        }
        
        return fieldDependentPicklistValues;
    }
}