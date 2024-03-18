public with sharing class DirectConnectController {
  @testVisible
  private static String dcHost {
    get {
      return OrgUtil.isProduction()
        ? Label.MTC_System_DirectConnect_URL
        : Label.MTC_System_DirectConnect_StagingURL;
    }
    private set;
  }

  /**History:
   *    28-07-2023  kamlesh.kahar  https://intertek.atlassian.net/browse/MBS-304
   */
  @AuraEnabled(cacheable=false)
  public static String getDirectConnectEphemeralURL() {
    String result = '';
    User currentUser = MTCUserUtil.currentUserObj;
    if (FeatureManagement.checkPermission('DirectConnect_Access')) {
      String shared = Label.MTC_System_DirectConnect_Application_ID;
      String URI = dcHost;

      String email = currentUser.Email;
      Integer expireAfterSeconds = Integer.valueOf(System.Label.Direct_Connect_Expire_Time_in_Seconds);
      Long currentTime = DateTime.now().getTime();
      Long littleLater = currentTime + (expireAfterSeconds * 1000);

      String toSign = 'autoLogin.htm?user=' + email + '&expires=' + littleLater;

      Blob digest = Crypto.generateDigest(
        'SHA-256',
        Blob.valueOf(toSign + shared)
      );

      String encoded = EncodingUtil.base64Encode(digest);

      result = '' + URI + toSign + '&sig=' + encoded + '&currenttimestamp=' + currentTime;
    }
    return result;
  }
}