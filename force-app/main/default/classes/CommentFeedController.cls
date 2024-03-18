public with sharing class CommentFeedController {
    public class CommentList {
        @AuraEnabled
        public Boolean hasUnread;
        @AuraEnabled
        public List<CommentFeedController.Comment> comments;
        public CommentList(Boolean hasUnread, List<CommentFeedController.Comment> comments) {
            this.hasUnread = hasUnread != null ? hasUnread : false;
            this.comments = comments;
        }
    }

    public class Comment {
        @AuraEnabled
        public String comment;
        @AuraEnabled
        public String userClass;
        @AuraEnabled
        public DateTime createdByDate;
        @AuraEnabled
        public String createdByName;
        @AuraEnabled
        public Id id;
        public Comment() {}
        public Comment(String comment, String userClass, DateTime createdByDate, String createdByName, Id id) {
            this.comment = comment;
            this.userClass = userClass;
            this.createdByDate = createdByDate;
            this.createdByName = createdByName;
            this.id = id;
        }
    }
}