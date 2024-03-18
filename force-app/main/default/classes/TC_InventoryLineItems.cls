/**
 * handles selecting Inventory_Line_Item__c sObjects and preparing for display in the UI
 * @author Kevin Reader (oe:gen)
 * @date December 2021
 */
public with sharing class TC_InventoryLineItems {
  /**
   * allows the UI to retrieve Inventory_Line_Item__c sObjects to display in a datatable
   * @param inventoryId - record Id of the parent Inventory__c sObject
   * @param recordCount - no. of records to return
   * @param offset - optional offset number if retrieving in batches
   * @param type - delivery or usage - determines the output columns in the UI
   * @return object containing result data prepped for displaying in c-datatable UI component
   */
  @AuraEnabled
  public static ListResponse getLineItemsForInventory(
    Id inventoryId,
    Integer recordCount,
    Integer offset,
    String type
  ) {
    //get the records
    List<Inventory_Line_Item__c> lineItems = getLineItemRecords(
      inventoryId,
      recordCount,
      offset
    );
    if (!lineItems.isEmpty()) {
      //build response
      return buildResponse(lineItems, type);
    }
    return null;
  }

  /**
   * getLineItemForProduct retrieve line item for this product.
   * @param inventoryId (Id): Inventory__c.Id
   * @param productGUID (String): ZDHC Product GUID
   * @return List<Inventory_Line_Item__c>: Line items for this product if any.
   */
  @AuraEnabled
  public static List<Inventory_Line_Item__c> getLineItemForProduct(
    Id inventoryId,
    Id productId
  ) {
    return [
      SELECT
        Id,
        Origin__c,
        Chemical_Product__c,
        Chemical_Product_Name__c,
        Formulator_Name__c,
        Product_Trade_Name_Other_Name__c,
        Substrate__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_Product_Id__c,
        ZDHC_Product_GUID__c,
        Conformant__c,
        Storage_Location__c,
        Lot_Number__c,
        Expiry_Date__c,
        Unit__c,
        Stock_Take_Month_Begin__c,
        Delivered_Stock_This_Month__c,
        Stock_Take_Month_End__c,
        Calculated_Usage__c,
        RecordType.Name,
        Name,
        Commodity_Chemical_Standard_Name__c
      FROM Inventory_Line_Item__c
      WHERE Inventory__c = :inventoryId AND Chemical_Product__c = :productId
    ];
  }

  /**
   * getLineItemProductGUIDs retrieve an inventories productGUIDs.
   * @param inventoryId (Id): Inventory__c.Id
   * @return List<String>: List of productGUIDs if any.
   */
  @AuraEnabled(cacheable=true)
  public static List<String> getLineItemProductGUIDs(Id inventoryId) {
    List<String> productGUIDs = new List<String>();
    for (Inventory_Line_Item__c i : [
      SELECT ZDHC_Product_GUID__c
      FROM Inventory_Line_Item__c
      WHERE Inventory__c = :inventoryId
    ]) {
      productGUIDs.add(i.ZDHC_Product_GUID__c);
    }
    return productGUIDs;
  }

  /**
   * queries the database for the Inventory_Line_Item__c sObjects
   * @param inventoryId - record Id of the parent Inventory__c sObject
   * @param recordCount - no. of records to return
   * @param offset - optional offset number if retrieving in batches
   * @return collection of sObjects retrieved from the database
   */
  @TestVisible
  private static List<Inventory_Line_Item__c> getLineItemRecords(
    Id inventoryId,
    Integer recordCount,
    Integer offset
  ) {
    if (offset == null) {
      offset = 0;
    }
    return [
      SELECT
        Origin__c,
        Chemical_Product_Name__c,
        Formulator_Name__c,
        Product_Trade_Name_Other_Name__c,
        Substrate__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_Product_Id__c,
        ZDHC_Product_GUID__c,
        Conformant__c,
        Storage_Location__c,
        Lot_Number__c,
        Expiry_Date__c,
        Unit__c,
        Stock_Take_Month_Begin__c,
        Delivered_Stock_This_Month__c,
        Stock_Take_Month_End__c,
        Calculated_Usage__c,
        RecordType.Name,
        Name,
        Commodity_Chemical_Standard_Name__c
      FROM Inventory_Line_Item__c
      WHERE Inventory__c = :inventoryId
      ORDER BY Chemical_Product_Name__c ASC
      LIMIT :recordCount
      OFFSET :offset
    ];
  }

  /**
   * builds the response for the UI
   * @param lineItems - collection of sObjects retrieved from the database used to populate the datatable
   * @param type - delivery or usage - determines the output columns in the UI
   * @return object containing result data prepped for displaying in c-datatable UI component
   */
  @TestVisible
  private static ListResponse buildResponse(
    List<Inventory_Line_Item__c> lineItems,
    String type
  ) {
    return new ListResponse(
      new DataTable.Table(buildColumns(type), buildRows(lineItems, type)),
      lineItems.size()
    );
  }

  /**
   * builds the column header information for the c-datatable cmp
   * @param type - delivery or usage - determines the output columns in the UI
   * @return collection of objects containing the metadata required to display table columns in c-datatable
   */
  @TestVisible
  private static List<DataTable.Column> buildColumns(String type) {
    List<DataTable.Column> columns = new List<DataTable.Column>();
    columns.add(new DataTable.Column('Name', Label.Name));
    columns.add(new DataTable.Column('Origin__c', Label.TC_Origin));
    columns.add(
      new DataTable.Column('Chemical_Product', Label.TC_Chemical_Product)
    ); //contains concatonated data from multiple fields
    columns.add(new DataTable.Column('Conformant__c', Label.TC_Conformant));
    columns.add(new DataTable.Column('Unit__c', Label.TC_Unit));
    if (type.toLowerCase() == 'usage') {
      columns.add(
        new DataTable.Column(
          'Stock_Take_Month_Begin__c',
          Label.TC_Stock_Take_Month_Begin
        )
      );
    }
    columns.add(
      new DataTable.Column(
        'Delivered_Stock_This_Month__c',
        Label.TC_Delivered_Stock_This_Month
      )
    );
    if (type.toLowerCase() == 'usage') {
      columns.add(
        new DataTable.Column(
          'Stock_Take_Month_End__c',
          Label.TC_Stock_Take_Month_End
        )
      );
    }
    if (type.toLowerCase() == 'usage') {
      columns.add(
        new DataTable.Column('Calculated_Usage__c', Label.TC_Calculated_Usage)
      );
    }
    columns.add(
      new DataTable.Column('Storage_Location__c', Label.TC_Storage_Location)
    );
    columns.add(new DataTable.Column('Lot_Number__c', Label.TC_Lot_Number));
    columns.add(new DataTable.Column('Expiry_Date__c', Label.TC_Expiry_Date));
    return columns;
  }

  /**
   * builds the table rows for each of the records returned from the database
   * @param lineItems - collection of sObjects retrieved from the database used to populate the datatable
   * @param type - delivery or usage - determines the output columns in the UI
   * @return collection of objects containing the metadata and data required to display table rows in c-datatable
   */
  @TestVisible
  private static List<DataTable.Row> buildRows(
    List<Inventory_Line_Item__c> lineItems,
    String type
  ) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Inventory_Line_Item__c lineItem : lineItems) {
      List<DataTable.Cell> cells = new List<DataTable.Cell>();
      cells.add(
        new DataTable.Cell(
          'Name',
          lineItem.Name,
          new Map<String, Object>{
            'type' => 'standard__recordPage',
            'attributes' => new Map<String, Object>{
              'recordId' => lineItem.Id,
              'objectApiName' => 'Inventory_Line_Item__c',
              'actionName' => 'view'
            }
          },
          true,
          false,
          true,
          null,
          null,
          null,
          Label.Name
        )
      );
      cells.add(
        new DataTable.Cell('Origin__c', lineItem.Origin__c, Label.TC_Origin)
      );
      cells.add(
        new DataTable.Cell(
          'Chemical_Product',
          getChemicalDetails(lineItem),
          Label.TC_Chemical_Product
        )
      );
      cells.add(
        new DataTable.Cell(
          'Conformant__c',
          lineItem.Conformant__c ? 'Yes' : 'No',
          Label.TC_Conformant
        )
      ); //may want to change to isCheckbox with disabled = true
      cells.add(new DataTable.Cell('Unit__c', lineItem.Unit__c, Label.TC_Unit));
      if (type.toLowerCase() == 'usage') {
        cells.add(
          new DataTable.Cell(
            'Stock_Take_Month_Begin__c',
            lineItem.Stock_Take_Month_Begin__c != null
              ? String.valueOf(lineItem.Stock_Take_Month_Begin__c)
              : '',
            Label.TC_Stock_Take_Month_Begin
          )
        );
      }
      cells.add(
        new DataTable.Cell(
          'Delivered_Stock_This_Month__c',
          lineItem.Delivered_Stock_This_Month__c != null
            ? String.valueOf(lineItem.Delivered_Stock_This_Month__c)
            : '',
          Label.TC_Delivered_Stock_This_Month
        )
      );
      if (type.toLowerCase() == 'usage') {
        cells.add(
          new DataTable.Cell(
            'Stock_Take_Month_End__c',
            lineItem.Stock_Take_Month_End__c != null
              ? String.valueOf(lineItem.Stock_Take_Month_End__c)
              : '',
            Label.TC_Stock_Take_Month_End
          )
        );
      }
      if (type.toLowerCase() == 'usage') {
        cells.add(
          new DataTable.Cell(
            'Calculated_Usage__c',
            lineItem.Calculated_Usage__c != null
              ? String.valueOf(lineItem.Calculated_Usage__c)
              : '',
            Label.TC_Calculated_Usage
          )
        );
      }
        cells.add(
        new DataTable.Cell(
          'Storage_Location__c',
          lineItem.Storage_Location__c,
          Label.TC_Storage_Location
        )
      );
      cells.add(
        new DataTable.Cell(
          'Lot_Number__c',
          lineItem.Lot_Number__c,
          Label.TC_Lot_Number
        )
      );
      cells.add(
        new DataTable.Cell(
          'Expiry_Date__c',
          lineItem.Expiry_Date__c != null
            ? String.valueOf(lineItem.Expiry_Date__c.format())
            : '',
          Label.TC_Expiry_Date
        )
      );
      rows.add(new DataTable.Row(lineItem.Id, cells));
    }
    return rows;
  }

  /**
   * concatonates multiple field values to build the Chemical Detail column of the inventory line item row
   * @param lineItem - sObject being processed for displaying in the UI
   * @return concatonated string built from multiple field values
   */
  @TestVisible
  private static String getChemicalDetails(Inventory_Line_Item__c lineItem) {
    List<String> fieldValues = new List<String>{
      lineItem.Chemical_Product_Name__c,
      lineItem.Formulator_Name__c,
      lineItem.Product_Trade_Name_Other_Name__c,
      lineItem.Substrate__c,
      lineItem.ZDHC_MRSL_v2_0__c,
      lineItem.ZDHC_Product_Id__c,
      lineItem.ZDHC_Product_GUID__c
    };
    return String.join(fieldValues, ' ');
  }
}