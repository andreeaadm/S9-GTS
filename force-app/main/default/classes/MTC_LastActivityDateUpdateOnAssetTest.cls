@isTest
public class MTC_LastActivityDateUpdateOnAssetTest {
    public static testMethod void method1(){
        Account acc = new Account();
        acc.name = 'Test Account';
        insert acc;
        
        MTC_Project__c mtcProj = new MTC_Project__c(name = 'Test Project');
        insert mtcProj;
        
        List<Asset> assetsToBeUpdated = new List<Asset>();
        for(Integer i=1; i<=50; i++){
            Asset ast = new Asset();
            ast.name = 'Test Report' + i;
            if(i==1 && i<=15){
                ast.Date_Issued__c = system.today() + i; 
                ast.Date_Revised__c = system.today() + i + 2;
            }
            if(i==16 && i<=20){
                ast.Date_Issued__c = system.today() + i; 
                ast.Date_Revised__c = system.today() + i;
            }
            if(i==21 && i<= 35){
                ast.Date_Issued__c = system.today() + i; 
                ast.Date_Revised__c = null; 
            }
            if(i==36 && i<= 45){
                ast.Date_Issued__c = null; 
                ast.Date_Revised__c = system.today() + i;
            }
            if(i==46 && i<=50){
                ast.Date_Issued__c = null; 
                ast.Date_Revised__c = null; 
            }
            ast.MTC_Status__c = 'Official';
            assetsToBeUpdated.add(ast);
        }
        insert assetsToBeUpdated;
        
        Test.startTest();
        Id batchProcessId = Database.executeBatch(
            new MTC_LastActivityDateUpdateOnAsset(),
            200
        );
        Test.stopTest();
        
        Set<Id> assetId = new Set<Id>();
        for(Asset a : assetsToBeUpdated){
            assetId.add(a.Id);
        }
        
        List<Asset> updatedAssets = [Select id,Last_Activity_Date__c from Asset Where Id IN:assetId];
        system.assertEquals(updatedAssets.size(), assetsToBeUpdated.size());        
    }
}