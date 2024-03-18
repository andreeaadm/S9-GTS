public with sharing class ICareFileUploadController {
  private static Map<String, String> RECORD_TYPE_MAPPING = new Map<String, String>{
    'GTS_Certificate_of_Conformity' => 'COC',
    'GTS_Registration_License_Product_Certificate' => 'REGISTRATION',
    'GTS_Commercial_Service' => 'TRADEABLE'
  };

  @AuraEnabled(cacheable=true)
  public static List<String> getFileFormats() {
    List<String> fileFormats = new List<String>();
    List<ICare_GTS_Doc_Format__mdt> gtsDocFormats = [
      SELECT Id, Label
      FROM ICare_GTS_Doc_Format__mdt
    ];

    if (gtsDocFormats.size() > 0) {
      for (ICare_GTS_Doc_Format__mdt docFormat : gtsDocFormats) {
        fileFormats.add(docFormat.Label);
      }
    }
    return fileFormats;
  }

  @AuraEnabled(cacheable=true)
  public static List<String> getDocumentTypes(String formName) {
    List<String> documentTypes = new List<String>();
    List<GTS_DocumentType__mdt> docTypes = [
      SELECT Id, Label, GTS_Form_Name__c
      FROM GTS_DocumentType__mdt
      WHERE GTS_Form_Name__c = :formName
    ];

    if (docTypes.size() > 0) {
      for (GTS_DocumentType__mdt docType : docTypes) {
        documentTypes.add(docType.Label);
      }
    }
    return documentTypes;
  }

  @AuraEnabled
  public static ContentVersion createContentVersion(
    String base64,
    String filename,
    String documentType
  ) {
    ContentVersion cv = new ContentVersion();
    cv.VersionData = EncodingUtil.base64Decode(base64);
    cv.Title = filename;
    cv.PathOnClient = filename;
    cv.GTS_Document_Type__c = documentType;
    try {
      insert cv;
      return cv;
    } catch (DMLException e) {
      System.debug(e);
      return null;
    }
  }

  @AuraEnabled
  public static List<ContentDocumentLink> createContentLink(
    List<String> contentVersionIds,
    String recordId
  ) {
    List<ContentDocumentLink> lstConDocLink = new List<ContentDocumentLink>();
    try {
      for (ContentVersion cv : [
        SELECT Id, ContentDocumentId
        FROM ContentVersion
        WHERE Id IN :contentVersionIds
      ]) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        lstConDocLink.add(cdl);
      }
      if (lstConDocLink.size() > 0) {
        insert lstConDocLink;
      }
    } catch (Exception e) {
      System.debug(e);
    }
    return lstConDocLink;
  }

  @AuraEnabled
  public static List<ContentVersion> getContentVersions(
    List<String> contentVersionIds
  ) {
    List<ContentVersion> lstConVer = new List<ContentVersion>();
    try {
      lstConVer = [
        SELECT Id, Title, GTS_Document_Type__c
        FROM ContentVersion
        WHERE Id IN :contentVersionIds
        WITH SECURITY_ENFORCED
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    return lstConVer;
  }

  @AuraEnabled(cacheable=true)
  public static String getFormVersionName(String jobRecordId) {
    String recordTypeDevName = '';
    try {
      iCare_Job__c jobRecord = [
        SELECT RecordTypeId
        FROM iCare_Job__c
        WHERE Id = :jobRecordId
        WITH SECURITY_ENFORCED
      ];
      recordTypeDevName = Schema.getGlobalDescribe()
        .get('iCare_Job__c')
        .getDescribe()
        .getRecordTypeInfosById()
        .get(jobRecord.RecordTypeId)
        .getDeveloperName();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    System.debug(RECORD_TYPE_MAPPING.get(recordTypeDevName));
    return RECORD_TYPE_MAPPING.get(recordTypeDevName);
  }
}