public with sharing class GTS_JobRequestWrapper {
  public JobRequestHeader jobRequestHeader;
  public JobDetails jobDetails;

  public class Address {
    public String city;
    public String countryCode;
    public String postalCode;
    public String stateCode;
    public String street;
  }

  public class Account {
    public String opsSystemAccountNumber;
    public String opsSystem;
    public String opsSystemAccountType;
    public String accountName;
    public Address address;
  }

  public class CompanyInformation {
    public String companyName;
    public Account account;
    public Contact contact;
    public String taxNumber;
    public String taxOffice;
    public Address address;
    public String purchaseOrderNumber;
    public String goodsAvailableDate;
    public String proposedInspectionDate;
    public String shipmentMode;
    public String shipmentType;
    public Integer numberOfFCL;
  }

  public class Contact {
    public String contactOpsSystemId;
    public String opsSystem;
    public String contactFirstName;
    public String contactLastName;
    public String contactEmail;
    public String contactFax;
    public String contactPhone;
  }

  public class JobDetails {
    public String previousReportNumber;
    public String formCompletionDate;
  }

  public class JobRequestHeader {
    /**
         * "enum": [
            "CertificateOfCompliance",
            "Tradeable",
            "RegistrationAndLicense"
          ]
         */
    public String rfcType;
    public String jobRequestRecordId;
    public String exporterReference;
    public CompanyInformation exporter;
    public CompanyInformation importer;
    public CompanyInformation inspectionLocation;
    public CompanyInformation payer;
    public Programme shipmentCertificateProgramme;
  }

  public class Programme {
    public String programmeName;
    public String programmeId;
    public String programmeCode;
    public String country;
  }

  public class SalesForceUser {
    public String email;
  }
}