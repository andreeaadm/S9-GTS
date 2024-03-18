public with sharing class FacilityListController {
  @AuraEnabled(cacheable=true)
  public static ListResponse getFacilitiesListTableData() {
    return FacilityListTableHelper.buildTable();
  }
}