public with sharing class TC_AddFormulators {
  @AuraEnabled
  public static String addFormulator(
    String organizationName,
    String formulatorGUID,
    String address,
    String supplierAID
  ) {
    List<Formulator__c> formulatorList = [
      SELECT Id
      FROM Formulator__c
      WHERE ZDHC_Formulator_GUID__c = :formulatorGUID
    ];

    if (formulatorList.size() == 0) {
      final TC_ExperienceCloud context = new TC_ExperienceCloud();
      formulatorList.add(
        new Formulator__c(
          Name = organizationName,
          ZDHC_Formulator_GUID__c = formulatorGUID,
          Address_from_ZDHC__c = address,
          ZDHC_Supplier_AID__c = supplierAID,
          Origin__c = 'ZDHC Gateway',
          Created_By__c = context.user.Contact.Main_Facility__c
        )
      );
      insert formulatorList;
    }
    return formulatorList[0].Id;
  }
}