public with sharing class ReportAccessListController {
  @AuraEnabled(cacheable=true)
  public static Boolean isCurrentUserAdminForReport(Id reportId) {
    try {
      List<Asset> reports = [SELECT AccountId FROM Asset WHERE Id = :reportId];
      System.debug(reports);
      if (!reports.isEmpty()) {
        List<AccountContactRelation> acrs = AccountRelationUtil.getFilteredACRsForAccountIds(
          new Set<Id>{ reports[0].AccountId },
          new Set<String>{ 'admin', 'cga' }
        );
        System.debug(acrs);
        User currentUser = MTCUserUtil.currentUserObj;
        for (AccountContactRelation acr : acrs) {
          if (currentUser.ContactId == acr.ContactId) {
            return true;
          }
        }
      }
      return false;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static ListResponse getTableData(
    Integer rowLimit,
    String orderBy,
    List<String> selectedRowIds,
    Id reportId
  ) {
    Boolean isAdmin = MTCUserUtil.isCurrentUserAdmin;

    DataTable.Table returnData = new DataTable.Table();
    try {
      Id userContactId = MTCUserUtil.currentUserContactId;
      String soql =
        'SELECT Contact_Group_Name_FF__c, Contact_Group__c, Report_Asset__c' +
        ' FROM Access__c' +
        ' WHERE Report_Asset__c = \'' +
        reportId +
        '\'';

      soql += (orderBy != null && orderBy != '') ? ' ORDER BY ' + orderBy : '';
      soql += ' LIMIT ' + rowLimit;

      List<DataTable.Column> columns = new List<DataTable.Column>();
      List<DataTable.Row> rows = new List<DataTable.Row>();

      columns = getColumns(orderBy, isAdmin);
      rows = getRows(soql, selectedRowIds, userContactId, isAdmin);

      returnData.columns = columns;
      returnData.rows = rows;
      return new ListResponse(returnData, rows.size());
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }

  private static List<DataTable.Column> getColumns(
    String orderBy,
    Boolean isAdmin
  ) {
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column(
        'Contact_Group_Name_FF__c',
        'Group name',
        orderBy.contains('Contact_Group_Name_FF__c')
          ? orderBy.substringAfter(' ')
          : ''
      )
    };
    if (isAdmin) {
      columns.add(new DataTable.Column('Remove', 'Remove'));
    }
    return columns;
  }

  private static List<DataTable.Row> getRows(
    String soql,
    List<String> selectedRowIds,
    String userContactId,
    Boolean isAdmin
  ) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Access__c access : (List<Access__c>) Database.query(soql)) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => access.id,
          'objectApiName' => 'Access__c',
          'actionName' => 'remove'
        }
      };
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell(
          'Contact_Group_Name_FF__c',
          access.Contact_Group_Name_FF__c,
          'Group name'
        )
      };
      if (isAdmin) {
        rowCells.add(
          new DataTable.Cell(
            'Remove',
            'Remove',
            null,
            true,
            false,
            true,
            'Remove',
            'customEvent',
            null,
            'Remove'
          )
        );
      }
      rows.add(
        new DataTable.Row(access.Id, access.Contact_Group_Name_FF__c, rowCells)
      );
    }
    return rows;
  }

  @AuraEnabled
  public static APIResponse deleteAccess(Id accessId) {
    try {
      Access__c toDelete = new Access__c(Id = accessId);
      delete new List<Access__c>{ toDelete };
      return new APIResponse('OK', 200, 'Success');
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return new APIResponse('Bad Request', 400, e.getMessage());
    }
  }
}