public with sharing class RelatedRecordFeedController {

    @AuraEnabled(cacheable=true)
    public static CommentFeedController.CommentList getRelatedRecords(Id recordId, String childObjectType, String relationshipFieldName, String commentFieldName, String markAsReadFieldName, Boolean reverseFeed) {
        List<CommentFeedController.Comment> comments = new List<CommentFeedController.Comment>();
        Boolean hasUnread = false;
        try {
            String soqlStr = 'SELECT Id,' + commentFieldName + ', CreatedById, CreatedDate, CreatedBy.Name';
            if(markAsReadFieldName != null && markAsReadFieldName != '') {
                soqlStr += ',' + markAsReadFieldName;
            }
            soqlStr += ' FROM ' + childObjectType + ' WHERE ' + relationshipFieldName + ' = \'' + recordId + '\' ORDER BY CreatedDate ';
            soqlStr += reverseFeed ? 'DESC' : 'ASC';
            for(SObject s : Database.query(soqlStr)) {
                CommentFeedController.Comment c = new CommentFeedController.Comment();
                c.comment = (String) s.get(commentFieldName);
                c.userClass = (String) s.get('CreatedById') == UserInfo.getUserId() ? 'currentuser' : 'otheruser';
                c.createdByDate = (DateTime) s.get('CreatedDate');
                c.createdByName = s.getSobject('CreatedBy') != null ? (String) s.getSobject('CreatedBy').get('Name') : '';
                c.id = (String) s.get('Id');
                if(markAsReadFieldName != null && markAsReadFieldName != '') {
                    if((Boolean) s.get(markAsReadFieldName) == false) {
                        hasUnread = true;
                    }
                }
                comments.add(c);
            }
            return new CommentFeedController.CommentList(hasUnread, comments);

        } catch(Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage());return null; }
    }

    @AuraEnabled
    public static Boolean markAsRead(String recordString, String markAsReadFieldName) {
        // We use a without sharing class to alow guest users to mark comments as read if there is a requirement to do so
        NoSharing ns = new NoSharing();
        return ns.markAsRead(recordString, markAsReadFieldName);
    }

    public without sharing class NoSharing {
        public NoSharing() {}
        public Boolean markAsRead(String recordString, String markAsReadFieldName) {
            try {
                List<SObject> records = new List<SObject>();
                for(CommentFeedController.Comment c : (List<CommentFeedController.Comment>)JSON.deserialize(recordString, List<CommentFeedController.Comment>.class)) {
                    SObject sObj = c.id.getSObjectType().newSObject(c.id);
                    sObj.put('Id', c.id);
                    sObj.put(markAsReadFieldName, true);
                    records.add(sObj);
                }
                Database.update(records);
                return true;
            } catch(Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); return false; }
        }
    }

    @AuraEnabled
    public static Boolean createRecord(Id recordId, String childObjectType, String relationshipFieldName, String commentFieldName, String markAsReadFieldName, String newComment, Map<String, Object> presetFields) {
        try {
            SObject sObj = (SObject)Schema.getGlobalDescribe().get(addNamespacePrefix(childObjectType)).newSObject();
            sObj.put(relationshipFieldName, recordId);
            sObj.put(commentFieldName, newComment);
            if(markAsReadFieldName != null && markAsReadFieldName != '') {
                sObj.put(markAsReadFieldName, false);
            }
            if(presetFields != null) {
                for(String fieldName : presetFields.keySet()) {
                    sObj.put(fieldName, presetFields.get(fieldName));
                }
            }
            Database.insert(sObj);
            return true;
        } catch(Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); return false; }
    }

    @TestVisible
    private static String addNamespacePrefix(String customObjName) {
        Integer indexOfToken = -1;
        for(Schema.SObjectType type : Schema.getGlobalDescribe().values()) {
            String sObjName = String.valueOf(type);
            if(sObjName != null) {
                indexOfToken = sObjName.indexOf(customObjName);
                if(indexOfToken != -1) {
                    return sObjName;
                }
            }
        }
        return null; // no matching object found
    }
}