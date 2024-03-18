public with sharing class ProjectListController {
  @AuraEnabled(cacheable=true)
  public static ListResponse getRelatedReportsAsTableData(Id projectId) {
    DataTable.Table returnData = new DataTable.Table();
    try {
      String soql =
        'SELECT Id, Name, Type__c' +
        ' FROM Asset' +
        ' WHERE MTC_Project__c = \'' +
        projectId +
        '\'';

      List<DataTable.Column> columns = new List<DataTable.Column>{
        new DataTable.Column('Name', 'Report Name', ''),
        new DataTable.Column('Type', 'Report Type', ''),
        new DataTable.Column('View', 'View')
      };

      List<DataTable.Row> rows = new List<DataTable.Row>();
      for (Asset report : (List<Asset>) Database.query(soql)) {
        Map<String, Object> pageRef = new Map<String, Object>{
          'type' => 'standard__recordPage',
          'attributes' => new Map<String, Object>{
            'recordId' => report.id,
            'objectApiName' => 'Asset',
            'actionName' => 'view'
          }
        };
        List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
          new DataTable.Cell('Name', report.Name, 'Report name'),
          new DataTable.Cell('Type', report.Type__c, 'Report type'),
          new DataTable.Cell(
            'View',
            'View',
            pageRef,
            true,
            false,
            true,
            null,
            null,
            null,
            'View'
          )
        };
        rows.add(new DataTable.Row(report.Id, rowCells));
      }
      returnData.columns = columns;
      returnData.rows = rows;
      return new ListResponse(returnData, rows.size());
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      if (Test.isRunningTest()) {
        throw new ReportListController.TestRunException(e.getMessage() + ' - ' + e.getStackTraceString());
      }
      return null;
    }
  }
  @AuraEnabled(cacheable=true)
  public static ListResponse getTableData(
    Integer rowLimit,
    String orderBy,
    String context,
    String filterStatus,
    String filterSearch,
    String filterDateFrom,
    String filterDateTo
  ) {
    context = context != null ? context : '';
    filterSearch = (filterSearch != null &&
      filterSearch != '')
      ? String.escapeSingleQuotes(filterSearch)
      : '';
    DataTable.Table returnData = new DataTable.Table();
    try {
      Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();

      String soql =
        'SELECT Id, Name, Account_Name_FF__c, Quote_Number__c, PurchaseOrder_Number__c, Scheduled_Start_Date__c, Schedule_Complete__c, Status__c' +
        ' FROM MTC_Project__c' +
        ' WHERE Account__c IN (\'' +
        String.join(new List<Id>(myRelatedAccountIds), '\',\'') +
        '\') AND Name != null';
      soql += (filterSearch != null &&
        filterSearch != '')
        ? ' AND (Name LIKE \'%' +
          filterSearch +
          '%\' OR Account_Name_FF__c LIKE \'%' +
          filterSearch +
          '%\' OR Quote_Number__c LIKE \'%' +
          filterSearch +
          '%\' OR PurchaseOrder_Number__c LIKE \'%' +
          filterSearch +
          '%\')'
        : '';
      soql += (filterStatus != null &&
        filterStatus != '')
        ? ' AND Status__c = \'' + filterStatus + '\''
        : '';
      soql += (filterDateFrom != null &&
        filterDateFrom != '')
        ? ' AND Scheduled_Start_Date__c >= ' + filterDateFrom
        : '';
      soql += (filterDateTo != null &&
        filterDateTo != '')
        ? ' AND Scheduled_Start_Date__c <= ' + filterDateTo
        : '';
      Integer totalRows = new List<MTC_Project__c>(
          (List<MTC_Project__c>) Database.query(soql)
        )
        .size();
      soql += (orderBy != null && orderBy != '') ? ' ORDER BY ' + orderBy : '';
      soql += ' LIMIT ' + rowLimit;

      List<DataTable.Column> columns = new List<DataTable.Column>();
      List<DataTable.Row> rows = new List<DataTable.Row>();
      switch on context {
        when 'X' {
          // Leaving context support here in case we need different project lists in different contexts in future
          // columns = getColumnsX(orderBy);
          // rows = getRowsX(soql);
        }
        when else {
          columns = getColumnsElse(orderBy);
          rows = getRowsElse(soql);
        }
      }
      returnData.columns = columns;
      returnData.rows = rows;
      return new ListResponse(returnData, totalRows);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      if (Test.isRunningTest()) {
        throw new ReportListController.TestRunException(e.getMessage() + ' - ' + e.getStackTraceString());
      }
      return null;
    }
  }

  private static List<DataTable.Column> getColumnsElse(String orderBy) {
    List<DataTable.Column> cols = new List<DataTable.Column>{
      new DataTable.Column(
        'Name',
        'Project Number',
        orderBy.contains('Name') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Account_Name_FF__c',
        'Account',
        orderBy.contains('Account_Name_FF__c')
          ? orderBy.substringAfter(' ')
          : ''
      ),
      new DataTable.Column(
        'PurchaseOrder_Number__c',
        'Purchase Order',
        orderBy.contains('PurchaseOrder_Number__c')
          ? orderBy.substringAfter(' ')
          : ''
      ),
      new DataTable.Column(
        'Quote_Number__c',
        'Quote',
        orderBy.contains('Quote_Number__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Scheduled_Start_Date__c',
        'Scheduled Start',
        orderBy.contains('Scheduled_Start_Date__c')
          ? orderBy.substringAfter(' ')
          : ''
      ),
      new DataTable.Column(
        'Schedule_Complete__c',
        'Scheduled End',
        orderBy.contains('Schedule_Complete__c')
          ? orderBy.substringAfter(' ')
          : ''
      ),
      new DataTable.Column(
        'Status__c',
        'Status',
        orderBy.contains('Status__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column('View', 'View')
    };
    Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();
    Boolean singleAccount = myRelatedAccountIds.size() == 1;
    if (singleAccount) {
      cols.remove(1);
    }
    return cols;
  }

  private static List<DataTable.Row> getRowsElse(String soql) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();
    Boolean singleAccount = myRelatedAccountIds.size() == 1;
    for (MTC_Project__c p : (List<MTC_Project__c>) Database.query(soql)) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => p.id,
          'objectApiName' => 'MTC_Project__c',
          'actionName' => 'view'
        }
      };
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell('Name', p.Name, 'Project Number'),
        new DataTable.Cell(
          'Account_Name_FF__c',
          p.Account_Name_FF__c,
          'Account'
        ),
        new DataTable.Cell(
          'PurchaseOrder_Number__c',
          p.PurchaseOrder_Number__c,
          'Purchase Order'
        ),
        new DataTable.Cell('Quote_Number__c', p.Quote_Number__c, 'Quote'),
        new DataTable.Cell(
          'Scheduled_Start_Date__c',
          p.Scheduled_Start_Date__c != null
            ? String.valueOf(p.Scheduled_Start_Date__c.format())
            : '',
          'Scheduled start'
        ),
        new DataTable.Cell(
          'Schedule_Complete__c',
          p.Schedule_Complete__c != null
            ? String.valueOf(p.Schedule_Complete__c.format())
            : '',
          'Scheduled end'
        ),
        new DataTable.Cell('Status__c', p.Status__c, 'Status'),
        new DataTable.Cell(
          'View',
          'View',
          pageRef,
          true,
          false,
          true,
          null,
          null,
          null,
          'View'
        )
      };
      if (singleAccount) {
        rowCells.remove(1);
      }
      rows.add(new DataTable.Row(p.Id, rowCells));
    }
    return rows;
  }

  @AuraEnabled(cacheable=false)
  public static String exportAsCSV() {
    Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();

    String result = '"Project_Number","Description","Account_Name","Quote_Number","PO_Number","Primary_Salesperson","Project_Manager","Start","End","Status"';
    List<String> rows = new List<String>{ result };
    for (MTC_Project__c proj : [
      SELECT
        Name,
        Description__c,
        Account_Name_FF__c,
        Quote_Number__c,
        PurchaseOrder_Number__c,
        Scheduled_Start_Date__c,
        Schedule_Complete__c,
        Primary_Salesperson__c,
        Project_Manager__c,
        Status__c
      FROM MTC_Project__c
      WHERE Account__c IN :myRelatedAccountIds
      ORDER BY Name
      LIMIT 25000
    ]) {
      List<String> cols = new List<String>{
        proj.Name.escapeCsv(),
        String.isBlank(proj.Description__c)
          ? ''
          : proj.Description__c.escapeCsv(),
        proj.Account_Name_FF__c.escapeCsv(),
        String.isBlank(proj.Quote_Number__c)
          ? ''
          : proj.Quote_Number__c.escapeCsv(),
        String.isBlank(proj.PurchaseOrder_Number__c)
          ? ''
          : proj.PurchaseOrder_Number__c.escapeCsv(),
        String.isBlank(proj.Primary_Salesperson__c)
          ? ''
          : proj.Primary_Salesperson__c.escapeCsv(),
        String.isBlank(proj.Project_Manager__c)
          ? ''
          : proj.Project_Manager__c.escapeCsv(),
        proj.Scheduled_Start_Date__c == null
          ? ''
          : '' + proj.Scheduled_Start_Date__c.format(),
        proj.Schedule_Complete__c == null
          ? ''
          : '' + proj.Schedule_Complete__c.format(),
        String.isBlank(proj.Status__c) ? '' : proj.Status__c.escapeCsv()
      };
      rows.add(String.join(cols, ','));
    }
    return String.join(rows, '\n');
  }
}