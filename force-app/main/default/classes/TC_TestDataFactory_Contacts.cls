@isTest
public with sharing class TC_TestDataFactory_Contacts {
  public static Contact create(Contact template) {
    Contact c = withRequiredFields(
      template != null ? template.clone() : new Contact()
    );
    // Special case when email is in the template
    if (String.isNotBlank(template.Email)) {
      List<String> e = template.Email.split('@');
      c.Email = (e[0] +
        '+' +
        c.FirstName.replaceAll('[^A-Za-z0-9]', '') +
        '.' +
        c.LastName.replaceAll('[^A-Za-z0-9]', '') +
        '@' +
        e[1])
        .toLowerCase();
    }
    if (String.isNotBlank(c.Id)) {
      c.Id = null;
    }
    return c;
  }

  public static Contact withRequiredFields(Contact c) {
    // if (String.isBlank(c.Title)) {
    //   c.Title = TC_TestDataFactory.randomValue(TC_TestDataFactory.titles);
    // }
    if (String.isBlank(c.FirstName)) {
      c.FirstName = TC_TestDataFactory.getFirstname();
    }
    if (String.isBlank(c.LastName)) {
      c.LastName = TC_TestDataFactory.getLastname();
    }
    if (String.isBlank(c.Email)) {
      c.Email = (c.FirstName.replaceAll('[^A-Za-z0-9]', '') +
        '.' +
        c.LastName.replaceAll('[^A-Za-z0-9]', '') +
        '@example.com')
        .toLowerCase();
    }
    if (String.isBlank(c.Phone)) {
      c.Phone = TC_TestDataFactory.random(12, '0123456789');
    }
    return c;
  }

  public static List<Contact> create(Integer count, Contact template) {
    List<Contact> contacts = new List<Contact>();
    String lastName = template != null && String.isNotBlank(template.LastName)
      ? template.LastName + ' '
      : '';
    Contact t = template != null ? template : new Contact();
    for (Integer i = 0; i < count; i++) {
      contacts.add(create(t));
    }
    return contacts;
  }

  public static List<Contact> createForEachAccount(
    Integer count,
    List<Account> accounts,
    Contact template
  ) {
    List<Contact> contacts = new List<Contact>();
    Contact t = template != null ? template.clone() : new Contact();
    for (Account account : accounts) {
      t.AccountId = account.Id;
      if (account.ToxClear_Account_Type__c == 'Facility') {
        t.Main_Facility__c = account.Id;
      }
      contacts.addAll(create(count, t));
    }
    return contacts;
  }

  public static List<Contact> create(
    List<Integer> count,
    List<Account> accounts,
    Contact template
  ) {
    List<Contact> contacts = new List<Contact>();
    Contact t = template != null ? template.clone() : new Contact();
    for (Integer i = 0; i < accounts.size(); i++) {
      t.AccountId = accounts[i].Id;
      if (accounts[i].ToxClear_Account_Type__c == 'Facility') {
        t.Main_Facility__c = accounts[i].Id;
      }
      contacts.addAll(create(count[Math.mod(i, count.size())], t));
    }
    return contacts;
  }

  public static List<Contact> createForEachAccount(
    Integer atleast,
    Integer atmost,
    List<Account> accounts,
    Contact template
  ) {
    List<Contact> contacts = new List<Contact>();
    Contact t = template != null ? template.clone() : new Contact();
    for (Account account : accounts) {
      t.AccountId = account.Id;
      contacts.addAll(create(TC_TestDataFactory.random(atleast, atmost), t));
    }
    return contacts;
  }

  public List<Contact> supplierAdminContacts;
  public List<Contact> supplierStdContacts;
  public List<Contact> supplierContacts;
  public List<Contact> facilityAdminContacts;
  public List<Contact> facilityStdContacts;
  public List<Contact> facilityContacts;
  public List<Contact> brandAdminContacts;
  public List<Contact> brandStdContacts;
  public List<Contact> brandContacts;

  // prettier-ignore
  /**
   * TC_TestDataFactory_Contacts Query for expected data, ready to perform helpful assertions
   * in @isTest method, after first constructing with insertion in @testSetup method.
   */
  public TC_TestDataFactory_Contacts(){
    supplierAdminContacts = [SELECT Id, AccountId, FirstName, LastName, Email, Phone, ToxClear_User_Type__c FROM Contact WHERE ToxClear_User_Type__c = 'ToxClear Administrator' AND Account.ToxClear_Account_Type__c = 'Supplier' ORDER BY Id ASC LIMIT 25];
    supplierStdContacts = [SELECT Id, AccountId, FirstName, LastName, Email, Phone, ToxClear_User_Type__c FROM Contact WHERE ToxClear_User_Type__c = 'ToxClear Standard User' AND Account.ToxClear_Account_Type__c = 'Supplier' ORDER BY Id ASC LIMIT 25];
    facilityAdminContacts = [SELECT Id, AccountId, FirstName, LastName, Email, Phone, ToxClear_User_Type__c FROM Contact WHERE ToxClear_User_Type__c = 'ToxClear Administrator' AND Account.ToxClear_Account_Type__c = 'Facility' ORDER BY Id ASC LIMIT 25];
    facilityStdContacts = [SELECT Id, AccountId, FirstName, LastName, Email, Phone, ToxClear_User_Type__c FROM Contact WHERE ToxClear_User_Type__c = 'ToxClear Standard User' AND Account.ToxClear_Account_Type__c = 'Facility' ORDER BY Id ASC LIMIT 25];
    brandAdminContacts = [SELECT Id, AccountId, FirstName, LastName, Email, Phone, ToxClear_User_Type__c FROM Contact WHERE ToxClear_User_Type__c = 'ToxClear Administrator' AND Account.ToxClear_Account_Type__c = 'Brand' ORDER BY Id ASC LIMIT 25];
    brandStdContacts = [SELECT Id, AccountId, FirstName, LastName, Email, Phone, ToxClear_User_Type__c FROM Contact WHERE ToxClear_User_Type__c = 'ToxClear Standard User' AND Account.ToxClear_Account_Type__c = 'Brand' ORDER BY Id ASC LIMIT 25];

    supplierContacts = new List<Contact>();
    supplierContacts.addAll(supplierAdminContacts);
    supplierContacts.addAll(supplierStdContacts);
    facilityContacts = new List<Contact>();
    facilityContacts.addAll(facilityAdminContacts);
    facilityContacts.addAll(facilityStdContacts);
    brandContacts = new List<Contact>();
    brandContacts.addAll(brandAdminContacts);
    brandContacts.addAll(brandStdContacts);
  }
  /**
   * TC_TestDataFactory_Contacts Inserts a bunch of contacts.
   *
   * @param tdfa (TC_TestDataFactory_Accounts): The accounts constructed already by the Test Data Factory for Accounts.
   * @param email (String): A valid email address to construct distinct addresses based on, or some test email address.
   * @param supplierAdminCount (List<Integer>): Optional null, number of admin contacts to create for as many suppliers as specified in the list.
   * @param supplierStdCount (List<Integer>): Optional null, number of standard contacts to create for as many suppliers as specified in the list.
   * @param facilityAdminCount (List<Integer>): Optional null, number of admin contacts to create for as many facilities as specified in the list.
   * @param facilityStdCount (List<Integer>): Optional null, number of standard contacts to create for as many facilities as specified in the list.
   * @param brandAdminCount (List<Integer>): Optional null, number of admin contacts to create for as many brands as specified in the list.
   * @param brandStdCount (List<Integer>): Optional null, number of standard contacts to create for as many brands as specified in the list.
   */
  public TC_TestDataFactory_Contacts(
    TC_TestDataFactory_Accounts tdfa,
    String email,
    List<Integer> supplierAdminCount,
    List<Integer> supplierStdCount,
    List<Integer> facilityAdminCount,
    List<Integer> facilityStdCount,
    List<Integer> brandAdminCount,
    List<Integer> brandStdCount
  ) {
    // Lists of counts..
    // For each account type encountered, uses Integer from the list until all used up.
    // By design this leaves any remaining accounts without contacts.
    // Initially First supplier to have 1 admin, 1 standard users, etc...
    supplierAdminCount = supplierAdminCount == null
      ? new List<Integer>{ 1, 1, 1, 0, 1 }
      : supplierAdminCount;
    supplierStdCount = supplierStdCount == null
      ? new List<Integer>{ 1, 4, 3, 2, 1 }
      : supplierStdCount;
    facilityAdminCount = facilityAdminCount == null
      ? new List<Integer>{ 1, 2, 0, 1, 1, 1, 1, 1 }
      : facilityAdminCount;
    facilityStdCount = facilityStdCount == null
      ? new List<Integer>{ 1, 4, 3, 2, 2, 1 }
      : facilityStdCount;
    brandAdminCount = brandAdminCount == null
      ? new List<Integer>{ 1, 1 }
      : brandAdminCount;
    brandStdCount = brandStdCount == null
      ? new List<Integer>{ 1, 5, 1 }
      : brandStdCount;

    Contact adminContactTemplate = new Contact(
      Email = email,
      ToxClear_User_Type__c = 'ToxClear Administrator'
    );
    Contact stdContactTemplate = new Contact(
      Email = email,
      ToxClear_User_Type__c = 'ToxClear Standard User'
    );

    supplierAdminContacts = create(
      supplierAdminCount,
      tdfa.suppliers,
      adminContactTemplate
    );
    supplierStdContacts = create(
      supplierStdCount,
      tdfa.suppliers,
      stdContactTemplate
    );
    facilityAdminContacts = create(
      facilityAdminCount,
      tdfa.facilities,
      adminContactTemplate
    );
    facilityStdContacts = create(
      facilityStdCount,
      tdfa.facilities,
      stdContactTemplate
    );
    brandAdminContacts = create(
      brandAdminCount,
      tdfa.brands,
      adminContactTemplate
    );
    brandStdContacts = create(brandStdCount, tdfa.brands, stdContactTemplate);

    insert supplierAdminContacts;
    insert supplierStdContacts;
    insert facilityAdminContacts;
    insert facilityStdContacts;
    insert brandAdminContacts;
    insert brandStdContacts;

    // Now the facilties can have a manger.
    Map<Id, Account> facilities = new Map<Id, Account>(tdfa.facilities);
    List<Account> withManager = new List<Account>();
    for (Contact c : facilityStdContacts) {
      Account facility = facilities.get(c.AccountId);
      if (facility.Facility_Manager__c == null) {
        facility.Facility_Manager__c = c.Id;
        withManager.add(facility);
      }
    }
    update withManager;

    supplierContacts = new List<Contact>();
    supplierContacts.addAll(supplierAdminContacts);
    supplierContacts.addAll(supplierStdContacts);
    facilityContacts = new List<Contact>();
    facilityContacts.addAll(facilityAdminContacts);
    facilityContacts.addAll(facilityStdContacts);
    brandContacts = new List<Contact>();
    brandContacts.addAll(brandAdminContacts);
    brandContacts.addAll(brandStdContacts);
  }

  public static Contact findForAcount(List<Contact> contacts, Account account) {
    for (Contact c : contacts) {
      if (c.AccountId == account.Id) {
        return c;
      }
    }
    return null;
  }
}