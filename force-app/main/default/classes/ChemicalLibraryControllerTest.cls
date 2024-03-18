@isTest
public with sharing class ChemicalLibraryControllerTest {
    
    @testSetup
    static void setup() {
        TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts(
            1,
            0, // inactive
            new List<Integer>{ 1 },
            new List<Integer>{ 0 }, // inactive
            1,
            0 // inactive
        );
        TC_TestDataFactory_Contacts tdfc = new TC_TestDataFactory_Contacts(
            tdfa,
            'unittest@example.com',
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 },
            new List<Integer>{ 1 }
        );
        TC_TestDataFactory_Connections bsc = new TC_TestDataFactory_Connections(
            tdfa,
            tdfc
        );
        TC_TestDataFactory_Formulators tdff = new TC_TestDataFactory_Formulators(
            tdfa.facilities
        );
        TC_TestDataFactory_Chemicals chemical = new TC_TestDataFactory_Chemicals(
            tdff,
            null
        );
        TC_TestDataFactory_Inventories inventory = new TC_TestDataFactory_Inventories(
            tdfa.facilities,
            new List<Integer>{ 3 },
            Date.today()
        );
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users(tdfc, true);
        TC_TestDataFactory_Users.insertPermissionSetAssignments(
            tdfu.permissionSetAssignments
        );
    }
    
    @isTest
    static void test_Method(){
        TC_TestDataFactory_Users tdfu = new TC_TestDataFactory_Users();
        ListResponse ChemicalProductListResults; 
        ListResponse conformantChemicalProductListResults;
        ListResponse sdsChemicalProductListResults; 
        ListResponse mrslChemicalProductListResults;
        String suppliersActiveFaciities = '';
        String suppliersForBrand = '';
        String facilityListBySelectedSupplier = '';
        Integer recordCount = 10;
        Integer offSet = 0;
        
        TC_TestDataFactory_Accounts tdfa = new TC_TestDataFactory_Accounts();
        String facilityId = tdfa.facilities[0].Id; 
        String supplierId = tdfa.suppliers[0].Id; 
        
        Test.startTest();
        System.runAs(tdfu.supplierAdminUsers[0]) {
            suppliersActiveFaciities = ChemicalLibraryController.getSuppliersFacilityList();
            ChemicalProductListResults = ChemicalLibraryController.getChemicalProducts(facilityId,null, recordCount, offset);
            conformantChemicalProductListResults = ChemicalLibraryController.getConformantChemicalProducts(facilityId, null, true, 10, 0);
            sdsChemicalProductListResults = ChemicalLibraryController.getSDSChemicalProducts(facilityId, null, false, 10, 0);
            mrslChemicalProductListResults = ChemicalLibraryController.getMrslChemicalProducts(facilityId, null, false, 10, 0);
        }
        System.runAs(tdfu.brandAdminUsers[0]) {
           suppliersActiveFaciities = ChemicalLibraryController.getSuppliersFacilityList();
           suppliersForBrand = ChemicalLibraryController.getSuppliersForBrand();
           facilityListBySelectedSupplier = ChemicalLibraryController.getFacilityListBySelectedSupplier(supplierId);
        }
        Test.stopTest();
        
        System.assertEquals(false, String.isEmpty(suppliersActiveFaciities));
        System.assertEquals(true, ChemicalProductListResults.totalRows > 0);
        System.assertEquals(true, conformantChemicalProductListResults.totalRows > 0);
        System.assertEquals(true, sdsChemicalProductListResults.totalRows > 0);
        System.assertEquals(true, mrslChemicalProductListResults.totalRows > 0);
    }
}