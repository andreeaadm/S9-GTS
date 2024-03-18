/*
 * Test data factory for Chemical_Product__c objects
 */
@IsTest
public with sharing class TC_TestDataFactory_Chemicals {
  /*
   * Returns a list of chemical products with random names and Last_Verified_Date__c = now
   *
   * If isActive = true: product status = Active, random GUID, Origin__c = Supplier, MRSL = Level 2, ZDHC status = Success
   * If isActive = false: product status = Deactivated, ZDHC status = Error
   */
  public static List<Chemical_Product__c> create(
    Boolean isActive,
    Integer count
  ) {
    return create(
      isActive ? 'Active' : 'Deactivated',
      'Level 2',
      'Supplier',
      Datetime.now(),
      null,
      count
    );
  }

  /*
   * Returns a list of chemical products with random names and GUIDs and other fields specified
   */
  public static List<Chemical_Product__c> create(
    String prodStatus,
    String mrsl,
    String origin,
    Datetime verifiedDate,
    Id formulatorId,
    Integer count
  ) {
    List<Chemical_Product__c> toReturn = new List<Chemical_Product__c>();

    for (Integer i = 0; i < count; i++) {
      if (prodStatus == 'Pending') {
        toReturn.add(
          create(
            TC_TestDataFactory.randomWord(10) + i,
            prodStatus,
            null,
            null,
            null,
            null,
            null,
            formulatorId
          )
        );
      } else {
        toReturn.add(
          create(
            TC_TestDataFactory.randomWord(10) + i,
            prodStatus,
            prodStatus == 'Active'
              ? String.valueOf(TC_TestDataFactory.random(10, 20))
              : null,
            mrsl,
            origin,
            prodStatus == 'Active' ? 'Success' : 'Error',
            verifiedDate,
            formulatorId
          )
        );
      }
    }

    return toReturn;
  }

  /*
   * Returns a single chemical product with specified values for fields
   */
  public static Chemical_Product__c create(
    String name,
    String prodStatus,
    String guid,
    String mrsl,
    String origin,
    String zdhcStatus,
    Datetime verifiedDate,
    Id formulatorId
  ) {
    Chemical_Product__c chem = new Chemical_Product__c(
      Chemical_Product_Name__c = name,
      Product_Status__c = prodStatus,
      ZDHC_Product_GUID__c = guid,
      ZDHC_MRSL_v2_0__c = mrsl,
      Origin__c = origin,
      ZDHC_Status__c = zdhcStatus,
      Last_Verified_Date__c = verifiedDate,
      Formulator__c = formulatorId
    );

    return chem;
  }

  /*
   * Inserts a list of formulators for a specified facility, each with a list of chemical product records
   * Returns the list of chemical products
   */
  public static List<Chemical_Product__c> createInsertedWithFormulators(
    Id facilityId,
    Integer formulatorCount,
    Integer activeProductCount,
    Integer inactiveProductCount,
    Integer pendingProductCount
  ) {
    List<Formulator__c> formulators = TC_TestDataFactory_Formulators.create(
      facilityId,
      formulatorCount
    );
    insert formulators;

    Date today = Date.today();
    Datetime verificationTime = Datetime.newInstance(
      today.addDays(-1),
      Time.newInstance(0, 0, 0, 0)
    );

    List<Chemical_Product__c> chemList = new List<Chemical_Product__c>();
    for (Formulator__c f : formulators) {
      chemList.addAll(
        create(
          'Active',
          'Level 2',
          'Supplier',
          verificationTime,
          f.Id,
          activeProductCount
        )
      );
      chemList.addAll(
        create(
          'Deactivated',
          'Level 2',
          'Supplier',
          verificationTime,
          f.Id,
          inactiveProductCount
        )
      );
      chemList.addAll(
        create('Pending', null, null, null, f.Id, pendingProductCount)
      );
    }
    insert chemList;

    return chemList;
  }

  public List<Chemical_Product__c> products;

  /**
   * productUpdates Simulate changes to chemical products over time.
   * @param accountId (Id): Restrict products to any created by this facility.
   * @param zdhcMRSLv2 (List<String>): A pattern to use when updating all the conformances.
   * @return List<Chemical_Product__c>: all the chewmical products
   */
  public List<Chemical_Product__c> productUpdates(
    Id accountId,
    List<String> zdhcMRSLv2
  ) {
    List<Chemical_Product__c> selection = new List<Chemical_Product__c>();
    for (Integer i = 0; i < products.size(); i++) {
      if (products[i].Formulator__r.Created_By__c == accountId) {
        products[i].ZDHC_MRSL_v2_0__c = zdhcMRSLv2[
          Math.mod(i, zdhcMRSLv2.size())
        ];
        selection.add(products[i]);
      }
    }
    update selection;
    return selection;
  }

  public TC_TestDataFactory_Chemicals() {
    products = [
      SELECT
        Category__c,
        Certified_Date__c,
        Chemical_Product_Name__c,
        Conformant__c,
        CreatedById,
        CreatedDate,
        CurrencyIsoCode,
        Expiry_Date__c,
        Formulator_Country__c,
        Formulator__c,
        Id,
        Intertek_Certification_No__c,
        Intertek_Certified_Result__c,
        IsDeleted,
        LastActivityDate,
        LastModifiedById,
        LastModifiedDate,
        LastReferencedDate,
        LastViewedDate,
        Last_Verified_Date__c,
        Name,
        Origin__c,
        Other_Certifications__c,
        OwnerId,
        Product_Status__c,
        Product_Trade_Name_Other_Name__c,
        Registered__c,
        Substrate__c,
        SystemModstamp,
        Test_Report_No__c,
        Testing_Laboratory__c,
        Type__c,
        ZDHC_Certification_JSON__c,
        ZDHC_Description__c,
        ZDHC_Formulator_GUID__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_PID__c,
        ZDHC_Product_Code__c,
        ZDHC_Product_GUID__c,
        ZDHC_Product_Id__c,
        ZDHC_Status__c,
        Formulator__r.Created_By__c
      FROM Chemical_Product__c
      ORDER BY Id ASC
      LIMIT 1000
    ];
  }

  public TC_TestDataFactory_Chemicals(Account facility) {
    products = [
      SELECT
        Category__c,
        Certified_Date__c,
        Chemical_Product_Name__c,
        Conformant__c,
        CreatedById,
        CreatedDate,
        CurrencyIsoCode,
        Expiry_Date__c,
        Formulator_Country__c,
        Formulator__c,
        Id,
        Intertek_Certification_No__c,
        Intertek_Certified_Result__c,
        IsDeleted,
        LastActivityDate,
        LastModifiedById,
        LastModifiedDate,
        LastReferencedDate,
        LastViewedDate,
        Last_Verified_Date__c,
        Name,
        Origin__c,
        Other_Certifications__c,
        OwnerId,
        Product_Status__c,
        Product_Trade_Name_Other_Name__c,
        Registered__c,
        Substrate__c,
        SystemModstamp,
        Test_Report_No__c,
        Testing_Laboratory__c,
        Type__c,
        ZDHC_Certification_JSON__c,
        ZDHC_Description__c,
        ZDHC_Formulator_GUID__c,
        ZDHC_MRSL_v2_0__c,
        ZDHC_PID__c,
        ZDHC_Product_Code__c,
        ZDHC_Product_GUID__c,
        ZDHC_Product_Id__c,
        ZDHC_Status__c,
        Formulator__r.Created_By__c
      FROM Chemical_Product__c
      WHERE Formulator__r.Created_By__c = :facility.Id
    ];
  }

  public TC_TestDataFactory_Chemicals(
    TC_TestDataFactory_Formulators tdff,
    Integer count
  ) {
    Map<String, Formulator__c> formulator = new Map<String, Formulator__c>();
    for (Formulator__c f : tdff.formulators) {
      formulator.put(f.ZDHC_Formulator_GUID__c, f);
    }
    // prettier-ignore
    List<Chemical_Product__c> all = new List<Chemical_Product__c> {
      new Chemical_Product__c(Formulator__c=formulator.get('00000000000000000000000000000000').Id,ZDHC_Formulator_GUID__c='00000000000000000000000000000000',Chemical_Product_Name__c='0 4 one one',ZDHC_Product_GUID__c='11111111000000000000000000000000'),
      new Chemical_Product__c(Formulator__c=formulator.get('D77D2CB25ABB5BABE0530100007F44A5').Id,ZDHC_Formulator_GUID__c='D77D2CB25ABB5BABE0530100007F44A5',Chemical_Product_Name__c='A test product 567123',ZDHC_Product_GUID__c='D77D2CB25ABE5BABE0530100007F44A5',ZDHC_Product_Id__c='190290',ZDHC_PID__c='P650EK25',Registered__c='Intertek',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2022-02-08T06:55:12Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9281631729E67F0CE0530100007FFD4B').Id,ZDHC_Formulator_GUID__c='9281631729E67F0CE0530100007FFD4B',Chemical_Product_Name__c='ACETIC ACID',ZDHC_Product_GUID__c='930697241BD24032E0530100007F7E1A',ZDHC_Product_Id__c='120250',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='ACETONE',ZDHC_Product_GUID__c='517D678FBE2256F5E0530100007F7511',ZDHC_Product_Id__c='38432',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('6F731E04E38F6BFBE0530100007F90C8').Id,ZDHC_Formulator_GUID__c='6F731E04E38F6BFBE0530100007F90C8',Chemical_Product_Name__c='ACRO conc',ZDHC_Product_GUID__c='8C0A267891C474F8E0530100007FF04F',ZDHC_Product_Id__c='98927',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('9010B9336CB85B14E0530100007FA3D9').Id,ZDHC_Formulator_GUID__c='9010B9336CB85B14E0530100007FA3D9',Chemical_Product_Name__c='ACTIVE ARMY BLUE FW-B H/C',ZDHC_Product_GUID__c='901DE67BE2E91820E0530100007F194F',ZDHC_Product_Id__c='108548',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOBOND 8585',ZDHC_Product_GUID__c='B8EC9F31520C1F35E0530100007FE899',ZDHC_Product_Id__c='186407',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P359DS61',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T06:42:56Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOFAT CD',ZDHC_Product_GUID__c='B8C84B4343673709E0530100007F6BC5',ZDHC_Product_Id__c='186276',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P571LI41',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T08:25:10Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOFAT LW',ZDHC_Product_GUID__c='B8C89432B58F5091E0530100007F3A28',ZDHC_Product_Id__c='186278',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P258XL54',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T05:54:50Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOFAT SF 3',ZDHC_Product_GUID__c='B8C8CE44C936658EE0530100007F5172',ZDHC_Product_Id__c='186279',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P496SN43',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T07:49:28Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOLIP LAF',ZDHC_Product_GUID__c='B8C97533C60D1BA5E0530100007F4534',ZDHC_Product_Id__c='186283',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P522IH34',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T08:01:21Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOPLEX RV',ZDHC_Product_GUID__c='A10CCFD137A31C43E0530100007FDC9A',ZDHC_Product_Id__c='150844',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P432OX37',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T07:18:27Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOPUR 96 BM',ZDHC_Product_GUID__c='B8D85A6F2DAE749EE0530100007FC785',ZDHC_Product_Id__c='186308',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P232PI79',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T05:05:11Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN ACR-ECO',ZDHC_Product_GUID__c='A570B5108EBB6C00E0530100007F430D',ZDHC_Product_Id__c='153786',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P436RK35',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T07:20:25Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN B57 LIQ',ZDHC_Product_GUID__c='B8DA5825B3732393E0530100007FE2C3',ZDHC_Product_Id__c='186314',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P759QH37',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T09:55:27Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN BIO-P2F',ZDHC_Product_GUID__c='B8DADB9D092A4FE8E0530100007F195B',ZDHC_Product_Id__c='186317',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P470QC25',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T07:37:22Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN DX',ZDHC_Product_GUID__c='B8DC83BAF4CC5C20E0530100007FCBAC',ZDHC_Product_Id__c='186326',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P590YK27',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T08:35:20Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN HB 01',ZDHC_Product_GUID__c='B8DCCBB675F87524E0530100007F84F7',ZDHC_Product_Id__c='186332',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P443BH72',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T07:23:19Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN LT',ZDHC_Product_GUID__c='B8EC791A928913F6E0530100007F49C6',ZDHC_Product_Id__c='186405',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P992CR20',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T11:47:17Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN N D C',ZDHC_Product_GUID__c='B8DDB5394E754479E0530100007FF3F0',ZDHC_Product_Id__c='186344',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P307DN24',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T06:19:01Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN P 165',ZDHC_Product_GUID__c='B8EB8BDC5C613FD2E0530100007FEC9B',ZDHC_Product_Id__c='186390',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P694EO53',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T09:24:31Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN PF10',ZDHC_Product_GUID__c='B8D896F098B30C47E0530100007F73D3',ZDHC_Product_Id__c='186310',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P436GA85',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T07:20:17Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN RCL',ZDHC_Product_GUID__c='B8EBD9CCCBC15B02E0530100007F73AA',ZDHC_Product_Id__c='186397',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P827MB54',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T10:27:10Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN SND LIQUID',ZDHC_Product_GUID__c='A10E36104802476EE0530100007F506C',ZDHC_Product_Id__c='150851',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P521EE12',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T08:00:38Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOTAN UHT',ZDHC_Product_GUID__c='A132DCCFDBD5605CE0530100007FA47E',ZDHC_Product_Id__c='151022',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P815FE88',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T10:21:41Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOWET A 86',ZDHC_Product_GUID__c='A1330FBBA2B8727DE0530100007F7E25',ZDHC_Product_Id__c='151023',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P741OP97',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T09:47:10Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOWET KC',ZDHC_Product_GUID__c='A133C80DB98B4B45E0530100007F4BAD',ZDHC_Product_Id__c='151029',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P981JE19',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T11:42:14Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCOWET VC 30',ZDHC_Product_GUID__c='A13453A5F3D70A4CE0530100007F3955',ZDHC_Product_Id__c='151033',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P394IF14',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T07:00:20Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='ALCROM CNE',ZDHC_Product_GUID__c='B8EC4C6C0AF87FD0E0530100007F5370',ZDHC_Product_Id__c='186402',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P349NM89',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T06:38:34Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7E0DA640555F1B6FE0530100007F5348').Id,ZDHC_Formulator_GUID__c='7E0DA640555F1B6FE0530100007F5348',Chemical_Product_Name__c='AMINO SILICON SOFTENER',ZDHC_Product_GUID__c='7E0DC98CBDFF37CBE0530100007F31BA',ZDHC_Product_Id__c='78546',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('B1142E0F542A5467E0530100007FEB0A').Id,ZDHC_Formulator_GUID__c='B1142E0F542A5467E0530100007FEB0A',Chemical_Product_Name__c='Ammonium sulfate',ZDHC_Product_GUID__c='B84E4914C83F5DC7E0530100007F3C14',ZDHC_Product_Id__c='185231',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-01-07T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('6F731E04E38F6BFBE0530100007F90C8').Id,ZDHC_Formulator_GUID__c='6F731E04E38F6BFBE0530100007F90C8',Chemical_Product_Name__c='ARCHOSOFT WF',ZDHC_Product_GUID__c='76E616273E911F6EE0530100007FAF9B',ZDHC_Product_Id__c='56683',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='ATB NLT / 60',ZDHC_Product_GUID__c='9338F216F1CE50B6E0530100007F581B',ZDHC_Product_Id__c='121415',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-23T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='ATB NLT/B',ZDHC_Product_GUID__c='9416B6E052E36D76E0530100007F4122',ZDHC_Product_Id__c='126461',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-10-04T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5A01F02025207C05E0530100007F79BD').Id,ZDHC_Formulator_GUID__c='5A01F02025207C05E0530100007F79BD',Chemical_Product_Name__c='AVOL PL',ZDHC_Product_GUID__c='92690F805F627835E0530100007F6DFE',ZDHC_Product_Id__c='116965',ZDHC_Product_Code__c='A749LT11',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='BLACK GENESTA RE-N 3L',ZDHC_Product_GUID__c='7397AC199D1932F2E0530100007F6B06',ZDHC_Product_Id__c='66415',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='BLACK JFN',ZDHC_Product_GUID__c='8E54C9C4D0661373E0530100007F70BA',ZDHC_Product_Id__c='103432',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='BLUE GENESTA DS 3L',ZDHC_Product_GUID__c='7397AC199D1A32F2E0530100007F6B06',ZDHC_Product_Id__c='66440',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='BLUE GENESTA RE-N 3L',ZDHC_Product_GUID__c='7397A941E3BA31F1E0530100007FBBCC',ZDHC_Product_Id__c='66462',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='BOOSTER OW',ZDHC_Product_GUID__c='93398D2032551057E0530100007F3F20',ZDHC_Product_Id__c='121435',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-23T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('8B09054ADA8366E0E0530100007F1FD7').Id,ZDHC_Formulator_GUID__c='8B09054ADA8366E0E0530100007F1FD7',Chemical_Product_Name__c='brightener mskG-B',ZDHC_Product_GUID__c='930BCD66C7C022C1E0530100007F716B',ZDHC_Product_Id__c='120772',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-21T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='BROWN CD 1916',ZDHC_Product_GUID__c='8E54C409646611FBE0530100007FC1E2',ZDHC_Product_Id__c='103431',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='Brown TT NEW',ZDHC_Product_GUID__c='941AE4CDDAA463F3E0530100007F8BF9',ZDHC_Product_Id__c='126497',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-10-04T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9C0ACD17FFC66CEBE0530100007FFA84').Id,ZDHC_Formulator_GUID__c='9C0ACD17FFC66CEBE0530100007FFA84',Chemical_Product_Name__c='CARBONATO DE POTASSIO',ZDHC_Product_GUID__c='9C0ACFBC924A6B1EE0530100007F126B',ZDHC_Product_Id__c='143818',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-01-13T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9010B9336CB85B14E0530100007FA3D9').Id,ZDHC_Formulator_GUID__c='9010B9336CB85B14E0530100007FA3D9',Chemical_Product_Name__c='CATIONIC BLUE X-BL 300%',ZDHC_Product_GUID__c='901DE71675133722E0530100007F791D',ZDHC_Product_Id__c='108537',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('9010B9336CB85B14E0530100007FA3D9').Id,ZDHC_Formulator_GUID__c='9010B9336CB85B14E0530100007FA3D9',Chemical_Product_Name__c='CATIONIC RED X-GRL 300%',ZDHC_Product_GUID__c='901DE77BEDCF3720E0530100007F5297',ZDHC_Product_Id__c='108541',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('877FB7B0F0C2124BE0530100007F7C0A').Id,ZDHC_Formulator_GUID__c='877FB7B0F0C2124BE0530100007F7C0A',Chemical_Product_Name__c='Corafix Navy GDB',ZDHC_Product_GUID__c='8780DFA33FDB77C2E0530100007F8143',ZDHC_Product_Id__c='88454',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-04-27T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('877FB7B0F0C2124BE0530100007F7C0A').Id,ZDHC_Formulator_GUID__c='877FB7B0F0C2124BE0530100007F7C0A',Chemical_Product_Name__c='CORALANE BRILL RED F3BS',ZDHC_Product_GUID__c='96C2D34CCF9B43DDE0530100007FA135',ZDHC_Product_Id__c='133452',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-11-07T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='CRIMSON GENESTA RE-N 3L',ZDHC_Product_GUID__c='7CCE9AE0FBCC651DE0530100007F6F95',ZDHC_Product_Id__c='46133',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7E76598DF53B3439E0530100007F8029').Id,ZDHC_Formulator_GUID__c='7E76598DF53B3439E0530100007F8029',Chemical_Product_Name__c='DISODIUM PHOSPHATE',ZDHC_Product_GUID__c='7E77236759076F26E0530100007F0E04',ZDHC_Product_Id__c='34764',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7E0DA640555F1B6FE0530100007F5348').Id,ZDHC_Formulator_GUID__c='7E0DA640555F1B6FE0530100007F5348',Chemical_Product_Name__c='DISPERSANT',ZDHC_Product_GUID__c='7E0DC98CBDF237CBE0530100007F31BA',ZDHC_Product_Id__c='78447',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='DISPERSE ORANGE 4RL',ZDHC_Product_GUID__c='B53BD93D9F357192E0530100007F9C65',ZDHC_Product_Id__c='181316',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-11-29T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('8756DEE1C86231C6E0530100007F274B').Id,ZDHC_Formulator_GUID__c='8756DEE1C86231C6E0530100007F274B',Chemical_Product_Name__c='Disperse SB',ZDHC_Product_GUID__c='8767858515A258EDE0530100007F99E5',ZDHC_Product_Id__c='88154',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-04-26T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='E-870',ZDHC_Product_GUID__c='4CDED6A8F6A66341E0530100007FEB09',ZDHC_Product_Id__c='29603',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='E.G',ZDHC_Product_GUID__c='8E54C437F58811F9E0530100007FFA71',ZDHC_Product_Id__c='103437',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('628D479F070E7261E0530100007F90C3').Id,ZDHC_Formulator_GUID__c='628D479F070E7261E0530100007F90C3',Chemical_Product_Name__c='Eco SB Gray',ZDHC_Product_GUID__c='B6641105CD1533EFE0530100007FDA8B',ZDHC_Product_Id__c='182918',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-12-14T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='ELAM RP CONC',ZDHC_Product_GUID__c='9339364FFD557099E0530100007FA682',ZDHC_Product_Id__c='121423',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-23T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='FAIP AM 500',ZDHC_Product_GUID__c='907DB83C6E76076BE0530100007F81FD',ZDHC_Product_Id__c='109283',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-08-19T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='FERON ICA',ZDHC_Product_GUID__c='8BC063DBAF6334B3E0530100007FE1B4',ZDHC_Product_Id__c='98369',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-06-20T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9863F9D7B4CA3E8BE0530100007F890A').Id,ZDHC_Formulator_GUID__c='9863F9D7B4CA3E8BE0530100007F890A',Chemical_Product_Name__c='FERRIC CHLORIDE',ZDHC_Product_GUID__c='986407166996453AE0530100007FB0B4',ZDHC_Product_Id__c='137637',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-11-28T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('6DDD5205A9957D8EE0530100007F4AF4').Id,ZDHC_Formulator_GUID__c='6DDD5205A9957D8EE0530100007F4AF4',Chemical_Product_Name__c='FERROLIX 8344',ZDHC_Product_GUID__c='6DDDECADF881307BE0530100007F3268',ZDHC_Product_Id__c='36459',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('B07D73CC40AB541AE0530100007FB907').Id,ZDHC_Formulator_GUID__c='B07D73CC40AB541AE0530100007FB907',Chemical_Product_Name__c='FKS',ZDHC_Product_GUID__c='B07D79D1F2545737E0530100007FC817',ZDHC_Product_Id__c='176470',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-09-29T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('54013893EDD747F6E0530100007F8A01').Id,ZDHC_Formulator_GUID__c='54013893EDD747F6E0530100007F8A01',Chemical_Product_Name__c='FM-0831S',ZDHC_Product_GUID__c='54036752FAF6679AE0530100007FA3E1',ZDHC_Product_Id__c='75056',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('54013893EDD747F6E0530100007F8A01').Id,ZDHC_Formulator_GUID__c='54013893EDD747F6E0530100007F8A01',Chemical_Product_Name__c='FM-1368F',ZDHC_Product_GUID__c='54036752FAF7679AE0530100007FA3E1',ZDHC_Product_Id__c='75079',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5A01F02025207C05E0530100007F79BD').Id,ZDHC_Formulator_GUID__c='5A01F02025207C05E0530100007F79BD',Chemical_Product_Name__c='Fortres CQS',ZDHC_Product_GUID__c='B089B7285C2D7E94E0530100007F9DB1',ZDHC_Product_Id__c='176610',ZDHC_Product_Code__c='A749LT11',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='FORTRESS GSL PLUS',ZDHC_Product_GUID__c='9338EC52B7665449E0530100007FBC67',ZDHC_Product_Id__c='121414',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-23T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='Geopower NPS',ZDHC_Product_GUID__c='9417192CBE8D109EE0530100007FB842',ZDHC_Product_Id__c='126466',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-10-04T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='Geopower PFD NEW',ZDHC_Product_GUID__c='947B1D8F60233E8BE0530100007FFDD4',ZDHC_Product_Id__c='128002',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-10-09T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='GREY GENESTA DS-F 3L',ZDHC_Product_GUID__c='7397A941E3BD31F1E0530100007FBBCC',ZDHC_Product_Id__c='66571',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5C4827F331A671E1E0530100007FB2E8').Id,ZDHC_Formulator_GUID__c='5C4827F331A671E1E0530100007FB2E8',Chemical_Product_Name__c='HEIQ ADAPTIVE AC-03',ZDHC_Product_GUID__c='7010830DED7C268FE0530100007F1462',ZDHC_Product_Id__c='78218',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5C4827F331A671E1E0530100007FB2E8').Id,ZDHC_Formulator_GUID__c='5C4827F331A671E1E0530100007FB2E8',Chemical_Product_Name__c='HEIQ BARRIER ECO',ZDHC_Product_GUID__c='5C54093B1C001602E0530100007F9655',ZDHC_Product_Id__c='64203',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5C4827F331A671E1E0530100007FB2E8').Id,ZDHC_Formulator_GUID__c='5C4827F331A671E1E0530100007FB2E8',Chemical_Product_Name__c='HEIQ EFFECT SAX',ZDHC_Product_GUID__c='5C54093B1BFF1602E0530100007F9655',ZDHC_Product_Id__c='64179',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5C4827F331A671E1E0530100007FB2E8').Id,ZDHC_Formulator_GUID__c='5C4827F331A671E1E0530100007FB2E8',Chemical_Product_Name__c='HEIQ HYDRO UPA',ZDHC_Product_GUID__c='77B4886E48743E23E0530100007F6442',ZDHC_Product_Id__c='73632',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5C4827F331A671E1E0530100007FB2E8').Id,ZDHC_Formulator_GUID__c='5C4827F331A671E1E0530100007FB2E8',Chemical_Product_Name__c='HEIQ REAL SILK',ZDHC_Product_GUID__c='9BAF0430DAFB4025E0530100007FE419',ZDHC_Product_Id__c='143203',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-01-09T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5C4827F331A671E1E0530100007FB2E8').Id,ZDHC_Formulator_GUID__c='5C4827F331A671E1E0530100007FB2E8',Chemical_Product_Name__c='HEIQ SOFT SHF',ZDHC_Product_GUID__c='6C702EDE6436289CE0530100007FBEC7',ZDHC_Product_Id__c='65767',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='HIDROS RTL',ZDHC_Product_GUID__c='9338E548C0474CFDE0530100007FD667',ZDHC_Product_Id__c='121413',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-23T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9010B9336CB85B14E0530100007FA3D9').Id,ZDHC_Formulator_GUID__c='9010B9336CB85B14E0530100007FA3D9',Chemical_Product_Name__c='HIGH WASH WATER DISPERSION YELLOW BROWN HW-SFN',ZDHC_Product_GUID__c='901DE64CA06836BCE0530100007FB39D',ZDHC_Product_Id__c='108533',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='HYDROCOL 2FD',ZDHC_Product_GUID__c='8834911D2B5652E8E0530100007FAF3C',ZDHC_Product_Id__c='90404',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('7E0DA640555F1B6FE0530100007F5348').Id,ZDHC_Formulator_GUID__c='7E0DA640555F1B6FE0530100007F5348',Chemical_Product_Name__c='HYDROPHILIC SOFTENER',ZDHC_Product_GUID__c='7E0DC98CBDF937CBE0530100007F31BA',ZDHC_Product_Id__c='78503',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='IKARON BLUE FBL',ZDHC_Product_GUID__c='B53C23F7CF070B44E0530100007FAEBF',ZDHC_Product_Id__c='181324',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-11-29T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='IKARON BLUE SGA',ZDHC_Product_GUID__c='B53C39D52F291264E0530100007FD692',ZDHC_Product_Id__c='181333',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-11-29T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='IKARON ORANGE 4RL',ZDHC_Product_GUID__c='B53C1913D42506EFE0530100007FC3EE',ZDHC_Product_Id__c='181319',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-11-29T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='IKARON RED BSW',ZDHC_Product_GUID__c='B53C1FE76525096EE0530100007FF3DE',ZDHC_Product_Id__c='181321',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-11-29T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='IKARON TQ BLUE S-BG',ZDHC_Product_GUID__c='B53C1FE76526096EE0530100007FF3DE',ZDHC_Product_Id__c='181325',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-11-29T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='IKARON YELLOW SEF',ZDHC_Product_GUID__c='B53C164934DD03C0E0530100007F7EB3',ZDHC_Product_Id__c='181318',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-11-29T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='ISOL BZ 9 (FA-400)',ZDHC_Product_GUID__c='4CDED6A8F6A16341E0530100007FEB09',ZDHC_Product_Id__c='29564',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='ISOL PPL',ZDHC_Product_GUID__c='8E54C437F58111F9E0530100007FFA71',ZDHC_Product_Id__c='103407',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('773BA3FF579B110DE0530100007F8F19').Id,ZDHC_Formulator_GUID__c='773BA3FF579B110DE0530100007F8F19',Chemical_Product_Name__c='ISOPON PSR',ZDHC_Product_GUID__c='94725C3BE88261EAE0530100007F7E97',ZDHC_Product_Id__c='127696',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('5A01F02027FD7C05E0530100007F79BD').Id,ZDHC_Formulator_GUID__c='5A01F02027FD7C05E0530100007F79BD',Chemical_Product_Name__c='JAKAZOL RED RB 130%',ZDHC_Product_GUID__c='8869BF23DC5322ECE0530100007F19B5',ZDHC_Product_Id__c='92003',ZDHC_Product_Code__c='A782MC51',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('8D049071E69E4C00E0530100007FD488').Id,ZDHC_Formulator_GUID__c='8D049071E69E4C00E0530100007FD488',Chemical_Product_Name__c='KIERALON XC-J CONC',ZDHC_Product_GUID__c='8D0490FFE7114687E0530100007FAA40',ZDHC_Product_Id__c='100870',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-07-06T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='LARANJA SUJA',ZDHC_Product_GUID__c='933957CDCC7979C1E0530100007F4C9F',ZDHC_Product_Id__c='121427',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-23T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('896197B6C7CD0B67E0530100007F7CF4').Id,ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4',Chemical_Product_Name__c='LEATHER DRESSING OIL (ALCOFAT 563)',ZDHC_Product_GUID__c='A134CB85272B4791E0530100007FBBD0',ZDHC_Product_Id__c='151036',ZDHC_Product_Code__c='A927FN15',ZDHC_PID__c='P648NA26',Registered__c='ZDHC Gateway',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2021-03-26T09:02:55Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='LIMPEZA ESPECIAL',ZDHC_Product_GUID__c='93391D474D236042E0530100007FAFF2',ZDHC_Product_Id__c='121419',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-23T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='LINEX FB',ZDHC_Product_GUID__c='9339364FFD537099E0530100007FA682',ZDHC_Product_Id__c='121422',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-23T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('8CFDDE43E65F70EAE0530100007FF4B5').Id,ZDHC_Formulator_GUID__c='8CFDDE43E65F70EAE0530100007FF4B5',Chemical_Product_Name__c='LK-Primasoft Light XL',ZDHC_Product_GUID__c='8CFDDC83B11E6B34E0530100007F7E79',ZDHC_Product_Id__c='100710',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-07-06T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='MAGENTA GENESTA DS 3L',ZDHC_Product_GUID__c='7CCE9AE0FBD2651DE0530100007F6F95',ZDHC_Product_Id__c='46244',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('B1142E0F542A5467E0530100007FEB0A').Id,ZDHC_Formulator_GUID__c='B1142E0F542A5467E0530100007FEB0A',Chemical_Product_Name__c='Magnesium Chloride',ZDHC_Product_GUID__c='B117F189677520EBE0530100007F9E9B',ZDHC_Product_Id__c='177743',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('98357423DCE15326E0530100007F8905').Id,ZDHC_Formulator_GUID__c='98357423DCE15326E0530100007F8905',Chemical_Product_Name__c='MALIC ACID',ZDHC_Product_GUID__c='9839AA21106659D5E0530100007F07D2',ZDHC_Product_Id__c='137315',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='NERO C',ZDHC_Product_GUID__c='9339805FA09D0AD4E0530100007F14C4',ZDHC_Product_Id__c='121433',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-23T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='NOVATIC BROWN R MICRO DISPERSE',ZDHC_Product_GUID__c='5B9F4CCF7DB07701E0530100007F0170',ZDHC_Product_Id__c='56498',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='NOVATIC JADE GREEN XBN MICRO DISPERSE',ZDHC_Product_GUID__c='5B9F4CCF7DB17701E0530100007F0170',ZDHC_Product_Id__c='56539',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='NOVATIC VIOLET XBN MICRO DISPERSE',ZDHC_Product_GUID__c='5B9F4CCF7DB37701E0530100007F0170',ZDHC_Product_Id__c='56581',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9281631729E67F0CE0530100007FFD4B').Id,ZDHC_Formulator_GUID__c='9281631729E67F0CE0530100007FFD4B',Chemical_Product_Name__c='NYLON FIXING AGENT 501',ZDHC_Product_GUID__c='930696F594074024E0530100007F3D65',ZDHC_Product_Id__c='120299',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='ORANGE GENESTA AC 3L',ZDHC_Product_GUID__c='7CCE9AE0FBD8651DE0530100007F6F95',ZDHC_Product_Id__c='46372',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='ORANGE GENESTA DS 3L',ZDHC_Product_GUID__c='7CCE9AE0FBDA651DE0530100007F6F95',ZDHC_Product_Id__c='46419',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='ORANGE GENESTA RE-N 3L',ZDHC_Product_GUID__c='7CCE9AE0FBDB651DE0530100007F6F95',ZDHC_Product_Id__c='46437',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9281631729E67F0CE0530100007FFD4B').Id,ZDHC_Formulator_GUID__c='9281631729E67F0CE0530100007FFD4B',Chemical_Product_Name__c='OXYGEN BLEACHING STABILIZER HD-702',ZDHC_Product_GUID__c='930697568D953FF3E0530100007FD69B',ZDHC_Product_Id__c='120300',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='PERRUSTOL AWPI',ZDHC_Product_GUID__c='984ABFF278D3656DE0530100007FD2AF',ZDHC_Product_Id__c='137523',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='PERRUSTOL OC SPL',ZDHC_Product_GUID__c='994601A4AFA45DD2E0530100007FB860',ZDHC_Product_Id__c='139456',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-12-09T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7397AF93ED4F3371E0530100007F1C26').Id,ZDHC_Formulator_GUID__c='7397AF93ED4F3371E0530100007F1C26',Chemical_Product_Name__c='PERSIL DETERGENT powder',ZDHC_Product_GUID__c='739802D528614CD5E0530100007F1FC3',ZDHC_Product_Id__c='67525',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='PIGMENT FLOURESCENT VIOLET (A007)',ZDHC_Product_GUID__c='4CDED6A8F69B6341E0530100007FEB09',ZDHC_Product_Id__c='29507',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='PIGMENT GREEN FB (A601)',ZDHC_Product_GUID__c='4CDED6A8F69C6341E0530100007FEB09',ZDHC_Product_Id__c='29515',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='PIGMENT MEDIUM YELLOW FG (A202 YELLOW F7G)',ZDHC_Product_GUID__c='4CDED6A8F6966341E0530100007FEB09',ZDHC_Product_Id__c='29468',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='POLYVINYL ALCOHOL (PVA)',ZDHC_Product_GUID__c='517D6D7288515AA5E0530100007F45D2',ZDHC_Product_Id__c='38510',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('89A586854362151EE0530100007F783A').Id,ZDHC_Formulator_GUID__c='89A586854362151EE0530100007F783A',Chemical_Product_Name__c='Reactive BLACK GWF',ZDHC_Product_GUID__c='94B1B972C1D23D02E0530100007F24AB',ZDHC_Product_Id__c='128894',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-10-12T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9010B9336CB85B14E0530100007FA3D9').Id,ZDHC_Formulator_GUID__c='9010B9336CB85B14E0530100007FA3D9',Chemical_Product_Name__c='REACTIVE BLACK L-GD',ZDHC_Product_GUID__c='901DE7CAA047371EE0530100007FCB8B',ZDHC_Product_Id__c='108543',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('89A586854362151EE0530100007F783A').Id,ZDHC_Formulator_GUID__c='89A586854362151EE0530100007F783A',Chemical_Product_Name__c='Reactive NAVY HS-G',ZDHC_Product_GUID__c='922A092689CB09D2E0530100007F47BB',ZDHC_Product_Id__c='114308',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-10T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9010B9336CB85B14E0530100007FA3D9').Id,ZDHC_Formulator_GUID__c='9010B9336CB85B14E0530100007FA3D9',Chemical_Product_Name__c='REACTIVE RUBY FW-2B H/C',ZDHC_Product_GUID__c='901DE71675143722E0530100007F791D',ZDHC_Product_Id__c='108542',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('9010B9336CB85B14E0530100007FA3D9').Id,ZDHC_Formulator_GUID__c='9010B9336CB85B14E0530100007FA3D9',Chemical_Product_Name__c='REACTIVE YELLOW 4GL 150%',ZDHC_Product_GUID__c='901DE6662C7B36B4E0530100007F4BC6',ZDHC_Product_Id__c='108534',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='RED GENESTA RE-N 3L',ZDHC_Product_GUID__c='7CCE9AE0FBDF651DE0530100007F6F95',ZDHC_Product_Id__c='46510',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='RUBINE GENESTA AC 3L',ZDHC_Product_GUID__c='7397B7452883362FE0530100007F405E',ZDHC_Product_Id__c='66615',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCO-DRY ECO PLUS',ZDHC_Product_GUID__c='956CB6A2B1BE31CEE0530100007F1133',ZDHC_Product_Id__c='130133',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-10-21T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCO-FIL HPYL',ZDHC_Product_GUID__c='76D861642A8A4708E0530100007FC0B9',ZDHC_Product_Id__c='55791',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCO-LINK WEB',ZDHC_Product_GUID__c='9C00D2D5351B2035E0530100007FA672',ZDHC_Product_Id__c='143716',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-01-13T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCO-STAB OKM',ZDHC_Product_GUID__c='883491977F94562AE0530100007F6C5F',ZDHC_Product_Id__c='90416',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCOBAC AGP',ZDHC_Product_GUID__c='8BBBB14F93A90486E0530100007F9572',ZDHC_Product_Id__c='98342',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-06-20T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCOFIN GWE',ZDHC_Product_GUID__c='76D861642A8E4708E0530100007FC0B9',ZDHC_Product_Id__c='55883',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCOFIN MIKA',ZDHC_Product_GUID__c='8E3A99DD0EF943AEE0530100007F739E',ZDHC_Product_Id__c='102879',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCOFIN SIQ',ZDHC_Product_GUID__c='914CB72944F01C75E0530100007FC98A',ZDHC_Product_Id__c='111285',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCOGEN BEST',ZDHC_Product_GUID__c='8834917F5456561DE0530100007F42B8',ZDHC_Product_Id__c='90411',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCOGEN WSL SPL',ZDHC_Product_GUID__c='914C0F6BEA4E5D06E0530100007F680D',ZDHC_Product_Id__c='111276',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCOLASE TWIN',ZDHC_Product_GUID__c='418B6310BB371A29E0530100007FA846',ZDHC_Product_Id__c='66589',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCOLIN CA',ZDHC_Product_GUID__c='838176DB8DDB5DC3E0530100007FD4E3',ZDHC_Product_Id__c='82364',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-03-07T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCON FEF-I',ZDHC_Product_GUID__c='8C0A1E696B9E74F2E0530100007FA72C',ZDHC_Product_Id__c='98714',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUCORIT INPK',ZDHC_Product_GUID__c='914C0F25F6E65D13E0530100007F42B2',ZDHC_Product_Id__c='111286',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='RUSTOL DAP',ZDHC_Product_GUID__c='883491FA351D5628E0530100007F93D7',ZDHC_Product_Id__c='90418',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('6498421CE2842F93E0530100007FEDA6').Id,ZDHC_Formulator_GUID__c='6498421CE2842F93E0530100007FEDA6',Chemical_Product_Name__c='SALE MARINO LAVATO RINFUSA',ZDHC_Product_GUID__c='64986475FD6E4224E0530100007F8FF8',ZDHC_Product_Id__c='33997',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('628D479F070E7261E0530100007F90C3').Id,ZDHC_Formulator_GUID__c='628D479F070E7261E0530100007F90C3',Chemical_Product_Name__c='SB 1650 WHITE',ZDHC_Product_GUID__c='8C0A1E696B9774F2E0530100007FA72C',ZDHC_Product_Id__c='98658',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='SBM-E',ZDHC_Product_GUID__c='8AF7D8A1A8441B9AE0530100007F5CEB',ZDHC_Product_Id__c='97499',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-06-10T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('773BA3FF579B110DE0530100007F8F19').Id,ZDHC_Formulator_GUID__c='773BA3FF579B110DE0530100007F8F19',Chemical_Product_Name__c='SEQUION 48/98',ZDHC_Product_GUID__c='773C041734DC2327E0530100007FEA89',ZDHC_Product_Id__c='62055',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5A8CE1DF10F65052E0530100007FFCCF').Id,ZDHC_Formulator_GUID__c='5A8CE1DF10F65052E0530100007FFCCF',Chemical_Product_Name__c='Seriprint T',ZDHC_Product_GUID__c='834421BEECAC304AE0530100007FFEB7',ZDHC_Product_Id__c='82014',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-03-04T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5A8CE1DF10F65052E0530100007FFCCF').Id,ZDHC_Formulator_GUID__c='5A8CE1DF10F65052E0530100007FFCCF',Chemical_Product_Name__c='SETPRINT GT',ZDHC_Product_GUID__c='5A8D6D27D4B57DF2E0530100007FE3EE',ZDHC_Product_Id__c='38028',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='SH-B300',ZDHC_Product_GUID__c='AE40AD09268F0FFCE0530100007F982A',ZDHC_Product_Id__c='173061',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-09-01T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='SH-TS400',ZDHC_Product_GUID__c='8E54C9C4D0671373E0530100007F70BA',ZDHC_Product_Id__c='103436',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('4CDE5F6F15E1416FE0530100007F256A').Id,ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A',Chemical_Product_Name__c='SHN-PH 1000',ZDHC_Product_GUID__c='A34FF8CC05055A90E0530100007F6945',ZDHC_Product_Id__c='152642',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-04-15T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('B1142E0F542A5467E0530100007FEB0A').Id,ZDHC_Formulator_GUID__c='B1142E0F542A5467E0530100007FEB0A',Chemical_Product_Name__c='Sodium Bicarbonate',ZDHC_Product_GUID__c='B117F1CA8E4020E9E0530100007FB357',ZDHC_Product_Id__c='177750',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('7E0DA640555F1B6FE0530100007F5348').Id,ZDHC_Formulator_GUID__c='7E0DA640555F1B6FE0530100007F5348',Chemical_Product_Name__c='SODIUM HYDROSULFIDE FOR INSURANCE',ZDHC_Product_GUID__c='7E0DC98CBDFB37CBE0530100007F31BA',ZDHC_Product_Id__c='78514',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='SODIUM HYDROSULFITE',ZDHC_Product_GUID__c='9A948D1B1E213D0AE0530100007F564B',ZDHC_Product_Id__c='141338',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-12-26T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('B1142E0F542A5467E0530100007FEB0A').Id,ZDHC_Formulator_GUID__c='B1142E0F542A5467E0530100007FEB0A',Chemical_Product_Name__c='SODIUM METABISULFITE',ZDHC_Product_GUID__c='B117F1CA8E3F20E9E0530100007FB357',ZDHC_Product_Id__c='177748',Registered__c='CleanChain'),
      new Chemical_Product__c(Formulator__c=formulator.get('9980AA535CF23BD4E0530100007FE2F8').Id,ZDHC_Formulator_GUID__c='9980AA535CF23BD4E0530100007FE2F8',Chemical_Product_Name__c='SODIUM SILICATE',ZDHC_Product_GUID__c='9980AC9C8E8E3E2DE0530100007F8B37',ZDHC_Product_Id__c='139999',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-12-12T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9BB52CFA80564DD2E0530100007FFD58').Id,ZDHC_Formulator_GUID__c='9BB52CFA80564DD2E0530100007FFD58',Chemical_Product_Name__c='SOFTASIL MIC 3030',ZDHC_Product_GUID__c='9BB5315DC9544DF2E0530100007F1A99',ZDHC_Product_Id__c='143321',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-01-09T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='Special Clean',ZDHC_Product_GUID__c='941744F52EB218ADE0530100007F365E',ZDHC_Product_Id__c='126471',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-10-04T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='Special White BR-LT',ZDHC_Product_GUID__c='94174E1460EA2199E0530100007F95EF',ZDHC_Product_Id__c='126473',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-10-04T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7E0DA640555F1B6FE0530100007F5348').Id,ZDHC_Formulator_GUID__c='7E0DA640555F1B6FE0530100007F5348',Chemical_Product_Name__c='STIFFENING FINISHING AGENT',ZDHC_Product_GUID__c='7E0DC98CBE0437CBE0530100007F31BA',ZDHC_Product_Id__c='78577',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7E0DA640555F1B6FE0530100007F5348').Id,ZDHC_Formulator_GUID__c='7E0DA640555F1B6FE0530100007F5348',Chemical_Product_Name__c='STRONG VAT CLEANER',ZDHC_Product_GUID__c='7E0DC98CBDF637CBE0530100007F31BA',ZDHC_Product_Id__c='78478',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('628D479F070E7261E0530100007F90C3').Id,ZDHC_Formulator_GUID__c='628D479F070E7261E0530100007F90C3',Chemical_Product_Name__c='SUBLIMATION INK BLACK',ZDHC_Product_GUID__c='7F1508BF82106ECEE0530100007FE00A',ZDHC_Product_Id__c='65590',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('628D479F070E7261E0530100007F90C3').Id,ZDHC_Formulator_GUID__c='628D479F070E7261E0530100007F90C3',Chemical_Product_Name__c='SUBLIMATION INK CYAN',ZDHC_Product_GUID__c='7F1508BF82116ECEE0530100007FE00A',ZDHC_Product_Id__c='65608',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('628D479F070E7261E0530100007F90C3').Id,ZDHC_Formulator_GUID__c='628D479F070E7261E0530100007F90C3',Chemical_Product_Name__c='SUBLIMATION INK MAGENTA',ZDHC_Product_GUID__c='7F1508BF82136ECEE0530100007FE00A',ZDHC_Product_Id__c='65654',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('628D479F070E7261E0530100007F90C3').Id,ZDHC_Formulator_GUID__c='628D479F070E7261E0530100007F90C3',Chemical_Product_Name__c='SUBLIMATION INK YELLOW',ZDHC_Product_GUID__c='7F1508BF82146ECEE0530100007FE00A',ZDHC_Product_Id__c='65675',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('90426863F26007D1E0530100007F7DA8').Id,ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8',Chemical_Product_Name__c='SUJO VERDE',ZDHC_Product_GUID__c='93395D6C713279C3E0530100007F1D63',ZDHC_Product_Id__c='121428',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-09-23T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('674283E762183E79E0530100007F426A').Id,ZDHC_Formulator_GUID__c='674283E762183E79E0530100007F426A',Chemical_Product_Name__c='SUN WHITE COB',ZDHC_Product_GUID__c='674296111C2143FBE0530100007F3F22',ZDHC_Product_Id__c='52880',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('8756DEE1C86231C6E0530100007F274B').Id,ZDHC_Formulator_GUID__c='8756DEE1C86231C6E0530100007F274B',Chemical_Product_Name__c='Sunacryl Black CDB',ZDHC_Product_GUID__c='875701BA14673D2BE0530100007F0AD0',ZDHC_Product_Id__c='88024',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-04-25T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('8756DEE1C86231C6E0530100007F274B').Id,ZDHC_Formulator_GUID__c='8756DEE1C86231C6E0530100007F274B',Chemical_Product_Name__c='Sunacryl Turq Blue SD-5G',ZDHC_Product_GUID__c='8756DF7FFE2C3058E0530100007F8BB1',ZDHC_Product_Id__c='88014',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-04-25T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9458BE1313371B3CE0530100007FE4BE').Id,ZDHC_Formulator_GUID__c='9458BE1313371B3CE0530100007FE4BE',Chemical_Product_Name__c='SUNFIX YELLOW S3R 150%',ZDHC_Product_GUID__c='9458C42155771ACEE0530100007FC102',ZDHC_Product_Id__c='126995',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-10-07T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('9458BE1313371B3CE0530100007FE4BE').Id,ZDHC_Formulator_GUID__c='9458BE1313371B3CE0530100007FE4BE',Chemical_Product_Name__c='SYNOZOL RED KHL',ZDHC_Product_GUID__c='9462B851CFCC543AE0530100007F5BAC',ZDHC_Product_Id__c='127530',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-10-08T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('5D9C762C1C7522EAE0530100007F1C24').Id,ZDHC_Formulator_GUID__c='5D9C762C1C7522EAE0530100007F1C24',Chemical_Product_Name__c='TLG (A)',ZDHC_Product_GUID__c='5D9CA1D589AF32A4E0530100007F119A',ZDHC_Product_Id__c='31902',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7E0DA640555F1B6FE0530100007F5348').Id,ZDHC_Formulator_GUID__c='7E0DA640555F1B6FE0530100007F5348',Chemical_Product_Name__c='ULTRAFINE FIBER LEVELLING AGENT',ZDHC_Product_GUID__c='7E0DC98CBDF037CBE0530100007F31BA',ZDHC_Product_Id__c='78432',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('416685DBDF9777FFE0530100007F9205').Id,ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205',Chemical_Product_Name__c='VEROLAN DET',ZDHC_Product_GUID__c='A7A13EC97ED457FEE0530100007F4647',ZDHC_Product_Id__c='161618',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-06-09T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('B07D73CC40AB541AE0530100007FB907').Id,ZDHC_Formulator_GUID__c='B07D73CC40AB541AE0530100007FB907',Chemical_Product_Name__c='XQS-1',ZDHC_Product_GUID__c='B07D74E4D72753C3E0530100007FE346',ZDHC_Product_Id__c='176468',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-09-29T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('B07D73CC40AB541AE0530100007FB907').Id,ZDHC_Formulator_GUID__c='B07D73CC40AB541AE0530100007FB907',Chemical_Product_Name__c='XQS-8P',ZDHC_Product_GUID__c='B07FDC8921931FE0E0530100007F1A46',ZDHC_Product_Id__c='176476',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2020-09-30T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('6E9359D43BE8766EE0530100007F30EF').Id,ZDHC_Formulator_GUID__c='6E9359D43BE8766EE0530100007F30EF',Chemical_Product_Name__c='YELLOW 2GL',ZDHC_Product_GUID__c='6E936F9334080202E0530100007FCCDE',ZDHC_Product_Id__c='52259',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='YELLOW GENESTA AC-F 3L',ZDHC_Product_GUID__c='7397B7452884362FE0530100007F405E',ZDHC_Product_Id__c='66622',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class)),
      new Chemical_Product__c(Formulator__c=formulator.get('7397A19C068F2F6BE0530100007F69C9').Id,ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9',Chemical_Product_Name__c='YELLOW GENESTA DS 3L',ZDHC_Product_GUID__c='7CCE9AE0FBEA651DE0530100007F6F95',ZDHC_Product_Id__c='46733',Registered__c='CleanChain',Last_Verified_Date__c=(DateTime)JSON.deserialize('"2019-02-02T00:00:00Z"', DateTime.class))
    };
    if (count == null || count >= all.size()) {
      products = all;
    } else {
      // Pick a selection up to count items.
      products = new List<Chemical_Product__c>();
      Integer step = (all.size() - 1) / count;
      for (Integer i = 0; i < count; i++) {
        products.add(all[i * step]);
      }
    }
    insert products;
  }
}