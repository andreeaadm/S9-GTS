// Test Data Factory for Brand_Supplier_Connection__c objects

@IsTest
public with sharing class TC_TestDataFactory_Connections {
  public static List<Brand_Supplier_Connection__c> insertActiveConnections(
    Integer count,
    Account brand,
    Account supplier,
    Contact requestorContact,
    String connectionStatus
  ) {
    List<Brand_Supplier_Connection__c> brandsToReturn = new List<Brand_Supplier_Connection__c>();

    for (Integer i = 0; i < count; i++) {
      brandsToReturn.add(
        create(brand, supplier, requestorContact, connectionStatus)
      );
    }

    insert brandsToReturn;
    return brandsToReturn;
  }

  /*
   * Returns a single brand supplier connection with specified values for fields
   */
  public static Brand_Supplier_Connection__c create(
    Account brand,
    Account supplier,
    Contact requestorContact,
    String status
  ) {
    return create(brand.Id, supplier.Id, requestorContact.Id, status, null);
  }

  /*
   * Returns a single brand supplier connection with specified values for fields
   */
  public static Brand_Supplier_Connection__c create(
    Account brand,
    Account supplier,
    Contact requestorContact,
    String status,
    Decimal conformanceTarget
  ) {
    return create(
      brand.Id,
      supplier.Id,
      requestorContact.Id,
      status,
      conformanceTarget
    );
  }

  /*
   * Returns a single brand supplier connection with specified values for fields
   */
  public static Brand_Supplier_Connection__c create(
    Id brandId,
    Id supplierId,
    Contact requestorContact,
    String status
  ) {
    return create(brandId, supplierId, requestorContact.Id, status, null);
  }

  /*
   * Returns a single brand supplier connection with specified values for fields
   */
  public static Brand_Supplier_Connection__c create(
    Id brandId,
    Id supplierId,
    Id requestorContactId,
    String status
  ) {
    return create(brandId, supplierId, requestorContactId, status, null);
  }

  /*
   * Returns a single brand supplier connection with specified values for fields
   */
  public static Brand_Supplier_Connection__c create(
    Id brandId,
    Id supplierId,
    Id requestorContactId,
    String status,
    Decimal conformanceTarget
  ) {
    Brand_Supplier_Connection__c connection = new Brand_Supplier_Connection__c(
      Brand_Account__c = brandId,
      Supplier_Account__c = supplierId,
      Requestor_Contact__c = requestorContactId,
      Status__c = status,
      Active__c = true,
      Supplier_Conformance_Target__c = conformanceTarget,
      Connection_Date__c = (status == 'Approved' ? Datetime.now() : null),
      Disconnection_Date__c = (status == 'Disconnected'
        ? Datetime.now()
        : null),
      Disconnected_By__c = (status == 'Disconnected'
        ? requestorContactId
        : null),
      Rejected_By__c = (status == 'Rejected' ? requestorContactId : null)
    );

    return connection;
  }

  List<Brand_Supplier_Connection__c> brandsSuppliers;

  public TC_TestDataFactory_Connections() {
    brandsSuppliers = [
      SELECT
        Active__c,
        Brand_Account__c,
        Brand_Name__c,
        Connection_Date__c,
        CreatedById,
        CreatedDate,
        CurrencyIsoCode,
        Disconnected_By__c,
        Disconnection_Date__c,
        Id,
        IsDeleted,
        LastActivityDate,
        LastModifiedById,
        LastModifiedDate,
        LastReferencedDate,
        LastViewedDate,
        Name,
        OwnerId,
        Rejected_By_Name__c,
        Rejected_By__c,
        Requestor_Account__c,
        Requestor_Contact_Name__c,
        Requestor_Contact__c,
        Status__c,
        Supplier_Account__c,
        Supplier_Conformance_Target__c,
        Supplier_Name__c,
        SystemModstamp
      FROM Brand_Supplier_Connection__c
      ORDER BY Id ASC
    ];
  }

  public TC_TestDataFactory_Connections(
    TC_TestDataFactory_Accounts tdfa,
    TC_TestDataFactory_Contacts tdfc
  ) {
    this(tdfa, tdfc, new List<String>{ '88.88', '50', '100', '25.99', '11' });
  }

  public TC_TestDataFactory_Connections(
    TC_TestDataFactory_Accounts tdfa,
    TC_TestDataFactory_Contacts tdfc,
    List<String> conformanceTarget
  ) {
    Integer conformanceIndex = 0;
    brandsSuppliers = new List<Brand_Supplier_Connection__c>{
      create(
        tdfa.brands[0],
        tdfa.suppliers[0],
        TC_TestDataFactory_Contacts.findForAcount(
          tdfc.supplierAdminContacts,
          tdfa.suppliers[0]
        ),
        'Approved',
        Decimal.valueOf(
          conformanceTarget[
            Math.mod(conformanceIndex++, conformanceTarget.size())
          ]
        )
      )
    };
    if (tdfa.suppliers.size() > 1) {
      brandsSuppliers.add(
        create(
          tdfa.brands[0],
          tdfa.suppliers[1],
          TC_TestDataFactory_Contacts.findForAcount(
            tdfc.supplierStdContacts,
            tdfa.suppliers[1]
          ),
          'Approved',
          Decimal.valueOf(
            conformanceTarget[
              Math.mod(conformanceIndex++, conformanceTarget.size())
            ]
          )
        )
      );
    }
    if (tdfa.suppliers.size() > 2) {
      brandsSuppliers.add(
        create(
          tdfa.brands[0],
          tdfa.suppliers[2],
          TC_TestDataFactory_Contacts.findForAcount(
            tdfc.supplierAdminContacts,
            tdfa.suppliers[2]
          ),
          'Requested',
          Decimal.valueOf(
            conformanceTarget[
              Math.mod(conformanceIndex++, conformanceTarget.size())
            ]
          )
        )
      );
    }
    if (tdfa.suppliers.size() > 3) {
      brandsSuppliers.add(
        create(
          tdfa.brands[0],
          tdfa.suppliers[3],
          TC_TestDataFactory_Contacts.findForAcount(
            tdfc.supplierStdContacts,
            tdfa.suppliers[3]
          ),
          'Disconnected',
          Decimal.valueOf(
            conformanceTarget[
              Math.mod(conformanceIndex++, conformanceTarget.size())
            ]
          )
        )
      );
    }
    if (tdfa.suppliers.size() > 4) {
      brandsSuppliers.add(
        create(
          tdfa.brands[0],
          tdfa.suppliers[4],
          TC_TestDataFactory_Contacts.findForAcount(
            tdfc.supplierAdminContacts,
            tdfa.suppliers[4]
          ),
          'Rejected',
          Decimal.valueOf(
            conformanceTarget[
              Math.mod(conformanceIndex++, conformanceTarget.size())
            ]
          )
        )
      );
    }
    insert brandsSuppliers;
  }
}