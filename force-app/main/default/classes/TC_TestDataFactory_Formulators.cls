/*
 * Test data factory for Formulator__c objects
 */
@IsTest
public with sharing class TC_TestDataFactory_Formulators {
  /*
   * Returns a single formulator with specified values for fields
   */
  public static Formulator__c create(
    String name,
    Id facilityId,
    String origin,
    String guid,
    String country
  ) {
    Formulator__c formulator = new Formulator__c(
      Created_By__c = facilityId,
      Name = name,
      Origin__c = origin,
      ZDHC_Formulator_GUID__c = guid,
      Country__c = country
    );

    return formulator;
  }

  /*
   * Returns a list of formulators for a specified facility with Origin__c = Supplier, Country__c = China and a random name and GUID
   */
  public static List<Formulator__c> create(Id facilityId, Integer count) {
    List<Formulator__c> toReturn = new List<Formulator__c>();

    for (Integer i = 0; i < count; i++) {
      toReturn.add(
        create(
          TC_TestDataFactory.getCompanyname() + ' Formulations',
          facilityId,
          'Supplier',
          StringUtil.random(32, '0123456789ABCDEF'),
          'China'
        )
      );
    }

    return toReturn;
  }

  /*
   * Inserts a list of formulators for a specified facility, each with a list of chemical product records
   */
  public static List<Formulator__c> createInsertedWithChemicalProducts(
    Id facilityId,
    Integer formulatorCount,
    Integer activeProductCount,
    Integer inactiveProductCount,
    Integer pendingProductCount
  ) {
    List<Formulator__c> formulators = create(facilityId, formulatorCount);
    insert formulators;

    Date today = Date.today();
    Datetime verificationTime = Datetime.newInstance(
      today.addDays(-1),
      Time.newInstance(0, 0, 0, 0)
    );

    List<Chemical_Product__c> chemList = new List<Chemical_Product__c>();
    for (Formulator__c f : formulators) {
      chemList.addAll(
        TC_TestDataFactory_Chemicals.create(
          'Active',
          'Level 2',
          'Supplier',
          verificationTime,
          f.Id,
          activeProductCount
        )
      );
      chemList.addAll(
        TC_TestDataFactory_Chemicals.create(
          'Deactivated',
          'Level 2',
          'Supplier',
          verificationTime,
          f.Id,
          inactiveProductCount
        )
      );
      chemList.addAll(
        TC_TestDataFactory_Chemicals.create(
          'Pending',
          null,
          null,
          null,
          f.Id,
          pendingProductCount
        )
      );
    }
    insert chemList;

    return formulators;
  }

  public List<Formulator__c> formulators;
  // Kept for existing unit tests, but should use TC_TestDataFactory_Chemicals.
  public List<Chemical_Product__c> products = new List<Chemical_Product__c>();

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

  /**
   * TC_TestDataFactory_Formulators Query for expected data, ready to perform helpful assertions
   * in @isTest method, after first constructing with insertion in @testSetup method.
   */
  public TC_TestDataFactory_Formulators() {
    formulators = [
      SELECT
        Address_from_ZDHC__c,
        City_Town__c,
        Contact_Email__c,
        Contact_Name__c,
        Country__c,
        CreatedById,
        CreatedDate,
        Created_By__c,
        CurrencyIsoCode,
        Id,
        IsDeleted,
        LastActivityDate,
        LastModifiedById,
        LastModifiedDate,
        LastReferencedDate,
        LastViewedDate,
        Name,
        Origin__c,
        OwnerId,
        Phone__c,
        State_Province__c,
        Supplier__c,
        SystemModstamp,
        ZDHC_Formulator_GUID__c,
        ZDHC_Supplier_AID__c,
        Zip_Postal_Code__c
      FROM Formulator__c
      ORDER BY Id ASC
      LIMIT 250
    ];
  }

  /**
   * TC_TestDataFactory_Formulators Inserts Formulators with Chemical Products.
   *
   * @param facilities (List<Account>): Facilities to insert Formulators for.
   * @param count (List<Integer>): Count of Formulators to insert for respective facility.
   */
  public TC_TestDataFactory_Formulators(
    List<Account> facilities,
    List<Integer> count
  ) {
    List<Integer> activeCount = new List<Integer>{ 1, 2, 3, 2, 1 };
    List<Integer> inactiveCount = new List<Integer>{ 2, 1, 2, 1 };
    List<Integer> pendingCount = new List<Integer>{ 0, 1, 2, 0, 0, 1, 0 };

    formulators = new List<Formulator__c>();
    for (Integer i = 0; i < facilities.size() && i < count.size(); i++) {
      formulators.addAll(create(facilities[i].Id, count[i]));
    }
    insert formulators;

    Date today = Date.today();
    Datetime verificationTime = Datetime.newInstance(
      today.addDays(-1),
      Time.newInstance(0, 0, 0, 0)
    );

    Integer levelIndex = 0;
    List<String> level = new List<String>{
      'Level 3',
      'Level 2',
      'Level 1',
      'Level 0',
      'Registered'
    };

    for (Integer i = 0; i < formulators.size(); i++) {
      products.addAll(
        TC_TestDataFactory_Chemicals.create(
          'Active',
          level[Math.mod(levelIndex++, level.size())],
          'Supplier',
          verificationTime,
          formulators[i].Id,
          activeCount[Math.mod(i, activeCount.size())]
        )
      );
      products.addAll(
        TC_TestDataFactory_Chemicals.create(
          'Deactivated',
          level[Math.mod(levelIndex++, level.size())],
          'Supplier',
          verificationTime,
          formulators[i].Id,
          inactiveCount[Math.mod(i, inactiveCount.size())]
        )
      );
      products.addAll(
        TC_TestDataFactory_Chemicals.create(
          'Pending',
          level[Math.mod(levelIndex++, level.size())],
          'Supplier',
          verificationTime,
          formulators[i].Id,
          pendingCount[Math.mod(i, pendingCount.size())]
        )
      );
    }
    insert products;
  }

  public TC_TestDataFactory_Formulators(List<Account> facility) {
    Integer facilities = facility.size();
    // Let the first 4 facilities get all these formulators.
    if (facilities > 4) {
      facilities = 4;
    }
    // prettier-ignore
    formulators = new List<Formulator__c>{
      new Formulator__c(ZDHC_Formulator_GUID__c='00000000000000000000000000000000', Name='     Formulator with all zeros GUID', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(0,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='CE23BC7011422B05E0530100007F1FA4', Name='   SHAOXING COUNTY YINGFENG TEXTILE(PRINTING&DYEING) CO.LTD.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(0,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D77D2CB25ABB5BABE0530100007F44A5', Name='A new new form', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(1,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6D3FA46AE4BD0BEBE0530100007F8830', Name='Absolute Denim Factory                                                                              ', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(2,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5D84933191A5665BE0530100007FD18B', Name='Adhunik Overseas Pvt Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(3,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='7244CD83A3A12B22E0530100007F1132', Name='Aitengda', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(4,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='896197B6C7CD0B67E0530100007F7CF4', Name='Alcover Quimica SL', ZDHC_Supplier_AID__c='A927FN15', Address_from_ZDHC__c='Ctra. de Alcover a Montblanc, km 2,4\n43460 Alcover (Tarragona)', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(5,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F0201D157C05E0530100007F79BD', Name='ALPHATEAM SB LTD', Address_from_ZDHC__c='negev 4', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(6,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8392A28240E05E81E0530100007FBE60', Name='AMKO EXPORTS', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(7,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B133F43258665AFCE0530100007F6572', Name='Anli Chemical(Taixing)Co.,Ltd', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(8,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B82568731A983E32E0530100007FA0E7', Name='Applinobel SDN BHD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(9,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6F731E04E38F6BFBE0530100007F90C8', Name='Arjyot Chemicals Private Limited', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(10,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B464321CE61622CFE0530100007F5195', Name='Arzignanese Srl', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(11,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='60446C046BB368DDE0530100007FFAD7', Name='ATT TEKSTIL SAN.TIC.A.S.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(12,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6DDD5205A9957D8EE0530100007F4AF4', Name='Aztech', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(13,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8D049071E69E4C00E0530100007FD488', Name='BASF (China) Co., Ltd', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(14,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F0201EB57C05E0530100007F79BD', Name='Bell Aliant Inc.', Address_from_ZDHC__c='Barrington Street\nHalifax, NS', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(15,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8756DEE1C86231C6E0530100007F274B', Name='Big Sunshine International Co.,Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(16,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D5FEC4A527A5271CE0530100007F1179', Name='Bluefire16', Address_from_ZDHC__c='India', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(17,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='ADE717D65ACA67B4E0530100007FE85D', Name='BluWin Ltd.', Address_from_ZDHC__c='35 Westgate, Huddersfield, HD 1 PA, UK', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(18,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9B9A900DFFA8742AE0530100007FF855', Name='Brachi Testing Services S.r.l. Unipersonale_MRSL', Address_from_ZDHC__c='Via Fona di Mezzana, 59100', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(19,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8EE0ECD3CB5A7134E0530100007F01F5', Name='Bums Ind', Address_from_ZDHC__c='RM410, 5, GASAN DIGITAL 1RO, GEUMCHEONGU SEOUL KOREA', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(20,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='650036F944ED24BBE0530100007FBE64', Name='BVB Tekstil San. ve Tic. Ltd. Sti.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(21,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8CFFEEF8AFC62504E0530100007F67CA', Name='Canko Marketing INC', Address_from_ZDHC__c='Canko Marketing INC, Room No. 901, 26, NOHAE-RO 69 GIL, DOBONG-GU, SEOUL, Korea', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(22,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='AA7A78D765E846BAE0530100007F4456', Name='CEL Seta s.a.s', Address_from_ZDHC__c='via manzoni, 5', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(23,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F02020527C05E0530100007F79BD', Name='Changshu huamao textile co., ltd', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(24,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8B09054ADA8366E0E0530100007F1FD7', Name='Changzhou pengxiang chemical technology co. LTD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(25,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8F4FCAF2A31507CCE0530100007F38CF', Name='Chemiplas Australia Pty Ltd', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(26,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B8C4005A4F1F4109E0530100007FBCDC', Name='Chne', ZDHC_Supplier_AID__c='A184XD93', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(27,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B9F843195DAD6249E0530100007F86AF', Name='CIEMMECI FASHION SRL', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(28,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='CE23BC7013292B05E0530100007F1FA4', Name='Coats Orizaba', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(29,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='877FB7B0F0C2124BE0530100007F7C0A', Name='COLOURTEX INDUSTRIES PVT. LTD.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(30,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D6623CC3417D22E1E0530100007F931A', Name='Company SC 2109', Address_from_ZDHC__c='South Korea', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(31,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D6623CC3449D22E1E0530100007F931A', Name='Company SC 2309', Address_from_ZDHC__c='South Korea', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(32,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D6623FF2538E22DAE0530100007F7CE7', Name='Company SC 2509', Address_from_ZDHC__c='South Korea', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(33,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D662456C22102663E0530100007F7B82', Name='Company SC 2709', Address_from_ZDHC__c='South Korea', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(34,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D6625ADCE3D52A58E0530100007F8C3E', Name='Company SC 2910', Address_from_ZDHC__c='South Korea', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(35,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D662658945CE2C55E0530100007F9CF1', Name='Company SC 3110', Address_from_ZDHC__c='South Korea', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(36,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D66285C1984E329AE0530100007F3087', Name='Company SC 3310', Address_from_ZDHC__c='South Korea', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(37,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='BAE19585B24A3D94E0530100007FD11A', Name='COMPEX FINISH SRL', ZDHC_Supplier_AID__c='A345HD98', Address_from_ZDHC__c='Via delle Fontane 3\\5', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(38,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B4E81F0E0EAD69AEE0530100007FE2C9', Name='Cong Ty TNHH SX TM XD Phu An Nam', Address_from_ZDHC__c='161/ 43 Ni Su Huynh Lien, Ward 10, Tan Binh dist.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(39,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5E7B81FA6D702BEBE0530100007F5A37', Name='Covestro Polymer (China) Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(40,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9D38A45C617B2675E0530100007F4E5C', Name='CTINA CASTANHO GAI BR', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(41,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B4865AEE8C947C2BE0530100007F5B55', Name='Curtiembres Bufalo SAS', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(42,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5D9C0096EF507C71E0530100007FF795', Name='Daikin Fluorochemicals (China) Co., Ltd. Shanghai Branch', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(43,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='CE23BC70139B2B05E0530100007F1FA4', Name='Deiveegam Dyers', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(44,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9609D842E395725EE0530100007F2F90', Name='Depura service', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(45,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B97F5BEA79C26014E0530100007FC5B3', Name='Digital Dyers', Address_from_ZDHC__c='Unit 9, Earls Way', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(46,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B951307715F22D98E0530100007F74D9', Name='DOMINGO MOLINA, S.A.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(47,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F02022BF7C05E0530100007F79BD', Name='dongguan enke chemical LTD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(48,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B07D73CC40AB541AE0530100007FB907', Name='Dongguan Xianqiao Detergent IND Co.,Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(49,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='94A03FA2BA972B95E0530100007F98C4', Name='Dry Wash S.r.l', Address_from_ZDHC__c='via Albano Laziale', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(50,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5EFD5689E9B71D7DE0530100007F3C61', Name='dystar de mexico', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(51,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='A29C9EBCF0734EB9E0530100007F776D', Name='Ecocert Greenlife', Address_from_ZDHC__c='Amsterdam, Netherlands', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(52,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8CFDDE43E65F70EAE0530100007FF4B5', Name='Elkay Chemicals Ltd.', Address_from_ZDHC__c='Works: J-i521153 MIDC, BHOSARI, PTINE-41 1026, INDIA', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(53,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='7397A19C068F2F6BE0530100007F69C9', Name='Epson Europe B.V.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(54,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8F67294DBF923A49E0530100007F4BD0', Name='Estrela', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(55,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8728FD47D81942AFE0530100007FD2B0', Name='Excell Specialities Co. Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(56,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F02024287C05E0530100007F79BD', Name='Farbotex', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(57,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='AEB528D374873B73E0530100007F6D8B', Name='Fileca Industry SA', Address_from_ZDHC__c='strada Valea Viilor nr 1', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(58,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9458BE1313371B3CE0530100007FE4BE', Name='FOCOR PRODUTOS QUIMICOS S.A.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(59,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9010B9336CB85B14E0530100007FA3D9', Name='Foshan Jinshengda Chemical Dyestuff Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(60,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6C23029898936640E0530100007F1A55', Name='Fu Hsiang Fortune Industrial Co., Ltd.', ZDHC_Supplier_AID__c='A468XN26', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(61,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F02024FC7C05E0530100007F79BD', Name='FULLTIDE ENTERPRISE CO., LTD.', Address_from_ZDHC__c='NO. 123, Ln. 61, Sec. 3, Zhongzheng E. Rd.,', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(62,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F02025207C05E0530100007F79BD', Name='GARMON KEMIN TEXTILES', ZDHC_Supplier_AID__c='A749LT11', Address_from_ZDHC__c='Strada Acquasalata 7D/E', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(63,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6498421CE2842F93E0530100007FEDA6', Name='Giglioli Srl', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(64,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='69BA75BCC19712CFE0530100007FDD45', Name='GOKHAN TEKSTIL SANAYI VE TICARET A.S.', Address_from_ZDHC__c='Organize Sanayi Bölgesi Fahri Karaca Cad.No:13 20330 Honaz / DENİZLİ', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(65,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='60D01B911C013188E0530100007F3FA0', Name='GREEN TECH VIET NAM JSC', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(66,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D7C02AF3F63150E5E0530100007FA60E', Name='Guangdong Galanz MicroOven & Elect Appl Mfg Co Ltd', Address_from_ZDHC__c='China', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(67,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='60CFC80C930114B2E0530100007F17C8', Name='Guangzhou Kam Hing Textile Dyeing Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(68,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8DD8E1EAC4542460E0530100007F6100', Name='GULIPEK KUMAS IP.TIC.SAN.AS.', Address_from_ZDHC__c='KALE MAH. KILICLAR CAD. NO:11 16450', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(69,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6148468395F80A4FE0530100007FEF33', Name='Haining Ryland Textile Co.,Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(70,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='98357423DCE15326E0530100007F8905', Name='Hangzhou Haishuo Trading Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(71,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='982D3E67F2360912E0530100007FA48F', Name='HANGZHOU XINYUAN PRINTING & DYEING CO. LTD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(72,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D5FEC4A5260D271CE0530100007F1179', Name='Hayabusa13', Address_from_ZDHC__c='India', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(73,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5C4827F331A671E1E0530100007FB2E8', Name='HeiQ Materials AG', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(74,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B476783246673B08E0530100007F6825', Name='Hilos A&E Dominicana', Address_from_ZDHC__c='ZONA FRANCA SANTIAGO R.D.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(75,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9E4CCE2B075C28AAE0530100007FA65C', Name='HOORAIN HTF LIMITED', Address_from_ZDHC__c='Bejura, Madhabpur, Hobigonj.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(76,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='89A586854362151EE0530100007F783A', Name='Hubei Hwalle Dyestuff Industry Co. Ltd', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(77,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6DF5D98ACB9728ADE0530100007F95C0', Name='Huntsman Advanced Materials', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(78,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B22465AC00E079EAE0530100007FBED7', Name='IBRAHEEM AND SONS', ZDHC_Supplier_AID__c='A943TJ95', Address_from_ZDHC__c='Plot No.12, Sector 35/A Korangi No.04', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(79,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9C0ACD17FFC66CEBE0530100007FFA84', Name='Incasa', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(80,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='628D479F070E7261E0530100007F90C3', Name='Inkcups', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(81,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='914E0C5BA04C1857E0530100007FD2E4', Name='Intertek India Tirupur', Address_from_ZDHC__c='No-501, Opposite to LRG college, Palladam road, Tirupur, India', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(82,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F02027D37C05E0530100007F79BD', Name='ITS ACADEMIC', Address_from_ZDHC__c='Unit 711, Hunghom Commercial Centre, Tower B, 37 Ma Tau Wai Road, Hung Hom, Kowloon, Hong Kong.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(83,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F02027FD7C05E0530100007F79BD', Name='Jay Chemical Industries Private Limited', ZDHC_Supplier_AID__c='A782MC51', Address_from_ZDHC__c='Jay House, Near Panchvati circle \nAmbawadi,', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(84,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='AC99327D8BD366ACE0530100007FA021', Name='JIANGMEN KAM FUNG FIBRE TECHNOLOGY CO.,LTD', Address_from_ZDHC__c='广东省江门市新会区罗坑镇陈冲工业区', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(85,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='60BFAE41716C59D9E0530100007F0EF1', Name='Jiangsu Lugang Woolen Textile Weaving&Dyeing Co,.LTD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(86,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6E9359D43BE8766EE0530100007F30EF', Name='Jiangyan Chemical Dyestuff Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(87,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='82C543BC932478D5E0530100007F4ED3', Name='Jiashan changYing Meticulous chemical Industry CO.,LTD.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(88,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B4714CD28BCB716AE0530100007FBADA', Name='Jinjiang Anhai Heng Tai Tannery Co Ltd', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(89,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='845A807FDE5125A7E0530100007F83E1', Name='Ju Jing Chemical Co.,Ltd', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(90,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9BB52CFA80564DD2E0530100007FFD58', Name='KANN ENDUSTRI MUHENDISLIK', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(91,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='90426863F26007D1E0530100007F7DA8', Name='Kemin Quimica Textil do Brasil Ltda', Address_from_ZDHC__c='Rua Libano, 54 E, Sala 301', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(92,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9980AA535CF23BD4E0530100007FE2F8', Name='KIRAN GLOBAL CHEMS LIMITED.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(93,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='97CBAE7BBA362F74E0530100007F47FC', Name='Kpr Proceessing Mill', Address_from_ZDHC__c='NN3, 5th cross road, Sipcot, Perundurai, Erode', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(94,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9FD55FA09BC704CDE0530100007F23BC', Name='KYUNGJIN TEXTILE., CO LTD', Address_from_ZDHC__c='66, Dadae-ro 170beon-gil, Saha-gu, Busan, Republic of Korea', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(95,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='88E578D1C3970CF6E0530100007FA3FE', Name='Lang fang OREDE ChemicalCo.,Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(96,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F02029D77C05E0530100007F79BD', Name='Lego Group', Address_from_ZDHC__c='Aastvej 1', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(97,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F0202A1A7C05E0530100007F79BD', Name='Link Real Estate Investment Trust', Address_from_ZDHC__c='33/F., AXA Tower, Landmark East, 100 How Ming Street, Kwun Tong, Kowloon, Hong Kong', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(98,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='CE23BC7017A82B05E0530100007F1FA4', Name='LOTUS TEXTILE & GARMENT CO., LTD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(99,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B473C1EE44964E01E0530100007F907E', Name='M/s. K. Md. Mohibullah & Co.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(100,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9C93387959783486E0530100007F211B', Name='Man Group plc', Address_from_ZDHC__c='at Riverbank House, 2 Swan Lane, London', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(101,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='449B9DEE1A8C0819E0530100007F3620', Name='MAS Fabrics PVT Limited–Matrix', Address_from_ZDHC__c='10th Floor, Aitken Spence Tower 2, 315, Vauxhall Street, Colombo 02, Sri Lanka', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(102,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6EEB9EE1274B6898E0530100007F49A4', Name='Medici Antonio S.r.l', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(103,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='A03308C9A174566DE0530100007F6FEB', Name='Mettler-Toledo International Inc.', Address_from_ZDHC__c='In Langacher 55', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(104,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='7273DFCB164A0420E0530100007FE62A', Name='Mistral Srl', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(105,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='775EC5C62B9671DBE0530100007F819F', Name='Motherland Garments Pvt. Ltd.', Address_from_ZDHC__c='NA', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(106,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='61C5E0A4686B2E54E0530100007F8994', Name='N.A.Z Bangladesh Ltd.', Address_from_ZDHC__c='5, Bishuya Kuribari, Mirzapur, Gazipur-1700, Bangladesh', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(107,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5D88E756EAFB430DE0530100007F9AC1', Name='Nantong Rising', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(108,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='60983189EFA80FE7E0530100007F1B5B', Name='Netherfield Mills', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(109,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='66F4923A277F10DEE0530100007F425B', Name='Nien Hsing Textile Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(110,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='87F33003BFB71D91E0530100007FBAAA', Name='Ningbo yinzhou landi trading co. LTD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(111,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9CBCE90F6C487E04E0530100007F7384', Name='Novachem S. De R.L. De C.V.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(112,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F0202CD07C05E0530100007F79BD', Name='OE SOLUTIONS', Address_from_ZDHC__c='53, Cheomdanyeonsin-ro 30beon-gil, Buk-gu, Gwangju, Republic of Korea', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(113,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D4E67ECC543B7164E0530100007F83B9', Name='Orient Craft Limited Unit J1 Ranchi', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(114,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6096DD6A1464270AE0530100007F18C8', Name='Oztek Tekstil Terbiye Tesisleri San. Tic A.S', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(115,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='7844809CBB361EE0E0530100007F22BE', Name='Parisini Pelletterie srl', Address_from_ZDHC__c='VIA DELL\'INCISORE, 9\n40138', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(116,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='791E4B26CA8D5D1DE0530100007FD303', Name='Pettenati S/A Industria Textil - Filial 05', Address_from_ZDHC__c='BR 116 KM 173 S/N', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(117,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9CE2F4189FA11D05E0530100007F7756', Name='POLAR GOOSE CLOTHING CO.,LTD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(118,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6D3FA46AE4F30BEBE0530100007F8830', Name='Pretty Sweaters Ltd                                                                                 ', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(119,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='62D0C5970B9936DBE0530100007F2077', Name='PROSYNTEX, S.A.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(120,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='773BA3FF579B110DE0530100007F8F19', Name='PT. Bozzetto Indonesia', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(121,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B2154D2563436E80E0530100007FE7C2', Name='Pulcra Chemicals, S.L.', ZDHC_Supplier_AID__c='A777KZ94', Address_from_ZDHC__c='Polígono Industrial San Vicente, s/n', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(122,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='97F02E4268127C15E0530100007F4C5B', Name='QINGHE BOXIN CASHMERE CO.,LTD', Address_from_ZDHC__c='清河县浦江街69号', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(123,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8ADCA895919D3026E0530100007F04AF', Name='R.H Corporation -Shahriar Rasid', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(124,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='66F3382C5A8629B7E0530100007F1C3E', Name='Raymond UCO Denim Pvt. Ltd.', Address_from_ZDHC__c='Plot No - C-1;  M.I.D.C - Lohara; Yavatmal', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(125,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6B463CEAEFFD17EDE0530100007F5957', Name='Resas Chemie', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(126,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6093DFE9EC8D3781E0530100007FE57E', Name='Riverside Dyeworks', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(127,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='416685DBDF9777FFE0530100007F9205', Name='RUDOLF Atul Chemicals Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(128,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B1142E0F542A5467E0530100007FEB0A', Name='S.R. Chemical supply', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(129,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='CE23BC701A252B05E0530100007F1FA4', Name='Samdani Washing', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(130,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='B67DD16D4A294FCFE0530100007F0FB3', Name='SAPPHIRE TEXTILE MILLS LIMITED', Address_from_ZDHC__c='1.5 KM Ferozwattoan, Warburton Road Sheikhupura', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(131,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='CE23BC701A502B05E0530100007F1FA4', Name='SCINTAN INDIA PVT LTD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(132,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A8CE1DF10F65052E0530100007FFCCF', Name='Serix Industrial Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(133,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9863F9D7B4CA3E8BE0530100007F890A', Name='SHALIBHADRA DYECHEM PVT.LTD', Address_from_ZDHC__c='12 ,IST FLOOR,New cloth Market', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(134,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8614D019681E4C96E0530100007F95C9', Name='Shanghai Chuang Feng special resin Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(135,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='7E76598DF53B3439E0530100007F8029', Name='Shanghai Ningbo', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(136,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='97C1B23EE34C19B5E0530100007FB179', Name='Shanghai Yiqiao Industry and Trade Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(137,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='A3528BD6FABF1967E0530100007FFD24', Name='SHAOXING JINDESHENG FASHION CO., LTD', Address_from_ZDHC__c='XieTang Town Industrial Park,Shangyu City', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(138,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5D9C762C1C7522EAE0530100007F1C24', Name='Sheng Zheng Guo feng da', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(139,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='76D55F8E379759CDE0530100007F72FB', Name='SHIMTRADING CO.,LTD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(140,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='54013893EDD747F6E0530100007F8A01', Name='Shuang-Bang Ind. Corp.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(141,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='A9C1F3C1BB0E7D57E0530100007FDE03', Name='Sinateks Tekstil San. Tic. A.S.', Address_from_ZDHC__c='Barakfakih Mah. 22. Cad. 15/A Kestel, Bursa', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(142,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='6D7C13F0E7881597E0530100007F0453', Name='Smily Chem Plus', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(143,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='4CDE5F6F15E1416FE0530100007F256A', Name='Son Hong Ngan Chemical Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(144,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F020319B7C05E0530100007F79BD', Name='Sponda Plc', Address_from_ZDHC__c='Korkeavuorenkatu 45', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(145,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='BBE7A58C81D427B8E0530100007F5462', Name='Star Garment (Pvt) Limited', Address_from_ZDHC__c='PO Box 1, Ring Road 2, Phase 1, Investment Promotion Zone, Katunayake.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(146,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='92D7A1DC48D1563CE0530100007F8A51', Name='SUMINISTROS Y DESARROLLOS QUIMICOS, S. DE R.L. DE C.V.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(147,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='674283E762183E79E0530100007F426A', Name='Sunwhite', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(148,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8999D35BE5491491E0530100007F2EA3', Name='SUZHOU DILANG TEXTILE CO., LTD', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(149,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F020327D7C05E0530100007F79BD', Name='Svenska Handelsbanken', Address_from_ZDHC__c='Grevgränd 3\n106 70 Stockholm', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(150,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D5FEC4A52981271CE0530100007F1179', Name='Tackifire6', Address_from_ZDHC__c='India', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(151,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='67310FC316B5036EE0530100007F0AC9', Name='Tai Yuen Textile Co., Ltd. - (Hsinchu)', Address_from_ZDHC__c='No.416, Zhongshan Road, Zhubei, Hsinchu, TAIWAN, R.O.C.\n', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(152,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='886DE6FCF1E512C0E0530100007FD9B2', Name='Tan Binh 2 Chemical Factory', Address_from_ZDHC__c='No.5 Street, 1st Bien Hoa Industrical Zone, Dong Nai Province.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(153,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='82C0D83485DB09E1E0530100007F8230', Name='Tatrasvit Svit Socks', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(154,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D5FEC4A526F8271CE0530100007F1179', Name='Tenergy30', Address_from_ZDHC__c='India', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(155,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D5DAD81442BE3CD1E0530100007F3EA1', Name='Tested', Address_from_ZDHC__c='string', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(156,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='873EF3A1B083579BE0530100007F61D3', Name='TF HOLDINGS CORPORATION LIMITED', Address_from_ZDHC__c='Unit 1107 11/F Global Gateway Tower No.63 Wing Hong Street Cheung Sha Wan Kowloon HK', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(157,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='82C11A278F8B42A3E0530100007F1C8E', Name='Thevenon', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(158,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F02033AE7C05E0530100007F79BD', Name='Times Microwave Systems', Address_from_ZDHC__c='358 Hall Avenue ', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(159,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='A019D3F8C26B1F13E0530100007F5126', Name='TOKYO HANDLOOM INDUSTRIES', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(160,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F02033FC7C05E0530100007F79BD', Name='TOYO INK ARETS NV', Address_from_ZDHC__c='Tunnelweg 3', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(161,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9152E179DCC466CDE0530100007FC954', Name='TRUMPLER ITALIA S.R.L.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(162,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='60E5AF60427C314EE0530100007F7761', Name='TY Fashion (Cambodia) Plc', Address_from_ZDHC__c='National Road No.51 , Srah Po Village, Phsardek Commune, Ponhealeu District, Kandal Province,Cambodia.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(163,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='7397AF93ED4F3371E0530100007F1C26', Name='Unilever Singapore', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(164,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='66F5A74CFC246405E0530100007FC87B', Name='US Apparel (Pvt) Ltd - Unit 05', Address_from_ZDHC__c='3 KM, Off Bhoptian Chowk, Raiwind Road, Lahore\n', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(165,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='87E8040680263BBCE0530100007FD3E3', Name='Velvetol NYST', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(166,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='97FBD4F849156905E0530100007FD7AE', Name='Vinh Ha Company', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(167,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='AB8171AEF9B410A9E0530100007F4302', Name='Vogue Sourcing', Address_from_ZDHC__c='2 City approach', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(168,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5E85A46274BB3938E0530100007F8AA8', Name='Wei Yi Dyeing & Finishing', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(169,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9CA82C2461386BABE0530100007F7C8C', Name='WHEELS HOLDCO INC', Address_from_ZDHC__c='1280 Courtneypark Drive East', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(170,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='76322F457E6A3372E0530100007F1910', Name='Wuhan Well Sailing Industry and Trade Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(171,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5C525686269E1298E0530100007F947C', Name='WUXI DOUBLE ELEPHANT MICRO FIBRE MATERIAL CO., LTD.', Address_from_ZDHC__c='wuxishi houzhaizhonglu188', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(172,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='7E0DA640555F1B6FE0530100007F5348', Name='Xiamen Dabang Ruida Printing Material Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(173,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5F2C235858F01D4EE0530100007FD8FF', Name='Xuchuan Chemical(Suzhou)Co.,Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(174,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='D5FEE6AD69342DFDE0530100007F9BD6', Name='Yasaka54', Address_from_ZDHC__c='China', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(175,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='7AB4DFC7A3DA52ADE0530100007FF303', Name='YIXING BAILI TEXTILE DYEING & FINISHING', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(176,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='543E55B8FFE42C13E0530100007F002C', Name='Youngor Sunrise (Sunrise (Shengzhou) Textiles Co., Ltd.)', Address_from_ZDHC__c='No. 1 West Section Yinxian Road Ningbo', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(177,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='94D6F97544E81077E0530100007F78E8', Name='ZDHC Supplier', Address_from_ZDHC__c='Bruxelles Capitale Evere, Belgium', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(178,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='9281631729E67F0CE0530100007FFD4B', Name='Zhangjiagang Hongda Additive Chemicals Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(179,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='8537C999C87A059AE0530100007F48E5', Name='ZHEJIANG GUANDONG PRINTING DYEING & GARMENTS CO LTD.', Address_from_ZDHC__c='No. #1, Guandong Road, Chengbei Development Zone, Shengzhou, Shaoxing, Zhejiang, China', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(180,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='A814FE3870CA12FDE0530100007F3C7A', Name='Zhejiang Namei Material Technology Co., Ltd.', ZDHC_Supplier_AID__c='A129BR12', Address_from_ZDHC__c='Beishan industrial park，Xiaoyuan district，Anji .', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(181,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='85D8D6041E0C6FBAE0530100007F3BC2', Name='ZheJiang ZhenGuang Tech Co., Ltd.', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(182,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5FBAF4A19B7E5056E0530100007F64BA', Name='Zhou Kou Heng Tong chemical Co.,Ltd', ZDHC_Supplier_AID__c='A391EA16', Address_from_ZDHC__c='south developing area', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(183,facilities)].Id),
      new Formulator__c(ZDHC_Formulator_GUID__c='5A01F020370C7C05E0530100007F79BD', Name='福彬新科化学有限公司', ZDHC_Supplier_AID__c='A266YI85', Origin__c='ZDHC Gateway', Created_By__c=facility[Math.mod(184,facilities)].Id)
    };
    insert formulators;
  }
}