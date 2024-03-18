@isTest
public inherited sharing class RelatedRecordFeedController_Test {

    @TestSetup static void createData() {
        Account a = new Account(Name='Test');
        insert a;
        Case c = new Case(AccountId=a.Id, Subject='Test');
        insert c;
        insert new CaseComment(CommentBody='Test', isPublished=true, ParentId=c.Id);
    }

    @isTest static void test_1_1() {
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        CommentFeedController.CommentList result;
        Test.startTest();
        result = RelatedRecordFeedController.getRelatedRecords(caseId, 'CaseComment', 'ParentId', 'CommentBody', null, false);
        Test.stopTest();
        System.assert(result.comments.size() == 1);
    }

    @isTest static void test_2_1() {
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        CommentFeedController.CommentList data = RelatedRecordFeedController.getRelatedRecords(caseId, 'CaseComment', 'ParentId', 'CommentBody', null, false);
        Boolean result;
        Test.startTest();
        CommentFeedController.Comment newComment = new CommentFeedController.Comment('Test', 'currentuser', DateTime.now(), 'Test Testerson', null);
        result = RelatedRecordFeedController.createRecord(caseId, RelatedRecordFeedController.addNamespacePrefix('CaseComment'), 'ParentId', 'CommentBody', null, JSON.serialize(newComment), new Map<String, Object>{'IsPublished' => true});
        Test.stopTest();
        // Assert createRecord returned a success boolean
        System.assert(result == true);
        // Assert 2 Case Comments now exist in the database (1 from createData() and 1 from this unit test)
        System.assert([SELECT Id FROM CaseComment].size() == 2);
    }

    @isTest static void test_3_1() {
        Id caseCommentId = [SELECT Id FROM CaseComment LIMIT 1].Id;
        Test.startTest();
        CommentFeedController.Comment c = new CommentFeedController.Comment('Test', 'currentuser', DateTime.now(), 'Test', caseCommentId);
        RelatedRecordFeedController.markAsRead(JSON.serialize(new List<CommentFeedController.Comment>{c}), 'IsPublished'); // using IsPublished on CaseComment to fake a "mark as read" field
        Test.stopTest();
    }

}