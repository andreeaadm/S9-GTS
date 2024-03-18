public without sharing class OrgUtil {
  public static String edition = '';
  public static String hostOverride = '';

  public static Boolean isProduction() {
    return !isSandbox() &&
      (getEdition().containsIgnoreCase('enterprise') ||
      getEdition().containsIgnoreCase('unlimited') ||
      getEdition().containsIgnoreCase('performance'));
  }
  public static String getEdition() {
    if (edition != '') {
      return edition;
    } else {
      edition = 'undecided';
      List<Organization> orgs = [
        SELECT Id, OrganizationType
        FROM Organization
        LIMIT 1
      ];

      // Check to make sure we have a result
      if (!orgs.isEmpty()) {
        edition = orgs[0].OrganizationType;
      }
      return edition;
    }
  }
  public static Boolean isSandbox() {
    String host = String.isEmpty(hostOverride)
      ? URL.getSalesforceBaseUrl().getHost()
      : hostOverride;
    String server = host.substring(0, host.indexOf('.'));

    // It's easiest to check for 'my domain' sandboxes first
    // even though that will be rare
    if (
      server.contains('--') ||
      server.contains('uat') ||
      server.contains('preprod')
    )
      return true;

    // tapp0 is a unique "non-cs" server so we check it now
    if (server == 'tapp0')
      return true;

    // If server is 'cs' followed by a number it's a sandbox
    if (server.length() > 2) {
      if (server.substring(0, 2) == 'cs') {
        try {
          Integer.valueOf(server.substring(2, server.length()));
        } catch (exception e) {
          //started with cs, but not followed by a number
          return false;
        }

        //cs followed by a number, that's a hit
        return true;
      }
    }

    // If we made it here it's a production box
    return false;
  }
}