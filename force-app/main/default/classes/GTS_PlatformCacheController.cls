global with sharing class GTS_PlatformCacheController {
  @InvocableMethod(label='Upload Data to Platform Cache')
  public static void uploadToCache(List<GTS_PlatformCacheRequest> requests) {
    if (requests != null && requests.size() > 0) {
      for (GTS_PlatformCacheRequest request : requests) {
        Cache.OrgPartition orgPartition = Cache.Org.getPartition(
          request.cachePartitionName
        );
        orgPartition.put(request.key, request.value);
      }
    }
  }

  public static String getValueForKey(String key, String cachePartitionName) {
    Cache.OrgPartition orgPartition = Cache.Org.getPartition(
      cachePartitionName
    );
    String cachedValue = (String) orgPartition.get(key);
    orgPartition.remove(key);
    if (cachedValue != null) {
      return cachedValue;
    } else {
      return null;
    }
  }

  global class GTS_PlatformCacheRequest {
    @InvocableVariable(required=true)
    global String cachePartitionName;

    @InvocableVariable(required=true)
    global String key;

    @InvocableVariable(required=true)
    global String value;
  }
}