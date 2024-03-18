public with sharing class ManageReportController {

  /* History*
   * 26-12-2023   kamlesh.kahar   MBS-313   Manage/Assign/Retract reports modal enhancement
   */
  
  @AuraEnabled
  public static ListResponse getTableData(
    Integer rowLimit,
    String filterSearch,
    String filterStatus,
    String orderBy,
    List<String> selectedRowIds,
    String mode
  ) {
   return ContactGroupUtil.getGroupTableData(rowLimit, filterSearch, filterStatus, orderBy, selectedRowIds, 'Report', mode);
  }

  @AuraEnabled
  public static APIResponse manage(
    List<String> selectedReportIds,
    List<String> selectedGroupIds
  ) {
    if (selectedReportIds != null && selectedReportIds.size() == 1) {
      try {
        List<Contact_Group__c> selectedGroups = new List<Contact_Group__c>();
        for (String s : selectedGroupIds) {
          selectedGroups.add(new Contact_Group__c(Id = s));
        }
        return ContactGroupUtil.grantReportAccessBasedOnSelection(
          selectedGroups,
          selectedReportIds[0]
        );
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
        return new APIResponse('Bad Request', 400, e.getMessage());
      }
    } else {
      return new APIResponse('Bad Request', 400, 'Invalid selectedReportIds');
    }
  }

  @AuraEnabled
  public static APIResponse assign(
    List<String> selectedReportIds,
    List<String> selectedGroupIds
  ) {
    try {
      List<Contact_Group__c> selectedGroups = new List<Contact_Group__c>();
      for (String s : selectedGroupIds) {
        selectedGroups.add(new Contact_Group__c(Id = s));
      }
      List<Asset> selectedReports = new List<Asset>();
      for (String r : selectedReportIds) {
        selectedReports.add(new Asset(Id = r));
      }
      ContactGroupUtil.linkGroupsToReports(selectedGroups, selectedReports);
      return new APIResponse('OK', 200);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return new APIResponse('Bad Request', 400, e.getMessage());
    }
  }

  @AuraEnabled
  public static APIResponse retract(
    List<String> selectedReportIds,
    List<String> selectedGroupIds
  ) {
    try {
      List<Contact_Group__c> selectedGroups = new List<Contact_Group__c>();
      for (String s : selectedGroupIds) {
        selectedGroups.add(new Contact_Group__c(Id = s));
      }
      List<Asset> selectedReports = new List<Asset>();
      for (String r : selectedReportIds) {
        selectedReports.add(new Asset(Id = r));
      }
      ContactGroupUtil.unlinkGroupsFromReports(selectedGroups, selectedReports);
      return new APIResponse('OK', 200);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return new APIResponse('Bad Request', 400, e.getMessage());
    }
  }
}