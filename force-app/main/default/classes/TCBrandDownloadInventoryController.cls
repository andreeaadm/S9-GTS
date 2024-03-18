public with sharing class TCBrandDownloadInventoryController {
    public static String csvDelimeter = ',';
    public static String csvNewLine = '\n';
    public static Map<String, String> fieldPathVsTypeMap;
    
    
    @AuraEnabled
    public static TCBrandDownloadInventoryWrapper getDataForDownload(Id inventoryId) {
        try {
            User user = [
                SELECT Contact.AccountId, Contact.Account.ToxClear_Account_Type__c,
                Contact.Account.Brand_Working_With__c, Contact.Account.Parent.Brand_Working_With__c 
                FROM User
                WHERE
                Id = :UserInfo.getUserId()
                AND (Contact.Account.ToxClear_Account_Type__c = 'Brand'
                     OR Contact.Account.ToxClear_Account_Type__c = 'Supplier'
                     OR Contact.Account.ToxClear_Account_Type__c = 'Facility')
            ];
            
            Id accountId = user.Contact.AccountId;
            String brand = user.Contact.Account.Brand_Working_With__c;

            Brand_Query__mdt queryMdt = [SELECT Brand__c, FieldSet_Name__c, Column_Name__c 
                                         FROM Brand_Query__mdt 
                                         WHERE Brand__c = :brand];
            
            String csvHeaders = queryMdt.Column_Name__c;
            System.debug('QueryMdt:: '+queryMdt);
            
            List<Brand_Inventory_Product__mdt> brandInventoryProducts = [SELECT Product_GUID__c, Formulator_Name__c, MasterLabel
                                                                         FROM Brand_Inventory_Product__mdt 
                                                                         WHERE Brand__c = :brand 
                                                                         AND Active__c = True];

            Map<String, String> productNamevsFormulatorName = new Map<String, String>();
            Map<String, Brand_Inventory_Product__mdt> BrandProductMap = new Map<String, Brand_Inventory_Product__mdt> ();
            for(Brand_Inventory_Product__mdt invProd :brandInventoryProducts){
                productNamevsFormulatorName.put(invProd.MasterLabel, invProd.Formulator_Name__c);
                BrandProductMap.put(invProd.MasterLabel.toLowerCase(), invProd);
            }
            fieldPathVsTypeMap = SchemaUtil.getQueryableFieldsFromFieldSet('Inventory_Line_Item__c', queryMdt.FieldSet_Name__c.toLowerCase());
            List<String> queryFields = new List<String>(fieldPathVsTypeMap.keySet());
            
            String queryDefaultFields = ',Inventory__r.Facility__r.Parent.Name,Inventory__r.Facility__r.Name,Inventory__r.Inventory_Name__c, Chemical_Product_Name__c,Formulator_Name__c ';
            String queryFrom = ' FROM Inventory_Line_Item__c ';
            String queryString = 'SELECT ' + String.join(queryFields, ',') + queryDefaultFields + queryFrom + ' WHERE Inventory__c = :inventoryId  ';
            if (user.Contact.Account.ToxClear_Account_Type__c == 'Supplier') {
                queryString += ' AND Inventory__r.Facility__r.ParentId = :accountId';
            } else if (user.Contact.Account.ToxClear_Account_Type__c == 'Facility') {
                queryString += ' AND Inventory__r.Facility__c = :accountId';
            }
            System.debug('Query: '+queryString);
            
            
            List<Inventory_Line_Item__c> querylineItems = Database.query(queryString);
            System.debug('Queryrecord: '+querylineItems.size());
            List<Inventory_Line_Item__c> lineItems = new List<Inventory_Line_Item__c>();
            for(Inventory_Line_Item__c lineItem : querylineItems){
                        List<String> productNameList = lineItem.Chemical_Product_Name__c.toLowerCase().split(' ');
                        system.debug('ProductNameList===='+productNameList);
                if(BrandProductMap.containskey(lineitem.Chemical_Product_Name__c.toLowerCase())){
                  lineItem.Product_Name__c = BrandProductMap.get(lineitem.Chemical_Product_Name__c.toLowerCase()).MasterLabel;
                    if(lineItem.Formulator_Name__c.containsIgnoreCase(BrandProductMap.get(lineitem.Chemical_Product_Name__c.toLowerCase()).Formulator_Name__c)){
                      lineItem.Formulator__c = BrandProductMap.get(lineitem.Chemical_Product_Name__c.toLowerCase()).Formulator_Name__c;
                      lineItems.add(lineItem);
                    }else if (lineItem.Formulator_Name__c.replaceAll('\\s+','').containsIgnoreCase(BrandProductMap.get(lineItem.Chemical_Product_Name__c.toLowerCase()).Formulator_Name__c.replaceAll('\\s+',''))){
                      lineItem.Formulator__c =  BrandProductMap.get(lineItem.Chemical_Product_Name__c.toLowerCase()).Formulator_Name__c;
                      lineItems.add(lineItem);
                    }
                }else{
                for(String productName : productNamevsFormulatorName.keySet()){
                  System.debug('Productname - Meta ==='+productName.toLowerCase());
                  if((!productName.contains(' ') && productNameList.contains(productName.toLowerCase())) || (productName.contains(' ') && lineItem.Chemical_Product_Name__c.toLowerCase().startsWith(productName.toLowerCase()))){
                    lineItem.Product_Name__c = productName;
                    system.debug('ProductName Selected ----'+productName);
                    if(lineItem.Formulator_Name__c.containsIgnoreCase(productNamevsFormulatorName.get(productName))){
                      lineItem.Formulator__c = productNamevsFormulatorName.get(productName);
                      system.debug('ProductName Selected in if -1 ----'+productName);
                      system.debug('Formulator Selected in if -1 ----'+productNamevsFormulatorName.get(productName));
                      lineItems.add(lineItem);
                    }else if(lineItem.Formulator_Name__c.replaceAll('\\s+','').containsIgnoreCase(productNamevsFormulatorName.get(productName).replaceAll('\\s+',''))){
                      lineItem.Formulator__c = productNamevsFormulatorName.get(productName);
                      system.debug('ProductName Selected in if -2 ----'+productName);
                      system.debug('Formulator Selected in if -2 ----'+productNamevsFormulatorName.get(productName));
                      lineItems.add(lineItem);
                    }
                    break;
                  }
                } 
              }
            }
            if (lineItems.size() > 0) {
                TCBrandDownloadInventoryWrapper wrapper = new TCBrandDownloadInventoryWrapper();
                wrapper.supplierName = lineItems[0].Inventory__r.Facility__r.Parent.Name;
                wrapper.facilityName = lineItems[0].Inventory__r.Facility__r.Name;
                wrapper.inventoryName = lineItems[0].Inventory__r.Inventory_Name__c;
                wrapper.csvFile = csvHeaders + csvNewLine + processInventoryLineItems(lineItems, queryFields);
                System.debug('Wrapper: '+wrapper);
                return wrapper;
            } else {
                return new TCBrandDownloadInventoryWrapper();
            }
        } catch (QueryException qe) {
            System.debug('Error: '+qe);
            throw new AuraHandledException(Label.TC_Download_Error_No_Items);
        } catch (Exception e) {
            System.debug('Exception: '+e);
            throw new AuraHandledException(Label.TC_Download_Inventory_Error);
        }
    }
    
    public static String processInventoryLineItems(List<SObject> lineItem, List<String> fields){
        String csvRows = '';
        for(SObject record :lineItem){
            for(String field :fields){
                String fieldType = fieldPathVsTypeMap.get(field);
                csvRows += StringUtil.formatForCsv(manipulateValue(String.valueOf(getValue(record, field)), fieldType)) + csvDelimeter;
            }
            csvRows += csvNewLine;
        }
        return csvRows;
    }
    
    
    public static Object getValue(SObject record, String path) {
        try {
            SObject temp = record;
            String[] parts = path.split('\\.');
            while(parts.size() > 1) {
                temp = temp.getSObject(parts.remove(0));
            }
            return temp.get(parts[0]);
        } catch(Exception e) {
            return null;
        }
    }
    
    public static String manipulateValue(String value, String type){
        if(type == 'DATE'){
            value = Datetime.valueOf(value).format('MM-dd-yyyy');
        }
        return value;
    }
    
    
    
    public class TCBrandDownloadInventoryWrapper{
        @AuraEnabled
        public String supplierName;
        @AuraEnabled
        public String facilityName;
        @AuraEnabled
        public String inventoryName;
        @AuraEnabled
        public String csvFile;
    }
}