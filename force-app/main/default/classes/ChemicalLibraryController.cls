public with sharing class ChemicalLibraryController {
    public class TestRunException extends Exception {
    }
    
    @AuraEnabled
    public static String getSuppliersForBrand() {
        TC_InventoryConformance context = new TC_InventoryConformance();
        if(context.isBrandUser){
            Set<Id> supplierAccountId = new Set<Id>();   
            String brandAccountId = context.user.Contact?.AccountId;
            List<Brand_Supplier_Connection__c> bsc = [
                SELECT Id, Supplier_Account__c
                FROM Brand_Supplier_Connection__c
                WHERE
                Brand_Account__c = :brandAccountId
                AND Active__c = TRUE
                AND Status__c = 'Approved'
            ];
            for (Brand_Supplier_Connection__c i : bsc) {
                supplierAccountId.add(i.Supplier_Account__c);
            }
            List<Account> suppliersForBrandList = [SELECT Id,Name, Is_ToxClear_Account__c, ToxClear_Account_Type__c, ToxClear_Subscription_Status__c,ParentId 
                                                   FROM Account 
                                                   WHERE ToxClear_Subscription_Status__c = 'Active' AND ToxClear_Account_Type__c = 'Supplier' AND Is_ToxClear_Account__c = true AND Id IN :supplierAccountId];
            if(!suppliersForBrandList.isEmpty()){
                Map<String, Object> suppliersForBrand = new Map<String,Object>{
                    'suppliers' => new List<Map<String,Object>>()
                        };
                            ((List<Map<String,Object>>) suppliersForBrand.get('suppliers')).add(
                                new Map<String, Object>{ 'label' => 'None', 'value' => 'None' }
                            );  
                for(Account acc : suppliersForBrandList){
                    ((List<Map<String,Object>>) suppliersForBrand.get('suppliers')).add(
                        new Map<String, Object>{ 'label' => acc.Name, 'value' => acc.Id }
                    );
                }
                return JSON.serialize(suppliersForBrand);
            }
            else{
                return 'No Active Suppliers are present';
            }  
        }
        else {
            return 'No Active Suppliers are present';
        }
    }
    
    @AuraEnabled
    public static String getSuppliersFacilityList(){
        TC_InventoryConformance context = new TC_InventoryConformance();
        Set<Id> supplierAccountId = new Set<Id>();
        if(context.isSupplierUser) {
            supplierAccountId.add(context.user.Contact?.AccountId); 
        }
        else if(context.isBrandUser) {
            String brandAccountId = context.user.Contact?.AccountId;
            List<Brand_Supplier_Connection__c> bsc = [
                SELECT Id, Supplier_Account__c
                FROM Brand_Supplier_Connection__c
                WHERE
                Brand_Account__c = :brandAccountId
                AND Active__c = TRUE
                AND Status__c = 'Approved'
            ];
            for (Brand_Supplier_Connection__c i : bsc) {
                supplierAccountId.add(i.Supplier_Account__c);
            }
        }
        
        List<Account> suppliersActiveFacilitiesList = [SELECT Id,Name, Is_ToxClear_Account__c, ToxClear_Account_Type__c, ToxClear_Subscription_Status__c,ParentId 
                                                       FROM Account 
                                                       WHERE ToxClear_Subscription_Status__c = 'Active' AND ToxClear_Account_Type__c = 'Facility' AND Is_ToxClear_Account__c = true AND ParentId =:supplierAccountId];
        if(!suppliersActiveFacilitiesList.isEmpty()){
            Map<String, Object> suppliersFacilities = new Map<String,Object>{
                'facilities' => new List<Map<String,Object>>()
                    };
                        ((List<Map<String,Object>>) suppliersFacilities.get('facilities')).add(
                            new Map<String, Object>{ 'label' => 'None', 'value' => 'None' }
                        );  
            for(Account acc : suppliersActiveFacilitiesList){
                ((List<Map<String,Object>>) suppliersFacilities.get('facilities')).add(
                    new Map<String, Object>{ 'label' => acc.Name, 'value' => acc.Id }
                );
            }
            return JSON.serialize(suppliersFacilities); 
        }
        else{
            return 'No Active Facilities are present';
        }
    }
    
    @AuraEnabled
    public static String getFacilityListBySelectedSupplier(String selectedSupplierId){        
        List<Account> suppliersActiveFacilitiesList = [SELECT Id,Name, Is_ToxClear_Account__c, ToxClear_Account_Type__c, ToxClear_Subscription_Status__c,ParentId 
                                                       FROM Account 
                                                       WHERE ToxClear_Subscription_Status__c = 'Active' AND ToxClear_Account_Type__c = 'Facility' AND Is_ToxClear_Account__c = true AND ParentId =:selectedSupplierId];
        if(!suppliersActiveFacilitiesList.isEmpty()){
            Map<String, Object> suppliersFacilities = new Map<String,Object>{
                'facilities' => new List<Map<String,Object>>()
                    };
                        ((List<Map<String,Object>>) suppliersFacilities.get('facilities')).add(
                            new Map<String, Object>{ 'label' => 'None', 'value' => 'None' }
                        );  
            for(Account acc : suppliersActiveFacilitiesList){
                ((List<Map<String,Object>>) suppliersFacilities.get('facilities')).add(
                    new Map<String, Object>{ 'label' => acc.Name, 'value' => acc.Id }
                );
            }
            return JSON.serialize(suppliersFacilities); 
        }
        else{
            return 'No Active Facilities are present';
        }
    }
    
    @AuraEnabled
    public static Boolean getLoggedInUserInfo(){
     TC_InventoryConformance context = new TC_InventoryConformance();
     return context.isBrandUser;
    }
    
    @AuraEnabled
    public static ListResponse getChemicalProducts(
        String facilityId,
        String Productname ,
        Integer recordCount,
        Integer offset
    ) {
        //get the records
        if (offset == null) {
            offset = 0;
        }
        Set<Id> chemicalProductId = new Set<Id>();
        List<Chemical_Product__c> chemicalProductList = new List<Chemical_Product__c>();
        List<Inventory__C> inventoryList = [SELECT Id, Facility__c,(SELECT Id, Chemical_Product__c FROM Inventory_Line_Items__r) FROM Inventory__c WHERE Facility__c =:facilityId];
        for(Inventory__C i : inventoryList){
            for(Inventory_Line_Item__C inv : i.Inventory_Line_Items__r){
                chemicalProductId.add(inv.Chemical_Product__c);
            }
        }
        
        Productname = (Productname != null &&
                       Productname != '')
            ? String.escapeSingleQuotes(Productname)
            : '';
        if(!chemicalProductId.isEmpty()){
            String soqlSelect = 'SELECT ID,Name,Origin__c,Chemical_Product_Name__c,Conformant__c,ZDHC_MRSL_v2_0__c,Formulator__r.Name,Is_Safety_Data_Sheet__c,Is_MRSL_Certificate__c,CreatedDate,Product_Trade_Name_Other_Name__c,Substrate__c,ZDHC_Product_Id__c,ZDHC_Product_GUID__c FROM Chemical_Product__c';
            String soqlFilters = ' WHERE ID IN :chemicalProductId';
            
            soqlFilters += (Productname != null && Productname != '') ? ' AND(Chemical_Product_Name__c LIKE \'%'+ Productname + '%\')': '';
            
            String soql = soqlSelect + soqlFilters;
            soql += ' ORDER BY Name ASC LIMIT ' + recordCount;
            soql += ' OFFSET ' + offset;
            
            
            chemicalProductList = Database.query(soql);
        }
        
        if (!chemicalProductList.isEmpty()) {
            //build response
            return buildResponse(chemicalProductList);
        }
        return null;
    }
    
    @AuraEnabled
    public static ListResponse getConformantChemicalProducts(
        String facilityId,
        String Productname ,
        Boolean conformant ,
        Integer recordCount,
        Integer offset
    ) {
        //get the records
        if (offset == null) {
            offset = 0;
        }
        Set<Id> chemicalProductId = new Set<Id>();
        List<Chemical_Product__c> chemicalProductList = new List<Chemical_Product__c>();
        List<Inventory__C> inventoryList = [SELECT Id, Facility__c,(SELECT Id, Chemical_Product__c FROM Inventory_Line_Items__r) FROM Inventory__c WHERE Facility__c =:facilityId];
        for(Inventory__C i : inventoryList){
            for(Inventory_Line_Item__C inv : i.Inventory_Line_Items__r){
                chemicalProductId.add(inv.Chemical_Product__c);
            }
        }
        
        Productname = (Productname != null &&
                       Productname != '')
            ? String.escapeSingleQuotes(Productname)
            : '';
        if(!chemicalProductId.isEmpty()){
            String soqlSelect = 'SELECT ID,Name,Origin__c,Chemical_Product_Name__c,Conformant__c,ZDHC_MRSL_v2_0__c,Formulator__r.Name,Is_Safety_Data_Sheet__c,Is_MRSL_Certificate__c,CreatedDate,Product_Trade_Name_Other_Name__c,Substrate__c,ZDHC_Product_Id__c,ZDHC_Product_GUID__c FROM Chemical_Product__c';
            String soqlFilters = ' WHERE ID IN :chemicalProductId';
            
            soqlFilters += (Productname != null && Productname != '') ? ' AND(Chemical_Product_Name__c LIKE \'%'+ Productname + '%\')': '';
            soqlFilters += ' AND Conformant__c =' + conformant;
            
            String soql = soqlSelect + soqlFilters;
            soql += ' ORDER BY Name ASC LIMIT ' + recordCount;
            soql += ' OFFSET ' + offset;
            
            
            chemicalProductList = Database.query(soql);
        }
        
        if (!chemicalProductList.isEmpty()) {
            //build response
            return buildResponse(chemicalProductList);
        }
        return null;
    }
    
    @AuraEnabled
    public static ListResponse getSDSChemicalProducts(
        String facilityId,
        String Productname ,
        Boolean safetyDataSheet ,
        Integer recordCount,
        Integer offset
    ) {
        //get the records
        if (offset == null) {
            offset = 0;
        }
        Set<Id> chemicalProductId = new Set<Id>();
        List<Chemical_Product__c> chemicalProductList = new List<Chemical_Product__c>();
        List<Inventory__C> inventoryList = [SELECT Id, Facility__c,(SELECT Id, Chemical_Product__c FROM Inventory_Line_Items__r) FROM Inventory__c WHERE Facility__c =:facilityId];
        for(Inventory__C i : inventoryList){
            for(Inventory_Line_Item__C inv : i.Inventory_Line_Items__r){
                chemicalProductId.add(inv.Chemical_Product__c);
            }
        }
        
        Productname = (Productname != null &&
                       Productname != '')
            ? String.escapeSingleQuotes(Productname)
            : '';
        if(!chemicalProductId.isEmpty()){
            String soqlSelect = 'SELECT ID,Name,Origin__c,Chemical_Product_Name__c,Conformant__c,ZDHC_MRSL_v2_0__c,Formulator__r.Name,Is_Safety_Data_Sheet__c,Is_MRSL_Certificate__c,CreatedDate,Product_Trade_Name_Other_Name__c,Substrate__c,ZDHC_Product_Id__c,ZDHC_Product_GUID__c FROM Chemical_Product__c';
            String soqlFilters = ' WHERE ID IN :chemicalProductId';
            
            soqlFilters += (Productname != null && Productname != '') ? ' AND(Chemical_Product_Name__c LIKE \'%'+ Productname + '%\')': '';
            soqlFilters += ' AND Is_Safety_Data_Sheet__c =' + safetyDataSheet;
            
            String soql = soqlSelect + soqlFilters;
            soql += ' ORDER BY Name ASC LIMIT ' + recordCount;
            soql += ' OFFSET ' + offset;
            
            
            chemicalProductList = Database.query(soql);
        }
        
        if (!chemicalProductList.isEmpty()) {
            //build response
            return buildResponse(chemicalProductList);
        }
        return null;
    }
    
    @AuraEnabled
    public static ListResponse getMrslChemicalProducts(
        String facilityId,
        String Productname ,
        Boolean MRSLCert ,
        Integer recordCount,
        Integer offset
    ) {
        //get the records
        if (offset == null) {
            offset = 0;
        }
        Set<Id> chemicalProductId = new Set<Id>();
        List<Chemical_Product__c> chemicalProductList = new List<Chemical_Product__c>();
        List<Inventory__C> inventoryList = [SELECT Id, Facility__c,(SELECT Id, Chemical_Product__c FROM Inventory_Line_Items__r) FROM Inventory__c WHERE Facility__c =:facilityId];
        for(Inventory__C i : inventoryList){
            for(Inventory_Line_Item__C inv : i.Inventory_Line_Items__r){
                chemicalProductId.add(inv.Chemical_Product__c);
            }
        }
        
        Productname = (Productname != null &&
                       Productname != '')
            ? String.escapeSingleQuotes(Productname)
            : '';
        if(!chemicalProductId.isEmpty()){
            String soqlSelect = 'SELECT ID,Name,Origin__c,Chemical_Product_Name__c,Conformant__c,ZDHC_MRSL_v2_0__c,Formulator__r.Name,Is_Safety_Data_Sheet__c,Is_MRSL_Certificate__c,CreatedDate,Product_Trade_Name_Other_Name__c,Substrate__c,ZDHC_Product_Id__c,ZDHC_Product_GUID__c FROM Chemical_Product__c';
            String soqlFilters = ' WHERE ID IN :chemicalProductId';
            
            soqlFilters += (Productname != null && Productname != '') ? ' AND(Chemical_Product_Name__c LIKE \'%'+ Productname + '%\')': '';
            soqlFilters += ' AND Is_MRSL_Certificate__c =' + MRSLCert;
            
            String soql = soqlSelect + soqlFilters;
            soql += ' ORDER BY Name ASC LIMIT ' + recordCount;
            soql += ' OFFSET ' + offset;
            
            
            chemicalProductList = Database.query(soql);
        }
        
        if (!chemicalProductList.isEmpty()) {
            //build response
            return buildResponse(chemicalProductList);
        }
        return null;
    }
    
    
    
    @TestVisible
    private static ListResponse buildResponse(List<Chemical_Product__c> chemicalProducts) {
        return new ListResponse(
            new DataTable.Table(getColumns(), getRows(chemicalProducts)),
            chemicalProducts.size()
        );
    }
    
    private static List<DataTable.Column> getColumns() {
        List<DataTable.Column> columns = new List<DataTable.Column>{
            new DataTable.Column(
                'Name',
                'Name'
            ),
                new DataTable.Column(
                    'Origin__c',
                    'Origin'
                ),
                new DataTable.Column(
                    'Chemical_Product_Name__c',
                    'Chemical Product'
                ),
                new DataTable.Column(
                    'Formulator_Name__c',
                    'Formulator Name'
                ),
                new DataTable.Column(
                    'Conformant__c', 
                    'Conformant'
                ),
                new DataTable.Column(
                    'ZDHC_MRSL_v2_0__c', 
                    'Conformant Level'
                ),
                new DataTable.Column(
                    'Is_Safety_Data_Sheet__c',
                    'Safety Data Sheet'
                ),
                new DataTable.Column(
                    'Is_MRSL_Certificate__c', 
                    'MRSL Certificate'
                ),
                new DataTable.Column(
                    'CreatedDate', 
                    'Date Created'
                )
                };
                    return columns;
    }
    
    private static List<DataTable.Row> getRows(List<Chemical_Product__c> chemicalProducts) {
        List<DataTable.Row> rows = new List<DataTable.Row>();
        for (Chemical_Product__c cp : chemicalProducts) {
            List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
                new DataTable.Cell(
                    'Name',
                    cp.Name,
                    null,
                    true,
                    false,
                    true,
                    null,
                    'customEvent',
                    null,
                    'Name'
                ),
                    new Datatable.Cell(
                        'Origin__c', 
                        cp.Origin__c, 
                        'Origin'
                    ),
                    new Datatable.Cell(
                        'Chemical_Product_Name__c', 
                        getChemicalDetails(cp), 
                        'Chemical Product'
                    ),
                    new Datatable.Cell(
                        'Formulator__r.Name', 
                        cp.Formulator__r.Name, 
                        'Formulator Name'
                    ),
                    new Datatable.Cell(
                        'Conformant__c', 
                        cp.Conformant__c ? 'Yes' : 'No', 
                        'Conformant'
                    ),
                    new Datatable.Cell(
                        'ZDHC_MRSL_v2_0__c', 
                        cp.ZDHC_MRSL_v2_0__c, 
                        'Conformant Level'
                    ),
                    new Datatable.Cell(
                        'Is_Safety_Data_Sheet__c', 
                        cp.Is_Safety_Data_Sheet__c ? 'Yes' : 'No', 
                        'Safety Data Sheet'
                    ),
                    new Datatable.Cell(
                        'Is_MRSL_Certificate__c', 
                        cp.Is_MRSL_Certificate__c ? 'Yes' : 'No', 
                        'MRSL Certificate'
                    ),
                    new Datatable.Cell(
                        'CreatedDate', 
                        cp.CreatedDate != null
                        ? String.valueOf(cp.CreatedDate.format('yyyy-MM-dd'))
                        : '',
                        'Date Created'
                    )
                    };
                        rows.add(new DataTable.Row(cp.Id, rowCells));
        }
        return rows;
    }
    
    @TestVisible
    private static String getChemicalDetails(Chemical_Product__c ChemicalProduct) {
        List<String> fieldValues = new List<String>{
            ChemicalProduct.Chemical_Product_Name__c,
                ChemicalProduct.Formulator__r.Name,
                ChemicalProduct.Product_Trade_Name_Other_Name__c,
                ChemicalProduct.Substrate__c,
                ChemicalProduct.ZDHC_MRSL_v2_0__c,
                ChemicalProduct.ZDHC_Product_Id__c,
                ChemicalProduct.ZDHC_Product_GUID__c
                };
                    return String.join(fieldValues, ' ');
    }
}