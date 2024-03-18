public with sharing class GTS_Portal {
  private String nameForPortalURL;

  public GTS_Portal(String nameForPortalURL) {
    this.nameForPortalURL = nameForPortalURL;
  }

  public String getiCarePortalBaseUrl() {
    Id siteId = [SELECT Id FROM Site WHERE Name = :this.nameForPortalURL].Id;
    SiteDetail siteDetail = [
      SELECT Id, SecureUrl
      FROM SiteDetail
      WHERE DurableId = :siteId
    ];
    return siteDetail.SecureUrl;
  }
}