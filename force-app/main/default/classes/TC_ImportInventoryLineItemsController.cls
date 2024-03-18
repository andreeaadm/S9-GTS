/******************************************************************************
Created Date: 2022 by Oegen
@description: controller class to create inventory line items from CSV and update product details on them.
@author: Oegen
Modification History:
Ver			Date			Author			Modification
1			3 Jan 2024		Akshay			Added new method to improve line item update process
******************************************************************************/
public with sharing class TC_ImportInventoryLineItemsController {
    @AuraEnabled
    public static APIResponse importLineItems(
        String settingName,
        String base64,
        String parentId
    ) {
        APIResponse response;
        // Set a savepoint so that we can undo the Inventory Line Items import if Chemical Product linking fail on any rows
        Savepoint sp = Database.setSavepoint();
        try {
            // import Inventory Line Items
            response = CSVImportController.doImport(settingName, base64, parentId);
        } catch (Exception e) {
            return new APIResponse(
                'Bad Request',
                400,
                new List<String>{ label.TC_General_Import_Error }
            );
        }
        
        // if there were any errors, return immediately
        if (response.statusCode == 400) {
            Database.rollback(sp);
            return response;
        }
        
        // Try to link to the new Inventory Line Items to Chemical Products in Salesforce. ZDHC_Product_GUID__c is the external Id field on Chemical_Product__c and it's required on CSV import.
        Set<String> chemicalProductGUIDs = new Set<String>();
        Set<Id> inventoryLineItemIds = new Set<Id>();
        List<Inventory_Line_Item__c> lineItems = new List<Inventory_Line_Item__c>(
            (List<Inventory_Line_Item__c>) response.objList
        );
        for (Inventory_Line_Item__c lineItem : lineItems) {
            lineItem.Chemical_Product__r = new Chemical_Product__c(
                ZDHC_Product_GUID__c = String.valueOf(
                    lineItem.get('ZDHC_Product_GUID__c')
                )
            );
            chemicalProductGUIDs.add(lineItem.ZDHC_Product_GUID__c);
            inventoryLineItemIds.add(lineItem.Id);
        }
        try {
            update lineItems;
        } catch (DmlException e) {
            Database.rollback(sp);
            response.status = 'Bad Request';
            response.statusCode = 400;
            for (Integer i = 0; i < e.getNumDml(); i++) {
                response.messages.add(
                    '[Row ' +
                    (e.getDmlIndex(i) + 1) +
                    '] ' +
                    label.TC_Chemical_Product_Does_Not_Exist.replace(
                        '{}',
                        lineItems[e.getDmlIndex(i)].ZDHC_Product_GUID__c
                    )
                );
            }
            return response;
        }
        getLatestProductDetailsFromGateway(chemicalProductGUIDs);
        return response;
    }
    
    /******************************************************************************
Created Date: 3 Jan 2024
@description: updates created line item records with its related chemical product data only for product GUIDs added in CSV to import
@author: Akshay
@param: chemicalProductGUIDs (Set<String>)
@return: NA
Modification History:
Ver			Date			Author			Modification
1			3 Jan 2024		Akshay			NA
******************************************************************************/
    
    @future(callout=true)
    public static void getLatestProductDetailsFromGateway(Set<String> chemicalProductGUIDs) {
        String userAccessKey;
        
        //Fetching ZDHC User Access Key from Custom Metadata based on environment
        if(OrgUtil.isProduction()){
            userAccessKey = ZDHC_Access_Key__mdt.getInstance('Sync_Chemical_Products_Key_PROD').ZDHC_User_Access_Key__c; 
        }
        else if(OrgUtil.isSandbox()){
            userAccessKey = ZDHC_Access_Key__mdt.getInstance('Sync_Chemical_Products_Key_SB').ZDHC_User_Access_Key__c;  
        }
        
        List<Chemical_Product__c> productsToBeUpdated = new List<Chemical_Product__c>();
        List<Chemical_Product__c> productsToBeUpdatedButNotFound = new List<Chemical_Product__c>();
        List<Chemical_Product__c> chemicalProductsList = [SELECT Id,Origin__c,ZDHC_Product_GUID__c,Chemical_Product_Name__c,Product_Trade_Name_Other_Name__c,
                                                          Product_Status__c,ZDHC_Product_Code__c,ZDHC_PID__c,Registered__c,ZDHC_Product_Id__c,Last_Verified_Date__c,ZDHC_Certification_JSON__c,
                                                          Other_Certifications__c,ZDHC_MRSL_v2_0__c,ZDHC_MRSL_Version__c,ZDHC_Formulator_GUID__c,Formulator__c,Formulator__r.Name,
                                                          (SELECT Id,Origin__c, ZDHC_MRSL_v2_0__c,ZDHC_MRSL_Version__c, Other_Certifications__c,ZDHC_Certification_JSON__c, ZDHC_Product_GUID__c, ZDHC_Product_Id__c 
                                                           FROM Inventory_Line_Items__r 
                                                           WHERE Inventory__r.Status__c = 'Pending' AND (Inventory__r.Inventory_Date__c = LAST_MONTH OR Inventory__r.Inventory_Date__c = THIS_MONTH))
                                                          FROM Chemical_Product__c 
                                                          WHERE ZDHC_Product_GUID__c IN: chemicalProductGUIDs];
        List<ZDHC_Error_Log__c> errorLogs = new List<ZDHC_Error_Log__c>();
        
        for (Chemical_Product__c product : chemicalProductsList) {
            
            Try{
                
                ZDHCGetProducts zdhcGetProducts = new ZDHCGetProducts(
                    errorLogs,
                    userAccessKey,
                    new Map<String, Object>{ 'productGUID' => product.ZDHC_Product_GUID__c }
                );
                if(zdhcGetProducts.call()) {
                    productsToBeUpdated.addAll(compareProductsWithZDHCData(product, zdhcGetProducts.response.data[0]));  
                }
                else {
                    product.Last_Verified_Date__c = Datetime.now();
                    product.ZDHC_Status__c = 'Error';
                    product.Product_Status__c = 'Deactivated';
                    productsToBeUpdatedButNotFound.add(product);
                }
            }
            catch (Exception e) {
                System.debug((e.getMessage() + '\n' + e.getStackTraceString()));
            }
        }
        productsToBeUpdated.addAll(productsToBeUpdatedButNotFound);
        update productsToBeUpdated;
        updateRelatedLineItems(productsToBeUpdated);
    }
    
    public static List<Chemical_Product__c> compareProductsWithZDHCData(Chemical_Product__c local,ZDHCGetProductsResponseData remote){
        List<Chemical_Product__c> productsToBeUpdated = new List<Chemical_Product__c>();
        Map<Id, Formulator__c> formulatorNameUpdated = new Map<Id, Formulator__c>();
        String certificationJson = remote.ProductCertifications != null
            ? JSON.serialize(remote.ProductCertifications, true)
            : null;
        Integer changes = 0;
        //update the ZDHC status
        local.Last_Verified_Date__c = Datetime.now();
        local.ZDHC_Status__c = 'Success';
        
        if (local.Product_Status__c == 'Deactivated') {
            local.Product_Status__c = 'Active';
            changes++;
        }
        if (local.Chemical_Product_Name__c != remote.productName) {
            local.Chemical_Product_Name__c = remote.productName;
            changes++;
        }
        if (local.Product_Trade_Name_Other_Name__c != remote.OtherName) {
            local.Product_Trade_Name_Other_Name__c = remote.OtherName;
            changes++;
        }
        if (local.ZDHC_Product_Code__c != remote.productCode) {
            local.ZDHC_Product_Code__c = remote.productCode;
            changes++;
        }
        if (local.ZDHC_PID__c != remote.zdhcPID) {
            local.ZDHC_PID__c = remote.zdhcPID;
            changes++;
        }
        if (local.Registered__c != remote.registered) {
            local.Registered__c = remote.registered;
            changes++;
        }
        if (local.ZDHC_Product_Id__c != remote.ProductID) {
            local.ZDHC_Product_Id__c = remote.ProductID;
            changes++;
        }
        if (local.ZDHC_Formulator_GUID__c != remote.formulatorGUID) {
            local.ZDHC_Formulator_GUID__c = remote.formulatorGUID;
            changes++;
        }
        if (local.ZDHC_Certification_JSON__c != certificationJson) {
            local.ZDHC_Certification_JSON__c = certificationJson;
            changes++;
        }
        if (remote.ProductCertifications != null) {
            Map<String, String> parsed = TC_ParseProductCertifications.parse(
                remote.ProductCertifications
            );
            
            if(parsed.get('mrsl2') == 'Level 1' || parsed.get('mrsl2') == 'Level 2' || parsed.get('mrsl2') == 'Level 3'){
                local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
                local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v2.0';
                changes++;
            }
            if(parsed.get('mrsl2') == 'Expired'){
                local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
                local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v2.0';
                changes++;
            }
            if(parsed.get('mrsl2') == 'Registered'){
                local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
                local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v2.0';
                changes++;
            }
            
            if(parsed.get('mrsl3') == 'Level 1' || parsed.get('mrsl3') == 'Level 2' || parsed.get('mrsl3') == 'Level 3'){
                local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl3');
                local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v3.1';
                changes++;
            }
            if(parsed.get('mrsl3') == 'Expired'){
                if(parsed.get('mrsl2') == 'Level 1' || parsed.get('mrsl2') == 'Level 2' || parsed.get('mrsl2') == 'Level 3'){
                    local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
                    local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v2.0';
                    changes++;
                }
                else{
                    local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl3');
                    local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v3.1';
                    changes++;
                }
            }
            if(parsed.get('mrsl3') == 'Registered'){
                if(parsed.get('mrsl2') == 'Level 1' || parsed.get('mrsl2') == 'Level 2' || parsed.get('mrsl2') == 'Level 3'){
                    local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
                    local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v2.0';
                    changes++;
                }
                else{
                    local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl3');
                    local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v3.1';
                    changes++;
                }
            }   
            if(parsed.get('mrsl3') == null && parsed.get('mrsl2') == null){
                local.ZDHC_MRSL_v2_0__c = '-';
                local.ZDHC_MRSL_Version__c = '-';
                changes++;
            }
            if (
                local.Other_Certifications__c != parsed.get('otherCertifications')
            ) {
                local.Other_Certifications__c = parsed.get('otherCertifications');
                changes++;
            }
            if((parsed.get('mrsl2') == 'Level 1' || parsed.get('mrsl2') == 'Level 2' || parsed.get('mrsl2') == 'Level 3') &&
               (parsed.get('mrsl3') == 'Level 1' || parsed.get('mrsl3') == 'Level 2' || parsed.get('mrsl3') == 'Level 3')
              ){
                  local.Other_Certifications__c += '\r\n ZDHC MRSL v2.0 - ' + parsed.get('mrsl2');
              } 
            
        } else {
            // No certifications.
            local.ZDHC_MRSL_v2_0__c = '-';
            local.ZDHC_MRSL_Version__c = '-';
            changes++;
            if (local.Other_Certifications__c != null) {
                local.Other_Certifications__c = null;
                changes++;
            }
        }
        if (local.ZDHC_Formulator_GUID__c != remote.formulatorGUID) {
            // I doubt this ever changes, as it identifies that record.
            // If this does change, a new Formulator__c will need creating.
            local.ZDHC_Formulator_GUID__c = remote.formulatorGUID;
            changes++;
        } else if (
            local.Formulator__c != null &&
            local.Formulator__r.Name != remote.formulatorName.trim() &&
            !formulatorNameUpdated.containsKey(local.Formulator__c)
        ) {
            // Same Formulator__c, but the Name updated.
            formulatorNameUpdated.put(
                local.Formulator__c,
                new Formulator__c(
                    Id = local.Formulator__c,
                    Name = remote.formulatorName.trim()
                )
            );
        }
        if (changes > 0) {
            productsToBeUpdated.add(local);
        }
        else {
            productsToBeUpdated.add(local);
        }
        return productsToBeUpdated;
    }
    
    public static void updateRelatedLineItems(List<Chemical_Product__c> products) {
        List<Inventory_Line_Item__c> lineItemsToUpdate = new List<Inventory_Line_Item__c>();
        for (Chemical_Product__c cp : products) {
            for (Inventory_Line_Item__c ili : cp.Inventory_Line_Items__r) {
                if (
                    ili.ZDHC_Product_GUID__c != cp.ZDHC_Product_GUID__c ||
                    ili.ZDHC_Product_Id__c != cp.ZDHC_Product_Id__c ||
                    ili.ZDHC_MRSL_v2_0__c != cp.ZDHC_MRSL_v2_0__c ||
                    ili.Other_Certifications__c != cp.Other_Certifications__c ||
                    ili.ZDHC_MRSL_Version__c != cp.ZDHC_MRSL_Version__c ||
                    ili.ZDHC_Certification_JSON__c != cp.ZDHC_Certification_JSON__c ||
                    ili.Origin__c != cp.Origin__c  
                ) {
                    ili.ZDHC_Product_GUID__c = cp.ZDHC_Product_GUID__c;
                    ili.ZDHC_Product_Id__c = cp.ZDHC_Product_Id__c;
                    ili.ZDHC_MRSL_v2_0__c = cp.ZDHC_MRSL_v2_0__c;
                    ili.Other_Certifications__c = cp.Other_Certifications__c;
                    ili.ZDHC_MRSL_Version__c = cp.ZDHC_MRSL_Version__c;
                    ili.ZDHC_Certification_JSON__c = cp.ZDHC_Certification_JSON__c;
                    ili.Origin__c = cp.Origin__c;
                    lineItemsToUpdate.add(ili);
                }
            }
        }
        update lineItemsToUpdate;
    }
}