public with sharing class MTC_LastActivityDateUpdateOnAsset implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Get Assets to loop over
        return Database.getQueryLocator(
            'SELECT Id,Date_Issued__c,Date_Revised__c,Last_Activity_Date__c FROM Asset'
        );
    }
    
    public void execute(Database.BatchableContext bc, List<Asset> scope) {
        List<Asset> assetsToBeUpdated = new List<Asset>();
        for (Asset ast : scope) {
            if(ast.Date_Issued__c == null && ast.Date_Revised__c == null){
                ast.Last_Activity_Date__c = null;
            }
            else if(ast.Date_Issued__c == null && ast.Date_Revised__c != null){
                ast.Last_Activity_Date__c = ast.Date_Revised__c;
            }
            else if(ast.Date_Issued__c != null && ast.Date_Revised__c == null){
                ast.Last_Activity_Date__c = ast.Date_Issued__c;
            }
            else if(ast.Date_Issued__c != null && ast.Date_Revised__c != null){
                if(ast.Date_Issued__c > ast.Date_Revised__c){
                    ast.Last_Activity_Date__c = ast.Date_Issued__c; 
                }
                else if(ast.Date_Revised__c > ast.Date_Issued__c){
                    ast.Last_Activity_Date__c = ast.Date_Revised__c;  
                }
                else if(ast.Date_Revised__c == ast.Date_Issued__c){
                    ast.Last_Activity_Date__c = ast.Date_Revised__c; 
                }
            }
            assetsToBeUpdated.add(ast);
        }
        update assetsToBeUpdated;
    }
    
    public void finish(Database.BatchableContext bc) {
    }
}