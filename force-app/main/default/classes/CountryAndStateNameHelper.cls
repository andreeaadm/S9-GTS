public class CountryAndStateNameHelper {
  @InvocableMethod(
    label='Get Country and State Names'
    description='Returns the name of country and state codes using ISO code values'
  )
  public static List<String> getCountryAndStateNames(
    List<RequestHelper> requests
  ) {
    List<String> responseList = new List<String>();
    for (RequestHelper objRequest : requests) {
      Map<String, List<String>> controllingInfo = new Map<String, List<String>>();
      Schema.DescribeFieldResult fieldResult;
      Schema.DescribeFieldResult countryFieldResult = User.Countrycode.getDescribe();
      Schema.DescribeFieldResult stateFieldResult = User.Statecode.getDescribe();

      List<Schema.PicklistEntry> countryValues = countryFieldResult.getPicklistValues();
      List<Schema.PicklistEntry> stateValues = stateFieldResult.getPicklistValues();

      for (Schema.PicklistEntry currCountryValue : countryValues) {
        controllingInfo.put(currCountryValue.getValue(), new List<String>());
      }

      for (Schema.PicklistEntry currDependentValue : stateValues) {
        String jsonString = JSON.serialize(currDependentValue);

        PickListInfoHelper info = (PickListInfoHelper) JSON.deserialize(
          jsonString,
          PickListInfoHelper.class
        );

        String hexString = EncodingUtil.convertToHex(
            EncodingUtil.base64Decode(info.validFor)
          )
          .toUpperCase();

        // System.debug('DependentField: Label:' + currDependentValue.getLabel() + ' ValidForInHex:' + hexString + ' JsonString:' + jsonString);

        Integer baseCount = 0;

        for (Integer curr : hexString.getChars()) {
          Integer val = 0;

          if (curr >= 65) {
            val = curr - 65 + 10;
          } else {
            val = curr - 48;
          }

          if ((val & 8) == 8) {
            controllingInfo.get(countryValues[baseCount + 0].getValue())
              .add(currDependentValue.getLabel());
          }
          if ((val & 4) == 4) {
            controllingInfo.get(countryValues[baseCount + 1].getValue())
              .add(currDependentValue.getLabel());
          }
          if ((val & 2) == 2) {
            controllingInfo.get(countryValues[baseCount + 2].getValue())
              .add(currDependentValue.getLabel());
          }
          if ((val & 1) == 1) {
            controllingInfo.get(countryValues[baseCount + 3].getValue())
              .add(currDependentValue.getLabel());
          }

          baseCount += 4;
        }
      }
      if (
        objRequest.countryISOCode != null &&
        objRequest.countryISOCode != '' &&
        (objRequest.stateISOCode == '' ||
        objRequest.stateISOCode == null)
      ) {
        fieldResult = User.Countrycode.getDescribe();
      } else if (
        objRequest.stateISOCode != null &&
        objRequest.stateISOCode != ''
      ) {
        fieldResult = User.Statecode.getDescribe();
      }
      for (Schema.PicklistEntry ple : fieldResult.getPicklistValues()) {
        if (
          ple.getValue() == objRequest.countryISOCode &&
          (objRequest.stateISOCode == '' ||
          objRequest.stateISOCode == null)
        ) {
          responseList.add(ple.getLabel());
        } else if (
          ple.getValue() == objRequest.stateISOCode &&
          controllingInfo.containsKey(objRequest.countryISOCode)
        ) {
          for (
            String stateVal : controllingInfo.get(objRequest.countryISOCode)
          ) {
            if (ple.getLabel() == stateVal) {
              responseList.add(ple.getLabel());
            }
          }
        }
      }
    }
    return responseList;
  }

  public class RequestHelper {
    @InvocableVariable
    public String countryISOCode;

    @InvocableVariable
    public String stateISOCode;
  }

  public class PickListInfoHelper {
    public String validFor;
  }
}