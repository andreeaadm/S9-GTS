public without sharing class ReportAccessUtil {
  @testVisible
  private static Boolean bypassQueueable = false;

  // facility to disable report access sharing calculations
  private static Boolean sharingProcessingDisabled =
    !Test.isRunningTest() &&
    ('' + Label.MTC_System_Disable_Sharing_Processing == 'true');
  private static Boolean systemFlagSharingProcessingDisabled =
    !Test.isRunningTest() &&
    ('' + Label.MTC_System_Disable_Sharing_Processing == 'true');

  // will bypass sharing calculations
  public static void disableSharingProcessing() {
    ReportAccessUtil.sharingProcessingDisabled = true;
  }
  // will re-enable sharing calculations unless the system flag is set
  public static void enableSharingProcessing() {
    ReportAccessUtil.sharingProcessingDisabled =
      false || systemFlagSharingProcessingDisabled;
  }

  // when a user is created on a contact already related to account with report
  public static void newUser(List<User> users) {
    if (sharingProcessingDisabled || users.isEmpty()) {
      return;
    }
    Set<Id> contactIds = new Set<Id>();
    for (User usr : users) {
      contactIds.add(usr.ContactId);
    }

    if (!contactIds.isEmpty()) {
      List<AccountContactRelation> acrs = [
        SELECT AccountId, ContactId, MTC_Role__c
        FROM AccountContactRelation
        WHERE ContactId IN :contactIds
      ];
      newAccountRelation(acrs);
    }
    return;
  }

  // when we establish a link between an account and a portal_enabled contact
  // retrieves all reports linked to the account
  public static void newAccountRelation(List<AccountContactRelation> acrs) {
    if (sharingProcessingDisabled || acrs.isEmpty()) {
      return;
    }
    Map<Id, Map<Id, AccountContactRelation>> conId2AccountId2ACR = AccountRelationUtil.buildCon2AccACRMap(
      acrs
    );
    Map<Id, Id> contactId2UserId = MTCUserUtil.getConId2UserId(
      conId2AccountId2ACR.keySet()
    );
    Set<Id> accountIds = new Set<Id>();

    for (Id conId : contactId2UserId.keySet()) {
      if (conId2AccountId2ACR.containsKey(conId)) {
        accountIds.addAll(conId2AccountId2ACR.get(conId).keySet());
      }
    }
    Set<Id> reportIds = AssetUtil.getReportIdsFromAccountIds(accountIds);
    calculateAccessRouter(reportIds);
  }
  // when a new report or deliverable is created or updated
  public static void newAssets(List<Asset> newReportOrDeliv) {
    if (sharingProcessingDisabled || newReportOrDeliv.isEmpty()) {
      return;
    }
    // Map<Id, Asset> assets = (new Map<Id, Asset>(newReportOrDeliv));
    Set<Id> reportIds = (new Map<Id, Asset>(newReportOrDeliv)).keySet().clone();

    for (Asset deliv : newReportOrDeliv) {
      if (deliv.ParentId != null) {
        reportIds.add(deliv.ParentId);
      }
    }

    // Map<Id, Asset> reports = AssetUtil.getReportsWithDeliverables(reportIds);
    calculateAccessRouter(reportIds);
  }
  // called when groups are linked to reports via access records
  public static void newReports(List<Access__c> accesses) {
    if (sharingProcessingDisabled) {
      return;
    }
    Set<Id> reportIds = new Set<Id>();
    for (Access__c access : accesses) {
      reportIds.add(access.Report_Asset__c);
    }
    // Map<Id, Asset> reports = AssetUtil.getReportsWithDeliverables(reportIds);
    calculateAccessRouter(reportIds);
  }
  // called when reports and groups get disconnected via access records
  public static void removedReports(List<Access__c> reportAccessesRemoved) {
    if (sharingProcessingDisabled || reportAccessesRemoved.isEmpty()) {
      return;
    }
    Set<Id> reportIds = new Set<Id>();
    for (Access__c rar : reportAccessesRemoved) {
      reportIds.add(rar.Report_Asset__c);
    }
    // Map<Id, Asset> reports = AssetUtil.getReportsWithDeliverables(reportIds);
    calculateAccessRouter(reportIds);
  }

  // called when contacts are linked to groups via group_membership records
  public static void newMembers(List<Group_Membership__c> members) {
    if (sharingProcessingDisabled || members.isEmpty()) {
      return;
    }
    Set<Id> contactGroupIds = ContactGroupUtil.getContactGroupIdsFrom(members);

    Set<Id> reportIds = ContactGroupUtil.getReportIdsRelatedToGroups(
      contactGroupIds
    );

    calculateAccessRouter(reportIds);
  }

  // called when contacts are unlinked from groups via group_membership records
  public static void removedMembers(List<Group_Membership__c> membersRemoved) {
    if (sharingProcessingDisabled || membersRemoved.isEmpty()) {
      return;
    }
    Set<Id> contactGroupIds = ContactGroupUtil.getContactGroupIdsFrom(
      membersRemoved
    );
    Set<Id> reportIds = ContactGroupUtil.getReportIdsRelatedToGroups(
      contactGroupIds
    );
    calculateAccessRouter(reportIds);
  }

  public static void calculateAccessRouter(Set<Id> reportIds) {
    if (reportIds.isEmpty()) {
      return;
    }
    if (bypassQueueable) {
      calculateAccess(reportIds);
    } else {
      System.enqueueJob(new ReportAccessCalcQAble(reportIds));
    }
  }

  public static void calculateAccess(Set<Id> reportIds) {
    Map<Id, Asset> reports = AssetUtil.getReportsWithDeliverables(reportIds);
    calculateAccess(reports);
  }

  public static void calculateAccess(Map<Id, Asset> reports) {
    Set<Id> reportIds = reports.keySet();
    Set<Id> assetIdsToEvaluate = reportIds.clone();
    Set<Id> allRelatedAccountIds = new Set<Id>();
    for (Asset parentAsset : reports.values()) {
      allRelatedAccountIds.add(parentAsset.AccountId);
      for (Asset childAsset : parentAsset.ChildAssets) {
        assetIdsToEvaluate.add(childAsset.Id);
      }
    }
    Map<Id, Set<Id>> group2reports = new Map<Id, Set<Id>>();
    Map<Id, Map<Id, Contact_Group__c>> report2groups = new Map<Id, Map<Id, Contact_Group__c>>();

    // which groups should have access
    List<Access__c> accesses = [
      SELECT
        Id,
        Contact_Group__c,
        Contact_Group__r.Account__c,
        Contact_Group__r.Is_Default_Group__c,
        Report_Asset__c
      FROM Access__c
      WHERE Report_Asset__c IN :reportIds
    ];
    for (Access__c access : accesses) {
      allRelatedAccountIds.add(access.Contact_Group__r.Account__c);
      Id reportId = access.Report_Asset__c;
      Id groupId = access.Contact_Group__c;
      Set<Id> reportIds4Group = group2reports.get(groupId);
      if (reportIds4Group == null) {
        group2reports.put(groupId, new Set<Id>{ reportId });
      } else {
        reportIds4Group.add(reportId);
      }
      Map<Id, Contact_Group__c> groups = report2groups.get(reportId);
      if (groups == null) {
        report2groups.put(
          reportId,
          new Map<Id, Contact_Group__c>{ groupId => access.Contact_Group__r }
        );
      } else {
        groups.put(groupId, access.Contact_Group__r);
      }
    }

    // which members should have access
    List<Group_Membership__c> members = [
      SELECT Id, Contact_Group__c, Contact__c
      FROM Group_Membership__c
      WHERE Contact_Group__c IN :group2reports.keySet()
    ];
    Set<Id> contactIdsWithAccess = new Set<Id>();
    for (Group_Membership__c member : members) {
      contactIdsWithAccess.add(member.Contact__c);
    }

    List<AccountContactRelation> allRelatedACRs = AccountRelationUtil.getACRsForAccountIds(
      allRelatedAccountIds
    );
    // builds accountId -> set( contactId ) (admins only)
    Map<Id, Set<Id>> accId2adminIds = buildAccId2adminIds(allRelatedACRs);
    for (Set<Id> adminConIds : accId2adminIds.values()) {
      contactIdsWithAccess.addAll(adminConIds);
    }
    Map<Id, Map<Id, AccountContactRelation>> conId2AccountId2ACR = AccountRelationUtil.buildCon2AccACRMap(
      allRelatedACRs
    );

    Map<Id, Id> contactId2UserId = MTCUserUtil.getConId2UserId(
      contactIdsWithAccess
    );

    Map<String, String> sharingToEstablish = new Map<String, String>();
    for (Group_Membership__c member : members) {
      Id memberUserId = contactId2UserId.get(member.Contact__c);
      if (String.isEmpty(memberUserId)) {
        continue;
      }
      // limit sharing to the reports identified earlier
      for (Id reportId : group2reports.get(member.Contact_Group__c)) {
        Asset report = reports.get(reportId);
        String accessLevel = computeAccessLevel(
          member.Contact__c,
          report,
          conId2AccountId2ACR
        );
        if (accessLevel == null) {
          continue;
        }

        sharingToEstablish.put(buildKey(reportId, memberUserId), accessLevel);
        for (Asset deliverable : reports.get(reportId).ChildAssets) {
          sharingToEstablish.put(
            buildKey(deliverable.Id, memberUserId),
            accessLevel
          );
        }
      }
    }

    for (Asset report : reports.values()) {
      Id reportId = report.Id;

      // admins should have access to all reports (changed from just unassigned)
      Set<Id> confirmedContacts = new Set<Id>();

      Set<Id> adminIdsForAccount = accId2adminIds.get(report.AccountId);
      if (adminIdsForAccount != null) {
        confirmedContacts = adminIdsForAccount.clone();
      }
      for (Id contactId : confirmedContacts) {
        Id withAccessUserId = contactId2UserId.get(contactId);
        if (String.isEmpty(withAccessUserId)) {
          continue;
        }
        String accessLevel = computeAccessLevel(
          contactId,
          report,
          conId2AccountId2ACR
        );
        if (accessLevel == null) {
          continue;
        }

        sharingToEstablish.put(
          buildKey(reportId, withAccessUserId),
          accessLevel
        );
        for (Asset deliverable : reports.get(reportId).ChildAssets) {
          sharingToEstablish.put(
            buildKey(deliverable.Id, withAccessUserId),
            accessLevel
          );
        }
      }
    }

    List<AssetShare> assetShareRecords = getAssetSharesForReportsAndDeliverables(
      assetIdsToEvaluate
    );
    // Set<String> alreadyExist = new Set<String>();
    Map<String, AssetShare> reportUserKeys2AssetShare = new Map<String, AssetShare>();
    List<AssetShare> assetSharesToRemove = new List<AssetShare>();
    List<AssetShare> assetSharesToCreate = new List<AssetShare>();
    for (AssetShare aShr : assetShareRecords) {
      String key = buildKey(aShr.AssetId, aShr.UserOrGroupId);

      if (!sharingToEstablish.containsKey(key)) {
        assetSharesToRemove.add(aShr);
      } else if (sharingToEstablish.get(key) == aShr.AssetAccessLevel) {
        // exact match found, do not recreate
        // alreadyExist.add(key);
        sharingToEstablish.remove(key);
      }
    }

    createSharingRecords(sharingToEstablish);

    Database.delete(assetSharesToRemove, false);

    // removeExpiredSharingRecords(
    //   assetIdsToEvaluate,
    //   sharingToEstablish.keySet()
    // );
  }

  // builds accountId -> set( contactId ) (admins only)
  public static Map<Id, Set<Id>> buildAccId2adminIds(
    List<AccountContactRelation> acrs
  ) {
    Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
    for (AccountContactRelation acr : acrs) {
      if (acr.MTC_Role__c != 'admin') {
        continue;
      }
      Set<Id> adminIds = result.get(acr.AccountId);
      if (adminIds == null) {
        result.put(acr.AccountId, new Set<Id>{ acr.ContactId });
      } else {
        adminIds.add(acr.ContactId);
      }
    }
    return result;
  }

  public static String computeAccessLevel(
    Id contactId,
    Asset report,
    Map<Id, Map<Id, AccountContactRelation>> conId2AccountId2ACR
  ) {
    String accessLevel;

    AccountContactRelation acrForReport;
    Map<Id, AccountContactRelation> acrs = conId2AccountId2ACR.get(contactId);
    if (acrs != null) {
      acrForReport = acrs.get(report.AccountId);
    }
    if (acrForReport != null) {
      if (!String.isEmpty(acrForReport.MTC_Role__c)) {
        if (
          acrForReport.MTC_Role__c == 'admin' ||
          acrForReport.MTC_Role__c == 'cga'
        ) {
          accessLevel = 'Edit';
        } else if (
          acrForReport.MTC_Role__c == 'read-only' ||
          acrForReport.MTC_Role__c == 'restricted'
        ) {
          accessLevel = 'Read';
        }
      }
    }
    return accessLevel;
  }

  // removes MTC managed sharing records
  public static void removeExpiredSharingRecords(
    Set<Id> assetIds,
    Set<String> assetKeysToKeep
  ) {
    //
    List<AssetShare> assetShareRecords = getAssetSharesForReportsAndDeliverables(
      assetIds
    );
    Map<String, AssetShare> reportUserKeys2AssetShare = new Map<String, AssetShare>();
    List<AssetShare> assetSharesToRemove = new List<AssetShare>();
    for (AssetShare aShr : assetShareRecords) {
      String key = buildKey(aShr.AssetId, aShr.UserOrGroupId);
      if (!assetKeysToKeep.contains(key)) {
        assetSharesToRemove.add(aShr);
      }
    }

    Database.delete(assetSharesToRemove);
  }

  // builds the composite key to track user entitlement to asset
  public static String buildKey(String part1, String part2) {
    return part1 + '-' + part2;
  }

  public static void createSharingRecords(
    Map<String, String> reportIdUserId2AccessLevel
  ) {
    Set<String> reportUserKeys = reportIdUserId2AccessLevel.keySet();
    List<AssetShare> sharesToCreate = new List<AssetShare>();
    for (String reportUserKey : reportUserKeys) {
      Id reportId = reportUserKey.substringBefore('-');
      Id userId = reportUserKey.substringAfter('-');
      sharesToCreate.add(
        new AssetShare(
          AssetId = reportId,
          UserOrGroupId = userId,
          AssetAccessLevel = reportIdUserId2AccessLevel.get(reportUserKey),
          RowCause = 'Manual'
        )
      );
    }
    Database.insert(sharesToCreate, false);
  }

  // retrieves the sharing records for the asset object
  public static List<AssetShare> getAssetSharesForReportsAndDeliverables(
    Set<Id> assetIds
  ) {
    List<AssetShare> shares = new List<AssetShare>(
      [
        SELECT AssetId, UserOrGroupId, AssetAccessLevel
        FROM AssetShare
        WHERE AssetId IN :assetIds AND RowCause = 'Manual'
      ]
    );
    return shares;
  }
}