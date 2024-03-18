/**
 * Inventory__c methods for Status
 * @author Alan West (oe:gen)
 * @date January 2022
 */
public with sharing class TC_InventoryStatus extends TC_ExperienceCloud {
  /**
   * DataTable Columns for Inventory status table.
   */
  private static List<DataTable.Column> columns = new List<DataTable.Column>{
    new DataTable.Column('Facility__r.Name', 'Facility', 'ASC'),
    new DataTable.Column('Inventory_Name__c', 'Inventory', ''),
    new DataTable.Column('Status__c', 'Status', '')
  };

  /**
   * buildTable builds a DataTable.Table from a list of fields and a collection
   * of objects.
   *
   * @param fields (List<String>): Write the parameter description
   * @param records (List<Inventory__c>): Write the parameter description
   * @return DataTable.Table: A table for presenting in UI c-datatable.
   */
  private static DataTable.Table buildTable(List<Inventory__c> records) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Inventory__c i : records) {
      List<DataTable.Cell> cells = new List<DataTable.Cell>{
        new DataTable.Cell('Name', i.Facility__r.Name, 'Name'),
        new DataTable.Cell(
          'Inventory_Name__c',
          i.Inventory_Name__c,
          'Inventory'
        ),
        new DataTable.Cell(
          'Status__c',
          i.Status__c,
          new Map<String, Object>{
            'type' => 'standard__recordPage',
            'attributes' => new Map<String, Object>{
              'objectApiName' => 'Inventory__c',
              'actionName' => 'view',
              'recordId' => i.Id
            }
          },
          true, // isAction
          false, // isButton
          true, // isLink
          'view', // actionType
          'view', // actionName
          null, // buttonVariant
          'Status' // columnLabel
        )
      };
      rows.add(new DataTable.Row(i.Id, cells));
    }
    return new DataTable.Table(columns, rows);
  }

  /**
   * buildRowsForCreate Optionally builds rows to create inventory for the listed facilities.
   *
   * @param table (DataTable.Table): The table to update with rows to create.
   * @param records (List<Account>): The records to reference for creation.
   * @return DataTable.Table: A table for presenting in UI c-datatable.
   */
  private static DataTable.Table buildCreateInventoryRows(
    DataTable.Table table,
    String inventoryName,
    List<Account> records
  ) {
    if (records != null) {
      for (Account a : records) {
        List<DataTable.Cell> cells = new List<DataTable.Cell>{
          new DataTable.Cell('Name', a.Name, 'Name'),
          new DataTable.Cell('Inventory_Name__c', inventoryName, 'Inventory'),
          new DataTable.Cell(
            'Status__c',
            'Create',
            new Map<String, Object>{
              'type' => 'standard__webPage',
              'attributes' => new Map<String, Object>{
                'url' => '/inventory/Inventory__c/Default?facilityId=' +
                a.Id +
                '&action=new&facilityName=' +
                EncodingUtil.urlEncode(a.Name, 'UTF-8')
              }
            },
            true, // isAction
            false, // isButton
            true, // isLink
            'create', // actionType
            'create', // actionName
            null, // buttonVariant
            'Status' // columnLabel
          )
        };
        table.rows.add(new DataTable.Row(a.Id, cells));
      }
    }
    return table;
  }

  /**
   * getFacilities Get a list of facilities for Inventory Status,
   * determined by the current context, for user types:
   *   Supplier Admin, a list of related Facilities.
   *   Supplier Standard, only their Facility.
   *   Any other user type, an empty list.
   * @return List<Account>: A list of Accounts appropriate for the context.
   */
  public List<Account> getFacilities() {
    Id recordId = this.isSupplierAdminUser
      ? this.user.Contact.AccountId
      : this.isSupplierStandardUser ? this.user.Contact.Main_Facility__c : null;
    if (recordId == null) {
      return new List<Account>(); // No results.
    }
    return this.isSupplierAdminUser
      ? [
          SELECT Id, Name
          FROM Account
          WHERE
            ParentId = :recordId
            AND Is_ToxClear_Account__c = TRUE
            AND ToxClear_Account_Type__c = 'Facility'
        ]
      : [
          SELECT Id, Name
          FROM Account
          WHERE
            Id = :recordId
            AND Is_ToxClear_Account__c = TRUE
            AND ToxClear_Account_Type__c = 'Facility'
        ];
  }

  /**
   * getRecordsFiltered allows the UI to retrieve filtered Inventory__c
   * sObjects to display in a datatable.
   *
   * @param month (Date): filter by month, use null for today's month.
   * @param recordLimit (Integer): Maximum number of records to return.
   * @param offset (Integer): Optional offset for retrieving in batches.
   *
   * @return ListResponse: containing result data prepped for displaying in
   *         c-datatable UI component.
   */
  public ListResponse getRecordsFiltered(
    Date month,
    Integer recordLimit,
    Integer offset
  ) {
    // Discover which facilities we'll be interested in.

    Map<Id, Account> facilities = new Map<Id, Account>(getFacilities());
    if (facilities == null || facilities.size() == 0) {
      // Without an association to a Facility Account,
      // return no results.
      return new ListResponse(
        TC_InventoryStatus.buildTable(new List<Inventory__c>()),
        0
      );
    }

    // Filter for the specified month.
    Date startOfMonth = month != null
      ? month.toStartOfMonth()
      : Date.today().toStartOfMonth();
    Date startOfNextMonth = startOfMonth.addMonths(1);

    // Ensure limits and offset are valid.
    if (recordLimit == null || recordLimit > 100) {
      recordLimit = 100;
    }
    if (offset == null) {
      offset = 0;
    }
    List<Inventory__c> records = [
      SELECT Facility__c, Facility__r.Name, Inventory_Name__c, Status__c
      FROM Inventory__c
      WHERE
        Facility__c IN :facilities.keySet()
        AND Inventory_Date__c >= :startOfMonth
        AND Inventory_Date__c < :startOfNextMonth
      ORDER BY Facility__r.Name ASC
      LIMIT :recordLimit
      OFFSET :offset
    ];
    Integer totalRows = [
      SELECT COUNT()
      FROM Inventory__c
      WHERE
        Facility__c IN :facilities.keySet()
        AND Inventory_Date__c >= :startOfMonth
        AND Inventory_Date__c < :startOfNextMonth
    ];

    // Build the response table.
    // Data going to client must do FLS, redact that which should not be readable to this user.
    DataTable.Table table = TC_InventoryStatus.buildTable(
      Security.stripInaccessible(AccessType.READABLE, records).getRecords()
    );

    // Remove from facilities map any facilities with inventory.
    for (Inventory__c i : records) {
      if (facilities.containsKey(i.Facility__c)) {
        facilities.remove(i.Facility__c);
      }
    }
    // Do any facilities remain?
    // Then it is these which have no Inventory.
    // Add any additional create rows and pass the returned table to the new ListResponse.
    return new ListResponse(
      TC_InventoryStatus.buildCreateInventoryRows(
        table,
        Datetime.now().format('MMMM YYYY'),
        facilities.values()
      ),
      totalRows + facilities.values().size()
    );
  }

  /**
   * getRecords allows the UI to retrieve Inventory__c sObjects to display in
   * a datatable.
   *
   * @param month (Date): filter by month, use null for today's month.
   * @param recordLimit (Integer): Maximum number of records to return.
   * @param offset (Integer): Optional offset for retrieving in batches.
   *
   * @return ListResponse: containing result data prepped for displaying in
   *         c-datatable UI component.
   * @throws AuraHandledException
   *
   * @example
   *   TC_InventoryStatus.getRecords(new List<String>{'Id','Facility__r.Name', 'Inventory_Name__c', 'Status__c'}, null, null, null);
   */
  @AuraEnabled(cacheable=true)
  public static ListResponse getRecords(
    Date month,
    Integer recordLimit,
    Integer offset
  ) {
    try {
      TC_InventoryStatus context = new TC_InventoryStatus();
      return context.getRecordsFiltered(month, recordLimit, offset);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}