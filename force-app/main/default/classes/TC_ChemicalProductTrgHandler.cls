public without sharing class TC_ChemicalProductTrgHandler extends TriggerHandler {
    public override void beforeInsert() {
        setOrigin((List<Chemical_Product__c>) Trigger.new);
    }
    public override void afterInsert() {
        setOriginForSupplier((List<Chemical_Product__c>) Trigger.new);
    }
    
    /**
* setOrigin to 'Intertek' when created by Internal users:
*  o ToxClear Intertek Back Office Administrator
*  o ToxClear Customer Service Representatives
* @param products (List<Chemical_Product__c>): All chemical products to
* conditionally set the origin for.
*/
    @TestVisible
    private static void setOrigin(List<Chemical_Product__c> products) {
        Set<Id> internalUserIds = internalUsers();
        
        for (Chemical_Product__c p : products) {
            if (internalUserIds.contains(p.OwnerId)) {
                p.Origin__c = 'Intertek';
            }
        }
    }
    
    @TestVisible
    private static void setOriginForSupplier(List<Chemical_Product__c> products) {
        Set<Id> externalUserIds = new Set<Id>();
        Set<Id> ownerId = new Set<Id>();
        Set<Id> productId = new Set<Id>();
        
        for(Chemical_Product__c p : products){
            productId.add(p.Id);
            ownerId.add(p.OwnerId);
        }
        
        List<Chemical_Product__c> chemicalProductList = [SELECT Id,Origin__c,OwnerId FROM Chemical_Product__c Where ID IN :productId];
        List<Chemical_Product__c> chemicalProductListToUpdate = new List<Chemical_Product__c>();
        
        if(!ownerId.isEmpty()){
            Set<Id> chemicalProductOwnersIdOnlyPortal = new Map<Id,User>([
                SELECT Id,ContactId,IsActive 
                FROM User 
                WHERE ContactId != null AND IsActive = true AND ID IN :ownerId]).keyset();
            
            if(!chemicalProductOwnersIdOnlyPortal.isEmpty()){
                externalUserIds = TC_ChemicalProductTrgHandler.externalUsers(chemicalProductOwnersIdOnlyPortal); 
            }
        }
        
        for (Chemical_Product__c p : chemicalProductList) {
            if(externalUserIds.contains(p.OwnerId)){
                if(p.Origin__c == 'ZDHC Gateway'){
                    p.Origin__c = 'ZDHC Gateway'; 
                }
                else if(p.Origin__c == 'Intertek'){
                    p.Origin__c = 'Intertek';
                }
                else if(p.Origin__c == null || p.Origin__c == 'Supplier'){
                    p.Origin__c = 'Supplier';
                }
                chemicalProductListToUpdate.add(p);
            }
        }
        update chemicalProductListToUpdate; 
    }
    
    @TestVisible
    private static Set<Id> internalUsers() {
        Set<Id> userIds = new Set<Id>();
        Map<Id, PermissionSetGroup> internalGroups = new Map<Id, PermissionSetGroup>(
            [
                SELECT Id
                FROM PermissionSetGroup
                WHERE
                DeveloperName IN (
                    'ToxClear_Intertek_Back_Office_Administrator',
                    'ToxClear_Customer_Services_Representatives',
                    'ToxClear_Internal_Light_No_Case_Access'
                )
                AND Status = 'Updated'
            ]
        );
        List<PermissionSetAssignment> psa = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSetGroupId IN :internalGroups.keySet()
        ];
        for (PermissionSetAssignment a : psa) {
            userIds.add(a.AssigneeId);
        }
        return userIds;
    }
    
    @TestVisible
    private static Set<Id> externalUsers(Set<Id> externalSupplierUsersId) {
        Set<Id> userIds = new Set<Id>();
        Map<Id, PermissionSetGroup> externalGroups = new Map<Id, PermissionSetGroup>(
            [
                SELECT Id
                FROM PermissionSetGroup
                WHERE
                DeveloperName IN (
                    'ToxClear_Supplier_Administrator',
                    'ToxClear_Supplier_Standard_User'
                )
                AND Status = 'Updated'
            ]
        );
        List<PermissionSetAssignment> psa = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSetGroupId IN :externalGroups.keySet() AND AssigneeId IN :externalSupplierUsersId
        ];
        for (PermissionSetAssignment a : psa) {
            userIds.add(a.AssigneeId);
        }
        return userIds;
    }
}