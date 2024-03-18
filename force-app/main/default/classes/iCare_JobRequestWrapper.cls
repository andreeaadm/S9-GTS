/*******************************************************************************************
 * @Name         iCare_JobRequestWrapper
 * @Test Class :  iCare_JobTriggerHandlerTest
 * @Author       Praveen Kumar R
 * @Description  This acts as the wrapper class to job request API call (iCare_JobQueuable).
 *******************************************************************************************/
public class iCare_JobRequestWrapper {
  public class BuyerProgramme {
    public String buyerAccountName;
    public String intertekBuyerId;
  }

  public class Account {
    public String accountId;
    public String accountName;
    public String opsSystemAccountNumber;
    public String opsSystem;
    public Address address;
    public Contact contact;
    public String nirvanaUniqueId;
    public String accountNumber;
  }

  public class TestsRequired {
    public Boolean fullTestUpToTheStandard;
    public String dimensionalStability;
    public Integer dimensionalStabilityNumberOfWashes;
    public String appearance;
    public Integer appearanceNumberOfWashes;
    public Boolean printDurability;
    public Integer printDurabilityNumberOfWashes;
    public Boolean spirality;
    public Integer spiralityNumberOfWashes;
    public String colourfastness;
    public String physical;
    public String heavyMetals;
    public String chemical;
    public String lightGrade;
    public Integer abrasionCycles;
    public Integer pillingASTMISOCycleHours;
    public Integer pillingICIISOCycleHours;
    public Integer pillingMartindaleISOCycleHours;
    public String otherOrganicTinComposition;
    public String shrinkage;
    public String footwear;
    public Integer afterDryCleaningNoOfWashes;
    public Integer afterWashingNoWashes;
    public Integer dryCleaningNoOfWashes;
    public Integer steamingNoOfWashes;
    public String typeOfPrint;
    public String typeOfFinish;
    public String standardSelection;
  }

  public class Products {
    public String orderNumber;
    public String season;
    public Integer numberOfSamples;
    public List<Samples> samples;
    public List<CareLabels> careLabels;
    public String additionalCareLabels;
    public Boolean careLabelControl;
    public String careLabelCountry;
    public String otherStatement;
    public String commentOnTestResult;
    public Boolean careLabelRecommend;
    public String careLabelDisplayMode;
  }

  public class Agency {
    public String agencyName;
    public String contactName;
    public String email;
    public String fax;
    public String telephone;
  }

  public JobRequestHeader jobRequestHeader;
  public JobDetails jobDetails;

  public class Address {
    public String countryCode;
    public String stateCode;
    public String city;
    public String street;
    public String postalCode;
  }

  public class JobRequestHeader {
    public String etrfNumber;
    public String formVersion;
    public String jobNumber;
    public String jobDescription;
    public TestingLocation testingLocation;
    public Agency agency;
    public BuyerProgramme buyerProgramme;
    public String buyerName;
    public String buyerRegion;
    public String otherBuyerRegion;
    public String serviceTerm;
    public String serviceTermRemarks;
    public ApplicantInformation applicantInformation;
    public ApplicantInformation invoicingInformation;
  }

  public class CareLabels {
    public String careLabelId;
    public String careLabelStandardCode;
    public String countryCode;
    public String category;
    public String subCategory;
    public String pictogram;
    public String statementCode;
    public String localisedStatementText;
  }

  public class ApplicantInformation {
    public Account account;
    public String email;
    public String telephone;
    public String taxNumber;
    public String taxOffice;
    public Address address;
    public String contactPersonName;
    public String fax;
  }

  public class TestingLocation {
    public String locationCode;
    public String locationName;
    public String systemInstance;
  }

  public class JobDetails {
    public String formCompletionDate;
    public String previousReportNumber;
    public List<Products> products;
    public TestsRequired testsRequired;
    public String testPackagesRequired;
    public String otherTestPackages;
    public String otherTests;
    public String specialRequests;
    public Boolean specimenReturnRequest;
  }

  public class Contact {
    public String contactPhone;
    public String contactFullName;
    public String contactEmail;
  }

  public class Samples {
    public String colour;
    public String modelNumber;
    public String sampleDescription;
    public String endUse;
    public String endUseOther;
    public String endUseChildAge;
    public String productType;
    public String otherProductType;
    public String fabricWeight;
    public String fabricUnits;
    public String fibreComposition;
    public String manufacturerName;
  }
}