public class welcomeEmailController extends iCare_CountryMetadata_Factory {
  public string customLabel { get; set; }
  public String usernamePassed { get; set; }
  public String communityNamePassed { get; set; }
  public String communityURLPassed { get; set; }
  public String userLanguage { get; set; }

  public String getMergedText() {
    customLabel = communityNamePassed == 'iCare' ? System.Label.iCare_WelcomeEmail_Universal : System.Label.GTS_Welcome_Email_Universal;
    List<String> obj = new List<String>{
      communityNamePassed,
      communityURLPassed,
      usernamePassed,
      this.getLanguageBannerURL(userLanguage)
    };
    return String.format(customLabel, obj);
  }
}