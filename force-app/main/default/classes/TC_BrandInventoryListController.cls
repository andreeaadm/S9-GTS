public with sharing class TC_BrandInventoryListController {
  @AuraEnabled(cacheable=true)
  public static string getFilterLists() {
    try {
      // get the current logged in user account
      Id accountId = [
        SELECT Contact.AccountId
        FROM User
        WHERE Id = :UserInfo.getUserId()
      ]
      .Contact.AccountId;

      // get all Active and Approved connections with the logged in Brand
      List<Brand_Supplier_Connection__c> connections = [
        SELECT Id, Supplier_Account__c, Supplier_Account__r.Name
        FROM Brand_Supplier_Connection__c
        WHERE
          Status__c = 'Approved'
          AND Brand_Account__c = :accountId
          AND Active__c = TRUE
        ORDER BY Supplier_Account__r.Name
      ];

      // construct a map to return the data so it can be read easily as a JSON
      Map<String, Object> toReturn = new Map<String, Object>{
        'supplierTypes' => new List<Map<String,Object>>(),
        'suppliers' => new List<Map<String, Object>>(),
        'facilities' => new List<Map<String, Object>>(),
        'inventories' => new List<Map<String, Object>>(),
        'supplierIdsToConnectionIds' => new Map<Id, Id>(),
        'validFacilityIds' => new Set<Id>()
      };
          
      //get types of Suppliers
          Schema.DescribeFieldResult fieldResult = Account.Type_of_Supplier__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            ((List<Map<String, Object>>) toReturn.get('supplierTypes'))
            .add(
                new Map<String, Object>{
                    'label' => pickListVal.getLabel(),
                        'value' => pickListVal.getValue()
                        }
            );
        }     

      // get all the unique suppliers the brand is connected with
      for (Brand_Supplier_Connection__c connection : connections) {
        if (
          !((Map<Id, Id>) toReturn.get('supplierIdsToConnectionIds'))
            .keySet()
            .contains(connection.Supplier_Account__c)
        ) {
          ((List<Map<String, Object>>) toReturn.get('suppliers'))
            .add(
              new Map<String, Object>{
                'label' => connection.Supplier_Account__r.Name,
                'value' => connection.Supplier_Account__c
              }
            );
          ((Map<Id, Id>) toReturn.get('supplierIdsToConnectionIds'))
            .put(connection.Supplier_Account__c, connection.Id);
        }
      }

      // get all Facilities and Inventories for the valid Suppliers
      List<Account> facilities = [
        SELECT Id, Name, (SELECT Inventory_Name__c FROM Inventories__r)
        FROM Account
        WHERE
          ParentId IN :((Map<Id, Id>) toReturn.get(
              'supplierIdsToConnectionIds'
            ))
            .keySet()
        ORDER BY Name
      ];

      // get all the unique facilities and inventory names
      Set<String> inventoryNames = new Set<String>();
      for (Account facility : facilities) {
        if (
          !((Set<Id>) toReturn.get('validFacilityIds')).contains(facility.Id)
        ) {
          ((List<Map<String, Object>>) toReturn.get('facilities'))
            .add(
              new Map<String, Object>{
                'label' => facility.Name,
                'value' => facility.Id
              }
            );
          ((Set<Id>) toReturn.get('validFacilityIds')).add(facility.Id);
        }
        for (Inventory__c inventory : facility.Inventories__r) {
          if (!inventoryNames.contains(inventory.Inventory_Name__c)) {
            inventoryNames.add(inventory.Inventory_Name__c);
            ((List<Map<String, Object>>) toReturn.get('inventories'))
              .add(
                new Map<String, Object>{
                  'label' => inventory.Inventory_Name__c,
                  'value' => inventory.Inventory_Name__c
                }
              );
          }
        }
      }
      return JSON.serialize(toReturn);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static ListResponse getInventoriesListTableData(
    String supplierType,
    String supplierId,
    String facilityId,
    String inventoryName,
    Map<Id, Id> supplierIdsToConnectionIds,
    List<Id> validFacilityIds
  ) {
    try {
      DataTable.Table returnData = new DataTable.Table();
      Set<Id> validSupplierIds = supplierIdsToConnectionIds.keySet();

      // start off the query string
      String queryString = 'SELECT Facility__r.Parent.Name, Facility__r.ParentId, Facility__r.Name, Facility__r.Supplier_AID__c, Facility__r.HIGG_Id__c, Facility__r.BillingStreet, Facility__r.BillingCity, Facility__r.BillingState, Facility__r.BillingPostalCode, Facility__r.BillingCountry, Inventory_Name__c, InCheck_Report_Verification_Id__c FROM Inventory__c WHERE Status__c = \'Submitted\'';
      
        Set<Id> matchingSuppliersWithSelectedType = new Set<Id>();
        if(!String.isBlank(supplierType)) {
            List<Account> suppliersList = [SELECT Id,Type_of_Supplier__c FROM Account Where ID IN :validSupplierIds];
            for(Account supp : suppliersList) {
                if(supp.Type_of_Supplier__c == supplierType) {
                    matchingSuppliersWithSelectedType.add(supp.Id);  
                }
            }
        }
            
      queryString += getWhereClause(
        supplierType,
        matchingSuppliersWithSelectedType,
        supplierId,
        facilityId,
        inventoryName,
        validSupplierIds,
        validFacilityIds
      );
      queryString += ' ORDER BY Inventory_Date__c DESC';
      
      List<Inventory__c> inventoryList = Database.query(queryString);

      returnData.columns = getColumns();
      returnData.rows = getRows(inventoryList, supplierIdsToConnectionIds);
      return new ListResponse(returnData, inventoryList.size());
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static String getWhereClause(
    String supplierType,
    Set<Id> matchingSuppliersWithSelectedType, 
    String supplierId,
    String facilityId,
    String inventoryName,
    Set<Id> validSupplierIds,
    List<Id> validFacilityIds
  ) {
    String toReturn = '';
     
      if(!String.isBlank(supplierType)) {
          toReturn += ' AND Facility__r.ParentId IN :matchingSuppliersWithSelectedType';
      }
      
    if (!String.isBlank(supplierId) && validSupplierIds.contains(supplierId)) {
      toReturn += ' AND Facility__r.ParentId = \'' + supplierId + '\'';
    } else {
      toReturn += ' AND Facility__r.ParentId IN :validSupplierIds';
    }

    if (!String.isBlank(facilityId) && validFacilityIds.contains(facilityId)) {
      toReturn += ' AND Facility__c = \'' + facilityId + '\'';
    } else {
      toReturn += ' AND Facility__c IN :validFacilityIds';
    }

    if (!String.isBlank(inventoryName)) {
      toReturn += ' AND Inventory_Name__c = \'' + inventoryName + '\'';
    }

    return toReturn;
  }

  @TestVisible
  private static List<DataTable.Column> getColumns() {
    return new List<DataTable.Column>{
      new DataTable.Column('SupplierName', Label.TC_Supplier_Name_Column),
      new DataTable.Column('FacilityName', Label.TC_Facility_Name_Column),
      new DataTable.Column('FacilityHIGGId',Label.TC_HIGGID),
      new DataTable.Column('FacilitySupplierAID',Label.TC_SupplierAID),
      new DataTable.Column('FacilityStreet', Label.TC_Facility_Street_Column),
      new DataTable.Column(
        'FacilityCityTown',
        Label.TC_Facility_CityTown_Column
      ),
      new DataTable.Column('FacilityCountry', Label.TC_Facility_Country_Column),
      new DataTable.Column(
        'FacilityPostalCode',
        Label.TC_Facility_Postal_Code_Column
      ),
      new DataTable.Column('InventoryName', Label.TC_Inventory_Name_Column),
      new DataTable.Column('InCheckReport', ''),
      new DataTable.Column('DownloadButton', '')
    };
  }

  @TestVisible
  private static List<DataTable.Row> getRows(
    List<Inventory__c> inventories,
    Map<Id, Id> supplierIdsToConnectionIds
  ) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Inventory__c i : inventories) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => supplierIdsToConnectionIds.get(i.Facility__r.ParentId),
          'objectApiName' => 'Brand_Supplier_Connection__c',
          'actionName' => 'view'
        }
      };

      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell(
          'SupplierName',
          i.Facility__r.Parent.Name,
          pageRef,
          true,
          false,
          true,
          null,
          null,
          null,
          Label.TC_Supplier_Name_Column
        ),
        
        new DataTable.Cell(
          'FacilityName',
          i.Facility__r.Name,
          Label.TC_Facility_Name_Column
        ),
        new DataTable.Cell(
          'FacilityHIGGId',
          i.Facility__r.HIGG_Id__c,
          Label.TC_HIGGID
        ),
        new DataTable.Cell(
          'FacilitySupplierAID',
          i.Facility__r.Supplier_AID__c,
          Label.TC_SupplierAID
        ),
        new DataTable.Cell(
          'FacilityStreet',
          i.Facility__r.BillingStreet,
          Label.TC_Facility_Street_Column
        ),
        new DataTable.Cell(
          'FacilityCityTown',
          i.Facility__r.BillingCity,
          Label.TC_Facility_CityTown_Column
        ),
        new DataTable.Cell(
          'FacilityCountry',
          i.Facility__r.BillingCountry,
          Label.TC_Facility_Country_Column
        ),
        new DataTable.Cell(
          'FacilityPostalCode',
          i.Facility__r.BillingPostalCode,
          Label.TC_Facility_Postal_Code_Column
        ),
        new DataTable.Cell(
          'InventoryName',
          i.Inventory_Name__c,
          Label.TC_Inventory_Name_Column
        ),
        new DataTable.cell(
          'InCheckReport',
          Label.TC_View_InCheck_Report,
          null,
          true,
          true,
          false,
          'viewInCheck',
          'customEvent',
          'BtnLnkDisableable',
          '',
          (i.InCheck_Report_Verification_Id__c == null)
        ),
        new DataTable.Cell(
          'DownloadButton',
          Label.TC_Download_Inventory,
          null,
          true,
          true,
          false,
          'downloadInventory',
          'customEvent',
          'IntkBrandOneBtn',
          ''
        )
      };
      rows.add(new DataTable.Row(i.Id, rowCells));
    }
    return rows;
  }
}