public with sharing virtual class iCare_CountryMetadata_Factory {
  private Map<String, iCare_Country_specific_information__mdt> countrySpecificInformation = iCare_Country_specific_information__mdt.getAll();

  protected virtual Map<String, String> getCountryTimeZone() {
    Map<String, String> mapCountryTimezone = new Map<String, String>();
    for (String key : countrySpecificInformation.keySet()) {
      mapCountryTimezone.put(
        ((iCare_Country_specific_information__mdt) countrySpecificInformation.get(
            key
          ))
          .iCare_Three_Letter_Country_Code__c,
        ((iCare_Country_specific_information__mdt) countrySpecificInformation.get(
            key
          ))
          .iCare_Timezone_Mapping__c
      );
    }
    return mapCountryTimezone;
  }

  protected virtual String getLanguageBannerURL(String languageCode) {
    for (String key : countrySpecificInformation.keySet()) {
      if (
        languageCode != null &&
        languageCode.equals(
          ((iCare_Country_specific_information__mdt) countrySpecificInformation.get(
              key
            ))
            .Country_Language__c
        )
      ) {
        return ((iCare_Country_specific_information__mdt) countrySpecificInformation.get(
            key
          ))
          .Banner_URL_Local_Language__c;
      }
    }
    return ((iCare_Country_specific_information__mdt) countrySpecificInformation.get(
        'IN'
      ))
      .Banner_URL_Local_Language__c;
  }
}