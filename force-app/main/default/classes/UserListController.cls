public with sharing class UserListController {
  @AuraEnabled
  public static ListResponse getTableData(
    Integer rowLimit,
    String orderBy,
    List<String> selectedRowIds,
    String context,
    String filterStatus,
    String filterSearch,
    String filterDateFrom,
    String filterDateTo,
    Boolean filterUnassignedOnly,
    String groupId
  ) {
    if (filterUnassignedOnly == null) {
      filterUnassignedOnly = false;
    }
    context = context != null ? context : '';
    DataTable.Table returnData = new DataTable.Table();
    List<User> users = new List<User>();
    Set<Id> unassignedUserIds = new Set<Id>();
    Set<Id> groupMemberUserIds = new Set<Id>();
    User u = MTCUserUtil.currentUserObj;
    Boolean isAdmin = MTCUserUtil.isCurrentUserAdmin;
    Set<Id> accountIdsIsAdminFor = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();
    Set<Id> contactIdsCurrentUsercanAdminister = AccountRelationUtil.getContactIdsFromAccountIds(
      accountIdsIsAdminFor
    );
    Set<Id> MTC_PROFILE_IDS = MTCUserUtil.mtcProfiles.keySet();

    try {
      if (filterUnassignedOnly) {
        unassignedUserIds = new Map<Id, User>(
            [
              SELECT Id
              FROM User
              WHERE
                ContactId IN :contactIdsCurrentUsercanAdminister
                AND ProfileId IN :MTC_PROFILE_IDS
                AND Contact.Approval_Status__c != :Label.MTC_Approval_DeclinedStatus
                AND ContactId NOT IN (
                  SELECT Contact__c
                  FROM Group_Membership__c
                  WHERE
                    Contact_Group__r.Account__c IN :accountIdsIsAdminFor
                    AND (Contact_Group__r.Expiry__c = NULL
                    OR Contact_Group__r.Expiry__c >= TODAY)
                )
            ]
          )
          .keyset();
      }
      if (!String.isEmpty(groupId)) {
        groupMemberUserIds = new Map<Id, User>(
            [
              SELECT Id
              FROM User
              WHERE
                ContactId IN (
                  SELECT Contact__c
                  FROM Group_Membership__c
                  WHERE
                    Contact_Group__c = :groupId
                    AND Contact__c IN :contactIdsCurrentUsercanAdminister
                )
                AND ProfileId IN :MTC_PROFILE_IDS
            ]
          )
          .keyset();
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    filterSearch = (filterSearch != null &&
      filterSearch != '')
      ? String.escapeSingleQuotes(filterSearch)
      : '';
    try {
      String soql =
        'SELECT Id, Name, Username, Email, LastLoginDate, ContactId, IsActive, Contact.Approval_Status__c FROM User ' +
        ' WHERE ContactId IN :contactIdsCurrentUsercanAdminister' +
        ' AND ProfileId IN :MTC_PROFILE_IDS' +
        ' AND Contact.Approval_Status__c != \'' +
        Label.MTC_Approval_DeclinedStatus +
        '\'';
      soql += (filterStatus != null &&
        filterStatus != '')
        ? ' AND IsActive = ' + (filterStatus == 'Active' ? 'true' : 'false')
        : '';
      soql += (filterSearch != null &&
        filterSearch != '')
        ? ' AND Email LIKE \'%' + filterSearch + '%\''
        : '';
      soql += (filterDateFrom != null &&
        filterDateFrom != '')
        ? ' AND LastLoginDate >= ' + filterDateFrom + 'T00:00:00Z'
        : '';
      soql += (filterDateTo != null &&
        filterDateTo != '')
        ? ' AND LastLoginDate <= ' + filterDateTo + 'T00:00:00Z'
        : '';
      soql += (filterUnassignedOnly != null && filterUnassignedOnly)
        ? ' AND Id IN :unassignedUserIds'
        : '';
      soql += (!String.isEmpty(groupId))
        ? ' AND Id IN :groupMemberUserIds'
        : '';
      Integer totalRows = new List<User>((List<User>) Database.query(soql))
        .size();
      soql += (orderBy != null && orderBy != '') ? ' ORDER BY ' + orderBy : '';
      soql += ' LIMIT ' + rowLimit;
      users = new List<User>((List<User>) Database.query(soql));

      Set<Id> userContactIds = new Set<id>();
      for (User user : users) {
        userContactIds.add(user.ContactId);
      }

      Map<Id, List<String>> groupsMap = buildGroupsMap(userContactIds, groupId);

      Map<Id, List<String>> acrContact2AccountsMap = buildACRContact2AccountsMap(
        userContactIds
      );

      List<DataTable.Column> columns = new List<DataTable.Column>();
      List<DataTable.Row> rows = new List<DataTable.Row>();
      switch on context {
        when 'home' {
          columns = buildColumnsHome(orderBy);
          rows = buildRowsHome(users, groupsMap);
        }
        when else {
          columns = buildColumnsElse(orderBy, isAdmin);
          rows = buildRowsElse(
            users,
            selectedRowIds,
            acrContact2AccountsMap,
            groupsMap,
            isAdmin
          );
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

  private static List<Datatable.Row> buildRowsHome(
    List<User> users,
    Map<Id, List<String>> groupsMap
  ) {
    List<Datatable.Row> rows = new List<DataTable.Row>();
    for (User user : users) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => user.id,
          'objectApiName' => 'User__c',
          'actionName' => 'view'
        }
      };
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell('Name', user.Name, 'Name'),
        new DataTable.Cell(
          'LastLoginDate',
          user.LastLoginDate != null
            ? String.valueOf(user.LastLoginDate.format())
            : '',
          'Last Login'
        ),
        new DataTable.Cell(
          'LinkedGroups',
          groupsMap.get(user.ContactId) != null
            ? String.valueOf(groupsMap.get(user.ContactId))
                .remove('(')
                .remove(')')
            : 'Unassigned',
          'Linked Groups'
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
      rows.add(new DataTable.Row(user.Id, rowCells));
    }
    return rows;
  }

  private static List<DataTable.Column> buildColumnsHome(String orderBy) {
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column(
        'Name',
        'Name',
        orderBy.contains('Name') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'LastLoginDate',
        'Last Login',
        orderBy.contains('LastLoginDate') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column('LinkedGroups', 'Linked Groups'),
      new DataTable.Column('View', 'View')
    };
    return columns;
  }

  private static List<Datatable.Row> buildRowsElse(
    List<User> users,
    List<String> selectedRowIds,
    Map<Id, List<String>> accountsMap,
    Map<Id, List<String>> groupsMap,
    Boolean isAdmin
  ) {
    List<Datatable.Row> rows = new List<DataTable.Row>();
    for (User user : users) {
      Map<String, Object> pageRef = new Map<String, Object>{
        'type' => 'standard__recordPage',
        'attributes' => new Map<String, Object>{
          'recordId' => user.id,
          'objectApiName' => 'User__c',
          'actionName' => 'view'
        }
      };
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell(
          'Check',
          selectedRowIds.contains(user.Id) ? 'true' : 'false',
          true,
          false,
          null,
          'Check'
        ),
        new DataTable.Cell('Username', user.Username, 'Username'),
        new DataTable.Cell(
          'LastLoginDate',
          user.LastLoginDate != null
            ? String.valueOf(user.LastLoginDate.format())
            : '',
          'Last Login'
        ),
        new DataTable.Cell(
          'LinkedAccounts',
          accountsMap.get(user.ContactId) != null
            ? String.valueOf(accountsMap.get(user.ContactId))
                .remove('(')
                .remove(')')
            : '',
          'Linked accounts'
        ),
        new DataTable.Cell(
          'LinkedGroups',
          groupsMap.get(user.ContactId) != null
            ? String.valueOf(groupsMap.get(user.ContactId))
                .remove('(')
                .remove(')')
            : 'Unassigned',
          'Linked Groups'
        ),
        new DataTable.Cell('IsActive', statusColumnValue(user), 'IsActive'),
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
      if (!isAdmin) {
        rowCells.remove(0);
      }
      rows.add(new DataTable.Row(user.Id, rowCells));
    }
    return rows;
  }

  public static String statusColumnValue(User u) {
    String v = u.IsActive ? 'Active' : 'Inactive';
    if (u.Contact.Approval_Status__c == Label.MTC_Approval_RequestedStatus) {
      v += ', ' + Label.MTC_Approval_RequestingAccess;
    }
    return v;
  }

  private static List<DataTable.Column> buildColumnsElse(
    String orderBy,
    Boolean isAdmin
  ) {
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column('Check', true),
      new DataTable.Column(
        'Username',
        'Username',
        orderBy.contains('Username') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'LastLoginDate',
        'Last Login',
        orderBy.contains('LastLoginDate') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column('LinkedAccounts', 'Linked Accounts'),
      new DataTable.Column('LinkedGroups', 'Linked Groups'),
      new DataTable.Column(
        'IsActive',
        'Status',
        orderBy.contains('IsActive') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column('View', 'View')
    };
    if (!isAdmin) {
      columns.remove(0);
    }
    return columns;
  }

  @AuraEnabled(cacheable=true)
  public static Integer countOfUnassigned() {
    Integer theCount = 0;
    Set<Id> accountIdsIsAdminFor = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();
    Set<Id> contactIdsCurrentUsercanAdminister = AccountRelationUtil.getContactIdsFromAccountIds(
      accountIdsIsAdminFor
    );
    Set<Id> MTC_PROFILE_IDS = MTCUserUtil.mtcProfiles.keySet();

    if (!contactIdsCurrentUsercanAdminister.isEmpty()) {
      theCount = [
        SELECT COUNT()
        FROM User
        WHERE
          ContactId IN :contactIdsCurrentUsercanAdminister
          AND ProfileId IN :MTC_PROFILE_IDS
          AND Contact.Approval_Status__c != 'Rejected'
          AND ContactId NOT IN (
            SELECT Contact__c
            FROM Group_Membership__c
            WHERE
              Contact_Group__r.Account__c IN :accountIdsIsAdminFor
              AND (Contact_Group__r.Expiry__c = NULL
              OR Contact_Group__r.Expiry__c >= TODAY)
          )
      ];
    }
    return theCount;
  }

  private static Map<Id, List<String>> buildGroupsMap(
    Set<Id> userContactIds,
    Id groupId
  ) {
    String groupMembersSOQL =
      'SELECT Id, Contact__c,Contact_Group__r.Name, Contact_Group__r.Group_Name_FF__c' +
      ' FROM Group_Membership__c' +
      ' WHERE' +
      ' Contact__c IN :userContactIds';
    if (String.isEmpty(groupId)) {
      groupMembersSOQL += ' AND (Contact_Group__r.Expiry__c = NULL OR Contact_Group__r.Expiry__c >= TODAY)';
    }
    List<Group_Membership__c> groupMembers = (List<Group_Membership__c>) Database.query(
      groupMembersSOQL
    );
    Map<Id, List<String>> groupsMap = new Map<Id, List<String>>();

    for (Group_Membership__c groupMem : groupMembers) {
      List<String> groupsList = new List<String>();
      if (groupsMap.containsKey(groupMem.Contact__c)) {
        groupsMap.get(groupMem.Contact__c)
          .add(groupMem.Contact_Group__r.Group_Name_FF__c);
      } else {
        groupsList.add(groupMem.Contact_Group__r.Group_Name_FF__c);
        groupsMap.put(groupMem.Contact__c, groupsList);
      }
    }
    return groupsMap;
  }

  public static Map<Id, List<String>> buildACRContact2AccountsMap(
    Set<Id> userContactIds
  ) {
    List<AccountContactRelation> relations = [
      SELECT Account.Name, ContactId, AccountId
      FROM AccountContactRelation
      WHERE ContactId IN :userContactIds
    ];
    Map<Id, List<String>> acrContact2AccountsMap = new Map<Id, List<String>>();

    for (AccountContactRelation acr : relations) {
      List<String> accounts = new List<String>();
      if (acrContact2AccountsMap.containsKey(acr.contactId)) {
        acrContact2AccountsMap.get(acr.contactId)
          .add(String.valueOf(acr.Account.Name));
      } else {
        accounts.add(String.valueOf(acr.Account.Name));
        acrContact2AccountsMap.put(acr.ContactId, accounts);
      }
    }
    return acrContact2AccountsMap;
  }

  @AuraEnabled(cacheable=false)
  public static String exportAsCSV() {
    Set<Id> accountIdsIsAdminFor = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();
    Set<Id> contactIdsCurrentUsercanAdminister = AccountRelationUtil.getContactIdsFromAccountIds(
      accountIdsIsAdminFor
    );
    Set<Id> MTC_PROFILE_IDS = MTCUserUtil.mtcProfiles.keySet();

    List<User> usersForExport = [
      SELECT ContactId
      FROM User
      WHERE
        ContactId IN :contactIdsCurrentUsercanAdminister
        AND ProfileId IN :MTC_PROFILE_IDS
        AND Contact.Approval_Status__c != :Label.MTC_Approval_DeclinedStatus
    ];

    Set<Id> userIds = new Set<Id>();
    Set<Id> userContactIds = new Set<id>();
    for (User user : usersForExport) {
      userContactIds.add(user.ContactId);
      userIds.add(user.Id);
    }

    Map<Id, List<String>> groupsMap = buildGroupsMap(userContactIds, null);

    Map<Id, List<String>> acrContact2AccountsMap = buildACRContact2AccountsMap(
      userContactIds
    );

    String result = '"Firstname","Lastname","Username","Email","Active","Linked_Accounts","Linked_Groups"';
    List<String> rows = new List<String>{ result };
    for (User u : [
      SELECT
        Contact.Firstname,
        Contact.Lastname,
        Username,
        Contact.Email,
        IsActive,
        ContactId
      FROM User
      WHERE Id IN :userIds
      ORDER BY Lastname
    ]) {
      List<String> groups4user = groupsMap.get(u.ContactId);
      String groupsForUser = groups4user == null
        ? ''
        : String.join(groups4user, ';');

      List<String> accounts4user = acrContact2AccountsMap.get(u.ContactId);
      String accountsForUser = accounts4user == null
        ? ''
        : String.join(accounts4user, ';');

      List<String> cols = new List<String>{
        String.isEmpty(u.Contact.Firstname)
          ? ''
          : u.Contact.Firstname.escapeCsv(),
        String.isEmpty(u.Contact.Lastname)
          ? ''
          : u.Contact.Lastname.escapeCsv(),
        String.isEmpty(u.Username) ? '' : u.Username.escapeCsv(),
        String.isEmpty(u.Contact.Email) ? '' : u.Contact.Email.escapeCsv(),
        u.IsActive ? '1' : '0',
        accountsForUser.escapeCsv(),
        groupsForUser.escapeCsv()
      };
      rows.add(String.join(cols, ','));
    }
    return String.join(rows, '\n');
  }
}