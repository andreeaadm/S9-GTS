@isTest(SeeAllData=true)
public with sharing class CMSController_Test {
  @isTest
  private static void test_1_1() {
    //ConnectApi.ManagedContentVersionCollection collection = ConnectApi.ManagedContent.getAllManagedContent([SELECT Id FROM Network LIMIT 1].Id, 0, 1, 'en_US', 'CTA');
    Test.startTest();

    //CMSController.getSingleItem(collection.items[0].contentKey, 'CTA');
    CMSController.getSingleItem('12345', 'CTA');

    Test.stopTest();
  }

  @isTest
  private static void test_2_1() {
    Test.startTest();

    //CMSController.getAllItemsForType('CTA', 250, 0, null, null);

    Test.stopTest();
  }

  @isTest
  private static void test_4_1() {
    //ConnectApi.ManagedContentVersionCollection collection = ConnectApi.ManagedContent.getAllManagedContent([SELECT Id FROM Network LIMIT 1].Id, 0, 1, 'en_US', 'Blog');
    Test.startTest();

    //CMSController.getBlogMetrics(collection.items[0].contentKey);
    CMSController.getBlogMetrics('12345');

    Test.stopTest();
  }

  @isTest
  private static void test_5_1() {
    //ConnectApi.ManagedContentVersionCollection collection = ConnectApi.ManagedContent.getAllManagedContent([SELECT Id FROM Network LIMIT 1].Id, 0, 1, 'en_US', 'Blog');
    Test.startTest();

    //CMSController.toggleLike(collection.items[0].contentKey, true);
    CMSController.toggleLike('12345', true);

    Test.stopTest();
  }

  @isTest
  private static void test_5_2() {
    //ConnectApi.ManagedContentVersionCollection collection = ConnectApi.ManagedContent.getAllManagedContent([SELECT Id FROM Network LIMIT 1].Id, 0, 1, 'en_US', 'Blog');
    Test.startTest();

    //CMSController.toggleLike(collection.items[0].contentKey, false);
    CMSController.toggleLike('12345', false);

    Test.stopTest();
  }

  @isTest
  private static void test_6_1() {
    //ConnectApi.ManagedContentVersionCollection collection = ConnectApi.ManagedContent.getAllManagedContent([SELECT Id FROM Network LIMIT 1].Id, 0, 1, 'en_US', 'Blog');
    Test.startTest();

    //CMSController.viewBlog(collection.items[0].contentKey);
    CMSController.viewBlog('12345');

    Test.stopTest();
  }

  @isTest
  private static void getAllItemsForType_withTopics() {
    Test.startTest();
    /*CMSController.AllItemsWrapper faqContent = CMSController.getAllItemsForType(
      'FAQ',
      250,
      0,
      new List<String>{ 'Topic 1' },
      null
    );*/
    Test.stopTest();
  }

  @isTest
  private static void allBlogMetrics() {
    Test.startTest();

    //CMSController.getBlogMetrics(collection.items[0].contentKey);
    //CMSController.toggleLike(collection.items[0].contentKey, true);
    //CMSController.viewBlog(collection.items[0].contentKey);

    CMSController.getBlogMetrics('12345');
    CMSController.toggleLike('12345', true);
    CMSController.toggleLike('12345', false);
    CMSController.toggleLike('12345', true);
    CMSController.viewBlog('12345');
    CMSController.getBlogMetrics('12345');

    Test.stopTest();
  }
}