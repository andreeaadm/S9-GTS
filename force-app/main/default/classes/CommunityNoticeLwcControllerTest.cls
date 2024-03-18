@isTest
public with sharing class CommunityNoticeLwcControllerTest {
    @isTest
    public static void testCommunityNotice(){
        System.assertEquals(CommunityNoticeLwcController.getCommunityNotices('MTC').size(), 2, 'There should be 2 notices returned!');
    }
}