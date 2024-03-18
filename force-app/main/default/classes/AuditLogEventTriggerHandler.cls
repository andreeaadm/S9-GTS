/*
 * Author: Kamlesh.kahar@intertek.com
 * Test Class: AuditLogEventTriggerHandlerTest
 * History:
 * 		14-09-2023	MBS-4	Created this class	Kamlesh.kahar
*/

public with sharing class AuditLogEventTriggerHandler extends TriggerHandler{

    static List<Audit_Log_Event__e> newList = (List<Audit_Log_Event__e>)Trigger.new;
    public override void afterInsert() {
        createAuditLogs(newList);
    }

    public static void createAuditLogs(List<Audit_Log_Event__e> newList){
        List<Audit_Log__c> newAuditLogs = new List<Audit_Log__c>();
        for(Audit_Log_Event__e event :newList){
            Audit_Log__c log = new Audit_Log__c();
            log.Application__c = event.Application__c;
            log.Type__c = event.Type__c;
            log.New_Value__c = event.New_Value__c;
            log.Old_Value__c = event.Old_Value__c;
            log.Action_Performed__c = event.Action_Performed__c;
            log.RecordId_Reference__c = event.RecordId_Reference__c;
            log.Account__c = event.AccountId__c;
            log.User__c = event.UserId__c;
            newAuditLogs.add(log);
        }

        if(!newAuditLogs.isEmpty()){
            insert newAuditLogs;
        }
    }
}