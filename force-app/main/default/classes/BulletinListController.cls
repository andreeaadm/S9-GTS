public with sharing class BulletinListController {
  @AuraEnabled(cacheable=true)
  public static ListResponse getBulletins(Integer rowLimit, String context) {
    DataTable.Table returnData = new DataTable.Table();
    try {
      rowLimit = context == BulletinUtil.pinnedType ? null : rowLimit;
      List<Bulletin__c> bulletins = BulletinUtil.getBulletins(
        rowLimit,
        context
      );
      returnData.columns = getColumns();
      returnData.rows = getRows(bulletins);

      return new ListResponse(returnData, bulletins.size());
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @TestVisible
  private static List<DataTable.Column> getColumns() {
    return new List<DataTable.Column>{
      new DataTable.Column(Label.TC_Date_Sent, Label.TC_Date_Sent),
      new DataTable.Column(Label.Subject, Label.Subject),
      // Removed description 07-03-2022 Jira: IT-1275
      new DataTable.Column(Label.From.capitalize(), Label.From.capitalize()),
      new DataTable.Column('View', '')
    };
  }

  @TestVisible
  private static List<DataTable.Row> getRows(List<Bulletin__c> bulletins) {
    List<DataTable.Row> rows = new List<DataTable.Row>();

    for (Bulletin__c bulletin : bulletins) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => bulletin.Id,
          'objectApiName' => 'Bulletin__c',
          'actionName' => 'view'
        }
      };

      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell(
          Label.TC_Date_Sent,
          String.valueOf(bulletin.Sent_Date__c.format()),
          Label.TC_Date_Sent
        ),
        new DataTable.Cell(Label.Subject, bulletin.Subject__c, Label.Subject),
        new DataTable.Cell(Label.From.capitalize(), bulletin.From__c, Label.From.capitalize()),
        new DataTable.Cell(
          'View',
          Label.View,
          pageRef,
          true,
          false,
          true,
          null,
          null,
          null,
          ''
        )
      };

      rows.add(new DataTable.Row(bulletin.Id, rowCells));
    }

    return rows;
  }
}