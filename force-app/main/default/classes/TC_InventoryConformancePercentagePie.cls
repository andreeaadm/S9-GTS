public with sharing class TC_InventoryConformancePercentagePie extends ChartDataProvider {
    /**
* getOptions Builds the tree of options.
*            Includes special case 'ALL'.
*
* @return ChartDataProvider.ChartOption: JSON style objects and arrays of objects.
* {
*   "label": "Supplier: / Facility:",
*   "field": "recordId",   // key value to set in parameters for apex call
*   "options": [
*      { "label": "Account Name",
*        "value": "recordId",
*        "selector": {
*            "label": "Month",
*            "field": "month"    // key value to set in parameters for apex call
*            "options": [
*               { "label": "January 2022", "value": -1 },
*               { "label": "December 2021", "value": -2 },
*               { ... }
*            ]
*         }
*      },
*      { ... }
*   ]
* }
*/
    public virtual override ChartDataProvider.ChartOption getOptions(
        Object parameter
    ) {
        final Date startOfMonth = Date.today().toStartOfMonth();
        final Date startOfNextMonth = startOfMonth.addMonths(1);
        final Date oldestMonthLimit = startOfMonth.addMonths(-23);
        final Time midnight = Time.newInstance(0, 0, 0, 0);
        
        TC_InventoryConformance context = new TC_InventoryConformance();
        // For the user type contexts:
        // * As a Brand Administrator or Brand Standard User, I'm interested in all my suppliers' active facilities.
        // * As a Supplier Administrator, I'm interested in all my supplier's active facilities.
        // getSuppliers returns the relevant records matching facilities.
        Map<Id, Account> suppliers = context.isBrandUser ||
            (context.isSupplierAdminUser  &&
             context.user.Contact?.Account?.ToxClear_Account_Type__c == 'Supplier')
            ? new Map<Id, Account>(context.getSuppliers())
            : null;
        // * As a Supplier Standard User, I'm interested in this one main facility.
        // getFacilities returns the relevant objects, for either contexts optionally with the suppliers Id keySet.
        Map<Id, Account> facilities = new Map<Id, Account>(
            context.getFacilities(null, suppliers != null ? suppliers.keySet() : null,null,null)
        );
        if (facilities.size() == 0) {
            return new ChartDataProvider.ChartOption(); // Nothing to query. No results.
        }
        
        List<Inventory__c> inventories = context.getInventories(
            facilities.keySet(),
            oldestMonthLimit,
            startOfNextMonth
        );
        
        final Map<String, Map<String, Inventory__c>> groupByAccountMonthly = new Map<String, Map<String, Inventory__c>>();
        groupByAccountMonthly.put('ALL', new Map<String, Inventory__c>());
        final Map<String, Inventory__c> allByMonths = groupByAccountMonthly.get(
            'ALL'
        );
        // Group the values hierarchically, by Account, then by month.
        for (Inventory__c i : inventories) {
            Id recordId = context.isBrandUser
                ? i.Facility__r.ParentId // supplierId
                : i.Facility__c; // facilityId
            if (!groupByAccountMonthly.containsKey(recordId)) {
                groupByAccountMonthly.put(
                    String.valueOf(recordId),
                    new Map<String, Inventory__c>()
                );
            }
            String month = String.valueOf(
                startOfMonth.monthsBetween(i.Inventory_Date__c.toStartOfMonth())
            );
            Map<String, Inventory__c> groupByMonth = groupByAccountMonthly.get(
                recordId
            );
            if (!groupByMonth.containsKey(month)) {
                // Even if there are more than one for this month, only need to track one.
                groupByMonth.put(month, i);
            }
            if (!allByMonths.containsKey(month)) {
                allByMonths.put(month, i);
            }
        }
        
        // Build the options.
        // Brand users are intrested in Suppliers.
        // Supplier users are interested in Facilities.
        ChartDataProvider.ChartOption account = new ChartDataProvider.ChartOption(
            context.isBrandUser ? Label.Filter_Supplier : Label.Filter_Facility,
            context.isBrandUser || context.isSupplierAdminUser
            ? 'ALL' // Default to 'All Suppliers' or 'All Facilities'
            : facilities.values()[0].Id, // Default to be only interested in their main facility.
            'recordId',
            'SelectList',
            new List<ChartDataProvider.ChartOption>()
        );
        Map<Id, Account> accounts = context.isBrandUser ? suppliers : facilities;
        for (String recordId : groupByAccountMonthly.keySet()) {
            ChartDataProvider.ChartOption months = new ChartDataProvider.ChartOption(
                Label.Filter_Month,
                '0',
                'month',
                'SelectList',
                new List<ChartDataProvider.ChartOption>()
            );
            for (Integer i = 0; i > -24; i--) {
                String monthKey = String.valueOf(i);
                if (
                    groupByAccountMonthly.get(recordId).containsKey(monthKey) || i == 0
                ) {
                    String label = Datetime.newInstance(
                        startOfMonth.addMonths(i),
                        midnight
                    )
                        .format('MMMM YYYY');
                    months.options.add(
                        new ChartDataProvider.ChartOption(label, monthKey)
                    );
                }
            }
            if (recordId == 'ALL') {
                if (context.isBrandUser || context.isSupplierAdminUser) {
                    // Only include ALL option for Brand Administrators, Brand Standard Users and Supplier Administrators.
                    account.options.add(
                        new ChartDataProvider.ChartOption(
                            context.isBrandUser ? Label.All_Suppliers : Label.All_Facilities,
                            'ALL',
                            months
                        )
                    );
                }
            } else {
                Account a = accounts.get(recordId);
                account.options.add(
                    new ChartDataProvider.ChartOption(a.Name, a.Id, months)
                );
            }
        }
        return account;
    }
    
    @AuraEnabled
    public static String getSupplierLocationsList(){
        try{
            final Date startOfMonth = Date.today().toStartOfMonth();
            final Date startOfNextMonth = startOfMonth.addMonths(1);
            final Date oldestMonthLimit = startOfMonth.addMonths(-23);
            TC_InventoryConformance context = new TC_InventoryConformance();
            if(context.isBrandUser){
                Map<Id, Account> suppliers = context.isBrandUser
                    ? new Map<Id, Account>(context.getSuppliers())
                    : null;
                Map<Id, Account> facilities = new Map<Id, Account>(
                    context.getFacilities(null, suppliers != null ? suppliers.keySet() : null, null,null)
                );
                Map<Id,Account> suppliersWithFacilities = new Map<Id,Account>();
                List<Inventory__c> inventories = context.getInventories(
                    facilities.keySet(),
                    oldestMonthLimit,
                    startOfNextMonth
                );
                for(Inventory__c i : inventories){
                    Id recordId = context.isBrandUser
                        ? i.Facility__r.ParentId // supplierId
                        : null;
                    if (!suppliersWithFacilities.containsKey(recordId)) {
                        suppliersWithFacilities.put(
                            recordId,
                            suppliers.get(recordId)
                        );
                    }
                }
                if (facilities.size() == 0) {
                    return 'Data Not Available';
                }
                else {
                    Map<String,List<Account>> suppliersByLocation = new Map<String,List<Account>>();
                    suppliersByLocation.put('All Locations',new List<Account>());
                    List<Account> locationWithTheirSuppliers = new List<Account>();
                    if(!suppliersWithFacilities.isEmpty()){
                        for(Id supplierId : suppliersWithFacilities.keySet()){
                            if(suppliersByLocation.get(suppliersWithFacilities.get(supplierId).Country__c) == NULL){
                                suppliersByLocation.put(suppliersWithFacilities.get(supplierId).Country__c,new List<Account>()); 
                            }
                            suppliersByLocation.get(suppliersWithFacilities.get(supplierId).Country__c).add(suppliersWithFacilities.get(supplierId));
                        } 
                    }
                    Map<String, Object> supplierLocations = new Map<String,Object>{
                        'locations' => new List<Map<String,Object>>(),
                            'fieldId' => 'location',
                            'value' => 'All'
                            }; 
                                
                                for(String loc : suppliersByLocation.KeySet()){
                                    ((List<Map<String,Object>>) supplierLocations.get('locations')).add(
                                        new Map<String, Object>{ 'label' => loc, 'value' => loc }
                                    );
                                }
                    return JSON.serialize(supplierLocations);  
                }
            }
            else{
                return 'Data Not Available';
            }
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getSupplierTypeList(){
        TC_InventoryConformance context = new TC_InventoryConformance();
        if(context.isBrandUser){
            //get types of Suppliers
            Map<String, Object> supplierType = new Map<String, Object>{
                'supplierTypes' => new List<Map<String,Object>>(),
                    'fieldId' => 'supplierType',
                    'value' => 'All'
                    };
                        ((List<Map<String, Object>>) supplierType.get('supplierTypes'))
                        .add(
                            new Map<String, Object>{
                                'label' => 'All Types',
                                    'value' => 'All Types'
                                    }
                        );
            
            
            Schema.DescribeFieldResult fieldResult = Account.Type_of_Supplier__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                ((List<Map<String, Object>>) supplierType.get('supplierTypes'))
                .add(
                    new Map<String, Object>{
                        'label' => pickListVal.getLabel(),
                            'value' => pickListVal.getValue()
                            }
                );
            } 
            
            return JSON.serialize(supplierType);
        }
        else{
            return 'Data Not Available';
        }
    }
    
    @AuraEnabled
    public static String getInventoryTypeList() {
        TC_InventoryConformance context = new TC_InventoryConformance();
        if(context.isBrandUser) {
            //get inventory types
            Map<String, Object> inventoryType = new Map<String, Object>{
                'inventoryTypes' => new List<Map<String,Object>>(),
                    'fieldId' => 'inventoryType',
                    'value' => 'All'
                    };
                        ((List<Map<String, Object>>) inventoryType.get('inventoryTypes'))
                        .add(
                            new Map<String, Object>{
                                'label' => 'All Types',
                                    'value' => 'All Types'
                                    }
                        );
            
            Schema.DescribeSObjectResult R = Inventory_Line_Item__c.SObjectType.getDescribe();
            List<Schema.RecordTypeInfo> recordTypeList = R.getRecordTypeInfos();
            for( Schema.RecordTypeInfo rt : recordTypeList){
                if(rt.getDeveloperName() == 'Usage_Inventory_Line_Item') {
                    ((List<Map<String, Object>>) inventoryType.get('inventoryTypes'))
                    .add(
                        new Map<String, Object>{
                            'label' => 'Usage',
                                'value' => rt.getDeveloperName()
                                }
                    ); 
                }
                else if(rt.getDeveloperName() == 'Delivery_Inventory_Line_Item') {
                    ((List<Map<String, Object>>) inventoryType.get('inventoryTypes'))
                    .add(
                        new Map<String, Object>{
                            'label' => 'Delivery',
                                'value' => rt.getDeveloperName()
                                }
                    );
                }
            } 
            return JSON.serialize(inventoryType);
        }
        else{
            return 'Data Not Available';
        }
    }
    
    @AuraEnabled
    public static String getConformanceTypeList() {
        TC_InventoryConformance context = new TC_InventoryConformance();
        Map<String, Object> conformanceType = new Map<String, Object>{
            'conformanceTypes' => new List<Map<String,Object>>(),
                'fieldId' => 'conformanceType',
                'value' => 'All'
                };
                   
        ((List<Map<String, Object>>) conformanceType.get('conformanceTypes'))
        .add(
            new Map<String, Object>{
                'label' => 'ZDHC MRSL',
                    'value' => 'ZDHC MRSL'
                    }
        );
        ((List<Map<String, Object>>) conformanceType.get('conformanceTypes'))
        .add(
            new Map<String, Object>{
                'label' => 'Inditex The List',
                    'value' => 'Inditex The List'
                    }
        );
        return JSON.serialize(conformanceType);
    }
    
    @AuraEnabled
    public static String getClassificationList() {
        TC_InventoryConformance context = new TC_InventoryConformance();
        Map<String, Object> classification = new Map<String, Object>{
            'classifications' => new List<Map<String,Object>>(),
                'fieldId' => 'classification',
                'value' => 'All'
                };
                    ((List<Map<String, Object>>) classification.get('classifications'))
                    .add(
                        new Map<String, Object>{
                            'label' => 'All Types',
                                'value' => 'All Types'
                                }
                    );
        ((List<Map<String, Object>>) classification.get('classifications'))
        .add(
            new Map<String, Object>{
                'label' => 'Babies',
                    'value' => 'Babies'
                    }
        );
        ((List<Map<String, Object>>) classification.get('classifications'))
        .add(
            new Map<String, Object>{
                'label' => 'Children & Adults',
                    'value' => 'Children & Adults'
                    }
        );
        return JSON.serialize(classification);
    }
    
    @AuraEnabled
    Public static Boolean isSupplierUser() {
        TC_InventoryConformance context = new TC_InventoryConformance();
        return context.isSupplierUser;
    }
    
    public virtual override List<ChartDataProvider.ChartData> getData(
        final Object parameter
    ) {
        Map<String, Object> parameters = null;
        try {
            parameters = parameter != null
                ? (Map<String, Object>) JSON.deserializeUntyped((String) parameter)
                : null;
        } catch (JSONException e) {
            // The parameters are optional. No error.
        }
        final String recordId = parameters != null
            ? (String) parameters.get('recordId')
            : null;
        final Integer month = parameters != null
            ? Integer.valueOf(parameters.get('month'))
            : null;
        
        final String location = parameters != null
            ? (String) (parameters.get('location'))
            : null;
        final String suppType = parameters != null
            ? (String) (parameters.get('supplierType'))
            : null;
        final String invType = parameters != null
            ? (String) (parameters.get('inventoryType'))
            : null;
        final String confType = parameters != null
            ? (String) (parameters.get('conformanceType'))
            : null;
        final String classfType = parameters != null
            ? (String) (parameters.get('classification'))
            : null;
        
        final TC_InventoryConformance context = new TC_InventoryConformance();
        final ChartDataProvider.ChartData aChartData = new ChartDataProvider.ChartData();
        
        List<Integer> i = context.getCounts(recordId, month, location, suppType, invType, confType, classfType);
        
        // Match the scale of the target field.
        Integer targetScale = Brand_Supplier_Connection__c.Supplier_Conformance_Target__c.getDescribe()
            .getScale();
        system.debug('confType is::'+confType);
        if(confType == 'ZDHC MRSL' || confType == 'All Types' || confType == null || confType == 'All') {
           aChartData.labels = new List<String>{
            'Level 3',
                'Level 2',
                'Level 1',
                Label.TC_Percent_NonConformant
                }; 
        }
        else{
            system.debug('Inside this');
            aChartData.labels = new List<String>{
            'A',
                'B',
                'C',
                Label.TC_Percent_NonConformant_Inditex
                };
        }
        system.debug(aChartData.labels);
        
                    
                    // Supply the conformance/non-conformance counts as a percentage.
                    Decimal total = i[0] + i[1] + i[2] + i[3];
        
        if (total > 0) {
            aChartData.detail = new List<Decimal>{
                (Decimal.valueOf(i[0]) / total * 100).setScale(targetScale),
                    (Decimal.valueOf(i[1]) / total * 100).setScale(targetScale),
                    (Decimal.valueOf(i[2]) / total * 100).setScale(targetScale),
                    (Decimal.valueOf(i[3]) / total * 100).setScale(targetScale)
                    };
                        aChartData.allZero = false;
        } else {
            aChartData.detail = new List<Decimal>{ 0, 0, 0, 0 };
                aChartData.allZero = true;
        }
        return new List<ChartDataProvider.ChartData>{ aChartData };
            }
    
    public class DataProviderException extends Exception {
    }
}