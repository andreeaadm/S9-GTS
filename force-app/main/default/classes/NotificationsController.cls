public with sharing class NotificationsController {
  public class Notification {
    @AuraEnabled
    public Boolean isReport = false;
    @AuraEnabled
    public Boolean isCase = false;
    @AuraEnabled
    public Boolean isUser = false;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String subtitle;
    public Notification(String objectType, String title, String subtitle) {
      this.isReport = objectType == 'Asset' ? true : false;
      this.isCase = objectType == 'Case' ? true : false;
      this.isUser = objectType == 'User' ? true : false;
      this.title = title;
      this.subtitle = subtitle;
    }
  }

  @AuraEnabled
  public static List<Notification> getNotifications(Integer rowLimit) {
    List<Notification> returnData = new List<Notification>();
    try {
      returnData = buildData(rowLimit);
      return returnData;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return returnData;
    }
  }

  static List<Notification> buildData(Integer rowLimit) {
    List<Notification> returnData = new List<Notification>();
    User currentUser = MTCUserUtil.currentUserObj;
    Id currentUserId = currentUser.Id;
    DateTime notificationsCutoff = currentUser.Notifications_Cutoff__c != null
      ? currentUser.Notifications_Cutoff__c
      : DateTime.now().addMonths(-1);

    Set<Id> currentUserRelatedAccountIds = AccountRelationUtil.getRelatedMTCAccountIdsforContact(
      currentUser.contactId
    );
    Id reportRTId = AssetUtil.reportRT.recordId;

    List<Asset> assets = [
      SELECT
        Id,
        Name,
        ParentId,
        RecordTypeId,
        Last_Notification_Date__c,
        Last_Notification_Reason__c
      FROM Asset
      WHERE
        AccountId IN :currentUserRelatedAccountIds
        AND Is_Hidden_By_Intertek__c = FALSE
        AND SystemModStamp >= :notificationsCutoff
        AND Last_Notification_Date__c != NULL
        AND Last_Notification_Date__c >= :notificationsCutoff
        AND RecordTypeId = :reportRTId
      ORDER BY Last_Notification_Date__c DESC
      LIMIT :rowLimit
    ];

    List<Case> cases = [
      SELECT
        Id,
        CaseNumber,
        Subject,
        Last_Notification_Date__c,
        Last_Notification_Reason__c
      FROM Case
      WHERE
        AccountId IN :currentUserRelatedAccountIds
        AND Last_Notification_Date__c != NULL
        AND Last_Notification_Date__c >= :notificationsCutoff
      ORDER BY Last_Notification_Date__c DESC
      LIMIT :rowLimit
    ];

    List<User> users = new List<User>();
    List<User> otherUsers = new List<User>();

    Set<Id> accountIdsCanAdminister = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin(
      currentUser.contactId
    );
    if (!accountIdsCanAdminister.isEmpty()) {
      // The current user is admin for at least one Account
      Set<Id> contactIdsCanAdminister = AccountRelationUtil.getMTCContactIdsFromAccountIds(
        accountIdsCanAdminister
      );
      users = [
        SELECT
          Id,
          Name,
          Last_Notification_Date__c,
          Last_Notification_Reason__c,
          Contact.Approval_Status__c
        FROM User
        WHERE
          ContactId IN :contactIdsCanAdminister
          AND Id != :currentUserId
          AND Last_Notification_Date__c != NULL
          AND Last_Notification_Date__c >= :notificationsCutoff
        ORDER BY Last_Notification_Date__c DESC
        LIMIT :rowLimit
      ];

      List<User> usersAwaitingApproval = new List<User>();

      otherUsers = new List<User>();
      for (User usr : users) {
        if (
          usr.Contact.Approval_Status__c == Label.MTC_Approval_RequestedStatus
        ) {
          usersAwaitingApproval.add(usr);
        } else {
          otherUsers.add(usr);
        }
      }

      User notificationForApprovals;

      if (usersAwaitingApproval.size() == 1) {
        // ensure this entry is first
        returnData.add(buildNotification(usersAwaitingApproval[0]));
      } else if (usersAwaitingApproval.size() > 1) {
        String title =
          usersAwaitingApproval.size() +
          ' users' +
          ' <a target="_self" href="./users?unassigned=true">are requesting access to MTC</a>.';
        returnData.add(new Notification('User', title, ''));
      }
    }

    //filter out users in approval process

    List<List<SObject>> allRecordLists = new List<List<SObject>>{
      assets,
      cases,
      otherUsers
    };

    // Loop through each list of SObjects that were found by SOSL, adding each SObject record to a merged record list
    List<NotificationObjWrapper> mergedRecordList = new List<NotificationObjWrapper>();
    Map<Id, NotificationObjWrapper> duplicateRemover = new Map<Id, NotificationObjWrapper>();
    for (List<SObject> records : allRecordLists) {
      for (SObject so : records) {
        NotificationObjWrapper notifWrap = new NotificationObjWrapper(so);
        duplicateRemover.put(notifWrap.sObj.Id, notifWrap);
      }
    }

    // Get Access records separately as we need to bypass sharing
    List<List<SObject>> accessesList = WithoutSharing.getAccessesWithNotifications(
      currentUser,
      notificationsCutoff,
      rowLimit
    );
    // only add access notifications for reports *not already seen*
    for (List<SObject> sobjects : accessesList) {
      for (SObject so : sobjects) {
        Access__c access = (Access__c) so;
        if (!duplicateRemover.containsKey(access.Report_Asset__c)) {
          NotificationObjWrapper notifWrap = new NotificationObjWrapper(so);
          duplicateRemover.put(notifWrap.sObj.Id, notifWrap);
        }
      }
    }

    // Call our custom sort (NotificationObjWrapper implements comparable) to sort the list of merged records by a common field... Last_Notification_Date__c
    mergedRecordList = duplicateRemover.values();
    mergedRecordList.sort();

    // And now we trim the list down so that it's no longer than rowLimit
    List<SObject> sortedAndTrimmedRecordList = new List<SObject>();
    Integer i = 0;
    while (i < rowLimit && i < mergedRecordList.size()) {
      sortedAndTrimmedRecordList.add(mergedRecordList[i].sObj);
      i++;
    }

    // Finally, we have a sorted, trimmed list of SObjects which we can process and turn into Notifications
    for (SObject so : sortedAndTrimmedRecordList) {
      returnData.add(buildNotification(so));
    }
    return returnData;
  }

  static Notification buildNotification(sObject sObj) {
    String title = '';
    String subtitle = '';
    switch on String.valueOf(sObj.get('Last_Notification_Reason__c')) {
      when 'Access created or modified' {
        title =
          'Report ' +
          String.valueOf(sObj.getSObject('Report_Asset__r').get('Name')) +
          ' is <a target="_self" href="./detail/' +
          String.valueOf(sObj.get('Report_Asset__c')) +
          '">ready to view</a>.';
        subtitle = '';
      }
      when 'Report ready to view' {
        String reportId = String.valueOf(sObj.get('Id'));
        if (sObj.get('RecordTypeId') == AssetUtil.deliverableRT.recordId) {
          reportId = String.valueOf(sObj.get('ParentId'));
        }
        title =
          'Report ' +
          String.valueOf(sObj.get('Name')) +
          ' is <a target="_self" href="./detail/' +
          reportId +
          '">ready to view</a>.';
        subtitle = '';
      }
      when 'Report revised' {
        String reportId = String.valueOf(sObj.get('Id'));
        if (sObj.get('RecordTypeId') == AssetUtil.deliverableRT.recordId) {
          reportId = String.valueOf(sObj.get('ParentId'));
        }
        title =
          'Report ' +
          String.valueOf(sObj.get('Name')) +
          ' was <a target="_self" href="./detail/' +
          reportId +
          '">revised</a>.';
        subtitle = '';
      }
      when 'Case updated' {
        title =
          'Case no ' +
          String.valueOf(sObj.get('CaseNumber')) +
          ' has <a target="_self" href="./detail/' +
          String.valueOf(sObj.get('Id')) +
          '">been updated</a>.';
        subtitle = '';
      }
      when 'Case closed' {
        title =
          'Case no ' +
          String.valueOf(sObj.get('CaseNumber')) +
          ' was <a target="_self" href="./detail/' +
          String.valueOf(sObj.get('Id')) +
          '">closed</a>.';
        subtitle = '';
      }
      when 'User created' {
        title =
          'User ' +
          String.valueOf(sObj.get('Name')) +
          ' has <a target="_self" href="./detail/' +
          String.valueOf(sObj.get('Id')) +
          '">been created</a>.';
        subtitle = '';
      }
      when 'User requesting approval' {
        title =
          'User ' +
          String.valueOf(sObj.get('Name')) +
          ' <a target="_self" href="./detail/' +
          String.valueOf(sObj.get('Id')) +
          '">is requesting approval</a>.';
        subtitle = '';
      }
    }
    return new Notification(
      String.valueOf(sObj.getSObjectType()),
      title,
      subtitle
    );
  }
}