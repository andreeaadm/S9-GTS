@isTest
public inherited sharing class CommentFeedController_Test {
    // Construct a CommentList with comments
    @isTest private static void Test_1_1() {
        Test.startTest();
        List<CommentFeedController.Comment> comments = new List<CommentFeedController.Comment>();
        CommentFeedController.Comment c = new CommentFeedController.Comment('Test', 'currentuser', DateTime.now(), 'Test', null);
        comments.add(c);
        CommentFeedController.CommentList commentsList = new CommentFeedController.CommentList(true, comments);
        Test.stopTest();
        System.assert(commentsList.comments.size() > 0);
    }
}