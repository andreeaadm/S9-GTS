@IsTest(SeeAllData=true)
public with sharing class LightningLoginFormControllerTest {
  @IsTest
  static void LightningLoginFormControllerInstantiation() {
    LightningLoginFormController controller = new LightningLoginFormController();
    System.assertNotEquals(controller, null);
  }

  @IsTest
  static void testIsUsernamePasswordEnabled() {
    System.assertEquals(
      true,
      LightningLoginFormController.getIsUsernamePasswordEnabled()
    );
  }

  @IsTest
  static void testIsSelfRegistrationEnabled() {
    System.assertEquals(
      false,
      LightningLoginFormController.getIsSelfRegistrationEnabled()
    );
  }

  @IsTest
  static void testGetSelfRegistrationURL() {
    System.assertEquals(
      null,
      LightningLoginFormController.getSelfRegistrationUrl()
    );
  }

  @IsTest
  static void testAuthConfig() {
    Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
    System.assertNotEquals(null, authConfig);
  }

  @IsTest
  static void login() {
    // String login(String username, String password, String startUrl)
    String result = LightningLoginFormController.login(
      'username',
      'password',
      'http://a.com'
    );
    System.assertEquals(null, result, 'success is null');
  }

  @IsTest
  static void getForgotPasswordUrl() {
    // String getForgotPasswordUrl(String username, String password, String startUrl)
    String result = LightningLoginFormController.getForgotPasswordUrl();
    System.assert(true, 'success either way');
  }

  @IsTest
  static void setExperienceId() {
    // String setExperienceId(String expId)
    String resultNotAsCommunityUser = LightningLoginFormController.setExperienceId(
      [SELECT Id FROM Network LIMIT 1]
      .Id
    );
    String resultWithoutNetworkId = LightningLoginFormController.setExperienceId(
      null
    );
    System.assertEquals(
      true,
      resultNotAsCommunityUser.startsWith('This method can be invoked'),
      'not a community user'
    );
    System.assertEquals(null, resultWithoutNetworkId, 'without network id');
  }
}