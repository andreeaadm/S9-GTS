public with sharing class ReportListController {
  public class TestRunException extends Exception {
  }

  private static final List<String> PUBLISHED_REPORT_STATUSES = new List<String>{
    'Official',
    'Withdrawn'
  };
  public static final String STATUS_WITHDRAWN = 'Withdrawn';

  @AuraEnabled
  public static ListResponse getTableData(
    Integer rowLimit,
    String orderBy,
    List<String> selectedRowIds,
    String context,
    String filterStatus,
    String filterReportType,
    String filterSearch,
    String filterDateFrom,
    String filterDateTo,
    Boolean filterHiddenOnly,
    Boolean filterWithdrawnOnly,
    Boolean filterUnassignedOnly,
    String groupId
  ) {
   //String orderBy = 'Last_Activity_Date__c DESC';
    context = context != null ? context : '';
    DataTable.Table returnData = new DataTable.Table();
    Boolean isAdmin = MTCUserUtil.isCurrentUserAdmin;
    Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();
    Set<Id> groupReportIds = new Set<Id>();
    //List<Asset> assetList = new List<Asset>();
    String unassignedReportIdsCSV;
	
   /* assetList = [Select Id,Date_Revised__c From Asset Where AccountId IN :myRelatedAccountIds]; 
        for(Asset ast : assetList){
            if(ast.Date_Revised__c != null){
                orderBy = 'Date_Revised__c DESC';
                break;
            }
            else{
                continue;
            }
        } */ 
      
    if (!String.isEmpty(groupId)) {
      try {
        groupReportIds = new Map<Id, Asset>(
            [
              SELECT Id
              FROM Asset
              WHERE
                Id IN (
                  SELECT Report_Asset__c
                  FROM Access__c
                  WHERE Contact_Group__c = :groupId
                )
            ]
          )
          .keyset();
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
        if (Test.isRunningTest()) {
          throw new ReportListController.TestRunException(e.getMessage() + ' - ' + e.getStackTraceString());
        }
      }
    }
    if (filterUnassignedOnly) {
      Set<Id> unassignedReportIds = new Map<Id, Asset>(
          [
            SELECT Id
            FROM Asset
            WHERE
              AccountId IN :myRelatedAccountIds
              AND Id NOT IN (
                SELECT Report_Asset__c
                FROM Access__c
                WHERE
                  Contact_Group__r.Account__c IN :myRelatedAccountIds
                  AND (Contact_Group__r.Expiry__c = NULL
                  OR Contact_Group__r.Expiry__c >= TODAY)
              )
          ]
        )
        .keyset();
      unassignedReportIdsCSV = String.join(
        new List<Id>(unassignedReportIds),
        '\',\''
      );
    }

    filterSearch = (filterSearch != null &&
      filterSearch != '')
      ? String.escapeSingleQuotes(filterSearch)
      : '';

    try {
      String soqlSelect = 'SELECT Id, Name, Account_Name_FF__c, Type__c, Products_Covered__c, Client_Reference__c, Date_Revised__c, Date_Issued__c,Last_Activity_Date__c, MTC_Status__c, Is_Hidden_By_Intertek__c FROM Asset ';
      String soqlCount = 'SELECT Count() FROM Asset ';
      String soqlFilters =
        ' WHERE MTC_Status__c IN :PUBLISHED_REPORT_STATUSES AND Is_Hidden_By_Intertek__c = FALSE AND RecordTypeId = ' +
        '\'' +
        AssetUtil.reportRT.recordId +
        '\'' +
        ' AND AccountId IN (\'' +
        String.join(new List<Id>(myRelatedAccountIds), '\',\'') +
        '\')';

      soqlFilters += !String.isEmpty(filterStatus)
        ? ' AND MTC_Status__c = \'' + filterStatus + '\''
        : '';

      soqlFilters += (filterUnassignedOnly != null && filterUnassignedOnly)
        ? ' AND Id IN (\'' + unassignedReportIdsCSV + '\')'
        : '';

      soqlFilters += (filterReportType != null &&
        filterReportType != '')
        ? ' AND Type__c = \'' + filterReportType + '\''
        : '';

      soqlFilters += (filterSearch != null &&
        filterSearch != '')
        ? ' AND (Name LIKE \'%' +
          filterSearch +
          '%\' OR Client_Reference__c LIKE \'%' +
          filterSearch +
          '%\' OR Account_Name_FF__c LIKE \'%' +
          filterSearch +
          '%\' OR Tokenized_Products_Covered__c LIKE \'%' +
          filterSearch +
          '%\')'
        : '';

      soqlFilters += (filterDateFrom != null &&
        filterDateFrom != '')
        ? ' AND ( Date_Issued__c >= ' +
          filterDateFrom +
          ' OR Date_Revised__c >= ' +
          filterDateFrom +
          ')'
        : '';

      soqlFilters += (filterDateTo != null &&
        filterDateTo != '')
        ? ' AND ( Date_Issued__c <= ' +
          filterDateTo +
          ' OR Date_Revised__c <= ' +
          filterDateTo +
          ')'
        : '';

      soqlFilters += (!String.isEmpty(groupId))
        ? ' AND Id IN :groupReportIds'
        : '';

      Integer totalRows = Database.countQuery(soqlCount + soqlFilters);

      String soql = soqlSelect + soqlFilters;
      soql += (orderBy != null &&
        orderBy != '')
        ? ' ORDER BY ' + orderBy + ' NULLS LAST'
        : '';

      List<DataTable.Column> columns = new List<DataTable.Column>();
      List<DataTable.Row> rows = new List<DataTable.Row>();
      switch on context {
        when 'home' {
          soql += ' LIMIT ' + rowLimit;
          columns = getColumnsHome(orderBy);
          rows = getRowsHome(soql, selectedRowIds, groupReportIds);
        }
        when else {
          if (totalRows / rowLimit > 20 && rowLimit <= totalRows / rowLimit) {
            rowLimit = totalRows / rowLimit;
            if (rowLimit > 400) {
              rowLimit = 400;
            }
          }
          soql += ' LIMIT ' + rowLimit;

          columns = getColumnsElse(orderBy, isAdmin);
          rows = getRowsElse(soql, selectedRowIds, isAdmin);
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

  private static List<DataTable.Column> getColumnsHome(String orderBy) {
    return new List<DataTable.Column>{
      new DataTable.Column(
        'Name',
        'Report Number',
        orderBy.contains('Name') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Date_Issued__c',
        'Issued',
        orderBy.contains('Date_Issued__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'MTC_Status__c',
        'Status',
        orderBy.contains('MTC_Status__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column('View', 'View')
    };
  }

  private static List<DataTable.Column> getColumnsElse(
    String orderBy,
    Boolean isAdmin
  ) {
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column('Check', true),
      new DataTable.Column(
        'Name',
        'Report Number',
        orderBy.contains('Name') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Account_Name_FF__c',
        'Account',
        orderBy.contains('Account') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Type__c',
        'Report Type',
        orderBy.contains('Type__c') ? orderBy.substringAfter(' ') : ''
      ),
      // Products_Covered__c is a long text area and cannot be sorted in Apex
      new DataTable.Column('Products_Covered__c', 'Products Covered'),
      new DataTable.Column(
        'Client_Reference__c',
        'Client Reference',
        orderBy.contains('Client_Reference__c')
          ? orderBy.substringAfter(' ')
          : ''
      ),
      new DataTable.Column(
        'Date_Issued__c',
        'Issued',
        orderBy.contains('Date_Issued__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Last_Activity_Date__c',
        'Last Official Date',
        orderBy.contains('Last_Activity_Date__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'MTC_Status__c',
        'Status',
        orderBy.contains('MTC_Status__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column('View', 'View')
    };

    Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();
    Boolean singleAccount = myRelatedAccountIds.size() == 1;
    if (singleAccount) {
      // remove from the higher numbers first!
      columns.remove(2);
    }
    return columns;
  }

  private static List<DataTable.Row> getRowsHome(
    String soql,
    List<String> selectedRowIds,
    Set<Id> groupReportIds
  ) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Asset a : (List<Asset>) Database.query(soql)) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => a.id,
          'objectApiName' => 'Asset',
          'actionName' => 'view'
        }
      };
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell('Name', a.Name, 'Report name'),
        new DataTable.Cell(
          'Date_Issued__c',
          a.Date_Issued__c != null
            ? String.valueOf(a.Date_Issued__c.format())
            : '',
          'Date Issued'
        ),
        new DataTable.Cell('MTC_Status__c', a.MTC_Status__c, 'Status'),
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
      rows.add(new DataTable.Row(a.Id, rowCells));
    }
    return rows;
  }

  private static List<DataTable.Row> getRowsElse(
    String soql,
    List<String> selectedRowIds,
    Boolean isAdmin
  ) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();
    Boolean singleAccount = myRelatedAccountIds.size() == 1;

    for (Asset a : (List<Asset>) Database.query(soql)) {
     /* Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => a.id,
          'objectApiName' => 'Asset',
          'actionName' => 'view'
        }
      };*/
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell(
          'Check',
          selectedRowIds.contains(a.Id) ? 'true' : 'false',
          true,
          false,
          null,
          'Check'
        ),
        new DataTable.Cell('Name', a.Name, 'Report name'),
        new DataTable.Cell(
          'Account_Name_FF__c',
          a.Account_Name_FF__c,
          'Account'
        ),
        new DataTable.Cell('Type__c', a.Type__c, 'Type'),
        new DataTable.Cell(
          'Products_Covered__c',
          a.Products_Covered__c,
          'Products covered'
        ),
        new DataTable.Cell(
          'Client_Reference__c',
          a.Client_Reference__c,
          'Client reference'
        ),
        new DataTable.Cell(
          'Date_Issued__c',
          a.Date_Issued__c != null
            ? String.valueOf(a.Date_Issued__c.format())
            : '',
          'Issued'
        ),
        new DataTable.Cell(
          'Last_Activity_Date__c',
          a.Last_Activity_Date__c != null
            ? String.valueOf(a.Last_Activity_Date__c.format())
            : '',
          'Last Official Date'
        ),
        new DataTable.Cell('MTC_Status__c', a.MTC_Status__c, 'Status'),
        new DataTable.Cell(
          'View',
          'View',
          null,
          true,
          false,
          true,
          null,
          'customEvent',
          null,
          'View'
        )
      };

      if (singleAccount) {
        // remove from the higher numbers first!
        rowCells.remove(2);
      }
      rows.add(new DataTable.Row(a.Id, rowCells));
    }
    return rows;
  }

  @AuraEnabled
  public static APIResponse hideReports(List<String> selectedReportIds) {
    try {
      User thisUser = new User(
        Id = UserInfo.getUserId(),
        Hidden_Report_IDs_JSON__c = JSON.serialize(selectedReportIds)
      );
      update thisUser;
      return new APIResponse('OK', 200, 'Success');
    } catch (Exception e) {
      return new APIResponse('Bad Request', 400, e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static Integer countOfUnassigned() {
    Integer theCount = 0;
    if (MTCUserUtil.isCurrentUserAdmin) {
      Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();
      for (
        Asset report : AssetUtil.getReportsWithActiveAccessesFromAccountIds(
          myRelatedAccountIds
        )
      ) {
        if (report.Report_Accesses__r.isEmpty()) {
          theCount++;
        }
      }
    }
    return theCount;
  }

  @AuraEnabled(cacheable=false)
  public static String exportAsCSV() {
    Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();

    String result = '"Report Number","Account_Name","Reference","Type","Products_Covered","Standards","Date_Issued","Date_Revised","Status"';
    List<String> rows = new List<String>{ result };
    for (Asset report : [
      SELECT
        Name,
        Account_Name_FF__c,
        Type__c,
        Products_Covered__c,
        Standards__c,
        Client_Reference__c,
        Date_Revised__c,
        Date_Issued__c,
        MTC_Status__c
      FROM Asset
      WHERE
        MTC_Status__c IN :PUBLISHED_REPORT_STATUSES
        AND Is_Hidden_By_Intertek__c = FALSE
        AND RecordTypeId = :AssetUtil.reportRT.recordId
        AND AccountId IN :myRelatedAccountIds
      ORDER BY Date_Issued__c DESC
      LIMIT 21000
    ]) {
      List<String> cols = new List<String>{
        report.Name.escapeCsv(),
        report.Account_Name_FF__c.escapeCsv(),
        String.isBlank(report.Client_Reference__c)
          ? ''
          : report.Client_Reference__c.escapeCsv(),
        String.isBlank(report.Type__c) ? '' : report.Type__c.escapeCsv(),
        String.isBlank(report.Products_Covered__c)
          ? ''
          : report.Products_Covered__c.escapeCsv(),
        String.isBlank(report.Standards__c)
          ? ''
          : report.Standards__c.escapeCsv(),
        report.Date_Issued__c == null ? '' : report.Date_Issued__c.format(),
        report.Date_Revised__c == null ? '' : report.Date_Revised__c.format(),
        String.isBlank(report.MTC_Status__c)
          ? ''
          : report.MTC_Status__c.escapeCsv()
      };
      rows.add(String.join(cols, ','));
    }
    return String.join(rows, '\n');
  }

  /**History
   * 12-11-2023   kamlesh.kahar   Added check for admin user    https://intertek.atlassian.net/browse/MBS-307
   */
  @AuraEnabled(cacheable=true)
  public static Boolean isAdminUser(){
    return MTCUserUtil.isCurrentUserAdmin;
  }
}