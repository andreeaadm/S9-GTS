public with sharing class GroupListController {

  /**
   * History:
   * 27-11-2023   Kamlesh.kahar   MBS-309   Added filter for Active/Inactive groups.
   */
  @AuraEnabled
  public static ListResponse getTableData(
    Integer rowLimit,
    String orderBy,
    List<String> selectedRowIds,
    String context,
    String filterGroupName,
    String filterStatus
  ) {
    context = context != null ? context : '';

    Boolean isAdmin = MTCUserUtil.isCurrentUserAdmin;

    filterGroupName = (filterGroupName != null &&
      filterGroupName != '')
      ? String.escapeSingleQuotes(filterGroupName)
      : '';
    DataTable.Table returnData = new DataTable.Table();
    try {
      Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();
      String relatedAccounts =
        '(\'' +
        String.join(new List<Id>(myRelatedAccountIds), '\',\'') +
        '\')';

      String soql =
        'SELECT Id, Group_Name__c, Group_Name_FF__c, Group_Description__c,CreatedDate, Account_Name__c, Group_Members__c' +
        ' FROM Contact_Group__c' +
        ' WHERE Account__c IN ' +
        relatedAccounts;

      if (filterGroupName != null && filterGroupName != '') {
        soql += ' AND Group_Name__c LIKE \'%' + filterGroupName + '%\'';
      }
      if(String.isNotBlank(filterStatus)){
        soql += ' AND Has_Expired_FF__c = ' + filterStatus;
      }
      Integer totalRows = new List<Contact_Group__c>(
          (List<Contact_Group__c>) Database.query(soql)
        )
        .size();
      soql += (orderBy != null && orderBy != '') ? ' ORDER BY ' + orderBy : '';
      soql += ' LIMIT ' + rowLimit;

      List<DataTable.Column> columns = new List<DataTable.Column>();
      List<DataTable.Row> rows = new List<DataTable.Row>();
      switch on context {
        when 'home' {
          columns = getColumnsHome(orderBy);
          rows = getRowsHome(soql, selectedRowIds);
        }
        when else {
          columns = getColumnsElse(orderBy, isAdmin);
          rows = getRowsElse(soql, selectedRowIds, isAdmin);
        }
      }
      returnData.columns = columns;
      returnData.rows = rows;
      return new ListResponse(returnData, totalRows);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }

  private static List<DataTable.Column> getColumnsHome(String orderBy) {
    return new List<DataTable.Column>{
      new DataTable.Column(
        'Group_Name_FF__c',
        'Group Name',
        orderBy.contains('Group_Name__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Account_Name__c',
        'Account',
        orderBy.contains('Account_Name__c') ? orderBy.substringAfter(' ') : ''
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
        'Group_Name_FF__c',
        'Group Name',
        orderBy.contains('Group_Name__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column('Group_Description__c', 'Group Description', ''),
      new DataTable.Column(
        'CreatedDate',
        'Date Created',
        orderBy.contains('CreatedDate') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Account_Name__c',
        'Account',
        orderBy.contains('Account_Name__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Group_Members__c',
        'No. of Users',
        orderBy.contains('Group_Members__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column('View', 'View')
    };

    Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();
    Boolean singleAccount = myRelatedAccountIds.size() == 1;
    if (singleAccount) {
      // remove from the higher numbers first!
      columns.remove(4);
    }
    if (!isAdmin) {
      columns.remove(0);
    }
    return columns;
  }

  private static List<DataTable.Row> getRowsHome(
    String soql,
    List<String> selectedRowIds
  ) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Contact_Group__c cg : (List<Contact_Group__c>) Database.query(soql)) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => cg.Id,
          'objectApiName' => 'Contact_Group__c',
          'actionName' => 'view'
        }
      };
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell(
          'Group_Name_FF__c',
          cg.Group_Name_FF__c,
          'Group Name'
        ),
        new DataTable.Cell('Account_Name__c', cg.Account_Name__c, 'Account'),
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
      rows.add(new DataTable.Row(cg.Id, rowCells));
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

    for (Contact_Group__c cg : (List<Contact_Group__c>) Database.query(soql)) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => cg.id,
          'objectApiName' => 'Contact_Group__c',
          'actionName' => 'view'
        }
      };
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell(
          'Check',
          selectedRowIds.contains(cg.Id) ? 'true' : 'false',
          true,
          false,
          null,
          'Check'
        ),
        new DataTable.Cell(
          'Group_Name_FF__c',
          cg.Group_Name_FF__c,
          'Group Name'
        ),
        new DataTable.Cell(
          'Group_Description__c',
          cg.Group_Description__c,
          'Group Description'
        ),
        new DataTable.Cell(
          'CreatedDate',
          String.valueOf(cg.CreatedDate.format()),
          'Date created'
        ),
        new DataTable.Cell('Account_Name__c', cg.Account_Name__c, 'Account'),
        new DataTable.Cell(
          'Group_Members__c',
          String.valueOf(cg.Group_Members__c),
          'No. of users'
        ),
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
        // remove from the higher numbers first!
        rowCells.remove(4);
      }
      if (!isAdmin) {
        rowCells.remove(0);
      }
      rows.add(new DataTable.Row(cg.Id, rowCells));
    }
    return rows;
  }

  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getAccountOptions() {
    List<Map<String, String>> accountOptions = new List<Map<String, String>>();
    Set<Id> accountIdsIsAdminFor = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin(
      MTCUserUtil.currentUserContactId
    );
    for (Account a : [
      SELECT Id, Name
      FROM Account
      WHERE Id IN :accountIdsIsAdminFor
    ]) {
      accountOptions.add(
        new Map<String, String>{ 'label' => a.Name, 'value' => a.Id }
      );
    }
    return accountOptions;
  }

  @AuraEnabled(cacheable=true)
  public static String checkForDupeGroup(String groupName, String accountId) {
    try {
      return ([
          SELECT COUNT()
          FROM Contact_Group__c
          WHERE Group_Name__c = :groupName AND Account__c = :accountId
        ] == 0)
        ? 'false'
        : 'true';
    } catch (Exception e) {
      return 'false';
    }
  }

  @AuraEnabled
  public static APIResponse insertGroup(Contact_Group__c newGroup) {
    try {
      if (
        [
          SELECT COUNT()
          FROM Contact_Group__c
          WHERE
            Account__c = :newGroup.Account__c
            AND Group_Name__c = :newGroup.Group_Name__c
        ] > 0
      ) {
        return new APIResponse(
          'Bad Request',
          400,
          'That group name is already taken. Please try again.'
        );
      }
      Set<Id> relatedAccountIds = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();

      if (relatedAccountIds.contains(newGroup.Account__c)) {
        insert newGroup;
        return new APIResponse('OK', 200, 'Success');
      } else {
        return new APIResponse('Bad Request', 400, 'Invalid Account');
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return new APIResponse('Bad Request', 400, e.getMessage());
    }
  }

  @AuraEnabled
  public static APIResponse updateGroup(Contact_Group__c editedGroup) {
    try {
      List<Contact_Group__c> originals = [
        SELECT Account__c, Is_Default_Group__c
        FROM Contact_Group__c
        WHERE Id = :editedGroup.Id
      ];
      if (originals.isEmpty()) {
        return new APIResponse(
          'Bad Request',
          400,
          'Could not find the group referenced.'
        );
      }
      Contact_Group__c original = originals[0];

      if (original.Is_Default_Group__c) {
        return new APIResponse(
          'Bad Request',
          400,
          'A default group cannot be modified.'
        );
      }

      if (
        [
          SELECT COUNT()
          FROM Contact_Group__c
          WHERE
            Group_Name__c = :editedGroup.Group_Name__c
            AND Account__c = :original.Account__c
            AND Id != :editedGroup.Id
        ] > 0
      ) {
        return new APIResponse(
          'Bad Request',
          400,
          'That group name is already taken. Please try again.'
        );
      }
      Set<Id> relatedAccountIds = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();
      if (relatedAccountIds.contains(original.Account__c)) {
        update editedGroup;
        return new APIResponse('OK', 200, 'Success');
      } else {
        return new APIResponse('Bad Request', 400, 'Invalid Account');
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return new APIResponse('Bad Request', 400, e.getMessage());
    }
  }

  /**
   * History:
   * 27-11-2023   Kamlesh.Kahar   MBS-308   Changed the group delete behavior to set the expiry date.
   */
  @AuraEnabled
  public static APIResponse deleteGroups(List<String> selectedRowIds) {
    try {
      Set<Id> groupIds = new Set<Id>((List<Id>) selectedRowIds);
      Set<Id> adminAccountIds = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();

      List<Contact_Group__c> groupsToDelete = [
        SELECT Id
        FROM Contact_Group__c
        WHERE
          Id IN :groupIds
          AND Account__c IN :adminAccountIds
          AND Is_Default_Group__c = FALSE
      ];
      if (groupsToDelete.isEmpty()) {
        return new APIResponse(
          'Bad Request',
          400,
          'Default Groups cannot be deleted or edited.'
        );
      }
      List<Contact_Group__c> groupsToDeactivate = [
        SELECT Id
        FROM Contact_Group__c
        WHERE
          Id IN :groupsToDelete
          AND Has_Expired_FF__c = False
      ];
      if(groupsToDeactivate.isEmpty()){
        return new APIResponse(
          'Already Inactive',
          400,
          'The selected group(s) are already inactive.'
        );
      }

      //Set yesterday's date to make the contact group inactive!
      for(Contact_Group__c cg :groupsToDeactivate){
        cg.Expiry__c = System.today().addDays(-1);
      }

      update groupsToDeactivate;
      //delete groupsToDelete;
      return new APIResponse('OK', 200, 'Success');
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return new APIResponse('Bad Request', 400, e.getMessage());
    }
  }

  /**@Author: Kamlesh.kahar@intertek.com
   * @Created: 12-12-2023
   * @Params:
   *      @selectedRowIds:- List of selected contact groups.
   * History:
   * 12-12-2023   Kamlesh.Kahar   MBS-312   Restore the expired contact groups.
   */
  @AuraEnabled
  public static APIResponse restoreGroups(List<String> selectedRowIds){
    try {
      Set<Id> groupIds = new Set<Id>((List<Id>) selectedRowIds);
      Set<Id> adminAccountIds = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();

      List<Contact_Group__c> groupsToRestore = [
        SELECT Id
        FROM Contact_Group__c
        WHERE
          Id IN :groupIds
          AND Account__c IN :adminAccountIds
          AND Has_Expired_FF__c = true
      ];

      if(groupsToRestore.isEmpty()){
        return new APIResponse(
          'Can\'t Restore!',
          400,
          'These groups can\'t be restored!'
        );
      }

      //Clear the expiry date to restore the group (To activate them again)
      for(Contact_Group__c cg :groupsToRestore){
        cg.Expiry__c = null;
      }

      update groupsToRestore;
      //delete groupsToDelete;
      return new APIResponse('OK', 200, 'Success');
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return new APIResponse('Bad Request', 400, e.getMessage());
    }
  }

  @AuraEnabled(cacheable=false)
  public static String exportAsCSV() {
    Set<Id> myRelatedAccountIds = AccountRelationUtil.getCachedRelatedMTCAccountIdsforContact();
    Set<Id> MTC_PROFILE_IDS = MTCUserUtil.mtcProfiles.keySet();

    List<Contact_Group__c> groups = [
      SELECT
        Group_Name_FF__c,
        Group_Description__c,
        (SELECT Contact__c FROM Group_Memberships__r),
        (
          SELECT
            Report_Asset__r.Report_Name_FF__c,
            Report_Asset__r.Client_Reference__c
          FROM Accesses__r
          WHERE Report_Asset__r.Is_Hidden_By_Intertek__c = FALSE
        )
      FROM Contact_Group__c
      WHERE Account__c IN :myRelatedAccountIds
    ];

    Set<Id> contactIds = new Set<Id>();
    for (Group_Membership__c gm : [
      SELECT Contact__c
      FROM Group_Membership__c
      WHERE Contact_Group__r.Account__c IN :myRelatedAccountIds
    ]) {
      contactIds.add(gm.Contact__c);
    }

    Map<Id, List<String>> acrContact2AccountsMap = UserListController.buildACRContact2AccountsMap(
      contactIds
    );

    Map<Id, User> conId2User = new Map<Id, User>();
    for (User usr : [
      SELECT
        Contact.Firstname,
        Contact.Lastname,
        Username,
        Contact.Email,
        IsActive,
        ContactId
      FROM User
      WHERE
        ContactId IN :contactIds
        AND ProfileId IN :MTC_PROFILE_IDS
        AND Contact.Approval_Status__c != :Label.MTC_Approval_DeclinedStatus
    ]) {
      conId2User.put(usr.ContactId, usr);
    }

    List<String> rows = new List<String>();

    rows.add('** LIST OF USERS BY GROUP **');
    rows.add(
      'Group_Name,Group_Description,Firstname,Lastname,Username,Email,Active,Linked_Accounts'
    );
    for (Contact_Group__c cg : groups) {
      String escapedGroupName = cg.Group_Name_FF__c.escapeCsv();
      String escapedGroupDesc = String.isBlank(cg.Group_Description__c)
        ? ''
        : cg.Group_Description__c.escapeCsv();

      rows.add(
        String.join(new List<String>{ escapedGroupName, escapedGroupDesc }, ',')
      );

      for (Group_Membership__c gm : cg.Group_Memberships__r) {
        User u = conId2User.get(gm.Contact__c);
        if (u != null) {
          List<String> accounts4user = acrContact2AccountsMap.get(u.ContactId);
          String accountsForUser = accounts4user == null
            ? ''
            : String.join(accounts4user, ';').escapeCsv();

          List<String> cols = new List<String>{
            escapedGroupName,
            escapedGroupDesc,
            String.isEmpty(u.Contact.Firstname)
              ? ''
              : u.Contact.Firstname.escapeCsv(),
            String.isEmpty(u.Contact.Lastname)
              ? ''
              : u.Contact.Lastname.escapeCsv(),
            u.Username.escapeCsv(),
            String.isEmpty(u.Contact.Email) ? '' : u.Contact.Email.escapeCsv(),
            u.IsActive ? '1' : '0',
            accountsForUser
          };
          rows.add(String.join(cols, ','));
        }
      }
    }

    rows.add('** LIST OF REPORTS BY GROUP **');
    rows.add('Group_Name,Group_Description,Report_Number,Client_Reference');
    for (Contact_Group__c cg : groups) {
      String escapedGroupName = cg.Group_Name_FF__c.escapeCsv();
      String escapedGroupDesc = String.isBlank(cg.Group_Description__c)
        ? ''
        : cg.Group_Description__c.escapeCsv();

      rows.add(
        String.join(new List<String>{ escapedGroupName, escapedGroupDesc }, ',')
      );

      for (Access__c access : cg.Accesses__r) {
        if (access.Report_Asset__r != null) {
          rows.add(
            String.join(
              new List<String>{
                escapedGroupName,
                escapedGroupDesc,
                access.Report_Asset__r.Report_Name_FF__c.escapeCsv(),
                String.isBlank(access.Report_Asset__r.Client_Reference__c)
                  ? ''
                  : access.Report_Asset__r.Client_Reference__c.escapeCsv()
              },
              ','
            )
          );
        }
      }
    }
    return String.join(rows, '\n');
  }
}