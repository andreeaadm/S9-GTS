public with sharing class CaseListController {
  @AuraEnabled(cacheable=true)
  public static ListResponse getCases(Integer rowLimit, String orderBy) {
    DataTable.Table returnData = new DataTable.Table();
    try {
      Integer totalRows = CaseUtil.getCases('', '', null).size();
      List<Case> cases = new List<Case>(
        CaseUtil.getCases(orderBy, '', rowLimit)
      );
      returnData.columns = getColumns(orderBy);
      returnData.rows = getRows(cases);
      return new ListResponse(returnData, totalRows);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }

  static List<DataTable.Column> getColumns(String orderBy) {
    return new List<DataTable.Column>{
      new DataTable.Column(
        'CaseNumber',
        'Case number',
        orderBy.contains('CaseNumber') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Subject',
        'Subject',
        orderBy.contains('Subject') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Status',
        'Status',
        orderBy.contains('Status') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Priority',
        'Priority',
        orderBy.contains('Priority') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column('View', 'View')
    };
  }

  static List<DataTable.Row> getRows(List<Case> cases) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Case c : cases) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => c.Id,
          'objectApiName' => 'Case',
          'actionName' => 'view'
        }
      };
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell('CaseNumber', c.CaseNumber, 'Case number'),
        new DataTable.Cell('Subject', c.Subject, 'Subject'),
        new DataTable.Cell('Status', c.Status, 'Status'),
        new DataTable.Cell('Priority', c.Priority, 'Priority'),
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
      rows.add(new DataTable.Row(c.Id, rowCells));
    }
    return rows;
  }
}