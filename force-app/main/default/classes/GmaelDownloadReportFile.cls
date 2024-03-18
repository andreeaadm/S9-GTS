public with sharing class GmaelDownloadReportFile {
  @AuraEnabled
  public static String getDownloadLink(String recordId) {
    GMAEL_Report__c report = [
      SELECT Id, Name, GMAEL_Report_Status__c, GMAEL_Generate_Report_File__c
      FROM GMAEL_Report__c
      WHERE Id = :recordId
    ];
    String reportTitle;

    if (report.GMAEL_Report_Status__c == 'Approved') {
      reportTitle = 'Report Name ' + report.Name + '.docx';
    } else {
      reportTitle = 'Report Name ' + report.Name + ' Draft.docx';
      if (report.GMAEL_Generate_Report_File__c == false) {
        deleteExistingDraftFiles(recordId, reportTitle);
      }
    }

    if (report.GMAEL_Generate_Report_File__c == false) {
      update new GMAEL_Report__c(
        Id = recordId,
        GMAEL_Generate_Report_File__c = true
      );
    }

    List<ContentDocumentLink> cdl = [
      SELECT ContentDocument.Id
      FROM ContentDocumentLink
      WHERE
        LinkedEntityId = :recordId
        AND ContentDocument.FileExtension = 'docx'
        AND ContentDocument.Title = :reportTitle
      ORDER BY ContentDocument.CreatedDate DESC
    ];

    if (!cdl.isEmpty()) {
      return cdl[0].ContentDocument.Id;
    } else {
      return null;
    }
  }

  private static void deleteExistingDraftFiles(
    String recordId,
    String reportTitle
  ) {
    List<ContentDocumentLink> cdl = [
      SELECT ContentDocument.Id
      FROM ContentDocumentLink
      WHERE
        LinkedEntityId = :recordId
        AND ContentDocument.FileExtension = 'docx'
        AND ContentDocument.Title = :reportTitle
      ORDER BY ContentDocument.CreatedDate DESC
    ];

    if (!cdl.isEmpty()) {
      List<Id> contentDocumentsIds = new List<Id>();
      for (ContentDocumentLink contentDocumentLink : cdl) {
        contentDocumentsIds.add(contentDocumentLink.ContentDocumentId);
      }
      delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentsIds];
    }
  }

  @AuraEnabled
  public static void resetGenerateReportFileValue(String recordId) {
    GMAEL_Report__c report = [
      SELECT Id, Name, GMAEL_Generate_Report_File__c
      FROM GMAEL_Report__c
      WHERE Id = :recordId
    ];

    if (report.GMAEL_Generate_Report_File__c == true) {
      update new GMAEL_Report__c(
        Id = recordId,
        GMAEL_Generate_Report_File__c = false
      );
    }
  }
}