public with sharing class ZDHCPostInCheckReportController {
    @AuraEnabled
    public static String postInCheckReportForInventory(String inventoryId) {
        try {
            // get the inventory in question - error occurs if it doesn't exist or isn't Complete
            Inventory__c inventoryToSend = [
                SELECT
                Facility__r.Facility_Manager__c,
                Facility__r.ZDHC_Organisation_GUID__c,
                Inventory_Date__c,
                Type__c,
                (
                    SELECT ZDHC_Product_GUID__c, Calculated_Usage__c, Unit__c, Commodity_Chemical_Standard_Name__c,Stock_Take_Month_Begin__c,Stock_Take_Month_End__c,Delivered_Stock_This_Month__c,RecordType.developerName
                    FROM Inventory_Line_Items__r
                )
                FROM Inventory__c
                WHERE Id = :inventoryId AND Status__c = 'Complete'
                LIMIT 1
                FOR UPDATE
            ];
            
            if (inventoryToSend.Inventory_Line_Items__r.size() > 0) {
                Integer countUsage = 0;
                Integer countDelivery = 0;
                for(Inventory_Line_Item__c inv : inventoryToSend.Inventory_Line_Items__r) {
                    if(inv.RecordType.developerName == 'Usage_Inventory_Line_Item') {
                        if(inv.Unit__c == null || inv.Stock_Take_Month_Begin__c == null || inv.Stock_Take_Month_End__c == null) {
                            countUsage++;  
                        } 
                    }
                    else if(inv.RecordType.developerName == 'Delivery_Inventory_Line_Item') {
                        if(inv.Unit__c == null || inv.Delivered_Stock_This_Month__c == null) {
                            countDelivery++;  
                        }
                    }
                }
                
                if(inventoryToSend.Type__c == 'Usage') {
                    if(countUsage != 0) {
                        return 'Stock Take month begin, Stock Take month end and Unit fields are mandatory';
                    }
                    else {
                        // get the access key of the relevant facility manager
                        String userAccessKey = ZDHCGatewayService.getUserAccessKey(
                            inventoryToSend.Facility__r.Facility_Manager__c
                        );
                        
                        // construct and send the request
                        ZDHCGatewayServiceRequest request = constructRequest(userAccessKey);
                        ZDHCPostInCheckReportRequest requestBody = constructRequestBody(
                            inventoryToSend
                        );
                        request.requestBody = requestBody;
                        ZDHCGatewayServiceResponse zdhcResponse = ZDHCGatewayService.makeCallout(
                            request
                        );
                        
                        // process the response and return any errors or a null
                        return processZDHCResponse(zdhcResponse, inventoryToSend);
                    }
                }
                else if(inventoryToSend.Type__c == 'Delivery') {
                   system.debug('inside delivery');
                    if(countDelivery != 0) {
                        system.debug('inside error');
                        return 'Delivered Stock this month and Unit fields are mandatory';
                    }
                    else {
                        // get the access key of the relevant facility manager
                        String userAccessKey = ZDHCGatewayService.getUserAccessKey(
                            inventoryToSend.Facility__r.Facility_Manager__c
                        );
                        
                        // construct and send the request
                        ZDHCGatewayServiceRequest request = constructRequest(userAccessKey);
                        ZDHCPostInCheckReportRequest requestBody = constructRequestBody(
                            inventoryToSend
                        );
                        request.requestBody = requestBody;
                        ZDHCGatewayServiceResponse zdhcResponse = ZDHCGatewayService.makeCallout(
                            request
                        );
                        
                        // process the response and return any errors or a null
                        return processZDHCResponse(zdhcResponse, inventoryToSend);
                    }
                }
            }
            return Label.TC_InCheck_Error_No_Items;
        } catch (Exception e) {
            return e.getMessage();
        }
    }
    
    @TestVisible
    private static ZDHCGatewayServiceRequest constructRequest(
        String userAccessKey
    ) {
        ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
        request.apiName = 'incheckReport';
        request.method = 'POST';
        request.userAccessKey = userAccessKey;
        
        return request;
    }
    
    @TestVisible
    private static ZDHCPostInCheckReportRequest constructRequestBody(
        Inventory__c inventoryToSend
    ) {
        List<ZDHCInCheckReportInventory> lineItems = new List<ZDHCInCheckReportInventory>();
        for (
            Inventory_Line_Item__c item : inventoryToSend.Inventory_Line_Items__r
        ) {
            ZDHCInCheckReportInventory wrappedItem = new ZDHCInCheckReportInventory();
            wrappedItem.productGuid = item.ZDHC_Product_GUID__c;
            wrappedItem.weight = item.Calculated_Usage__c;
            wrappedItem.unit = item.Unit__c == 'lb' ? 'lbs' : item.Unit__c;
            lineItems.add(wrappedItem);
        }
        
        ZDHCPostInCheckReportRequest requestBody = new ZDHCPostInCheckReportRequest();
        requestBody.OrganizationGUID = inventoryToSend.Facility__r.ZDHC_Organisation_GUID__c;
        requestBody.year = inventoryToSend.Inventory_Date__c.year();
        requestBody.month = inventoryToSend.Inventory_Date__c.month();
        requestBody.type = inventoryToSend.Type__c == 'Usage' ? 1 : 2;
        requestBody.inventory = lineItems;
        
        return requestBody;
    }
    
    @TestVisible
    private static String processZDHCResponse(
        ZDHCGatewayServiceResponse zdhcResponse,
        Inventory__c sentInventory
    ) {
        if (zdhcResponse?.isSuccess == true) {
            ZDHCPostInCheckReportResponse responseData = (ZDHCPostInCheckReportResponse) zdhcResponse
                ?.response;
            if (responseData.result.success == true) {
                sentInventory.InCheck_Report_Status__c = 'Success';
                sentInventory.InCheck_Report_Error_Message__c = null;
                sentInventory.InCheck_Report_Verification_Id__c = responseData.verificationId;
                sentInventory.Status__c = 'Submitted';
                sentInventory.Submitted_Date__c = Datetime.now();
                
                update sentInventory;
                return null;
            }
        }
        
        String errorString = zdhcResponse?.errors != null
            ? String.join(zdhcResponse.errors, ', ')
            : Label.TC_InCheck_Generic_Error;
        sentInventory.InCheck_Report_Status__c = 'Error';
        sentInventory.InCheck_Report_Error_Message__c = errorString;
        sentInventory.InCheck_Report_Verification_Id__c = null;
        sentInventory.Status__c = 'Complete';
        sentInventory.Submitted_Date__c = null;
        update sentInventory;
        return errorString;
    }
}