public with sharing class ContactGroupUtil {
  public static void setCGDupCheckFieldNoDML(List<Contact_Group__c> cgs) {
    for (Contact_Group__c cg : cgs) {
      if (String.isBlank(cg.DupCheck__c)) {
        cg.DupCheck__c = '' + cg.Group_Name__c.toLowerCase() + cg.Account__c;
      }
    }
  }
  public static void setAccessDupCheckFieldNoDML(List<Access__c> accesses) {
    for (Access__c a : accesses) {
      if (String.isBlank(a.DupCheck__c)) {
        a.DupCheck__c = '' + a.Contact_Group__c + a.Report_Asset__c;
      }
    }
  }
  public static void setGMbshipDupCheckFieldNoDML(
    List<Group_Membership__c> gms
  ) {
    for (Group_Membership__c gm : gms) {
      if (String.isBlank(gm.DupCheck__c)) {
        gm.DupCheck__c = '' + gm.Contact__c + gm.Contact_Group__c;
      }
    }
  }

  public static void updateHasExpiredFieldOnUpdateNoDML(
    List<Contact_Group__c> cgs
  ) {
    Date today = Date.today();
    for (Contact_Group__c cg : cgs) {
      if (cg.Expiry__c == null || cg.Expiry__c >= today) {
        cg.Has_Expired__c = false;
      } else if (cg.Expiry__c < today) {
        cg.Has_Expired__c = true;
      }
    }
  }

  public static Contact_Group__c constructGroup(
    Id accountId,
    String groupName
  ) {
    return new Contact_Group__c(
      Account__c = accountId,
      Group_Name__c = groupName,
      DupCheck__c = '' + groupName.toLowerCase() + accountId
    );
  }
  public static Contact_Group__c constructGroup(
    Id accountId,
    String groupName,
    Date expiry
  ) {
    Contact_Group__c cg = constructGroup(accountId, groupName);
    cg.Expiry__c = expiry;
    return cg;
  }
  // From members return a set of contact_group Ids
  public static Set<Id> getContactGroupIdsFrom(
    List<Group_Membership__c> groupMembers
  ) {
    Set<Id> cgIds = new Set<Id>();

    for (Group_Membership__c memb : groupMembers) {
      cgIds.add(memb.Contact_Group__c);
    }
    return cgIds;
  }
  // From members return a set of contact_group Ids
  public static Map<Id, Contact_Group__c> getContactGroupsForAccounts(
    Set<Id> accountIds
  ) {
    if (accountIds.isEmpty()) {
      return new Map<Id, Contact_Group__c>();
    }
    return new Map<Id, Contact_Group__c>(
      [
        SELECT Id, Group_Name_FF__c, Account__c, Expiry__c
        FROM Contact_Group__c
        WHERE Account__c IN :accountIds
      ]
    );
  }

  public static APIResponse linkGroupsToReports(
    List<Contact_Group__c> groups,
    List<Asset> reports
  ) {
    if (groups == null || reports == null) {
      return new APIResponse('Bad request', 400, 'Invalid data');
    } else {
      Map<Id, Contact_Group__c> cgs = new Map<Id, Contact_Group__c>(groups);
      Map<Id, Asset> assets = new Map<Id, Asset>(reports);
      cgs = new Map<Id, Contact_Group__c>(
        [SELECT Account__c FROM Contact_Group__c WHERE Id IN :cgs.keySet()]
      );
      assets = new Map<Id, Asset>(
        [SELECT AccountId FROM Asset WHERE Id IN :assets.keySet()]
      );

      List<Access__c> newAccesses = new List<Access__c>();
      for (Asset a : assets.values()) {
        for (Contact_Group__c cg : cgs.values()) {
          if (a.AccountId == cg.Account__c) {
            newAccesses.add(linkGroupToReport(cg, a, false));
          }
        }
      }
      Database.insert(newAccesses, false);
      return new APIResponse('OK', 200);
    }
  }

  public static APIResponse unlinkGroupsFromReports(
    List<Contact_Group__c> groups,
    List<Asset> reports
  ) {
    if (groups == null || reports == null) {
      return new APIResponse('Bad request', 400, 'Invalid data');
    } else {
      Map<Id, Contact_Group__c> groupsMap = new Map<Id, Contact_Group__c>(
        groups
      );
      Map<Id, Asset> reportsMap = new Map<Id, Asset>(reports);

      List<Access__c> accessesToDelete = new List<Access__c>(
        [
          SELECT Id
          FROM Access__c
          WHERE
            Contact_Group__c IN :groupsMap.keyset()
            AND Report_Asset__c IN :reportsMap.keyset()
        ]
      );
      Database.delete(accessesToDelete, false);
      return new APIResponse('OK', 200);
    }
  }

  // Links a single contact group to a report
  public static Access__c linkGroupToReport(
    Contact_Group__c grp,
    Asset report,
    Boolean store
  ) {
    if (grp == null || report == null) {
      return new Access__c();
    }
    Access__c newAccess = new Access__c(
      Contact_Group__c = grp.Id,
      Report_Asset__c = report.Id,
      DupCheck__c = '' + grp.Id + report.Id
    );
    if (store) {
      insert newAccess;
    }
    return newAccess;
  }

  // Links a single contact to a contact group
  public static Group_Membership__c linkContactToGroup(
    Contact con,
    Contact_Group__c grp,
    Boolean store
  ) {
    if (con == null || grp == null) {
      return new Group_Membership__c();
    }
    Group_Membership__c newMembership = new Group_Membership__c(
      Contact__c = con.Id,
      Contact_Group__c = grp.Id,
      DupCheck__c = '' + con.Id + grp.Id
    );
    if (store) {
      insert newMembership;
    }
    return newMembership;
  }


  /**
   * History:
   *    26-09-2023  MBS-305   Kamlesh.kahar   Fix: Now a CGA from other account can be added to the secondary account's contact group.
   */

  // links a list of contacts to ContactGroups
  public static List<Group_Membership__c> linkContactsToGroups(
    Set<Id> contIds,
    List<Id> grpIds,
    Boolean store
  ) {
    List<Group_Membership__c> memberships = new List<Group_Membership__c>();
    Set<Id> groupAccIds = new Set<Id>();
    Map<Id, AccountContactRelation> cgaACRMap = new Map<Id, AccountContactRelation>();
    if (contIds == null || grpIds == null) {
      return memberships;
    }
    
    for(Contact_Group__c cg :[SELECT Account__c FROM Contact_Group__c WHERE Id IN :grpIds]){
      groupAccIds.add(cg.Account__c);
    }

    for(AccountContactRelation acr :[SELECT ContactID, AccountId
                                   FROM AccountContactRelation
                                   WHERE AccountId = :groupAccIds
                                   AND ContactID IN :contIds
                                   AND MTC_Role__c = 'CGA']){
                                    cgaACRMap.put(acr.ContactId, acr);
                                   }

    for (Id contId : contIds) {
      AccountContactRelation acr = cgaACRMap.get(contId);
      for (Id grpId : grpIds) {
        // Block any CGA's being added to a Group if a CGA on the same account as contact group.
        if(acr != null && groupAccIds.contains(acr.AccountId) && acr.ContactId == contId){
          continue;
        }
        memberships.add(
          new Group_Membership__c(
            Contact__c = contId,
            Contact_Group__c = grpId,
            DupCheck__c = '' + contId + grpId
          )
        );
      }
    }
    if (store) {
      // Allow failures as duplicate Group memberships may aleady exist.
      Database.insert(memberships, false);
    }

    return memberships;
  }

  // Unlinks a list of contacts from a contact group
  //     aka delete membership records
  public static void unlinkContactsFromGroup(
    List<Contact> cons,
    Contact_Group__c grp
  ) {
    Map<Id, Contact> contacts = new Map<Id, Contact>(cons);
    List<Group_Membership__c> members = [
      SELECT Id
      FROM Group_Membership__c
      WHERE Contact__c IN :contacts.keySet() AND Contact_Group__c = :grp.Id
    ];
    delete members;
  }
  // Unlinks a list of groups from a report(asset)
  //     aka delete access records
  public static void unlinkGroupsFromReport(
    List<Contact_Group__c> groups,
    Id reportId
  ) {
    if (reportId != null && !groups.isEmpty()) {
      Map<Id, Contact_Group__c> GroupsMap = new Map<Id, Contact_Group__c>(
        groups
      );
      List<Access__c> accesses = [
        SELECT Id
        FROM Access__c
        WHERE
          Report_Asset__c = :reportId
          AND Contact_Group__c IN :groupsMap.keySet()
      ];
      delete accesses;
    }
  }
  // Unlinks a list of reports(asset) from a group
  //     aka delete access records
  public static void unlinkReportsFromGroup(List<Asset> reports, Id groupId) {
    if (groupId != null && !reports.isEmpty()) {
      Map<Id, Asset> reportsMap = new Map<Id, Asset>(reports);
      List<Access__c> accesses = [
        SELECT Id
        FROM Access__c
        WHERE
          Contact_Group__c = :groupId
          AND Report_Asset__c IN :reportsMap.keySet()
      ];
      delete accesses;
    }
  }

  // unlinks a list of contacts from Contact Groups by removing their Group Membership links.
  public static void unlinkContactsFromGroups(
    Set<Id> contIds,
    List<Id> grpIds
  ) {
    try {
      List<Group_Membership__c> memberships = [
        SELECT Id
        FROM Group_Membership__c
        WHERE Contact__c IN :contIds AND Contact_Group__c IN :grpIds
      ];

      delete memberships;
    } catch (Exception e) {
      //Allow failures to fall silent
    }
  }

  // Given a list of group Ids, returns a set of report Ids (asset Ids)
  public static Set<Id> getReportIdsRelatedToGroups(Set<Id> groupIds) {
    Set<Id> reportIds = new Set<Id>();
    if (!groupIds.isEmpty()) {
      for (Access__c access : [
        SELECT Report_Asset__c
        FROM Access__c
        WHERE Contact_Group__c IN :groupIds
      ]) {
        reportIds.add(access.Report_Asset__c);
      }
    }
    return reportIds;
  }

  public static List<Group_Membership__c> getGroupMembershipsForContacts(
    Set<Id> contactIds
  ) {
    if (contactIds.isEmpty()) {
      return new List<Group_Membership__c>();
    }
    return [
      SELECT Contact_Group__c, Contact_Group__r.Account__c, Contact__c
      FROM Group_Membership__c
      WHERE Contact__c IN :contactIds
    ];
  }

  // Given a user Id, returns a list of Group Membershipts for the user.
  public static List<Group_Membership__c> getGroupMembershipsForUser(
    Id userId
  ) {
    Id contactId = [SELECT ContactId FROM User WHERE Id = :userId].ContactId;
    return [
      SELECT Contact_Group__r.Group_Name__c, Contact_Group__r.Group_Name_FF__c
      FROM Group_Membership__c
      WHERE Contact__c = :contactId
    ];
  }

  // Given a list of contact groups, returns a set of account ids
  public static Set<Id> getAccountIdsFromContactGroup(
    List<Contact_Group__c> groups
  ) {
    Set<Id> accountIds = new Set<Id>();
    for (Contact_Group__c cg : groups) {
      accountIds.add(cg.Account__c);
    }
    return accountIds;
  }

  // Given a list of group memberships, returns a map of contact Ids with their associated account Ids
  public static Map<Id, Id> getAssociatedAccountIdsPerContactFromGroupMemberships(
    List<Group_Membership__c> groups
  ) {
    Map<Id, Id> contactIdToAccountIdMap = new Map<Id, Id>();
    Set<Id> contactIds = new Set<Id>();
    for (Group_Membership__c gm : groups) {
      contactIds.add(gm.Contact__c);
    }

    for (Contact c : [SELECT AccountId FROM Contact WHERE ID IN :contactIds]) {
      contactIdToAccountIdMap.put(c.Id, c.AccountId);
    }
    return contactIdToAccountIdMap;
  }

  // Given a list of group memberships, returns a map of contact group Ids with their associated account Ids
  // for each membership
  public static Map<Id, Id> getContactGroupIdsAndAssociatedAccountIdsFromGroupMemberships(
    List<Group_Membership__c> groups
  ) {
    Map<Id, Id> contactGroupIdsToAccountIdMap = new Map<Id, Id>();
    Set<Id> contactGroupIds = new Set<Id>();
    for (Group_Membership__c gm : groups) {
      contactGroupIds.add(gm.Contact_Group__c);
    }

    for (Contact_Group__c cG : [
      SELECT Id, Account__c
      FROM Contact_Group__c
      WHERE ID IN :contactGroupIds
    ]) {
      contactGroupIdsToAccountIdMap.put(cg.Id, cg.Account__c);
    }
    return contactGroupIdsToAccountIdMap;
  }

  // Given a list of groups and a report id, grants access to the groups passed in
  //    and revokes access from ones that aren't
  public static APIResponse grantReportAccessBasedOnSelection(
    List<Contact_Group__c> groups,
    Id reportId
  ) {
    if (reportId != null) {
      List<Access__c> accessToDelete = new List<Access__c>();
      List<Contact_Group__c> cgsToLink = new List<Contact_Group__c>();
      Map<Id, Contact_Group__c> groupsMap = new Map<Id, Contact_Group__c>(
        groups
      );
      Set<Id> groupsWithAccess = new Set<Id>();
      for (Access__c a : [
        SELECT Id, Contact_Group__c, Report_Asset__c
        FROM Access__c
        WHERE Report_Asset__c = :reportId
      ]) {
        groupsWithAccess.add(a.Contact_Group__c);
        if (!groupsMap.keyset().contains(a.Contact_Group__c)) {
          accessToDelete.add(a);
        }
      }
      for (String gId : groupsMap.keyset()) {
        if (!groupsWithAccess.contains(gId)) {
          cgsToLink.add(new Contact_Group__c(Id = gId));
        }
      }

      delete accessToDelete;
      return linkGroupsToReports(
        cgsToLink,
        new List<Asset>{ new Asset(Id = reportId) }
      );
    }
    return new APIResponse('Bad Request', 400, 'Invalid data');
  }

  // Given a report id, returns a set of contact group ids that have access
  public static Set<Id> getContactGroupIdsForReportId(Id reportId) {
    return new Map<Id, Contact_Group__c>(
        [
          SELECT Id
          FROM Contact_Group__c
          WHERE
            Id IN (
              SELECT Contact_Group__c
              FROM Access__c
              WHERE Report_Asset__c = :reportId
            )
        ]
      )
      .keyset();
  }

  // Given a set of contact group ids, returns a map from contact group Id to a set of contactIds who are group members
  public static List<Contact_Group__c> getGroupMembershipsForContactGroups(
    Set<Id> contactGroupIds
  ) {
    return new List<Contact_Group__c>(
      [
        SELECT Id, (SELECT Contact__c FROM Group_Memberships__r)
        FROM Contact_Group__c
        WHERE Id IN :contactGroupIds
      ]
    );
  }

  public static ListResponse getGroupTableData(
    Integer rowLimit,
    String filterSearch,
    String orderBy,
    List<String> selectedRowIds,
    String dataType,
    String mode
  ) {
    return getGroupTableData(rowLimit, filterSearch, null, orderBy, selectedRowIds, dataType, mode);
  }

  /* History*
   * 26-12-2023   kamlesh.kahar   MBS-313   Manage/Assign/Retract reports modal enhancement
   */

  // Build a TableData for Contact Groups. Applied in numerous LWC such
  // as ManageReportAccess and ManageUserGroupAccess.ApexPages
  // Unit tested in ManageReportControllerTest/ManageUserControllerTest
  public static ListResponse getGroupTableData(
    Integer rowLimit,
    String filterSearch,
    String filterStatus,
    String orderBy,
    List<String> selectedRowIds,
    String dataType,
    String mode
  ) {
    try {
      DataTable.Table tableData = new DataTable.Table();
      Set<Id> accountIds = new Set<Id>();

      if(!selectedRowIds.isEmpty() && Id.valueOf(selectedRowIds[0]).getSobjectType().getDescribe().getName() == 'Asset'){
        List<AggregateResult> assetAccounts = [SELECT AccountId acc
                                               FROM Asset 
                                               WHERE ID IN :selectedRowIds
                                               GROUP BY AccountId];

        for(AggregateResult reslut:assetAccounts){  //Get report accounts to filter the contact groups associated to the selected reports.
          accountIds.add((Id)reslut.get('acc'));
        }
      }else{
        accountIds = AccountRelationUtil.getRelatedMTCAccountIdsforContact();
      }
      
      String soql = 'SELECT Id, Group_Name_FF__c, Account__c, Expiry__c FROM Contact_Group__c WHERE Account__c IN :accountIds ';
      String soqlCount = 'SELECT Count() FROM Contact_Group__c WHERE Account__c IN :accountIds ';
      Integer totalRows = 0;

      if(String.isNotBlank(filterSearch)){
        soql += ' AND Group_Name__c LIKE \'%' + filterSearch + '%\'';
        soqlCount += ' AND Group_Name__c LIKE \'%' + filterSearch + '%\'';
      }
      if(String.isNotBlank(filterStatus)){
        soql += ' AND Has_Expired_FF__c = ' + filterStatus;
        soqlCount += ' AND Has_Expired_FF__c = ' + filterStatus;
      }
      soql += ' ORDER BY ' + orderBy + ' LIMIT ' + rowLimit;
      List<Contact_Group__c> groups = new List<Contact_Group__c>(
        (List<Contact_Group__c>) Database.query(soql)
      );

      totalRows = Database.countQuery(soqlCount);

      List<DataTable.Column> columns = buildColumns(orderBy);
      List<DataTable.Row> rows = buildRows(
        groups,
        selectedRowIds,
        dataType,
        mode
      );

      return new ListResponse(new DataTable.Table(columns, rows), totalRows);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }

  // Utility function used by getGroupTableData
  private static List<DataTable.Column> buildColumns(String orderBy) {
    return new List<DataTable.Column>{
      new DataTable.Column('Check', ''),
      new DataTable.Column(
        'Group_Name_FF__c',
        'Group',
        orderBy.contains('Group_Name_FF__c') ? orderBy.substringAfter(' ') : ''
      ),
      new DataTable.Column(
        'Expiry__c',
        'Expiry',
        orderBy.contains('Expiry__c') ? orderBy.substringAfter(' ') : ''
      )
    };
  }


  /**
   * History:
   *    18-01-2024    kamlesh.kahar   MBS-314   Retract Report Modal Enhancement.
   */
  // Utility function used by getGroupTableData
  private static List<DataTable.Row> buildRows(
    List<Contact_Group__c> groups,
    List<String> selectedRowIds,
    String dataType,
    String mode
  ) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    if (dataType == 'Report' && (mode == 'manage' || mode == 'retract')) {
      //single report mode
      // Id selectedReportId = selectedRowIds[0];
      // List<Asset> reports = [
      //   SELECT AccountId, (SELECT Contact_Group__c FROM Report_Accesses__r)
      //   FROM Asset
      //   WHERE Id = :selectedReportId
      // ];
      List<Access__c> reportAccess = [
        SELECT Report_Asset__r.AccountId, Contact_Group__c
        FROM Access__c
        WHERE Report_Asset__c IN :selectedRowIds
      ];
      List<Asset> reports = [SELECT Id FROM Asset WHERE Id IN :selectedRowIds];
      if (reports.isEmpty()) {
        return new List<DataTable.Row>();
      }
      //Asset report = reports[0];
      //Id accountIdForReport = report.AccountId;
      Set<Id> existingGroupsForReport = new Set<Id>();
      for (Access__c access : reportAccess) {
        existingGroupsForReport.add(access.Contact_Group__c);
      }
      for (Contact_Group__c cg : groups) {
        List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
          new DataTable.Cell(
            'Check',
            existingGroupsForReport.contains(cg.Id) ? 'true' : 'false',
            true,
            false,
            null,
            'Check'
          ),
          new DataTable.Cell('Group', cg.Group_Name_FF__c, 'Group'),
          new DataTable.Cell(
            'Expiry__c',
            cg.Expiry__c != null ? String.valueOf(cg.Expiry__c.format()) : '',
            'Expiry')
        };
        // if (accountIdForReport != null && cg.Account__c != accountIdForReport) {
        //   // making cells disabled because the account differs
        //   for (DataTable.Cell cell : rowCells) {
        //     cell.disabled = true;
        //   }
        // }
        rows.add(new DataTable.Row(cg.Id, rowCells));
      }
    } else if (mode == 'assign') {
      for (Contact_Group__c cg : groups) {
        List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
          new DataTable.Cell('Check', 'false', true, false, null, 'Check'),
          new DataTable.Cell('Group', cg.Group_Name_FF__c, 'Group'),
          new DataTable.Cell(
            'Expiry__c',
            cg.Expiry__c != null ? String.valueOf(cg.Expiry__c.format()) : '',
            'Expiry')
        };
        rows.add(new DataTable.Row(cg.Id, rowCells));
      }
    }
    return rows;
  }
}