public with sharing class InventoryListTableHelper {
  public static ListResponse buildTable(Id facilityId) {
    List<Inventory__c> inventories = getInventoriesByFacility(facilityId);
    DataTable.Table returnData = new DataTable.Table();
    returnData.columns = getColumns();
    returnData.rows = getRows(inventories);
    return new ListResponse(returnData, inventories.size());
  }

  @TestVisible
  private static List<Inventory__c> getInventoriesByFacility(Id facilityId) {
    return [
      SELECT
        Inventory_Name__c,
        Inventory_Date__c,
        Completed_Date__c,
        Submitted_Date__c,
        Status__c
      FROM Inventory__c
      WHERE Facility__c = :facilityId
      ORDER BY Inventory_Date__c DESC
      LIMIT 24
    ];
  }

  @TestVisible
  private static List<DataTable.Column> getColumns() {
    return new List<DataTable.Column>{
      new DataTable.Column('Inventory', Label.TC_Inventory_Column),
      new DataTable.Column('DateCreated', Label.TC_Date_Created_Column),
      new DataTable.Column('DateComplete', Label.TC_Date_Completed),
      new DataTable.Column('DateSubmitted', Label.TC_Date_Submitted_Column),
      new DataTable.Column('Status', Label.TC_Status_Column)
    };
  }

  @TestVisible
  private static List<DataTable.Row> getRows(List<Inventory__c> inventories) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Inventory__c i : inventories) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => i.Id,
          'objectApiName' => 'Inventory__c',
          'actionName' => 'view'
        }
      };
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell(
          'Inventory',
          i.Inventory_Name__c,
          pageRef,
          true,
          false,
          true,
          null,
          null,
          null,
          Label.TC_Inventory_Column
        ),
        new DataTable.Cell(
          'DateCreated',
          String.valueOf(i.Inventory_Date__c),
          Label.TC_Date_Created_Column
        ),
        new DataTable.Cell(
          'DateComplete',
          String.valueOf(i.Completed_Date__c),
          Label.TC_Date_Completed
        ),
        new DataTable.Cell(
          'DateSubmitted',
          String.valueOf(i.Submitted_Date__c),
          Label.TC_Date_Submitted_Column
        ),
        new DataTable.Cell('Status', i.Status__c, Label.TC_Status_Column)
      };
      rows.add(new DataTable.Row(i.Id, rowCells));
    }
    return rows;
  }
}