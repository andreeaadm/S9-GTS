public with sharing class CMSController {
  public class AllItemsWrapper {
    @AuraEnabled
    public ConnectApi.ManagedContentVersionCollection content;
    @AuraEnabled
    public Boolean moreItemsAvailable = false;
    public AllItemsWrapper(
      ConnectApi.ManagedContentVersionCollection content,
      Boolean moreItemsAvailable
    ) {
      this.content = content;
      this.moreItemsAvailable = moreItemsAvailable;
    }
  }

  @AuraEnabled(cacheable=true)
  public static ConnectApi.ManagedContentVersionCollection getSingleItem(
    String contentKey,
    String managedContentType
  ) {
    System.assert(contentKey != null && managedContentType != null);
    ConnectApi.ManagedContentVersionCollection returnData;
    String uniqueKey = contentKey + managedContentType;
    Id networkId;
    if (Test.isRunningTest()) {
      networkId = [SELECT Id FROM Network LIMIT 1].Id;
    } else {
      networkId = Network.getNetworkId();
    }
    try {
      // ConnectApi.ManagedContent.getManagedContentByContentKeys(communityId, contentKeys, pageParam, pageSize, language, managedContentType, showAbsoluteUrl)
      returnData = ConnectApi.ManagedContent.getManagedContentByContentKeys(
        networkId,
        new List<String>{ contentKey },
        0,
        1,
        'en_US',
        managedContentType,
        true
      );
      return returnData;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }

  @AuraEnabled(cacheable=true)
  public static AllItemsWrapper getAllItemsForType(
    String managedContentType,
    Integer itemsPerPage,
    Integer pageNumber,
    List<String> topics,
    String language
  ) {
    System.assert(managedContentType != null);
    itemsPerPage = itemsPerPage != null ? itemsPerPage : 250;
    pageNumber = pageNumber != null ? pageNumber : 0;
    language = language != null ? language : UserInfo.getLanguage();
    Id networkId;
    if (Test.isRunningTest()) {
      networkId = [SELECT Id FROM Network LIMIT 1].Id;
    } else {
      networkId = Network.getNetworkId();
    }
    try {
      // ConnectApi.ManagedContent.getManagedContentByTopics(communityId, topics, pageParam, pageSize, language, managedContentType, showAbsoluteUrl)
      // ConnectApi.ManagedContent.getAllManagedContent(communityId, pageParam, pageSize, language, managedContentType, showAbsoluteUrl)
      ConnectApi.ManagedContentVersionCollection content = topics != null &&
        topics.size() > 0
        ? ConnectApi.ManagedContent.getManagedContentByTopics(
            networkId,
            topics,
            pageNumber,
            itemsPerPage,
            language,
            managedContentType,
            true
          )
        : ConnectApi.ManagedContent.getAllManagedContent(
            networkId,
            pageNumber,
            itemsPerPage,
            language,
            managedContentType,
            true
          );

      ConnectApi.ManagedContentVersionCollection nextPage = (topics != null &&
        topics.size() > 0
        ? ConnectApi.ManagedContent.getManagedContentByTopics(
            networkId,
            topics,
            pageNumber + 1, // is the next page empty?
            itemsPerPage,
            language,
            managedContentType,
            true
          )
        : ConnectApi.ManagedContent.getAllManagedContent(
            networkId,
            pageNumber + 1, // is the next page empty?
            itemsPerPage,
            language,
            managedContentType,
            true
          ));

      return new AllItemsWrapper(
        content,
        nextPage.items != null &&
        nextPage.items.size() > 0
      );
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getBlogMetrics(String contentKey) {
    System.assert(contentKey != null);
    Map<String, Object> returnMap = new Map<String, Object>{
      'views' => 0,
      'likes' => 0
    };
    try {
      Blog_Metric__c blogMetric = [
        SELECT LikeCount__c, ViewCount__c
        FROM Blog_Metric__c
        WHERE Content_Key__c = :contentKey
        LIMIT 1
      ];
      returnMap.put('views', blogMetric.ViewCount__c);
      returnMap.put('likes', blogMetric.LikeCount__c);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      insert new Blog_Metric__c(Content_Key__c = contentKey);
    }
    return returnMap;
  }

  @AuraEnabled
  public static void toggleLike(String contentKey, Boolean isLike) {
    System.assert(contentKey != null && isLike != null);
    try {
      WithoutSharing ws = new WithoutSharing();
      ws.toggleLike(contentKey, isLike);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
  }

  @AuraEnabled
  public static void viewBlog(String contentKey) {
    System.assert(contentKey != null);
    try {
      WithoutSharing ws = new WithoutSharing();
      ws.viewBlog(contentKey);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
  }

  public without sharing class WithoutSharing {
    public WithoutSharing() {
    }
    public void toggleLike(String contentKey, Boolean isLike) {
      List<Blog_Metric__c> blogMetric = new List<Blog_Metric__c>(
        [
          SELECT LikeCount__c
          FROM Blog_Metric__c
          WHERE Content_Key__c = :contentKey
          LIMIT 1
          FOR UPDATE
        ]
      );
      if (blogMetric.isEmpty()) {
        Blog_Metric__c newMetric = new Blog_Metric__c(
          Content_Key__c = contentKey,
          LikeCount__c = 1
        );
        insert newMetric;
      } else {
        blogMetric[0].LikeCount__c = isLike
          ? blogMetric[0].LikeCount__c + 1
          : blogMetric[0].LikeCount__c - 1;
        update blogMetric;
      }
    }
    public void viewBlog(String contentKey) {
      List<Blog_Metric__c> blogMetric = new List<Blog_Metric__c>(
        [
          SELECT ViewCount__c
          FROM Blog_Metric__c
          WHERE Content_Key__c = :contentKey
          LIMIT 1
          FOR UPDATE
        ]
      );
      if (blogMetric.isEmpty()) {
        Blog_Metric__c newMetric = new Blog_Metric__c(
          Content_Key__c = contentKey,
          ViewCount__c = 1
        );
        insert newMetric;
      } else {
        blogMetric[0].ViewCount__c = blogMetric[0].ViewCount__c + 1;
        update blogMetric;
      }
    }
  }
}