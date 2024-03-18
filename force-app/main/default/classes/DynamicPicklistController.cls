/**
* @author Buddy Winter <buddy.winter@cloudshiftgroup.com>
* @date 2022-04-22
* @group CloudShiftGroup
* @description      Controller for dynamicPicklist LWC. Provides a map of keywords to picklist values available for search for a given picklist field.
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 22/04/2022        Buddy Winter        Created Class
*/
public without sharing class DynamicPicklistController {

    public class keywordDefinition {
        @AuraEnabled public String keywordsAsString;
        @AuraEnabled public String picklistValue;
        @AuraEnabled public String category;
    }
    /**
     * To provide for LWC information about picklist values to match based on search term (keyword or picklist value name) used
     *
     * @param  objectName   API Name of the object to retrieve picklist values and keywords for
     * @param  fieldName    API Name of the field of the object to retrieve picklist values and keywords for
     * @return              Map<String, keywordDefinition> Map of [available keywords] => [picklist value];[picklist category]
     * @see                 dynamicPicklist LWC
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, keywordDefinition> getPicklistOptions(String objectName, String fieldName){
        try {
            // Setup return map
            Map<String, keywordDefinition> keywordOptionsMap = new Map<String, keywordDefinition>();

            // Get available keywords for the given picklist based on Dynamic Picklist Keywords custom metadata values
            List<Dynamic_Picklist_Keywords__mdt> keywordDefinitionList = Dynamic_Picklist_Keywords__mdt.getAll().values();
            Map<String, String> keywordMap = new Map<String, String>();
            Map<String, String> keywordCategoryMap = new Map<String, String>();
            for(Dynamic_Picklist_Keywords__mdt keywordDefinition : keywordDefinitionList){
                if(keywordDefinition.Object_API_Name__c == objectName && keywordDefinition.Field_API_Name__c == fieldName){
                    String key = keywordDefinition.Picklist_Value__c.toLowerCase();
                    String keywords = (keywordMap.containsKey(key) ? keywordMap.get(key) : '');
                    keywords += keywordDefinition.Keywords__c;
                    keywordMap.put(key, keywords);
                    keywordCategoryMap.put(key, keywordDefinition.Category__c);
                }
            }

            // Get available picklist values for the picklist based on schema.
            Schema.SObjectField picklistDefinition = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName);
            List<Schema.PicklistEntry> picklistValues = picklistDefinition.getDescribe().getPicklistValues();
            for(Schema.PicklistEntry picklistValue : picklistValues){
                // Map a list of keywords (; separated) to picklist values (e.g. uk;britain => United Kingdom)
                String key = picklistValue.value.toLowerCase();
                if(keywordMap.containsKey(picklistValue.value.toLowerCase())){
                    key += ';' + keywordMap.get(picklistValue.value.toLowerCase())?.toLowerCase();
                }

                keywordDefinition def = new keywordDefinition();
                def.picklistValue = picklistValue.value;
                def.category = (keywordCategoryMap.containsKey(picklistValue.value.toLowerCase()) ? keywordCategoryMap.get(picklistValue.value.toLowerCase()) : '');
                keywordOptionsMap.put(key, def);
            }
            return keywordOptionsMap;

        } catch (Exception e) {
            System.debug(e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
}