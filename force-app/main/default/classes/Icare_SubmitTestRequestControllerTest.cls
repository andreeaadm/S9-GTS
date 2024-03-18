@isTest
public with sharing class Icare_SubmitTestRequestControllerTest {
    @isTest static void testGetJobRequests() {
        Id favouriteRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get('Favourite_Job_Request').getRecordTypeId();
        Id draftRecTypeId = Schema.SObjectType.icare_Job_Request__c.getRecordTypeInfosByDeveloperName().get('iCare_Job_Request').getRecordTypeId();

        icare_Job_Request__c objFavouriteJobRequest = new icare_Job_Request__c();
        objFavouriteJobRequest.RecordTypeId = favouriteRecTypeId;

        insert objFavouriteJobRequest;

        icare_Job_Request__c objDraftJobRequest = new icare_Job_Request__c();
        objDraftJobRequest.RecordTypeId = draftRecTypeId;

        insert objDraftJobRequest;

        Icare_SubmitTestRequestController.getJobRequests();
        List<icare_Job_Request__c> jobRequestBeforeDelete = Icare_SubmitTestRequestController.getAllJobRequests('Favourite_Job_Request');
        Icare_SubmitTestRequestController.totalRecords('Favourite_Job_Request');
        Icare_SubmitTestRequestController.getJobRequestList(0,0,'Favourite_Job_Request');
        Icare_SubmitTestRequestController.getNext(0,0);
        Icare_SubmitTestRequestController.getPrevious(0,0);
        Icare_SubmitTestRequestController.deleteJobRequest(objFavouriteJobRequest.Id);
        List<icare_Job_Request__c> jobRequestAfterDelete = new List<icare_Job_Request__c> ();
        jobRequestAfterDelete = Icare_SubmitTestRequestController.getAllJobRequests('Favourite_Job_Request');

        System.assert(jobRequestAfterDelete.size() != jobRequestBeforeDelete.size());
        
    }
}