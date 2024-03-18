public with sharing class TC_SearchFormulatorsResponse {
  @AuraEnabled
  public List<ZDHCGetFormulatorsResponseData> formulatorsResponseData;

  @AuraEnabled
  public Boolean isSuccess;

  @AuraEnabled
  public List<String> errors;
}