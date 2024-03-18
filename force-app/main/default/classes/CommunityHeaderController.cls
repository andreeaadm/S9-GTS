global with sharing class CommunityHeaderController {
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getNavIconsForConfig(String configDevName) {
    System.assert(configDevName != null && configDevName != '');
    Map<String, Object> returnMap = new Map<String, Object>();
    for (Community_Nav_Icon__mdt item : [
      SELECT
        Id,
        DeveloperName,
        Image_URL__c,
        Font_Awesome_Class__c,
        SVG_Component_Name__c,
        Navigation_Menu_Item_Label__c
      FROM Community_Nav_Icon__mdt
      WHERE Community_Nav_Icon_Configuration__r.DeveloperName = :configDevName
    ]) {
      returnMap.put(item.Navigation_Menu_Item_Label__c, item);
    }
    return returnMap;
  }

  /**
   * Perform two SOQL queries to determine all the children NavigationMenuItems
   * belonging to the provided menuName and publishedState. This example uses the
   * NavigationLinkSet.MasterLabel for the menuName. One could also use the
   * NavigationLinkSet.Id to ensure referential integrity if the MasterLabel changes.
   *
   * NavigationLinkSet contains both Draft and Live versions of the NavigationMenuItems.
   * Use the publishedState enumeration to filter between them.
   *
   * Cacheable = true allows this function to be wired.
   */
  @AuraEnabled(cacheable=true)
  public static List<NavigationMenuItem> getBuilderNavItems(
    String menuName,
    String publishedState
  ) {
    System.assert(menuName != null);
    System.assert(publishedState != null);
    List<NavigationMenuItem> returnData;

    String networkId = Network.getNetworkId();
    if (networkId == null && Test.isRunningTest()) {
      networkId = [SELECT Id FROM Network LIMIT 1].Id;
    }
    System.assert(networkId != null);

    String uniqueKey = networkId + menuName.deleteWhitespace() + publishedState;

    // find the link set belonging to the navigation menuName and active networkId
    List<NavigationLinkSet> linkSets = [
      SELECT Id
      FROM NavigationLinkSet
      WHERE MasterLabel = :menuName AND NetworkId = :networkId
    ];

    System.assert(linkSets.size() == 1);
    Id linkSetId = linkSets.get(0).Id;

    // collect all the menu items belonging to the link set
    // published state is either Draft or Live
    returnData = [
      SELECT
        Id,
        Label,
        Target,
        Type,
        DefaultListViewId,
        AccessRestriction,
        ParentId,
        Position,
        Status,
        TargetPrefs
      FROM NavigationMenuItem
      WHERE NavigationLinkSetId = :linkSetId AND Status = :publishedState
      ORDER BY Position
    ];

    return returnData;
  }
}