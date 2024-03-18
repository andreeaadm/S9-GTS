public with sharing class TC_SupplierFacilitiesController {
  @AuraEnabled(cacheable=true)
  public static ListResponse buildTable(String connectionId) {
    try {
      DataTable.Table returnData = new DataTable.Table();
      Brand_Supplier_Connection__c bsc = getBrandSupplierConnection(
        connectionId
      );

      if (bsc?.Supplier_Account__c != null) {
        List<Account> facilities = getFacilitiesForSupplier(
          bsc.Supplier_Account__c
        );
        returnData.columns = getColumns();
        returnData.rows = getRows(facilities);
        return new ListResponse(returnData, facilities.size());
      }
      return new ListResponse(returnData, 0);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @TestVisible
  private static Brand_Supplier_Connection__c getBrandSupplierConnection(
    String connectionId
  ) {
    return [
      SELECT Supplier_Account__c
      FROM Brand_Supplier_Connection__c
      WHERE Id = :connectionId AND Active__c = TRUE AND Status__c = 'Approved'
      LIMIT 1
    ];
  }

  @TestVisible
  private static List<Account> getFacilitiesForSupplier(String supplierId) {
    return [
      SELECT
        Id,
        Name,
        HIGG_Id__c,
        Supplier_AID__c,
        Facility_Manager__c,
        Facility_Manager__r.Name,
        BillingStreet,
        BillingCity,
        BillingCountry,
        BillingPostalCode
      FROM Account
      WHERE
        ToxClear_Subscription_Status__c = 'Active'
        AND ToxClear_Account_Type__c = 'Facility'
        AND ParentId = :supplierId
      ORDER BY Name
    ];
  }

  @TestVisible
  private static List<DataTable.Column> getColumns() {
    return new List<DataTable.Column>{
      new DataTable.Column('FacilityName', Label.TC_Facility_Name_Column),
      new DataTable.Column('HIGGID', Label.TC_HIGGID),
      new DataTable.Column('SupplierAID', Label.TC_SupplierAID),
      new DataTable.Column('Street', Label.TC_Street_Column),
      new DataTable.Column('CityTown', Label.TC_CityTown_Column),
      new DataTable.Column('Country', Label.TC_Country_Column),
      new DataTable.Column('PostalCode', Label.Postal_Code),
      new DataTable.Column('FacilityManager', Label.TC_Facility_Manager_Column)
    };
  }

  @TestVisible
  private static List<DataTable.Row> getRows(List<Account> facilities) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Account f : facilities) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'comm__namedPage',
        'attributes' => new Map<String, Object>{
          'name' => 'InCheck_Reports__c'
        },
        'state' => new Map<String, Object>{ 'facilityId' => f.Id }
      };
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell(
          'FacilityName',
          f.Name,
          pageRef,
          true,
          false,
          true,
          null,
          null,
          null,
          Label.TC_Facility_Name_Column
        ),
        new DataTable.Cell('HIGGID', f.HIGG_Id__c, Label.TC_HIGGID),
        new DataTable.Cell('SupplierAID', f.Supplier_AID__c, Label.TC_SupplierAID),
        new DataTable.Cell('Street', f.BillingStreet, Label.TC_Street_Column),
        new DataTable.Cell('CityTown', f.BillingCity, Label.TC_CityTown_Column),
        new DataTable.Cell(
          'Country',
          f.BillingCountry,
          Label.TC_Country_Column
        ),
        new DataTable.Cell(
          'PostalCode',
          f.BillingPostalCode,
          Label.Postal_Code
        ),
        new DataTable.Cell(
          'FacilityManager',
          f.Facility_Manager__r.Name,
          Label.TC_Facility_Manager_Column
        )
      };
      rows.add(new DataTable.Row(f.Id, rowCells));
    }
    return rows;
  }
}