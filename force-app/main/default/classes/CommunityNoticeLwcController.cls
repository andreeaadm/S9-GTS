/***
* Author: Kamlesh.kahar@intertek.com
* Created on: 27-07-2023
* Test Class: CommunityNoticeLwcControllerTest
* History:
    27-07-2023  kamlesh.kahar   Created.
***/

public with sharing class CommunityNoticeLwcController {

    @AuraEnabled(cacheable=true)
    public static List<SObject> getCommunityNotices(String communityName){
        System.debug('communityName: '+communityName);
        List<Community_Notice__mdt> noticeToShow = new List<Community_Notice__mdt>();
        List<Community_Notice__mdt> communityNotices = new List<Community_Notice__mdt>();
        if(Test.isRunningTest()){
            //Since we can't insert the test data for metadata types, assign Test data for unit testing here
            communityNotices.add(new Community_Notice__mdt(Start_Date__c = System.today(), End_Date__c = System.today().addDays(7),
                                    Active__c = true, Message__c = 'Test 1'));  
            communityNotices.add(new Community_Notice__mdt(Active__c = true, Message__c = 'Test 2'));  
        }else{
            communityNotices = [SELECT Message__c, Start_Date__c, End_Date__c, Label, DeveloperName
                                FROM Community_Notice__mdt
                                WHERE Active__c = TRUE
                                AND Community_Name__c = :communityName];
        }

        for(Community_Notice__mdt notice :communityNotices){
            if(notice.Start_Date__c != null && notice.End_Date__c != null){
                if(notice.Start_Date__c <= System.today() && notice.End_Date__c >= System.today()){
                    noticeToShow.add(notice);   //Consider only if the notice is not expired yet.
                }
            }else{
                noticeToShow.add(notice);   //Consider this when there is no start/end date on the notice.
            }
        }
        return noticeToShow;
    }
}