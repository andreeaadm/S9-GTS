/**
 * helper methods for unit testing the ZDHC Gateway API service
 * @author Kevin Reader
 * @date December 2021
 */
@isTest
public with sharing class ZDHCGatewayTestUtility {
  /**
   * gets the contents of a StaticResource which contains a mock response
   * @param staticResourceName - name of the StaticResource containing the mocked response
   * @return mocked response as JSON string
   */
  public static String getStaticResourceContents(String staticResourceName) {
    return [SELECT Body FROM StaticResource WHERE Name = :staticResourceName]
      .Body.toString();
  }

  /**
   * gets a specific metadata record to facilitate a unit test
   * @param metadataName - DeveloperName of the record being queried
   * @return a record containing API config details
   */
  public static ZDHC_Gateway_API__mdt getApiMetadata(String metadataName) {
    for (ZDHC_Gateway_API__mdt mdt : ZDHC_Gateway_API__mdt.getAll().values()) {
      if (mdt.DeveloperName == metadataName) {
        return mdt;
      }
    }
    return null;
  }
}