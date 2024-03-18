public with sharing class TC_ConnectionRequestController {
  @AuraEnabled
  public static String getUserType() {
    TC_ExperienceCloud userHelper = new TC_ExperienceCloud();
    if (userHelper.isSupplierAdminUser) {
      return 'supplier';
    } else if (userHelper.isBrandAdminUser) {
      return 'brand';
    } else {
      return '';
    }
  }

  @AuraEnabled
  public static TC_ConnectionsListController.ConnectionListWrapper getSearchTable(
    String userType,
    Integer amountToShow,
    String nameSearch,
    String countrySearch
  ) {
    Map<Integer, List<Account>> accountMap = new Map<Integer, List<Account>>();

    try {
      accountMap = TC_ConnectionRequestWithoutSharing.getAccounts(
        userType,
        amountToShow,
        nameSearch,
        countrySearch
      );
    } catch (Exception e) {
      return new TC_ConnectionsListController.ConnectionListWrapper(
        new DataTable.Table(
          getTableColumns(userType),
          new List<DataTable.Row>()
        ),
        0,
        e.getMessage()
      );
    }

    return new TC_ConnectionsListController.ConnectionListWrapper(
      new DataTable.Table(
        getTableColumns(userType),
        getTableRows(userType, accountMap.values()[0])
      ),
      new List<Integer>(accountMap.keySet())[0]
    );
  }

  @AuraEnabled
  public static String createConnection(
    String userType,
    String otherAccountId
  ) {
    User currentUser = [
      SELECT Contact.AccountId, ContactId
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];

    Brand_Supplier_Connection__c newConnection = new Brand_Supplier_Connection__c(
      Status__c = 'Requested',
      Requestor_Contact__c = currentUser.ContactId
    );

    if (userType == 'supplier') {
      newConnection.Brand_Account__c = otherAccountId;
      newConnection.Supplier_Account__c = currentUser.Contact.AccountId;
    } else {
      newConnection.Brand_Account__c = currentUser.Contact.AccountId;
      newConnection.Supplier_Account__c = otherAccountId;
    }

    try {
      TC_ConnectionRequestWithoutSharing.insertConnection(newConnection);
    } catch (Exception e) {
      return e.getMessage();
    }

    return 'success';
  }

  public static List<DataTable.Column> getTableColumns(String userType) {
    List<DataTable.Column> returnColumns = new List<DataTable.Column>();

    if (userType == 'supplier') {
      returnColumns.add(new DataTable.Column('0', Label.TC_Brand_Name));
    } else {
      returnColumns.add(new DataTable.Column('0', Label.TC_Supplier_Name));
    }
    returnColumns.add(new DataTable.Column('1', Label.MTC_Country));
    returnColumns.add(new DataTable.Column('2', ''));

    return returnColumns;
  }

  public static List<DataTable.Row> getTableRows(
    String userType,
    List<Account> accounts
  ) {
    String firstColumnName = (userType == 'supplier'
      ? Label.TC_Brand_Name
      : Label.TC_Supplier_Name);

    List<DataTable.Row> returnRows = new List<DataTable.Row>();

    for (Account acc : accounts) {
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>();
      rowCells.add(new DataTable.Cell('0', acc.Name, firstColumnName));
      rowCells.add(new DataTable.Cell('1', acc.Country__c, Label.MTC_Country));
      rowCells.add(
        new DataTable.Cell(
          '2',
          Label.Connect,
          null,
          true,
          true,
          false,
          'customEvent',
          'customEvent',
          'IntkBrandOneBtn',
          '',
          false,
          ''
        )
      );
      returnRows.add(new DataTable.Row(acc.Id, acc.Name, rowCells));
    }

    return returnRows;
  }
}