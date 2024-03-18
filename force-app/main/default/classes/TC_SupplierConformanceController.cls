public with sharing class TC_SupplierConformanceController {
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getSupplierConformanceByMonth(
    String selectedMonth
  ) {
    Map<String, Object> responseMap = new Map<String, Object>();
    DataTable.Table tableData = new DataTable.Table();
    String currentMonth =
      getMonthString(Date.today().month(), false) +
      ' ' +
      String.valueOf(Date.today().year());
    responseMap.put('currentMonth', currentMonth);

    selectedMonth = !String.isBlank(selectedMonth)
      ? selectedMonth
      : currentMonth;

    try {
      // Create a list of dateOptions (current and previous 23 months in MMMM - YYYY format)
      responseMap.put('dateOptions', getInventoryDateOptions());

      // get the current logged in user account
      User currentUser = UserUtil.getUserDetails(UserInfo.getUserId());

      // Get all Active and Approved connections with the logged in Brand
      List<Brand_Supplier_Connection__c> connections = [
        SELECT
          Id,
          Supplier_Account__c,
          Supplier_Account__r.Name,
          Supplier_Conformance_Target__c,
          Brand_Account__r.General_Supplier_Conformance_Target__c
        FROM Brand_Supplier_Connection__c
        WHERE
          Supplier_Account__r.ToxClear_Subscription_Status__c = 'Active'
          AND Status__c = 'Approved'
          AND Brand_Account__c = :currentUser.Contact.AccountId
          AND Active__c = TRUE
          AND Brand_Supplier_Connection__c.Supplier_Account__r.Is_ToxClear_Account__c = true
        ORDER BY Supplier_Account__r.Name ASC
      ];

      // Build a map from Supplier Id to their Conformance Target
      Map<Id, Decimal> supplierIdToConformanceTargetMap = new Map<Id, Decimal>();
      Map<Id, String> supplierIdToSupplierNameMap = new Map<Id, String>();
      for (Brand_Supplier_Connection__c bsc : connections) {
        supplierIdToConformanceTargetMap.put(
          bsc.Supplier_Account__c,
          bsc.Supplier_Conformance_Target__c != null
            ? bsc.Supplier_Conformance_Target__c
            : bsc.Brand_Account__r.General_Supplier_Conformance_Target__c
        );
        supplierIdToSupplierNameMap.put(
          bsc.Supplier_Account__c,
          bsc.Supplier_Account__r.Name
        );
      }

      // Build a map from Supplier Id to their Conformance / Non-Conformance
      Map<Id, Map<Boolean, Integer>> supplierIdToConformanceMap = new Map<Id, Map<Boolean, Integer>>();
      for (Inventory_Line_Item__c lineItem : [
        SELECT
          Id,
          Conformant__c,
          Inventory__r.Facility__c,
          Inventory__r.Inventory_Month__c,
          Inventory__r.Facility__r.ParentId
        FROM Inventory_Line_Item__c
        WHERE
          Inventory__r.Facility__r.ParentId IN :supplierIdToConformanceTargetMap.keyset()
          AND Inventory__r.Facility__r.Is_ToxClear_Account__c = true
          AND Inventory__r.Inventory_Month__c = :selectedMonth
          AND Commodity_Chemical_Standard_Name__c = null
      ]) {
        Map<Boolean, Integer> conformanceMapForFacility = new Map<Boolean, Integer>{
          true => 0,
          false => 0
        };
        if (
          supplierIdToConformanceMap.containsKey(
            lineItem.Inventory__r.Facility__r.ParentId
          )
        ) {
          conformanceMapForFacility = supplierIdToConformanceMap.get(
            lineItem.Inventory__r.Facility__r.ParentId
          );
        } else {
          supplierIdToConformanceMap.put(
            lineItem.Inventory__r.Facility__r.ParentId,
            conformanceMapForFacility
          );
        }
        Integer count = conformanceMapForFacility.get(lineItem.Conformant__c);
        conformanceMapForFacility.put(lineItem.Conformant__c, count + 1);
        supplierIdToConformanceMap.put(
          lineItem.Inventory__r.Facility__r.ParentId,
          conformanceMapForFacility
        );
      }

      // Now we have all our data mapped out, turn it into a DataTable.Table
      tableData.rows = buildTableRows(
        supplierIdToSupplierNameMap,
        supplierIdToConformanceTargetMap,
        supplierIdToConformanceMap
      );
      tableData.columns = new List<DataTable.Column>{
        new DataTable.Column('Supplier', Label.Supplier),
        new DataTable.Column('Target', Label.Target),
        new DataTable.Column('Actual', Label.Actual)
      };
      responseMap.put('table', tableData);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return responseMap;
  }

  private static List<DataTable.Row> buildTableRows(
    Map<Id, String> supplierIdToSupplierNameMap,
    Map<Id, Decimal> supplierIdToConformanceTargetMap,
    Map<Id, Map<Boolean, Integer>> supplierIdToConformanceMap
  ) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Id i : supplierIdToConformanceMap.keyset()) {
      Map<Boolean, Integer> conformanceMap = supplierIdToConformanceMap.get(i);
      Decimal target = supplierIdToConformanceTargetMap.get(i);
      Integer targetScale = Brand_Supplier_Connection__c.Supplier_Conformance_Target__c.getDescribe()
        .getScale();
      Integer conformant = conformanceMap.get(true);
      Integer nonConformant = conformanceMap.get(false);
      Decimal total = conformant + nonConformant;
      Decimal actual = ((conformant / total) * 100).setScale(targetScale);
      String targetString = String.valueOf(target);
      DataTable.Row row = new DataTable.Row(
        i,
        new List<DataTable.Cell>{
          new DataTable.Cell(
            'supplier',
            supplierIdToSupplierNameMap.get(i),
            Label.Supplier
          ),
          new DataTable.Cell(
            'target',
            String.isNotBlank(targetString) ? targetString + '%' : targetString,
            Label.Target
          ),
          new DataTable.Cell(
            'actual',
            String.valueOf(actual) + '%',
            Label.Actual,
            actual >= target ? 'green' : 'red'
          )
        }
      );
      rows.add(row);
    }
    return rows;
  }

  @TestVisible
  private static String getMonthString(Integer month, Boolean translate) {
    switch on month {
      when 1 {
        return translate ? Label.January : 'January';
      }
      when 2 {
        return translate ? Label.February : 'February';
      }
      when 3 {
        return translate ? Label.March : 'March';
      }
      when 4 {
        return translate ? Label.April : 'April';
      }
      when 5 {
        return translate ? Label.May : 'May';
      }
      when 6 {
        return translate ? Label.June : 'June';
      }
      when 7 {
        return translate ? Label.July : 'July';
      }
      when 8 {
        return translate ? Label.August : 'August';
      }
      when 9 {
        return translate ? Label.September : 'September';
      }
      when 10 {
        return translate ? Label.October : 'October';
      }
      when 11 {
        return translate ? Label.November : 'November';
      }
      when 12 {
        return translate ? Label.December : 'December';
      }
      when else {
        return null;
      }
    }
  }

  private static List<Map<String, String>> getInventoryDateOptions() {
    List<Map<String, String>> dateOptions = new List<Map<String, String>>();
    for (Integer i = 0; i > -24; i--) {
      Date adjustedDate = Date.today().addMonths(i);
      String dateOption =
        getMonthString(adjustedDate.month(), false) +
        ' ' +
        String.valueOf(adjustedDate.year());
      String dateOptionTranslated =
        getMonthString(adjustedDate.month(), true) +
        ' ' +
        String.valueOf(adjustedDate.year());
      dateOptions.add(
        new Map<String, String>{
          'label' => dateOptionTranslated,
          'value' => dateOption
        }
      );
    }
    return dateOptions;
  }
}