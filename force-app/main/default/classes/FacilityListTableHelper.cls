public with sharing class FacilityListTableHelper {
  public static ListResponse buildTable() {
    DataTable.Table returnData = new DataTable.Table();
    List<Account> facilities = getFacilitiesForTable();
    returnData.columns = getColumns();
    returnData.rows = getRows(facilities);
    return new ListResponse(returnData, facilities.size());
  }

  @TestVisible
  private static List<Account> getFacilitiesForTable() {
    Id accountId = [
      SELECT Contact.AccountId
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ]
    .Contact.AccountId;

    return new List<Account>(
      [
        SELECT
          Name,
          HIGG_Id__c,
          Supplier_AID__c,
          BillingStreet,
          BillingCity,
          BillingCountry,
          BillingPostalCode,
          ToxClear_Subscription_Status__c,
          InCheck_Subscription_Expiration_Date__c,
          Facility_Manager__r.Name
        FROM Account
        WHERE
          ToxClear_Account_Type__c = 'Facility'
          AND Is_ToxClear_Account__c = TRUE
          AND ToxClear_Subscription_Status__c = 'Active'
          AND ParentId = :accountId
        ORDER BY Name
      ]
    );
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
      new DataTable.Column(
        'SubscriptionStatus',
        Label.TC_Subscription_Status_Column
      ),
      new DataTable.Column(
        'SubscriptionExpiry',
        Label.TC_Subscription_Expiry_Column
      ),
      new DataTable.Column('FacilityManager', Label.TC_Facility_Manager_Column)
    };
  }

  @TestVisible
  private static List<DataTable.Row> getRows(List<Account> facilities) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Account f : facilities) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__objectPage',
        'attributes' => new Map<String, Object>{
          'objectApiName' => 'Inventory__c',
          'actionName' => 'list'
        },
        'state' => new Map<String, Object>{
          'facilityId' => f.Id,
          'facilityName' => f.Name
        }
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
          'SubscriptionStatus',
          f.ToxClear_Subscription_Status__c,
          Label.TC_Subscription_Status_Column
        ),
        new DataTable.Cell(
          'SubscriptionExpiry',
          String.valueOf(f.InCheck_Subscription_Expiration_Date__c),
          Label.TC_Subscription_Expiry_Column
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