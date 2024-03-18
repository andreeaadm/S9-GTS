@isTest
public class TCBrandDownloadInventoryControllerTest {
    
    static TC_TestDataFactory_SupplierFacilityBrand setup(Boolean withLineItems) {
        TC_TestDataFactory_SupplierFacilityBrand accounts = new TC_TestDataFactory_SupplierFacilityBrand(
            TC_TestDataFactory.randomWord(10) +
            '@' +
            TC_TestDataFactory.randomWord(10) +
            '.com'
        );
        
        List<Inventory__c> inventories = TC_TestDataFactory_Inventories.insertInventoriesForFacility(
            accounts.facility.Id,
            3,
            Date.today(),
            'Delivery',
            withLineItems ? 2 : 0,
            0,
            'kg',
            2.5,
            5.0,
            3.0
        );
        
        accounts.supplier.Brand_Working_With__c = 'Nike';
        accounts.supplier.Supplier_Code__c = 'sup-Code-01';
        update accounts.supplier;
       
        insert new Brand_Supplier_Connection__c(
            Brand_Account__c = accounts.brand.Id,
            Supplier_Account__c = accounts.supplier.Id,
            Requestor_Contact__c = accounts.supplierUsers[0].ContactId,
            Status__c = 'Approved',
            Active__c = true
        );
        
        return accounts;
    }
    
    @isTest
    static void test_getDataForDownload_WInventories() {
        // need to start and stop test because sharing of inventories to suppliers occurs asynchronously
        TC_TestDataFactory_SupplierFacilityBrand accounts = setup(true);
        List<String> chemilist = new List<String>();
        List<Inventory__c> inventories = [SELECT Id FROM Inventory__c];
        for(Inventory_Line_Item__c lineItem : [SELECT Id, Chemical_Product__c FROM Inventory_Line_Item__c where Inventory__c IN :inventories]){
            chemilist.add(lineItem.Chemical_Product__c);
        }
        List<String> formulatorList = new List<String>();
        List<Chemical_Product__c> chemList = [SELECT Id,Chemical_Product_Name__c,Formulator__c FROM Chemical_Product__c Where Id IN :chemilist LIMIT 1];
        for(Chemical_Product__c chemicalProduct : chemList){          
            chemicalProduct.Chemical_Product_Name__c = '2015K' ;
            formulatorList.add(chemicalProduct.Formulator__c);
        }
        List<Formulator__c> updateformulatorList = new List<Formulator__c>(); 
        for(Formulator__c form : [SELECT Id, Name FROM Formulator__c WHERE Id IN :formulatorList LIMIT 1]){
            form.Name = 'NANPAO';
            updateformulatorList.add(form);
        }
        
        update chemList;
        update updateformulatorList;
        test.startTest();
        TC_TriggeredSharing.processNewOrUpdatedAccounts(
            new List<Account>{ accounts.supplier }
        );
        test.stopTest();
        
        TCBrandDownloadInventoryController.TCBrandDownloadInventoryWrapper resultAsSupplierUser;
        System.runAs(accounts.supplierUsers[0]) {
            resultAsSupplierUser = TCBrandDownloadInventoryController.getDataForDownload(
                inventories[0].Id
            );
        }
    }
    
    @isTest
    static void test_getDataForDownload_noLineItems() {
        TC_TestDataFactory_SupplierFacilityBrand accounts = setup(false);
        
        TCBrandDownloadInventoryController.TCBrandDownloadInventoryWrapper resultAsSupplierUser;
        System.runAs(accounts.supplierUsers[0]) {
            resultAsSupplierUser = TCBrandDownloadInventoryController.getDataForDownload(
                accounts.facility.Id
            );
        }
        
        System.assertEquals(null, resultAsSupplierUser.facilityName);
        System.assertEquals(null, resultAsSupplierUser.supplierName);
        System.assertEquals(null, resultAsSupplierUser.inventoryName);
    }
    
}