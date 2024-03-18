@isTest
public with sharing class OrgUtilTest {
  @isTest
  static void editionCheck() {
    OrgUtil.edition = 'Developer Edition';
    System.assertEquals(false, OrgUtil.isProduction());
  }

  @isTest
  static void editionCheck2() {
    System.assertEquals(false, String.isEmpty(OrgUtil.getEdition()));
  }

  @isTest
  static void hostCheck1() {
    OrgUtil.edition = 'Unlimited Edition';
    OrgUtil.hostOverride = 'theCustomer--uat.cs40.my.salesforce.com';
    System.assertEquals(false, OrgUtil.isProduction());
  }

  @isTest
  static void hostCheck2() {
    OrgUtil.edition = 'Unlimited Edition';
    OrgUtil.hostOverride = 'theCustomer.lightning.force.com';
    System.assertEquals(true, OrgUtil.isProduction());
  }

  @isTest
  static void hostCheck3() {
    OrgUtil.hostOverride = 'cs40.my.salesforce.com';
    System.assertEquals(true, OrgUtil.isSandbox());
  }

  @isTest
  static void hostCheck4() {
    OrgUtil.hostOverride = 'tapp0.cs40.my.salesforce.com';
    System.assertEquals(true, OrgUtil.isSandbox());
  }

  @isTest
  static void hostCheck5() {
    OrgUtil.hostOverride = 'csABC.my.salesforce.com';
    System.assertEquals(false, OrgUtil.isSandbox());
  }
}