/******************************************************************************
Created Date: May 2022
@description: Fetches inventory line item data from database by inventory to add in CSV
@test class: TC_DownloadInventoryController_Test
@author: Intertek
Modification History:
Ver			Date			Author			Modification
1.0     Nov 2023  Akshay      Updated soql query to add Inditex classification fields(TBS-59)
2.0  		Jan 2024	Yash			  Added Commodity Chemical & Type of Chemical Fields(TBS-61)
******************************************************************************/

public with sharing class TC_DownloadInventoryController {
    

  @AuraEnabled
public static TC_DownloadInventoryWrapper getDataForDownload(Id inventoryId) {
    try {
      User user = [
        SELECT Contact.AccountId, Contact.Account.ToxClear_Account_Type__c
        FROM User
        WHERE
          Id = :UserInfo.getUserId()
          AND (Contact.Account.ToxClear_Account_Type__c = 'Brand'
          OR Contact.Account.ToxClear_Account_Type__c = 'Supplier'
          OR Contact.Account.ToxClear_Account_Type__c = 'Facility')
      ];

      Id accountId = user.Contact.AccountId;

      String queryString = 'SELECT Name, Inventory__r.Inventory_Name__c, Inventory__r.Inventory_Date__c, Inventory__r.Type__c, Inventory__r.Facility__r.Parent.Name, Inventory__r.Facility__r.Name, Chemical_Product__r.Name, Chemical_Product_Name__c, Formulator_Name__c, Product_Trade_Name_Other_Name__c, Substrate__c, Other_Certifications__c, ZDHC_MRSL_v2_0__c, ZDHC_MRSL_Version__c, Conformant__c,  ZDHC_Product_Id__c, ZDHC_Product_GUID__c, Unit__c, Stock_Take_Month_Begin__c, Delivered_Stock_This_Month__c, Stock_Take_Month_End__c, Calculated_Usage__c, Calculated_Weight_kg__c, Delivered_Stock_History__c, Storage_Location__c, Lot_Number__c, Expiry_Date__c, Chemical_Product__r.CAS_Number__c, Supplier_Reference_Number__c, Supplier_Reference_Name__c, Product_Name_Local_Language__c, Formulator_Name_Local_Language__c,Inditex_Classification_for_Babies__c,Inditex_Classification_for_Child_Adult__c, Commodity_Chemical_Standard_Name__c, Type_of_Chemicals__c FROM Inventory_Line_Item__c WHERE Inventory__c = :inventoryId';
      List<Id> supplierIds = new List<Id>();

      if (user.Contact.Account.ToxClear_Account_Type__c == 'Brand') {
        List<Brand_Supplier_Connection__c> connections = [
          SELECT Supplier_Account__c
          FROM Brand_Supplier_Connection__c
          WHERE
            Brand_Account__c = :accountId
            AND Status__c = 'Approved'
            AND Active__c = TRUE
        ];
        for (Brand_Supplier_Connection__c conn : connections) {
          supplierIds.add(conn.Supplier_Account__c);
        }
        queryString += ' AND Inventory__r.Facility__r.ParentId IN :supplierIds';
      } else if (user.Contact.Account.ToxClear_Account_Type__c == 'Supplier') {
        queryString += ' AND Inventory__r.Facility__r.ParentId = :accountId';
      } else if (user.Contact.Account.ToxClear_Account_Type__c == 'Facility') {
        queryString += ' AND Inventory__r.Facility__c = :accountId';
      }

      List<Inventory_Line_Item__c> lineItems = Database.query(queryString);

      if (lineItems.size() > 0) {
        return new TC_DownloadInventoryWrapper(lineItems);
      } else {
        return new TC_DownloadInventoryWrapper(
          new List<Inventory_Line_Item__c>()
        );
      }
    } catch (QueryException qe) {
      throw new AuraHandledException(Label.TC_Download_Error_No_Items);
    } catch (Exception e) {
      throw new AuraHandledException(Label.TC_Download_Inventory_Error);
    }
  }
}