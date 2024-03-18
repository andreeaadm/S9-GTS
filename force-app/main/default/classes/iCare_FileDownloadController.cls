/*
* ________________________________________________________________________________________________
* Controller class for File Download LWC component of iCare Portal
* Component to get the Job associated files
* ________________________________________________________________________________________________
* @author       Andres Morales
* @created      2023-05-01
* ________________________________________________________________________________________________
* @changes

* ________________________________________________________________________________________________
*/
public without sharing class iCare_FileDownloadController {
  private static final String METADATA_NAME_FOR_CONTENT_URL = 'URL_Portal_ContentDownload';

  @AuraEnabled(cacheable=true)
  public static Map<String, String> getRelatedFilesByRecordId(String recordId) {
    iCare_Portal__mdt contentUrlSetting = iCare_Portal__mdt.getAll()
      .get(METADATA_NAME_FOR_CONTENT_URL);

    // Get record file Names and IDs
    List<ContentDocumentLink> files = [
      SELECT ContentDocument.Title, ContentDocument.LatestPublishedVersionId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :recordId AND ContentDocument.FileExtension = 'pdf'
    ];
    List<Id> fileIds = new List<Id>();
    for (ContentDocumentLink docLink : files) {
      fileIds.add(docLink.ContentDocumentId);
    }

    Map<String, String> mapIdTitle = new Map<String, String>();

    for (ContentDocumentLink cdLink : files) {
      mapIdTitle.put(
        cdLink.ContentDocument.Title,
        contentUrlSetting.Variable_Value__c +
        cdLink.ContentDocument.LatestPublishedVersionId
      );
    }

    return mapIdTitle;
  }

  @AuraEnabled
  public static String getSingleDownloadLink(String recordId) {
    String result;
    // fetch newest pdf
    List<ContentDocumentLink> cdl = [
      SELECT ContentDocument.LatestPublishedVersionId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :recordId AND ContentDocument.FileExtension = 'pdf'
      ORDER BY ContentDocument.CreatedDate DESC
    ];
    iCare_Portal__mdt contentUrlSetting = iCare_Portal__mdt.getAll()
      .get(METADATA_NAME_FOR_CONTENT_URL);

    if (cdl.size() != 0) {
      result =
        contentUrlSetting.Variable_Value__c +
        cdl[0].ContentDocument.LatestPublishedVersionId;
      return result;
    } else {
      return null;
    }
  }
}