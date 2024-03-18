@isTest
public with sharing class TC_TestDataFactory_Bulletins {
  public static final String subjectString = 'This is my test bulletins subject line string';
  public static final String rawDescriptionString = '<h1>I am a test description</h1><p>I am rich text with html tags</p>';
  public static final String cleanDescriptionString = ' I am a test description  I am rich text with html tags ';
  public static final String intertekAudience = 'Intertek';
  public static final String brandAudience = 'Brands';
  public static final String supplierAudience = 'Suppliers';
  public static final String allAudience = String.join(
    new List<String>{ intertekAudience, brandAudience, supplierAudience },
    ';'
  );
  public static final String intertekAndBrandAudience = String.join(
    new List<String>{ intertekAudience, brandAudience },
    ';'
  );
  public static final String intertekAndSupplierAudience = String.join(
    new List<String>{ intertekAudience, supplierAudience },
    ';'
  );
  public static final String brandAndSupplierAudience = String.join(
    new List<String>{ brandAudience, supplierAudience },
    ';'
  );
  public static final List<String> audienceList = new List<String>{
    intertekAudience,
    brandAudience,
    supplierAudience,
    allAudience,
    intertekAndBrandAudience,
    intertekAndSupplierAudience,
    brandAndSupplierAudience
  };

  /*
   * Inserts 56 Bulletins which cover every combination of fields
   * Half of the Bulletins are sent by the account Id given and half by intertek
   * All audiences and combinations are covered
   */
  public TC_TestDataFactory_Bulletins(User sentFromUser) {
    List<Bulletin__c> intertekBulletins = new List<Bulletin__c>();
    List<Bulletin__c> userBulletins = new List<Bulletin__c>();
    for (String audience : audienceList) {
      intertekBulletins.add(create(true, true, audience));
      intertekBulletins.add(create(true, false, audience));
      intertekBulletins.add(create(false, true, audience));
      intertekBulletins.add(create(false, false, audience));

      userBulletins.add(create(true, true, audience));
      userBulletins.add(create(true, false, audience));
      userBulletins.add(create(false, true, audience));
      userBulletins.add(create(false, false, audience));
    }

    System.runAs(sentFromUser) {
      insert userBulletins;
    }

    insert intertekBulletins;
  }

  public static Bulletin__c create(
    Boolean isActive,
    Boolean isPinned,
    String targetAudience
  ) {
    Bulletin__c bulletin = new Bulletin__c();
    bulletin.Active__c = isActive;
    bulletin.Pinned__c = isPinned;
    bulletin.Target_Audience__c = targetAudience;
    bulletin.Subject__c = subjectString;
    bulletin.Description__c = rawDescriptionString;
    return bulletin;
  }
}