public with sharing class TC_SearchFormulatorsController {
  @AuraEnabled
  public static TC_SearchFormulatorsResponse getFormulators(
    String userAccessKey,
    String searchCriteria
  ) {
    ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
    zdhcRequest.apiName = 'formulators';
    zdhcRequest.method = 'GET';
    zdhcRequest.userAccessKey = userAccessKey;

    Map<String, Object> queryParams = new Map<String, Object>();
    queryParams.put('search', searchCriteria);
    zdhcRequest.queryParams = queryParams;

    ZDHCGatewayServiceResponse result = ZDHCGatewayService.makeCallout(
      zdhcRequest
    );

    TC_SearchFormulatorsResponse searchResponse = new TC_SearchFormulatorsResponse();

    if (result.response instanceof ZDHCGatewayUnexpectedResponse) {
      ZDHCGatewayUnexpectedResponse zdhcResponse = (ZDHCGatewayUnexpectedResponse) result.response;

      searchResponse.isSuccess = false;

      List<String> errors = new List<String>{};
      errors.add((String) zdhcResponse.body);
      searchResponse.errors = errors;
    } else if (result.response instanceof ZDHCGetFormulatorsResponse) {
      ZDHCGetFormulatorsResponse formulatorsResponse = (ZDHCGetFormulatorsResponse) result.response;

      if (result.isSuccess && result.response != null) {
        searchResponse.formulatorsResponseData = formulatorsResponse.data;
        searchResponse.isSuccess = true;
      } else {
        searchResponse.isSuccess = false;
        searchResponse.errors = result.errors;
      }
    } else {
      searchResponse.isSuccess = false;
      searchResponse.errors = new List<String>{
        'unknown response - neither ZDHCGatewayUnexpectedResponse nor ZDHCGetFormulatorsResponse'
      };
    }

    return searchResponse;
  }

  /**
   * getFormulatorId returns a formulator record id in Salesforce for the
   * GUID specified.
   * @param formulatorGUID (String): An existing ZDHC Formululator GUID to
   * lookup/update and create if not currently an existing formulator.
   * @return String: Id of the Formulator__c record.
   */
  @AuraEnabled
  public static String getFormulatorId(
    String userAccessKey,
    String formulatorGUID
  ) {
    try {
      List<Formulator__c> formulator = [
        SELECT Id
        FROM Formulator__c
        WHERE ZDHC_Formulator_GUID__c = :formulatorGUID
      ];
      final TC_ExperienceCloud context = new TC_ExperienceCloud();
      final ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
      zdhcRequest.apiName = 'formulators';
      zdhcRequest.method = 'GET';
      zdhcRequest.userAccessKey = userAccessKey;
      zdhcRequest.queryParams = new Map<String, Object>{
        'organizationGUID' => formulatorGUID
      };

      final ZDHCGatewayServiceResponse result = ZDHCGatewayService.makeCallout(
        zdhcRequest
      );
      if (
        result.isSuccess &&
        result.response != null &&
        result.response instanceof ZDHCGetFormulatorsResponse &&
        !((ZDHCGetFormulatorsResponse) result.response).data.isEmpty()
      ) {
        final ZDHCGetFormulatorsResponse formulatorsResponse = (ZDHCGetFormulatorsResponse) result.response;
        if (formulator.isEmpty()) {
          formulator.add(
            new Formulator__c(
              Name = formulatorsResponse.data[0].organizationName,
              ZDHC_Formulator_GUID__c = formulatorsResponse.data[0]
                .formulatorGUID,
              ZDHC_Supplier_AID__c = formulatorsResponse.data[0].supplierAID,
              Address_from_ZDHC__c = formulatorsResponse.data[0].address,
              Origin__c = 'ZDHC Gateway',
              Created_By__c = context.user.Contact.Main_Facility__c
            )
          );
        } else {
          formulator[0].Name = formulatorsResponse.data[0].organizationName;
          formulator[0].ZDHC_Formulator_GUID__c = formulatorsResponse.data[0]
            .formulatorGUID;
          formulator[0].ZDHC_Supplier_AID__c = formulatorsResponse.data[0]
            .supplierAID;
          formulator[0].Address_from_ZDHC__c = formulatorsResponse.data[0]
            .address;
        }
        upsert formulator;
      } else {
        throw new AuraHandledException(String.join(result.errors, ', '));
      }
      return formulator[0].Id;
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * createZDHCFormulator creates the formulator by posting to the
   * ZDHC Gateway service, obtaining a new formulator GUID.
   * @param formulatorId (String): SObject Id of a formulator to post to
   * ZDHC Gateway service.
   * @return String: Write the return description
   */
  @AuraEnabled
  public static Formulator__c createZDHCFormulator(
    String userAccessKey,
    String formulatorId
  ) {
    try {
      List<Formulator__c> formulator = [
        SELECT
          Address__c,
          Address_from_ZDHC__c,
          City_Town__c,
          Contact_Email__c,
          Contact_Name__c,
          Country__c,
          Created_By__c,
          Id,
          Name,
          Origin__c,
          Phone__c,
          State_Province__c,
          Supplier__c,
          ZDHC_Formulator_GUID__c,
          ZDHC_Supplier_AID__c,
          Zip_Postal_Code__c
        FROM Formulator__c
        WHERE Id = :formulatorId
      ];
      if (formulator.isEmpty()) {
        throw new AuraHandledException(Label.TC_Formulator_Not_Found);
      }
      final TC_ExperienceCloud context = new TC_ExperienceCloud();
      final ZDHCGatewayServiceRequest zdhcRequest = new ZDHCGatewayServiceRequest();
      zdhcRequest.apiName = 'formulators';
      zdhcRequest.method = 'POST';
      zdhcRequest.userAccessKey = userAccessKey;
      final ZDHCPostFormulatorRequest body = new ZDHCPostFormulatorRequest();
      body.name = formulator[0].Name;
      body.phone = formulator[0].Phone__c;
      body.address = formulator[0].Address__c;
      body.cityTown = formulator[0].City_Town__c;
      body.stateProvince = formulator[0].State_Province__c;
      body.country = formulator[0].Country__c;
      body.postalCode = formulator[0].Zip_Postal_Code__c;
      body.contactName = formulator[0].Contact_Name__c;
      body.contactEmail = formulator[0].Contact_Email__c;
      zdhcRequest.requestBody = body;
      final ZDHCGatewayServiceResponse result = ZDHCGatewayService.makeCallout(
        zdhcRequest
      );
      if (
        result.isSuccess &&
        result.response != null &&
        result.response instanceof ZDHCPostFormulatorsResponse &&
        String.isNotBlank(
          ((ZDHCPostFormulatorsResponse) result.response).formulatorGUID
        )
      ) {
        final ZDHCPostFormulatorsResponse formulatorResponse = (ZDHCPostFormulatorsResponse) result.response;
        formulator[0]
          .ZDHC_Formulator_GUID__c = formulatorResponse.formulatorGUID;
        formulator[0].Origin__c = 'Supplier';
        formulator[0].Created_By__c = context.user.Contact.Main_Facility__c;
        update formulator;
        return formulator[0];
      } else {
        throw new AuraHandledException(String.join(result.errors, '\n'));
      }
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}