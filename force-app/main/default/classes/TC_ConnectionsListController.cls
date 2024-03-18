public with sharing class TC_ConnectionsListController {
  @AuraEnabled
  public static ConnectionListWrapper getConnectionList(
    String listType,
    Integer amountToShow
  ) {
    User currentUser = [
      SELECT
        Id,
        Contact.AccountId,
        Contact.Account.ParentId,
        Contact.Account.Name,
        Contact.ToxClear_User_Type__c,
        Contact.ToxClear_Account_Type__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];

    List<Brand_Supplier_Connection__c> connections = new List<Brand_Supplier_Connection__c>();
    Integer connectionCount = 0;

    if (
      currentUser.Contact.ToxClear_User_Type__c == 'ToxClear Administrator' ||
      (currentUser.Contact.ToxClear_User_Type__c == 'ToxClear Standard User' &&
      listType == 'current')
    ) {
      String countString = getCountString(listType, currentUser);
      String queryString = getQueryString(listType, amountToShow, currentUser);

      connections = Database.query(queryString);
      connectionCount = Database.countQuery(countString);
    }

    return new ConnectionListWrapper(
      new DataTable.Table(
        createTableColumns(listType, currentUser),
        createTableRows(listType, connections, currentUser)
      ),
      connectionCount
    );
  }

  private static String getCountString(String listType, User currentUser) {
    String queryString = 'SELECT COUNT() FROM Brand_Supplier_Connection__c';
    queryString += getWhereClause(listType, currentUser);
    return queryString;
  }

  private static String getQueryString(
    String listType,
    Integer amountToShow,
    User currentUser
  ) {
    String queryString = 'SELECT Id, Name, Supplier_Name__c, Brand_Name__c, Requestor_Contact_Name__c, Connection_Date__c, CreatedDate, Active__c FROM Brand_Supplier_Connection__c';
    queryString += getWhereClause(listType, currentUser);
    if (listType == 'current') {
      queryString += ' ORDER BY Connection_Date__c DESC';
    } else {
      queryString += ' ORDER BY CreatedDate DESC';
    }
    queryString += ' LIMIT ' + amountToShow;
    return queryString;
  }

  private static String getWhereClause(String listType, User currentUser) {
    String queryString = '';
    if (listType == 'current' || listType == 'received') {
      if (currentUser.Contact.ToxClear_Account_Type__c == 'Brand') {
        queryString +=
          ' WHERE Brand_Account__c = \'' +
          currentUser.Contact.AccountId +
          '\'';
      } else if (currentUser.Contact.ToxClear_Account_Type__c == 'Supplier') {
        queryString +=
          ' WHERE Supplier_Account__c = \'' +
          currentUser.Contact.AccountId +
          '\'';
      } else if (currentUser.Contact.ToxClear_Account_Type__c == 'Facility') {
        queryString +=
          ' WHERE Supplier_Account__c = \'' +
          currentUser.Contact.Account.ParentId +
          '\'';
      }
    }
    if (listType == 'current') {
      queryString += ' AND Status__c = \'Approved\'';
    } else if (listType == 'received') {
      queryString +=
        ' AND Status__c = \'Requested\' AND Requestor_Contact__r.AccountId != \'' +
        currentUser.Contact.AccountId +
        '\'';
    } else if (listType == 'sent') {
      queryString +=
        ' WHERE (Status__c = \'Requested\' OR Status__c = \'Rejected\') AND Requestor_Contact__r.AccountId = \'' +
        currentUser.Contact.AccountId +
        '\'';
    }

    return queryString;
  }

  private static List<DataTable.Column> createTableColumns(
    String listType,
    User currentUser
  ) {
    List<DataTable.Column> returnList = new List<DataTable.Column>();
    returnList.add(new DataTable.Column('0', Label.Record));
    if (currentUser.Contact.ToxClear_Account_Type__c == 'Brand') {
      returnList.add(new DataTable.Column('1', Label.Supplier));
    } else {
      returnList.add(new DataTable.Column('1', Label.Brand));
    }
    returnList.add(new DataTable.Column('2', Label.TC_Requestor));
    if (listType == 'current') {
      returnList.add(new DataTable.Column('3', Label.TC_Date_Of_Connection));
      returnList.add(new DataTable.Column('4', Label.Active));
    } else {
      returnList.add(new DataTable.Column('3', Label.TC_Date_Of_Request));
    }

    return returnList;
  }

  private static List<DataTable.Row> createTableRows(
    String listType,
    List<Brand_Supplier_Connection__c> connections,
    User currentUser
  ) {
    List<DataTable.Row> returnList = new List<DataTable.Row>();

    for (Brand_Supplier_Connection__c connection : connections) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => connection.Id,
          'objectApiName' => 'Brand_Supplier_Connection__c',
          'actionName' => 'view'
        }
      };

      List<DataTable.Cell> tableCells = new List<DataTable.Cell>();
      tableCells.add(
        new DataTable.Cell(
          '0',
          connection.Name,
          pageRef,
          true,
          false,
          true,
          null,
          null,
          null,
          Label.Name
        )
      );

      if (currentUser.Contact.ToxClear_Account_Type__c == 'Brand') {
        tableCells.add(
          new DataTable.Cell('1', connection.Supplier_Name__c, Label.Supplier)
        );
      } else {
        tableCells.add(
          new DataTable.Cell('1', connection.Brand_Name__c, Label.Brand)
        );
      }
      tableCells.add(
        new DataTable.Cell(
          '2',
          connection.Requestor_Contact_Name__c,
          Label.TC_Requestor
        )
      );

      if (listType == 'current') {
        tableCells.add(
          new DataTable.Cell(
            '3',
            connection.Connection_Date__c == null
              ? ''
              : connection.Connection_Date__c.format('dd/MM/yyyy'),
            Label.TC_Date_Of_Connection
          )
        );
        DataTable.Cell newCell = new DataTable.Cell(
          '4',
          String.valueOf(connection.Active__c),
          true,
          false,
          null,
          Label.Active
        );

        newCell.disabled = true;
        tableCells.add(newCell);
      } else if (listType == 'received') {
        tableCells.add(
          new DataTable.Cell(
            '3',
            connection.CreatedDate.format('dd/MM/yyyy'),
            Label.TC_Date_Of_Request
          )
        );
      } else if (listType == 'sent') {
        tableCells.add(
          new DataTable.Cell(
            '3',
            connection.CreatedDate.format('dd/MM/yyyy'),
            Label.TC_Date_Of_Request
          )
        );
      }
      returnList.add(new DataTable.Row(connection.Id, tableCells));
    }

    return returnList;
  }

  public class ConnectionListWrapper {
    @AuraEnabled
    public DataTable.Table table;
    @AuraEnabled
    public Integer totalCount;
    @AuraEnabled
    public String error;

    public ConnectionListWrapper(DataTable.Table table, Integer totalCount) {
      this.table = table;
      this.totalCount = totalCount;
    }

    public ConnectionListWrapper(
      DataTable.Table table,
      Integer totalCount,
      String error
    ) {
      this.table = table;
      this.totalCount = totalCount;
      this.error = error;
    }
  }
}