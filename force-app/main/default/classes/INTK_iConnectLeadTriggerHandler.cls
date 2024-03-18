/*
* @author       Globant
* @created      22-Nov-2023
* @description  Handler Class for trigger on iConnect Lead object
*/
public class INTK_iConnectLeadTriggerHandler {
    public static void onAfterInsert(List<IConnect_Lead__c> iConnectLeadList) {
        // queuable job to generate leads in iConnect
        System.enqueueJob(new INTK_iConnectLeadIntegrationQueueable(iConnectLeadList, new List<IConnect_Lead__c>(), 
                                                        new List<iCare_Integration_Audit_Log__c>()));
    }
    
    
    public static void onAfterUpdate(List<IConnect_Lead__c> iConnectLeadList, Map<Id, IConnect_Lead__c> oldIConnectLeadMap) {
        
        List<IConnect_Lead__c> iConnectLeadProcessList = new List<IConnect_Lead__c>();
        for (IConnect_Lead__c iConnectLeadObj : iConnectLeadProcessList) {
            if (iConnectLeadObj.INTK_Retry_Sync_Counter__c != oldIConnectLeadMap.get(iConnectLeadObj.Id).INTK_Retry_Sync_Counter__c 
               && iConnectLeadObj.INTK_iConnect_Sync_Status__c != 'Success') {
                iConnectLeadProcessList.add(iConnectLeadObj);
            }
        }
        
        // queuable job to generate leads in iConnect
        if (!iConnectLeadProcessList.isEmpty()) {
            System.enqueueJob(new INTK_iConnectLeadIntegrationQueueable(iConnectLeadProcessList, new List<IConnect_Lead__c>(), 
                                                            new List<iCare_Integration_Audit_Log__c>()));
        }
    }
}