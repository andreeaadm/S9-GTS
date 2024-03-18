public with sharing class iCare_ReportsTableController {
  @AuraEnabled(cacheable=true)
  public static String getReports() {
    List<iCare_Job__c> lstJobs = iCare_ReportsTableController.getJobs();

    List<ReportWrappers> reportWrappers = new List<iCare_ReportsTableController.ReportWrappers>();
    for (iCare_Job__c job : lstJobs) {
      if (job.Job_Timestamps__r != null && job.Job_Timestamps__r.size() == 1) {
        reportWrappers.add(new ReportWrappers(job));
      }
    }

    return JSON.serialize(reportWrappers);
  }

  private static List<iCare_Job__c> getJobs() {
    List<String> filterStatuses = new List<String>{
      'Test Report Issued',
      'Cancelled'
    };

    return [
      SELECT
        Id,
        iCare_Job_ID__c,
        iCare_Job_Hyperlink__c,
        iCare_Buyer_Program_formula__c,
        iCare_Job_Status__c,
        toLabel(iCare_Job_Outcome__c) iCare_Job_Outcome__c,
        iCare_ETRF__r.iCare_SupplierLab__r.Name,
        iCare_Document_URL__c,
        iCare_Model_Style_Number__c,
        iCare_Agency_Name__c,
        iCare_Order_Number__c,
        iCare_Applicant_Contact_Person_Name__c,
        iCare_Product_Type__c,
        iCare_Sample_Description__c,
        (
          SELECT Id, iCare_Job_Timestamp__c
          FROM Job_Timestamps__r
          WHERE iCare_Job_Status__c = 'Test Report Issued'
          ORDER BY iCare_Job_Timestamp__c
          LIMIT 1
        )
      FROM iCare_Job__c
      WHERE iCare_Job_Status__c IN :filterStatuses
    ];
  }

  public class ReportWrappers {
    private String id;
    private String reportNumber;
    private String reportNumberLink;
    private String reportResult;
    private Datetime reportIssuedDate;
    private String buyer;
    private String intertekSite;
    private String detailsLink;
    private String reportLink;
    private String jobStatus;
    private String formatedDate;
    private String modelStyleNumber;
    private String agencyName;
    private String orderNumber;
    private String applicantContactPersonName;
    private String productType;
    private String sampleDescription;

    public ReportWrappers(iCare_Job__c job) {
      this.id = job.Id;
      this.reportNumber = job.iCare_Job_ID__c;
      this.reportNumberLink = job.iCare_Job_Hyperlink__c.substring(
        job.iCare_Job_Hyperlink__c.indexOf('href') + 6,
        job.iCare_Job_Hyperlink__c.indexOf('target') - 2
      );
      this.reportResult = job.iCare_Job_Outcome__c;
      this.reportIssuedDate = job.Job_Timestamps__r.get(0)
        .iCare_Job_Timestamp__c;
      this.formatedDate = job.Job_Timestamps__r.get(0)
        .iCare_Job_Timestamp__c.format('yyyy-MM-dd');
      this.buyer = job.iCare_Buyer_Program_formula__c;
      this.intertekSite = (String.isNotBlank(
          job.iCare_ETRF__r.iCare_SupplierLab__r.Name
        ))
        ? job.iCare_ETRF__r.iCare_SupplierLab__r.Name
        : '';
      this.detailsLink = job.iCare_Document_URL__c;
      this.reportLink = job.iCare_Document_URL__c;
      this.jobStatus = job.iCare_Job_Status__c;
      this.modelStyleNumber = job.iCare_Model_Style_Number__c;
      this.agencyName = job.iCare_Agency_Name__c;
      this.orderNumber = job.iCare_Order_Number__c;
      this.applicantContactPersonName = job.iCare_Applicant_Contact_Person_Name__c;
      this.productType = job.iCare_Product_Type__c;
      this.sampleDescription = job.iCare_Sample_Description__c;
    }
    public ReportWrappers() {
    }
  }
}