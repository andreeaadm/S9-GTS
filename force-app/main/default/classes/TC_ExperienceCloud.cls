// TC_ExperienceCloud base class extends the concept of a Site
// with specialisations/overrides for ToxClear.
//
// Implements core functionality typically required by every ToxClear specific
// controller or data service.
//
// Instances have the following public properties/methods:
//  *  The current user's User object.
//  *  Boolean 'is' states for the current user, to distinguish between
//     User Types; Supplier, Brand, Standard User, and Administrators, based
//     on the current user's PermissionSetAssignments.
//  *  userType Integer expressing all four Booleans bitwise.
//  *  getUserType AuraEnabled methods.
//
// Extending TC_ExperienceCloud in TC_DataService example:
//
//   public with sharing class TC_DataService extends TC_ExperienceCloud {
//       public TC_DataService(){ ... } // implement a constructor if needed.
//
//       public Set<Id> doSomething(){ ... }
//       public      Id doThisOtherThing(Set<Id> ids){ if(isSupplierAdminUser)... }
//       public  String filterThisAndThat(Id itemId){ ... }
//
//       @AuraEnabled // interface to TC_DataService functionality.
//       public static String methodName(){
//           try {
//               TC_DataService current = new TC_DataService();
//
//               // implement aura enabled method calling on the 'current' context for the user.
//               Set<Id> ids = current.doSomething();
//               Id itemId = current.doThisOtherThing(ids);
//               String result = current.filterThisAndThat(itemId);
//
//           } catch (Exception e) {
//               throw new AuraHandledException(e.getMessage());
//           }
//           return result;
//       }
//   }
//
// 2021/11/29: Initial version.
// 2022/01/06: Lazy initialisation.
public with sharing virtual class TC_ExperienceCloud {
  public static final Integer USERTYPE_ADMIN = 1;
  public static final Integer USERTYPE_STANDARD = 2;
  public static final Integer USERTYPE_SUPPLIER = 4;
  public static final Integer USERTYPE_BRAND = 8;

  // private PermissionSet and PermissionSetGroup implementation
  private static Cache.OrgPartition cache = new Cache.OrgPartition('local.tc');
  private static Id getPermissionSetId(String developerName) {
    String key = developerName.isAlphanumeric()
      ? developerName
      : developerName.replaceAll('[^A-Za-z0-9]', '');
    Id permissionSetId = (Id) (cache.contains(key) ? cache.get(key) : null);
    if (String.isBlank(permissionSetId)) {
      permissionSetId = [
        SELECT Id
        FROM PermissionSet
        WHERE Name = :developerName
        LIMIT 1
      ]
      .Id;
      cache.put(key, permissionSetId);
    }
    return permissionSetId;
  }
  private static Id getPermissionSetGroupId(String developerName) {
    String key = developerName.isAlphanumeric()
      ? developerName
      : developerName.replaceAll('[^A-Za-z0-9]', '');
    if (!Test.isRunningTest()) {
      Id permissionSetGroupId = (Id) (cache.contains(key)
        ? cache.get(key)
        : null);
      if (String.isBlank(permissionSetGroupId)) {
        permissionSetGroupId = [
          SELECT Id
          FROM PermissionSetGroup
          WHERE DeveloperName = :developerName AND Status = 'Updated'
          LIMIT 1
        ]
        .Id;
        cache.put(key, permissionSetGroupId);
      }
      return permissionSetGroupId;
    } else {
      PermissionSetGroup psg = [
        SELECT Id, Status
        FROM PermissionSetGroup
        WHERE DeveloperName = :developerName
        LIMIT 1
      ];
      return psg.Id;
    }
  }

  // Lazily initialised public PermissionSetId attribute:
  public static final Id ACCESS_PSID {
    get {
      if (ACCESS_PSID == null) {
        ACCESS_PSID = getPermissionSetId('ToxClear_Experience_Cloud_Access');
      }
      return ACCESS_PSID;
    }
    private set;
  }

  // Lazily initialised public PermissionSetGroupId attributes:
  public static final Id SUPPLIER_ADMINISTRATOR_PSGID {
    get {
      if (SUPPLIER_ADMINISTRATOR_PSGID == null) {
        SUPPLIER_ADMINISTRATOR_PSGID = getPermissionSetGroupId(
          'ToxClear_Supplier_Administrator'
        );
      }
      return SUPPLIER_ADMINISTRATOR_PSGID;
    }
    private set;
  }

  public static final Id SUPPLIER_STANDARD_USER_PSGID {
    get {
      if (SUPPLIER_STANDARD_USER_PSGID == null) {
        SUPPLIER_STANDARD_USER_PSGID = getPermissionSetGroupId(
          'ToxClear_Supplier_Standard_User'
        );
      }
      return SUPPLIER_STANDARD_USER_PSGID;
    }
    private set;
  }

  public static final Id BRAND_ADMINISTRATOR_PSGID {
    get {
      if (BRAND_ADMINISTRATOR_PSGID == null) {
        BRAND_ADMINISTRATOR_PSGID = getPermissionSetGroupId(
          'ToxClear_Brand_Administrator'
        );
      }
      return BRAND_ADMINISTRATOR_PSGID;
    }
    private set;
  }

  public static final Id BRAND_STANDARD_USER_PSGID {
    get {
      if (BRAND_STANDARD_USER_PSGID == null) {
        BRAND_STANDARD_USER_PSGID = getPermissionSetGroupId(
          'ToxClear_Brand_Standard_User'
        );
      }
      return BRAND_STANDARD_USER_PSGID;
    }
    private set;
  }

  // Private for permission set matching, to distinguish between 4 uesr profiles implemented as permission sets.
  private List<PermissionSetAssignment> permissionSetGroupAssignments; // Current user's PermissionSetGroupAssignments.
  private Boolean permissionSetGroupMatches(Id permissionSetGroupId) {
    for (PermissionSetAssignment a : permissionSetGroupAssignments) {
      if (a.PermissionSetGroupId == permissionSetGroupId) {
        return true;
      }
    }
    return false;
  }

  // Lazily initialised public attributes for the current user:
  public Boolean isSupplierAdminUser {
    get {
      if (isSupplierAdminUser == null) {
        isSupplierAdminUser = permissionSetGroupMatches(
          SUPPLIER_ADMINISTRATOR_PSGID
        );
      }
      return isSupplierAdminUser;
    }
    private set;
  }

  public Boolean isSupplierStandardUser {
    get {
      if (isSupplierStandardUser == null) {
        isSupplierStandardUser = permissionSetGroupMatches(
          SUPPLIER_STANDARD_USER_PSGID
        );
      }
      return isSupplierStandardUser;
    }
    private set;
  }

  public Boolean isBrandAdminUser {
    get {
      if (isBrandAdminUser == null) {
        isBrandAdminUser = permissionSetGroupMatches(BRAND_ADMINISTRATOR_PSGID);
      }
      return isBrandAdminUser;
    }
    private set;
  }

  public Boolean isBrandStandardUser {
    get {
      if (isBrandStandardUser == null) {
        isBrandStandardUser = permissionSetGroupMatches(
          BRAND_STANDARD_USER_PSGID
        );
      }
      return isBrandStandardUser;
    }
    private set;
  }

  public Boolean isSupplierUser {
    get {
      return this.isSupplierAdminUser || this.isSupplierStandardUser;
    }
    private set;
  }

  public Boolean isBrandUser {
    get {
      return this.isBrandAdminUser || this.isBrandStandardUser;
    }
    private set;
  }

  public Boolean isAdminUser {
    get {
      return this.isSupplierAdminUser || this.isBrandAdminUser;
    }
    private set;
  }

  public Boolean isStandardUser {
    get {
      return this.isSupplierStandardUser || this.isBrandStandardUser;
    }
    private set;
  }

  public Integer userType {
    get {
      if (userType == null) {
        userType = this.isSupplierStandardUser
          ? USERTYPE_SUPPLIER | USERTYPE_STANDARD
          : this.isBrandStandardUser
              ? USERTYPE_BRAND | USERTYPE_STANDARD
              : this.isSupplierAdminUser
                  ? USERTYPE_SUPPLIER | USERTYPE_ADMIN
                  : this.isBrandAdminUser ? USERTYPE_BRAND | USERTYPE_ADMIN : 0;
      }
      return userType;
    }
    private set;
  }

  public User user {
    get {
      // Query only when accessed.
      if (user == null) {
        // Use the userId from construction of permissionSetGroupAssignments.
        Id userId = this.permissionSetGroupAssignments != null &&
          this.permissionSetGroupAssignments.size() > 0
          ? this.permissionSetGroupAssignments[0].AssigneeId
          : null; // Otherwise, must not assume current user.
        if (userId != null) {
          user = [
            SELECT
              Id,
              Name,
              FirstName,
              LastName,
              Email,
              ProfileId,
              ContactId,
              Contact.AccountId,
              Contact.Account.ParentId,
              Contact.Main_Facility__c,
              Contact.Main_Facility__r.Facility_Manager__c,
              Contact.Account.ToxClear_Account_Type__c
            FROM User
            WHERE Id = :userId AND IsActive = TRUE AND IsPortalEnabled = TRUE
            LIMIT 1
          ];
        }
      }
      return user;
    }
    private set;
  }

  /**
   * TC_ExperienceCloud constructor for current user.
   */
  public TC_ExperienceCloud() {
    // UserInfo.getUserId() returned null when used directly as a parameter.
    this(UserInfo.getUserId());
  }

  /**
   * TC_ExperienceCloud constructor for specified userId.
   * @param userId (Id): Specify a User Id to construct the current context as.
   */
  public TC_ExperienceCloud(Id userId) {
    if (userId == null) {
      userId = UserInfo.getUserId();
    }
    Set<Id> permissionSetGroupIds = new Set<Id>{
      SUPPLIER_ADMINISTRATOR_PSGID,
      SUPPLIER_STANDARD_USER_PSGID,
      BRAND_ADMINISTRATOR_PSGID,
      BRAND_STANDARD_USER_PSGID
    };
    this.permissionSetGroupAssignments = [
      SELECT Id, PermissionSetGroupId, AssigneeId
      FROM PermissionSetAssignment
      WHERE
        AssigneeId = :userId
        AND IsActive = TRUE
        AND PermissionSetGroupId IN :permissionSetGroupIds
    ];
  }

  /**
   * getUserType
   * Uses the Integer USERTYPE_ bit constants.
   *
   * @return Integer: The user type.
   * @throws AuraHandledException
   */
  @AuraEnabled(cacheable=true)
  public static Integer getUserType() {
    try {
      return new TC_ExperienceCloud().userType;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      throw new AuraHandledException(
        'ToxClear Experience Cloud: access error for current user.'
      );
    }
  }
}