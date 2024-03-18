@IsTest
public class TC_ChemicalProductTrgHandler_Test {
    @isTest
    static void beforeInsert_notTheExpectedUser() {
        Test.startTest();
        List<Chemical_Product__c> products = new List<Chemical_Product__c>{
            new Chemical_Product__c(Chemical_Product_Name__c = 'BOBBO FOAM')
                };
                    insert products;
        Test.stopTest();
        
        System.assertNotEquals(
            'Intertek',
            products[0].Origin__c,
            'Check origin was not set'
        );
    }
    
    @isTest
    static void beforeInsert_asBackOfficeAdministrator() {
        User adminUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            adminUser = TestDataFactory.createAdminUser(
                'ToxClear_Intertek_Back_Office_Administrator'
            );
        }
        
        List<Chemical_Product__c> products = new List<Chemical_Product__c>{
            new Chemical_Product__c(Chemical_Product_Name__c = 'BOBBO FOAM')
                };
                    Test.startTest();
        System.runAs(adminUser) {
            insert products;
        }
        Test.stopTest();
        
        products = [
            SELECT Origin__c
            FROM Chemical_Product__c
            WHERE Chemical_Product_Name__c = 'BOBBO FOAM'
        ];
        System.assertEquals(
            'Intertek',
            products[0].Origin__c,
            'Check origin was set'
        );
    }
    
    @isTest
    static void beforeInsert_asCustomerServicesRepresentatives() {
        User adminUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            adminUser = TestDataFactory.createAdminUser(
                'ToxClear_Customer_Services_Representatives'
            );
        }
        
        List<Chemical_Product__c> products = new List<Chemical_Product__c>{
            new Chemical_Product__c(Chemical_Product_Name__c = 'BOBBO FOAM')
                };
                    Test.startTest();
        System.runAs(adminUser) {
            insert products;
        }
        Test.stopTest();
        
        products = [
            SELECT Origin__c
            FROM Chemical_Product__c
            WHERE Chemical_Product_Name__c = 'BOBBO FOAM'
        ];
        
        System.assertEquals(
            'Intertek',
            products[0].Origin__c,
            'Check origin was set'
        );
    }
    
    @isTest
    static void beforeInsert_asSupplierAdmin() {
        Account acc = new Account(
            name = 'Test TC Account',
            Is_ToxClear_Account__c = true,
            ToxClear_Account_Type__c = 'Supplier',
            Country__c = 'India'
        );
        insert acc;
        
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'TC Contact',
            AccountId = acc.Id,
            ToxClear_User_Type__c = 'ToxClear Administrator',
            Phone = '9999999999',
            Email = 'Testtccon@test.com'
        );
        insert con;
        
        User supplierAdminUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            supplierAdminUser = TestDataFactory.createSupplierCommunityUser(
                'Experience Cloud Site Admin - Login',
                con,
                'ToxClear_Supplier_Administrator'
            );
        }
        
        List<Chemical_Product__c> products = new List<Chemical_Product__c>{
            new Chemical_Product__c(Chemical_Product_Name__c = 'BOBBO FOAM')
                };
                    Test.startTest();
        System.runAs(supplierAdminUser) {
            insert products;
        }
        Test.stopTest();
        
        products = [
            SELECT Origin__c
            FROM Chemical_Product__c
            WHERE Chemical_Product_Name__c = 'BOBBO FOAM'
        ];
        
        System.assertEquals(
            'Supplier',
            products[0].Origin__c,
            'Check origin was set'
        );
    }
}