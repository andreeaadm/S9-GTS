global class iCareTranslatePicklistValueAction {
  @InvocableMethod(label='Translate Picklist Value')
  global static List<TranslatePicklistValueActionResult> translatedPicklistValues(
    List<TranslatePicklistValueRequest> requests
  ) {
    List<TranslatePicklistValueActionResult> results = new List<TranslatePicklistValueActionResult>();
    for (TranslatePicklistValueRequest request : requests) {
      results.add(translatePicklistValue(request));
    }
    return results;
  }

  public static TranslatePicklistValueActionResult translatePicklistValue(
    TranslatePicklistValueRequest request
  ) {
    TranslatePicklistValueActionResult result = new TranslatePicklistValueActionResult();
    String translatedValue;

    if (String.isBlank(request.picklistValue)) {
      result.translatedValue = '';
      return result;
    }

    List<PicklistController.PicklistWrapper> picklistValues = PicklistController.getDependentPicklistValues(
      request.objectName,
      request.fieldName,
      request.controllingFieldValue
    );
    translatedValue = request.picklistValue;

    for (PicklistController.PicklistWrapper picklistEntry : picklistValues) {
      if (picklistEntry.picklistValue == request.picklistValue) {
        translatedValue = picklistEntry.picklistLabel;
      }
    }

    result.translatedValue = translatedValue;
    return result;
  }

  global class TranslatePicklistValueActionResult {
    @InvocableVariable
    global String translatedValue;
  }

  global class TranslatePicklistValueRequest {
    @InvocableVariable(
      label='Object API Name'
      description='API name of the object'
      required=true
    )
    global String objectName;

    @InvocableVariable(
      label='Field Name'
      description='API name of the picklist field'
      required=true
    )
    global String fieldName;

    @InvocableVariable(
      label='Controlling field value'
      description='Value of the picklist controlling field'
      required=true
    )
    global String controllingFieldValue;

    @InvocableVariable(
      label='Picklist Value'
      description='Picklist value to be translated'
      required=true
    )
    global String picklistValue;
  }
}