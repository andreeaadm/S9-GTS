@isTest
public with sharing class DirectConnectControllerTest {
  @isTest
  static void nonDirectConnectUser_getEmptyString() {
    User notDC = TestDataFactory.createCommunityUser('MTC Standard');
    System.runAs(notDC) {
      System.assertEquals(
        '',
        DirectConnectController.getDirectConnectEphemeralURL()
      );
    }
  }

  @isTest
  static void directConnectUser_getLoginURL() {
    User dcUser = TestDataFactory.createCommunityUser('MTC Standard');
    System.runAs(new User(Id = UserInfo.getUserId())) {
      PermissionSet ps = [
        SELECT Id
        FROM PermissionSet
        WHERE Name = 'MTC_Satellite_User'
      ];
      PermissionSetAssignment psa = new PermissionSetAssignment(
        AssigneeId = dcUser.Id,
        PermissionSetId = ps.Id
      );
      insert psa;
    }
    System.runAs(dcUser) {
      String url = DirectConnectController.getDirectConnectEphemeralURL();
      System.assertNotEquals('', url);
      System.assert(url.startsWith(DirectConnectController.dcHost));
    }
  }
}