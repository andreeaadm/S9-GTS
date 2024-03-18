public with sharing class iCarePassReset extends iCare_CountryMetadata_Factory {
  public String communityNamePassed { get; set; }
  public String communityUrlPassed { get; set; }
  public string customLabel { get; set; }
  public string userLanguage { get; set; }

  public String getMergedText() {
    customLabel = communityNamePassed == 'iCare' ? System.Label.iCare_PasswordResetEmail_Universal : System.Label.GTS_Password_Reset_Email_Universal;
    List<String> obj = new List<String>{
      communityNamePassed,
      communityUrlPassed,
      this.getLanguageBannerURL(userLanguage)
    };
    return String.format(customLabel, obj);
  }
}