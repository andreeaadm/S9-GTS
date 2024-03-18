/*
* @author       Globant
* @created      22-Nov-2023
* @description  Queueable class for iConnect Lead Integration
*/
public class INTK_iConnectLeadIntegrationQueueable implements Queueable, Database.AllowsCallouts{
    public List<IConnect_Lead__c> iConnectLeadList = new List<IConnect_Lead__c>();
    public List<IConnect_Lead__c> iConnectLeadUpdateList = new List<IConnect_Lead__c>();
    public List<iCare_Integration_Audit_Log__c> auditLogList = new List<iCare_Integration_Audit_Log__c>();
     
    public INTK_iConnectLeadIntegrationQueueable(List<IConnect_Lead__c> iConnectLeadList, List<IConnect_Lead__c> iConnectLeadUpdateList, List<iCare_Integration_Audit_Log__c> auditLogList){
        this.iConnectLeadList.addAll(iConnectLeadList); 
        this.iConnectLeadUpdateList.addAll(iConnectLeadUpdateList);                                 
        this.auditLogList.addAll(auditLogList);                                 
    }
    
    public void execute (QueueableContext context) { 
        // variables
        Map<String, String> headersMap = new Map<String, String>();
        // get the integration details from the metadata
        iCare_Integration_Details__mdt createLeadMdtObj = iCare_Integration_Details__mdt.getInstance('GMAEL_IConnect_Lead_Create');
        
        if ((Test.isRunningTest() || 
            (createLeadMdtObj!=null && createLeadMdtObj.Is_Active__c && (createLeadMdtObj.Named_Credentials__c!=null && createLeadMdtObj.Named_Credentials__c.length()>0))) 
            && iConnectLeadList!=null && iConnectLeadList.size()>0) {

            String endpoint_service_url = Test.isRunningTest()? INTK_iConnectIntegrationUtility.ENDPOINT_SERVICE_URL_CREATE_LEAD : createLeadMdtObj.Endpoint_Service_Url__c;
            String method = Test.isRunningTest()? INTK_iConnectIntegrationUtility.POST_METHOD : createLeadMdtObj.Http_Method__c;
            String client_Id = Test.isRunningTest() ? INTK_iConnectIntegrationUtility.CLIENT_ID : createLeadMdtObj.Client_Id__c;
            String client_Secret = Test.isRunningTest() ? INTK_iConnectIntegrationUtility.CLIENT_SECRET : createLeadMdtObj.Client_Secret__c;
            String namedCredentials = Test.isRunningTest() ? INTK_iConnectIntegrationUtility.NAMED_CREDENTIALS : createLeadMdtObj.Named_Credentials__c;

            headersMap.put('client_id', client_Id);
            headersMap.put('client_secret', client_Secret);

            IConnect_Lead__c[] iConnectLeads = [SELECT Id, Name, INTK_Address__Street__s, INTK_Address__City__s, INTK_Address__PostalCode__s, 
                                                        INTK_Address__StateCode__s, INTK_Address__CountryCode__s, INTK_Address__Latitude__s, 
                                                        INTK_Address__Longitude__s, INTK_Address__GeocodeAccuracy__s, INTK_Address__c, INTK_Business_Phone__c, 
                                                        INTK_Campaign_Id__c, INTK_Company_Name__c, INTK_Description__c, INTK_Email__c, INTK_First_Name__c, 
                                                        INTK_Job_Title__c, INTK_Last_Name__c, INTK_Retry_Sync_Counter__c, INTK_Source_Application_Name__c, 
                                                        INTK_Source__c, INTK_Subject__c, INTK_iConnect_Sync_Status__c, RecordTypeId 
                                                FROM IConnect_Lead__c
                                                WHERE Id =: iConnectLeadList[0].Id];        
        
            //Generating IConnect Create Lead Payload                                                
            INTK_iConnectIntegrationUtility.iConnectLeadPayload iconnectLeadpayloadObj = new INTK_iConnectIntegrationUtility.iConnectLeadPayload();
            iconnectLeadpayloadObj.subject = iConnectLeadList[0].INTK_Subject__c;
            iconnectLeadpayloadObj.campaignCode = iConnectLeadList[0].INTK_Campaign_Id__c;
            iconnectLeadpayloadObj.source = iConnectLeadList[0].INTK_Source__c;
            iconnectLeadpayloadObj.description = iConnectLeadList[0].INTK_Description__c;
            iconnectLeadpayloadObj.externalSystem  = iConnectLeadList[0].INTK_Source_Application_Name__c;
            iconnectLeadpayloadObj.externalSystemId  = iConnectLeadList[0].Id;
            iconnectLeadpayloadObj.jobTitle =  iConnectLeads[0].INTK_Job_Title__c;
            iconnectLeadpayloadObj.companyName =  iConnectLeads[0].INTK_Company_Name__c;
            iconnectLeadpayloadObj.countryCode =  iConnectLeads[0].INTK_Address__CountryCode__s;
            iconnectLeadpayloadObj.city =  iConnectLeads[0].INTK_Address__City__s;
            iconnectLeadpayloadObj.state = iConnectLeadList[0].INTK_Address__StateCode__s;
            iconnectLeadpayloadObj.email =  iConnectLeads[0].INTK_Email__c;
            iconnectLeadpayloadObj.businessPhone =  iConnectLeads[0].INTK_Business_Phone__c;
            iconnectLeadpayloadObj.lastName =  iConnectLeads[0].INTK_Last_Name__c;
            iconnectLeadpayloadObj.firstName =  iConnectLeads[0].INTK_First_Name__c;
            
            String payload = JSON.serialize(iconnectLeadpayloadObj, true);
            
            // basic Callout
            String response = INTK_iConnectIntegrationUtility.basicAuthCallout(namedCredentials,endpoint_service_url, payload, method, headersMap);
            Integer intStatusCode = Integer.valueOf(response.substringBefore(':responseBody:'));
            
            // to update Sync Status
            iConnectLeadUpdateList.add(new IConnect_Lead__c(Id = iConnectLeadList[0].Id, INTK_iConnect_Sync_Status__c = intStatusCode == 200 ? 'Success' : 'Failure'));
            
            // to insert the logs
            auditLogList.add(new iCare_Integration_Audit_Log__c(iCare_Request_Payload__c = payload,
                                                                iCare_Response_Payload__c = response.substringAfter(':responseBody:'),
                                                                INTK_Source_Record_Identifiers__c = iConnectLeadList[0].Id,
                                                                INTK_Source_Record_Object__c = 'IConnect_Lead__c',
                                                                iCare_Integration_Reference__c='Create Lead - iConnect',
                                                                iCare_Sync_Status__c = intStatusCode == 200 ? 'Success' : 'Failure'));
            
            // process the next record by calling Queuable constructor
            if (!iConnectLeadList.isEmpty() && iConnectLeadList.size() > 1) {
                iConnectLeadList.remove(0);
                INTK_iConnectLeadIntegrationQueueable nextCall = new INTK_iConnectLeadIntegrationQueueable(iConnectLeadList, iConnectLeadUpdateList, auditLogList);
                nextCall.execute(context);
            } else {
                //System.debug('iConnectLeadUpdateList:'+iConnectLeadUpdateList);
                update iConnectLeadUpdateList;
                insert auditLogList;
            }
        }
    }
}