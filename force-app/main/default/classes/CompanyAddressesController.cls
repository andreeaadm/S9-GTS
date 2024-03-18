public with sharing class CompanyAddressesController {
  @AuraEnabled
  public static Boolean insertCase(Case newCase) {
    try {
      insert newCase;
      return true;
    } catch (Exception e) {return false; }
  }
}