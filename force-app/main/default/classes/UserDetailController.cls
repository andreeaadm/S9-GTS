public with sharing class UserDetailController {
  public class CompanyItem {
    @AuraEnabled
    public AccountContactRelation acr;
    @AuraEnabled
    public String uiFriendlyRole;
    @AuraEnabled
    public Boolean cannotManage = false;
    @AuraEnabled
    public Boolean isAssignedOnThisAccount = false;
    @AuraEnabled
    public Boolean isReadOnly {
      get {
        return acr.IsDirect || cannotManage;
      }
      private set;
    }
    @AuraEnabled
    public List<SchemaUtil.PicklistEntry> roleOptions;
    public CompanyItem(
      AccountContactRelation acr,
      String uiFriendlyRole,
      List<SchemaUtil.PicklistEntry> roleOptions
    ) {
      this.acr = acr;
      this.uiFriendlyRole = uiFriendlyRole;
      this.roleOptions = roleOptions;
    }
    public CompanyItem(
      AccountContactRelation acr,
      String uiFriendlyRole,
      List<SchemaUtil.PicklistEntry> roleOptions,
      Boolean cannotManage
    ) {
      this(acr, uiFriendlyRole, roleOptions);
      this.cannotManage = cannotManage;
    }
  }

  @AuraEnabled
  public static APIResponse updateUser(sObject record) {
    try {
      WithoutSharing.updateRecords(new List<sObject>{ record });
      return new APIResponse('OK', 200);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return new APIResponse('Bad Request', 400, e.getMessage());
    }
  }

  @AuraEnabled
  public static Boolean addAccountRelationship(
    String userId,
    String accountId,
    String mtcRole
  ) {
    User u = [SELECT ContactId FROM User WHERE Id = :userId];

    List<AccountContactRelation> existingRelation = new List<AccountContactRelation>(
      [
        SELECT Id, MTC_Role__c
        FROM AccountContactRelation
        WHERE ContactId = :u.ContactId AND AccountId = :accountId
        LIMIT 1
      ]
    );
    if (existingRelation.size() < 1) {
      AccountContactRelation newAcr = new AccountContactRelation(
        AccountId = accountId,
        ContactId = u.ContactId,
        MTC_Role__c = mtcRole
      );
      insert newAcr;
    }
    return true;
  }

  @AuraEnabled(cacheable=true)
  public static List<Account> getAccountOptions(String userId) {
    try {
      String contactId = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1]
      .ContactId;
      // below is for the logged-in user
      Set<Id> accountIdsIsAdminFor = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();

      List<Account> accounts = [
        SELECT Id, Name
        FROM Account
        WHERE
          Id IN :accountIdsIsAdminFor
          AND Id NOT IN (
            SELECT AccountId
            FROM AccountContactRelation
            WHERE ContactId = :contactId
          )
      ];
      return accounts;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<AccountContactRelation> getPrimaryAccountOptions(
    String userId
  ) {
    try {
      return AccountRelationUtil.getMTCACRsForContactWhenAdmin();
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }

  @AuraEnabled
  public static List<Group_Membership__c> getGroupList(Id userId) {
    return ContactGroupUtil.getGroupMembershipsForUser(userId);
  }

  @AuraEnabled
  public static Boolean updateRelationship(
    List<AccountContactRelation> acrList
  ) {
    try {
      // We need to remove any CGA's out of this list as the current user wont have permission to update these records
      for (Integer i = 0; i < acrList.size(); i++) {
        AccountContactRelation acr = acrList[i];
        if (acr.MTC_Role__c == 'CGA') {
          acrList.remove(i);
        }
      }
      WithoutSharing.updateRecordsFailSilently(acrList);
      return true;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return false;
    }
  }

  /*
  History:
      09-10-2023    MBS-306   Kamlesh.kahar   Updating ACR in without sharing context becasue of access issue.
  */ 
  @AuraEnabled
  public static Boolean removeRelationship(String acrId) {
    try {
      AccountContactRelation toRemove = [
        SELECT Id, MTC_Role__c
        FROM AccountContactRelation
        WHERE Id = :acrId
        LIMIT 1
      ];
      toRemove.MTC_Role__c = 'No-Access';
      WithoutSharing.updateRecord(toRemove);
      return true;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return false;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<CompanyItem> getCompanyList(String userId) {
    List<CompanyItem> companies = new List<CompanyItem>();
    try {
      Id contactId = [SELECT ContactId FROM User WHERE Id = :userId].ContactId;
      // for the logged-in user
      Set<Id> accountIdsIsAdminFor = AccountRelationUtil.getRelatedMTCAccountIdsforContactWhenAdmin();
      Set<Id> accountsIdsIsRelatedTo = AccountRelationUtil.getRelatedMTCAccountIdsforContact();
      List<AccountContactRelation> acrs = [
        SELECT
          Id,
          Account_Name_FF__c,
          ContactId,
          AccountId,
          MTC_Role__c,
          IsDirect
        FROM AccountContactRelation
        WHERE ContactId = :contactId AND AccountId IN :accountsIdsIsRelatedTo
        ORDER BY IsDirect DESC
      ];
      Set<Id> accountIdsWhenMember = AccountRelationUtil.accountIdsWhenAssignedToGroup(
        contactId
      );
      for (AccountContactRelation acr : acrs) {
        CompanyItem compItem = new CompanyItem(
          acr,
          getUIFriendlyRole(acr.MTC_Role__c),
          getUIFriendlyRoleOptions(acr.MTC_Role__c),
          !accountIdsIsAdminFor.contains(acr.AccountId)
        );
        compItem.isAssignedOnThisAccount = accountIdsWhenMember.contains(
          acr.AccountId
        );
        companies.add(compItem);
      }
      return companies;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }

  private static List<SchemaUtil.PicklistEntry> getUIFriendlyRoleOptions(
    String role
  ) {
    List<SchemaUtil.PicklistEntry> uiFriendly = new List<SchemaUtil.PicklistEntry>();
    switch on role {
      when 'CGA' {
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'Client Administrator', 'CGA')
        );
      }
      when 'Admin' {
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'Administrator', 'Admin')
        );
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'Read-Only', 'Read-Only')
        );
      }
      when 'Read-Only' {
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'Read-Only', 'Read-Only')
        );
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'Administrator', 'Admin')
        );
      }
      when 'No-Access' {
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'No-Access', 'No-Access')
        );
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'Administrator', 'Admin')
        );
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'Read-Only', 'Read-Only')
        );
      }
      when 'Restricted' {
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'No-Access', 'No-Access')
        );
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'Administrator', 'Admin')
        );
        uiFriendly.add(
          new SchemaUtil.PickListEntry(false, 'Read-Only', 'Read-Only')
        );
      }
    }
    return uiFriendly;
  }

  private static String getUIFriendlyRole(String role) {
    switch on role {
      when 'CGA' {
        return 'Client Administrator';
      }
      when 'Admin' {
        return 'Administrator';
      }
      when 'Read-Only' {
        return 'Read-Only';
      }
      when 'No-Access' {
        return 'No-Access';
      }
    }
    return null;
  }

  @AuraEnabled
  public static APIResponse createNewUser(String mtcRole, String userParam) {
    try {
      system.assertNotEquals(null, mtcRole, 'mtc role cannot be null');
      system.assertNotEquals(null, userParam, 'user cannot be null');
      return WithoutSharing.createUpdateAccountContactRelation(
        mtcRole,
        userParam
      );
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return new APIResponse('Bad Request', 400, 'An error occurred.');
    }
  }
}