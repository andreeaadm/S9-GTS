/**
 * @author          Globant
 * @description     LWC Controller to handle the ContentDocuments
 * @date            08/March/2024
 */
public with sharing class GTSFileDownloadController {
  private static final String METADATA_NAME_FOR_CONTENT_URL = 'URL_Portal_ContentDownload';

  /**
   * @description Get Content Documents linked to recordId
   * @param recordId
   *
   * @return
   */
  @AuraEnabled(cacheable=true)
  public static String getRelatedFilesByRecordId(String recordId) {
    iCare_Portal__mdt contentUrlSetting = iCare_Portal__mdt.getAll()
      .get(METADATA_NAME_FOR_CONTENT_URL);

    List<ContentDocumentLink> contentDocumentLinks = [
      SELECT Id, ContentDocument.Id
      FROM ContentDocumentLink
      WHERE
        LinkedEntityId = :recordId
        AND ContentDocument.LatestPublishedVersion.GTS_Document_Super_Type__c != NULL
      WITH SECURITY_ENFORCED
      ORDER BY ContentDocument.ContentModifiedDate DESC
    ];

    List<Id> contentDocumentIds = new List<Id>();
    for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
      contentDocumentIds.add(contentDocumentLink.ContentDocument.Id);
    }
    List<FileWrapper> fileWrappersByType = new List<FileWrapper>();

    if (!contentDocumentIds.isEmpty()) {
      List<ContentDocument> contentDocuments = [
        SELECT
          Id,
          Title,
          ContentModifiedDate,
          LatestPublishedVersionId,
          LatestPublishedVersion.GTS_Document_Super_Type__c,
          LatestPublishedVersion.GTS_Document_Show_All_Behaviour__c,
          (
            SELECT Id, GTS_Document_Super_Type__c, LastModifiedDate
            FROM ContentVersions
            WHERE GTS_Document_Super_Type__c != NULL
            ORDER BY LastModifiedDate DESC
          )
        FROM ContentDocument
        WHERE Id IN :contentDocumentIds
        WITH SECURITY_ENFORCED
        ORDER BY ContentModifiedDate
      ];

      for (ContentDocument contentDocument : contentDocuments) {
        if (
          contentDocument.LatestPublishedVersion.GTS_Document_Show_All_Behaviour__c
        ) {
          for (
            ContentVersion contentVersion : contentDocument.ContentVersions
          ) {
            fileWrappersByType.add(
              new FileWrapper(
                contentVersion.Id,
                contentDocument.Title,
                contentVersion.GTS_Document_Super_Type__c,
                contentVersion.LastModifiedDate,
                contentVersion.Id,
                contentUrlSetting
              )
            );
          }
        } else {
          fileWrappersByType.add(
            new FileWrapper(
              contentDocument.LatestPublishedVersionId,
              contentDocument.Title,
              contentDocument.LatestPublishedVersion.GTS_Document_Super_Type__c,
              contentDocument.ContentModifiedDate,
              contentDocument.LatestPublishedVersionId,
              contentUrlSetting
            )
          );
        }
      }
    }

    return JSON.serialize(fileWrappersByType);
  }
  /**
   * @description Get Certificate content Document
   * @param recordId
   *
   * @return
   */
  @AuraEnabled
  public static String getCertificate(String recordId) {
    iCare_Portal__mdt contentUrlSetting = iCare_Portal__mdt.getAll()
      .get(METADATA_NAME_FOR_CONTENT_URL);

    ContentDocumentLink certificateFile = [
      SELECT
        Id,
        ContentDocument.Title,
        ContentDocument.ContentModifiedDate,
        ContentDocument.LatestPublishedVersionId,
        ContentDocument.LatestPublishedVersion.GTS_Document_Super_Type__c
      FROM ContentDocumentLink
      WHERE
        LinkedEntityId = :recordId
        AND ContentDocument.LatestPublishedVersion.GTS_Document_Super_Type__c = 'Certificate'
      WITH SECURITY_ENFORCED
      ORDER BY ContentDocument.ContentModifiedDate DESC
      LIMIT 1
    ];

    String response = '';

    if (certificateFile != null) {
      response =
        contentUrlSetting.Variable_Value__c +
        certificateFile.ContentDocument.LatestPublishedVersionId;
    }

    return JSON.serialize(response);
  }
  /**
   * @description Get the download link for Conga generated file
   * @param recordId
   *
   * @return
   */
  @AuraEnabled
  public static String getCongaDocumentDownloadLink(String recordId) {
    String result;
    String congaFileName = System.Label.GTS_Conga_File_Name + '%';
    // fetch newest pdf
    List<ContentDocumentLink> cdl = [
      SELECT ContentDocument.LatestPublishedVersionId
      FROM ContentDocumentLink
      WHERE
        LinkedEntityId = :recordId
        AND ContentDocument.FileExtension = 'pdf'
        AND ContentDocument.Title LIKE :congaFileName
      WITH SECURITY_ENFORCED
      ORDER BY ContentDocument.ContentModifiedDate DESC
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

  /**
   * @description Wrapper for Files
   */
  @TestVisible
  class FileWrapper {
    String Id;
    String name;
    String documentType;
    String uploadedDate;
    String link;
    /**
     * @description Controller for FileWrapper
     * @param id
     * @param name
     * @param documentType
     * @param uploadedDate
     * @param lastVersionId
     * @param contentUrlSetting
     */
    public FileWrapper(
      String id,
      String name,
      String documentType,
      Datetime uploadedDate,
      Id lastVersionId,
      iCare_Portal__mdt contentUrlSetting
    ) {
      this.id = id;
      this.name = name;
      this.documentType = documentType;
      this.uploadedDate = uploadedDate.format('dd/MM/yyyy, hh:mm a');
      this.link = contentUrlSetting.Variable_Value__c + lastVersionId;
    }
  }
}