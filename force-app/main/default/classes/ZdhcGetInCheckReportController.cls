public with sharing class ZdhcGetInCheckReportController {
  @AuraEnabled
  public static string getInCheckReportForInventory(String inventoryId) {
    try {
      // check that the id corresponds to a valid inventory and retrieve the record
      Inventory__c inventoryToGet = getInventory(inventoryId);

      // get the access key of the relevant facility manager
      String userAccessKey = ZDHCGatewayService.getUserAccessKey(
        inventoryToGet.Facility__r.Facility_Manager__c
      );

      // construct the request and make the callout
      ZDHCGatewayServiceRequest request = constructRequest(
        userAccessKey,
        inventoryToGet.InCheck_Report_Verification_Id__c
      );

      // process the response and return the data or a null value
      return processResponse(
        ZDHCGatewayService.makeCallout(request),
        inventoryToGet
      );
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @TestVisible
  private static Inventory__c getInventory(String inventoryId) {
    User user = [
      SELECT Contact.AccountId, Contact.Account.ToxClear_Account_Type__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];

    Id accountId = user.Contact.AccountId;

    String queryString = 'SELECT Facility__r.Facility_Manager__c, Facility__r.Name, Facility__r.Parent.Name, Inventory_Name__c, InCheck_Report_Verification_Id__c FROM Inventory__c WHERE Id = :inventoryId AND Status__c = \'Submitted\' AND InCheck_Report_Verification_Id__c != NULL';
    List<Id> supplierIds = new List<Id>();

    if (user.Contact.Account.ToxClear_Account_Type__c == 'Brand') {
      List<Brand_Supplier_Connection__c> connections = [
        SELECT Supplier_Account__c
        FROM Brand_Supplier_Connection__c
        WHERE
          Brand_Account__c = :accountId
          AND Active__c = TRUE
          AND Status__c = 'Approved'
      ];

      for (Brand_Supplier_Connection__c conn : connections) {
        supplierIds.add(conn.Supplier_Account__c);
      }

      queryString += ' AND Facility__r.ParentId IN :supplierIds';
    } else if (user.Contact.Account.ToxClear_Account_Type__c == 'Supplier') {
      queryString += ' AND Facility__r.ParentId = :accountId';
    } else if (user.Contact.Account.ToxClear_Account_Type__c == 'Facility') {
      queryString += ' AND Facility__c = :accountId';
    }

    // get the inventory in question - error occurs if it doesn't exist or isn't valid
    return Database.query(queryString);
  }

  @TestVisible
  private static ZDHCGatewayServiceRequest constructRequest(
    String userAccessKey,
    String inCheckId
  ) {
    ZDHCGatewayServiceRequest request = new ZDHCGatewayServiceRequest();
    request.apiName = 'incheckReport';
    request.method = 'GET';
    request.userAccessKey = userAccessKey;
    request.queryParams = new Map<String, Object>{ 'reportId' => inCheckId };

    return request;
  }

  @TestVisible
  private static String processResponse(
    ZDHCGatewayServiceResponse zdhcResponse,
    Inventory__c inventoryToGet
  ) {
    // process a successful response
    if (zdhcResponse?.isSuccess == true) {
      ZDHCGetInCheckReportResponse responseData = (ZDHCGetInCheckReportResponse) zdhcResponse
        ?.response;
      if (responseData.result.success == true) {
        String fileName =
          inventoryToGet.Facility__r.Parent.Name +
          ' - ' +
          inventoryToGet.Facility__r.Name +
          ' - ' +
          inventoryToGet.Inventory_Name__c +
          '.pdf';

        return JSON.serialize(
          new Map<String, String>{
            'fileName' => fileName,
            'fileData' => responseData.incheckReport
          }
        );
      }
    }

    String errorString = zdhcResponse?.errors != null
      ? String.join(zdhcResponse.errors, ', ')
      : null;
    return errorString;
  }
}