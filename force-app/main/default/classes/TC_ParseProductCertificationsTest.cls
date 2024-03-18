/**
 * unit tests for the TS_ParseParseProductCertifications apex class
 * @author Kevin Reader (oe:gen)
 * @date January 2022
 */
@isTest
private class TC_ParseProductCertificationsTest {
  @isTest
  private static void parseCertsWithMrslAndOtherTest() {
    List<ZDHCGetProductsResponseCertifications> certs = new List<ZDHCGetProductsResponseCertifications>();
    certs.addAll(getMockMrslCert());
    certs.addAll(getMockOtherCerts());

    Test.startTest();
    Map<String, String> result = TC_ParseProductCertifications.parse(certs);
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assert(result.containsKey('mrsl2'));
    System.assertEquals('Level 3', result.get('mrsl2'));
    System.assert(result.containsKey('otherCertifications'));
    String otherCert = 'Control Union Level 3 - Passed\r\nControl Union Level 4 - Failed';
    System.assertEquals(otherCert, result.get('otherCertifications'));
  }

  @isTest
  private static void parseCertsWithOnlyMrslTest() {
    List<ZDHCGetProductsResponseCertifications> certs = new List<ZDHCGetProductsResponseCertifications>();
    certs.addAll(getMockMrslCert());

    Test.startTest();
    Map<String, String> result = TC_ParseProductCertifications.parse(certs);
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assert(result.containsKey('mrsl2'));
    System.assertEquals('Level 3', result.get('mrsl2'));
    System.assert(result.containsKey('otherCertifications'));
    System.assertEquals('', result.get('otherCertifications'));
  }

  @isTest
  private static void parseCertsWithOnlyOtherTest() {
    List<ZDHCGetProductsResponseCertifications> certs = new List<ZDHCGetProductsResponseCertifications>();
    certs.addAll(getMockOtherCerts());

    Test.startTest();
    Map<String, String> result = TC_ParseProductCertifications.parse(certs);
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assert(!result.containsKey('mrsl2'));
    System.assert(result.containsKey('otherCertifications'));
    String otherCert = 'Control Union Level 3 - Passed\r\nControl Union Level 4 - Failed';
    System.assertEquals(otherCert, result.get('otherCertifications'));
  }

  @isTest
  private static void parseCertsWithNoCertsTest() {
    List<ZDHCGetProductsResponseCertifications> certs = new List<ZDHCGetProductsResponseCertifications>();

    Test.startTest();
    Map<String, String> result = TC_ParseProductCertifications.parse(certs);
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assert(result.isEmpty());
  }

  private static List<ZDHCGetProductsResponseCertifications> getMockMrslCert() {
    List<ZDHCGetProductsResponseCertifications> mrslCert2and3 = new List<ZDHCGetProductsResponseCertifications>();
    ZDHCGetProductsResponseCertifications mrslCert2 = new ZDHCGetProductsResponseCertifications();
    mrslCert2.certificationId = '86';
    mrslCert2.certification = 'ZDHC MRSL v2.0';
    mrslCert2.certificationResult = 'Level 3';
    mrslCert2and3.add(mrslCert2);
    
    ZDHCGetProductsResponseCertifications mrslCert3 = new ZDHCGetProductsResponseCertifications();
    mrslCert3.certificationId = '186';
    mrslCert3.certification = 'ZDHC MRSL v3.1';
    mrslCert3.certificationResult = 'Level 3';
    mrslCert2and3.add(mrslCert3);
    return mrslCert2and3;
  }

  private static List<ZDHCGetProductsResponseCertifications> getMockOtherCerts() {
    List<ZDHCGetProductsResponseCertifications> otherCerts = new List<ZDHCGetProductsResponseCertifications>();
    ZDHCGetProductsResponseCertifications otherCertOne = new ZDHCGetProductsResponseCertifications();
    otherCertOne.certificationId = '6';
    otherCertOne.certification = 'Control Union Level 3';
    otherCertOne.certificationResult = 'Passed';
    otherCerts.add(otherCertOne);
    ZDHCGetProductsResponseCertifications otherCertTwo = new ZDHCGetProductsResponseCertifications();
    otherCertTwo.certificationId = '6';
    otherCertTwo.certification = 'Control Union Level 4';
    otherCertTwo.certificationResult = 'Failed';
    otherCerts.ADD(otherCertTwo);
    return otherCerts;
  }
}