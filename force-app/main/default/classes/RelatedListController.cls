public without sharing class RelatedListController {
    @AuraEnabled(cacheable=true)
    public static List<sObject> getRelatedRecords(String relatedObjectApiName, String parentFieldApiName, String parentRecordId) {
        String soqlStr = 'SELECT Id FROM ' + relatedObjectApiName + ' WHERE ' + parentFieldApiName + ' = \'' + parentRecordId + '\'';
        return Database.query(soqlStr);
    }
}