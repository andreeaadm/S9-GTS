@IsTest
public with sharing class TC_TestDataFactory_Accounts {
  public static Account supplierTemplate = new Account(
    Name = 'Supplier',
    ToxClear_Account_Type__c = 'Supplier',
    Is_ToxClear_Account__c = true,
    ToxClear_Subscription_Status__c = 'Active',
    Country__c = 'United States of America',
    Type_of_Supplier__c = 'Fabric Mills'
  );
  public static Account supplierTemplateSubscriptionInactive = new Account(
    Name = 'Supplier',
    ToxClear_Account_Type__c = 'Supplier',
    Is_ToxClear_Account__c = true,
    ToxClear_Subscription_Status__c = 'Inactive',
    Country__c = 'United States of America'
  );

  public static Account facilityTemplate = new Account(
    Name = 'Facility',
    ToxClear_Account_Type__c = 'Facility',
    Is_ToxClear_Account__c = true,
    ToxClear_Subscription_Status__c = 'Active',
    Country__c = 'United States of America'
  );
  public static Account facilityTemplateSubscriptionInactive = new Account(
    Name = 'Facility',
    ToxClear_Account_Type__c = 'Facility',
    Is_ToxClear_Account__c = true,
    ToxClear_Subscription_Status__c = 'Inactive',
    Country__c = 'United States of America'
  );

  public static Account brandTemplate = new Account(
    Name = 'Brand',
    ToxClear_Account_Type__c = 'Brand',
    Is_ToxClear_Account__c = true,
    ToxClear_Subscription_Status__c = 'Active',
    Country__c = 'United States of America'
  );
  public static Account brandTemplateSubscriptionInactive = new Account(
    Name = 'Brand',
    ToxClear_Account_Type__c = 'Brand',
    Is_ToxClear_Account__c = true,
    ToxClear_Subscription_Status__c = 'Inactive',
    Country__c = 'United States of America'
  );

  public static Account withRequiredFields(Account a) {
    if (String.isBlank(a.Name)) {
      a.Name = TC_TestDataFactory.randomName(
        TC_TestDataFactory.random(1, 3),
        3,
        10
      );
    }
    if (String.isBlank(a.Country__c)) {
      a.Country__c = 'United States of America';
    }
    return a;
  }

  public static Account create(Account template) {
    return withRequiredFields(
      template != null ? template.clone() : new Account()
    );
  }

  public static Account create(String name, Account template) {
    Account a = template != null ? template.clone() : new Account();
    // Special case, also append template.Name as suffix.
    a.Name =
      name +
      (template != null && String.isNotBlank(template.Name)
        ? ' ' + template.Name
        : '');
    return withRequiredFields(a);
  }

  public static Account create(String name, Account parent, Account template) {
    Account a = template != null ? template.clone() : new Account();
    a.ParentId = parent.Id;
    // Special case, also append template.Name as suffix.
    a.Name =
      name +
      (template != null && String.isNotBlank(template.Name)
        ? ' ' + template.Name
        : '');
    return withRequiredFields(a);
  }

  public static List<Account> create(
    List<Integer> count,
    List<Account> templates
  ) {
    List<Account> a = new List<Account>();
    Integer t = 0;
    for (Integer c : count) {
      a.addAll(create(c, templates[Math.mod(t, templates.size())]));
      t++;
    }
    return a;
  }

  public static List<Account> create(Integer count, Account template) {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < count; i++) {
      accounts.add(create(TC_TestDataFactory.getLettername(), template));
    }
    return accounts;
  }

  public static List<Account> create(
    Integer count,
    List<Account> parent,
    Account template
  ) {
    List<Account> accounts = new List<Account>();
    for (Account p : parent) {
      Account t = template != null ? template.clone() : new Account();
      t.ParentId = p.Id;
      accounts.addAll(create(count, t));
    }
    return accounts;
  }

  public static List<Account> create(
    List<Integer> count,
    List<Account> parent,
    Account template
  ) {
    List<Account> accounts = new List<Account>();
    Integer countMax = count.size() > parent.size()
      ? parent.size()
      : count.size();
    for (Integer i = 0; i < countMax; i++) {
      Account t = template != null ? template.clone() : new Account();
      t.ParentId = parent[i].Id;
      accounts.addAll(create(count[i], t));
    }
    return accounts;
  }

  public static List<Account> create(
    Integer count,
    Account parent,
    Account template
  ) {
    Account t = template != null ? template.clone() : new Account();
    t.ParentId = parent.Id;
    return create(count, t);
  }

  public static List<Account> create(
    Integer atleast,
    Integer atmost,
    List<Account> parent,
    Account template
  ) {
    List<Account> accounts = new List<Account>();
    for (Account p : parent) {
      Account t = template != null ? template.clone() : new Account();
      t.ParentId = p.Id;
      accounts.addAll(create(TC_TestDataFactory.random(atleast, atmost), t));
    }
    return accounts;
  }

  public List<Account> suppliers;
  public List<Account> facilities;
  public List<Account> brands;
  public List<Account> first;

  /**
   * TC_TestDataFactory_Accounts Query for Accounts inserted in testSetup,
   * ready to perform assertions. The plan is the Account names are created
   * in alphabetical order. ORDER BY Name therefore returns results in order
   * of creation.
   *
   * The last Accounts in the list are likely inactive and without connections.
   *
   * The most useful Accounts for testing are saved in; first (List<Account>).
   *   first[0] is the supplier.
   *   first[1]..first[first.size()-2] are the supplier's facilities.
   *   first[first.size()-1] is the brand.
   */
  public TC_TestDataFactory_Accounts() {
    suppliers = [
      SELECT Id, ParentId, Name, ToxClear_Account_Type__c
      FROM Account
      WHERE ToxClear_Account_Type__c = 'Supplier'
      ORDER BY Id ASC
      LIMIT 25
    ];
    facilities = [
      SELECT Id, ParentId, Name, ToxClear_Account_Type__c
      FROM Account
      WHERE ToxClear_Account_Type__c = 'Facility'
      ORDER BY Id ASC
      LIMIT 50
    ];
    brands = [
      SELECT Id, ParentId, Name, ToxClear_Account_Type__c
      FROM Account
      WHERE ToxClear_Account_Type__c = 'Brand'
      ORDER BY Id ASC
      LIMIT 25
    ];

    first = new List<Account>();
    first.add(suppliers[0]);
    for (Account facility : facilities) {
      if (facility.ParentId == suppliers[0].Id) {
        first.add(facility);
      }
    }
    first.add(brands[0]);
  }

  /**
   * TC_TestDataFactory_Accounts Construct test data.
   *
   * @param supplierCount (Integer): Number of suppliers to insert.
   * @param supplierCountInactive (Integer): Number of suppliers with an inactive subscription to insert.
   * @param facilityCounts (List<Integer>): Number of facilities to insert for each of the suppliers.
   * @param facilityCountsInactive (List<Integer>): Number of facilities with inactive subscription to insert for each of the suppliers.
   * @param brandCount (Integer): Number of brands to insert
   * @param brandCountInactive (Integer): Number of brands with inactive subscription to insert.
   */
  public TC_TestDataFactory_Accounts(
    Integer supplierCount,
    Integer supplierCountInactive,
    List<Integer> facilityCounts,
    List<Integer> facilityCountsInactive,
    Integer brandCount,
    Integer brandCountInactive
  ) {
    suppliers = create(supplierCount, supplierTemplate);
    suppliers.addAll(
      create(supplierCountInactive, supplierTemplateSubscriptionInactive)
    );
    insert suppliers;

    facilities = create(facilityCounts, suppliers, facilityTemplate);
    facilities.addAll(
      create(
        facilityCountsInactive,
        suppliers,
        facilityTemplateSubscriptionInactive
      )
    );
    insert facilities;

    brands = create(brandCount, brandTemplate);
    brands.addAll(
      create(brandCountInactive, brandTemplateSubscriptionInactive)
    );
    insert brands;

    first = new List<Account>();
    first.add(suppliers[0]);
    for (Account facility : facilities) {
      if (facility.ParentId == suppliers[0].Id) {
        first.add(facility);
      }
    }
    first.add(brands[0]);
  }
}