public with sharing class GTS_ContentVersion_TriggerHandler implements ICare_ContentVersion_Interface {
  public void afterInsert(List<ContentVersion> contentVersionList) {
    GTS_ContentDocumentLink contentDocumentLinkGTS = new GTS_ContentDocumentLink(
      contentVersionList
    );
    contentDocumentLinkGTS.setDocumentsByJob();
  }
}