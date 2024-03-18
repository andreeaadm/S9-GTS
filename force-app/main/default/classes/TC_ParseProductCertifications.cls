/**
 * parses the product certifications data received from ZDHC
 * @author Kevin Reader (oe:gen)
 * @date January 2022
 */
public with sharing class TC_ParseProductCertifications {
  /**
   * parses the a product's certifications returned from ZDHC
   * @param certs - a collection of certifications for a ZDHC product
   * @return key value pair of parsed data, including MRSL 2 level and other certs
   */
  @AuraEnabled
  public static Map<String, String> parse(
    List<ZDHCGetProductsResponseCertifications> certs
  ) {
    Map<String, String> parsedData = new Map<String, String>();
    if (!certs.isEmpty()) {
      String otherCerts = '';
      for (ZDHCGetProductsResponseCertifications cert : certs) {
        if (cert.certification == 'ZDHC MRSL v2.0' || cert.certification == 'Archived ZDHC MRSL v2.0') {
          parsedData.put('mrsl2', cert.certificationResult);
        }
        else if (cert.certification == 'ZDHC MRSL v3.1') {
          parsedData.put('mrsl3', cert.certificationResult);
        }
        else {
          otherCerts += String.format(
            '{0} - {1}\r\n',
            new List<String>{ cert.certification, cert.certificationResult }
          );
        }
      }
      otherCerts = otherCerts.removeEnd('\r\n');
      parsedData.put('otherCertifications', otherCerts);
    }
    return parsedData;
  }
}