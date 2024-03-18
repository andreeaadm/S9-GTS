public with sharing class iCare_TrackJobsController {
  public class Request {
    @AuraEnabled
    public String tableName { get; set; }
    @AuraEnabled
    public Integer recordLimit { get; set; }
    @AuraEnabled
    public Boolean isReport { get; set; }
    @AuraEnabled
    public Integer daysToSearch { get; set; }
    @AuraEnabled
    public Date startDate { get; set; }
    @AuraEnabled
    public Date endDate { get; set; }
    @AuraEnabled
    public Integer vOffset { get; set; }
    @AuraEnabled
    public Integer vPagesize { get; set; }
    @AuraEnabled
    public Boolean pagination { get; set; }
    @AuraEnabled
    public String recordTypeId { get; set; }
  }

  public static List<iCare_Job__c> getJobs(
    Request request,
    List<iCare_Track_Jobs_Table__mdt> tableComponentMetadata
  ) {
    String strStatusFilter = '';
    String strDateFilter = '';
    String strOffsetQuery = '';
    String selectQuery = 'SELECT ';
    String fromQuery = ' FROM iCare_Job__c';
    String orderByQuery = ' ORDER BY iCare_Date_Time__c DESC NULLS LAST LIMIT ';
    Date endDate = request.endDate;
    Date startDate = request.startDate;
    String recordTypeFilter = '';
    String recordTypeId = request.recordTypeId;

    String timeStampWhereString = 'Test Report Issued';
    List<String> filterStatuses = new List<String>{
      'Test Report Issued',
      'Cancelled'
    };

    if (
      request.tableName == 'GTS Completed Jobs' ||
      request.tableName == 'GTS Updated Jobs'
    ) {
      orderByQuery = ' ORDER BY iCare_Last_Job_Timestamp_Date__c DESC NULLS LAST LIMIT ';
    }

    // get offset
    if (
      request.vOffset != null &&
      request.vPageSize != null &&
      request.pagination
    ) {
      strOffsetQuery = ' OFFSET ' + request.vOffset;
      request.recordLimit = request.vPageSize;
    }

    // get fields for select
    selectQuery =
      selectQuery +
      getFieldString(
        getTableComponentMetadata(request.tableName, 'Searchable-Field')
      );
    selectQuery = selectQuery + ',';
    selectQuery = selectQuery + getFieldString(tableComponentMetadata);
    String statusString = 'Complete';

    if (request.tableName == 'View Reports') {
      strStatusFilter = ' WHERE iCare_Job_Status__c IN:filterStatuses';
    } else if (request.tableName == 'GTS Completed Jobs') {
      strStatusFilter = ' WHERE iCare_Job_Status__c =:statusString';
    } else if (request.tableName == 'GTS Updated Jobs') {
      strStatusFilter = ' WHERE iCare_Job_Status__c !=:statusString';
    }

    // filter on dates
    if (request.startDate != null || request.endDate != null) {
      if (request.startDate != null && request.endDate != null) {
        strDateFilter = '  iCare_Date_Time__c >= :startDate AND iCare_Date_Time__c <= :endDate ';
      } else if (request.startDate != null) {
        strDateFilter = '  iCare_Date_Time__c >=  :startDate ';
      } else if (request.endDate != null) {
        strDateFilter = '  iCare_Date_Time__c <= :endDate ';
      }
    } else if (request.daysToSearch != null && request.daysToSearch != 0) {
      strDateFilter =
        '  iCare_Date_Time__c = LAST_N_DAYS: ' + request.daysToSearch;
    }

    if (strDateFilter != '') {
      if (strStatusFilter == '') {
        strDateFilter = ' WHERE ' + strDateFilter;
      } else {
        strDateFilter = ' AND ' + strDateFilter;
      }
    }

    if (request.recordTypeId != null) {
      recordTypeFilter = ' RecordTypeId= :recordTypeId';

      if (strDateFilter == '') {
        recordTypeFilter = ' WHERE ' + recordTypeFilter;
      } else {
        recordTypeFilter = ' AND ' + recordTypeFilter;
      }
    }

    System.debug(
      selectQuery +
      fromQuery +
      strStatusFilter +
      strDateFilter +
      recordTypeFilter +
      orderByQuery +
      request.recordLimit +
      strOffsetQuery
    );

    List<iCare_Job__c> lstJobs = Database.query(
      String.escapeSingleQuotes(selectQuery) +
      String.escapeSingleQuotes(fromQuery) +
      String.escapeSingleQuotes(strStatusFilter) +
      String.escapeSingleQuotes(strDateFilter) +
      String.escapeSingleQuotes(recordTypeFilter) +
      String.escapeSingleQuotes(orderByQuery) +
      request.recordLimit +
      String.escapeSingleQuotes(strOffsetQuery)
    );

    return lstJobs;
  }

  public static String getFieldString(
    List<iCare_Track_Jobs_Table__mdt> tableComponentMetadata
  ) {
    String fields = '';
    String timestamp = '';
    for (iCare_Track_Jobs_Table__mdt tableComponent : tableComponentMetadata) {
      if (tableComponent.Column_Field_Tabs__c == 'iCare_Job_Status_Portal__c') {
        fields =
          fields + 'toLabel(iCare_Job_Status_Portal__c) translatedStatus,';
      } else if (
        tableComponent.Column_Field_Tabs__c == 'iCare_Job_Outcome__c'
      ) {
        fields = fields + 'toLabel(iCare_Job_Outcome__c) translatedOutcome,';
      } else if (
        tableComponent.Column_Field_Tabs__c == 'iCare_Job_Timestamp__c'
      ) {
        String timeStampWhereString = 'Test Report Issued';
        timeStamp = ', (SELECT Id, iCare_Job_Timestamp__c from Job_Timestamps__r WHERE iCare_Job_Status__c = :timeStampWhereString ORDER BY iCare_Job_Timestamp__c LIMIT 1) ';
        break;
      }
      fields = fields + tableComponent.Column_Field_Tabs__c + ', ';
    }

    return fields.removeEnd(', ') + timestamp;
  }

  @AuraEnabled
  public static Integer totalRecords(Request request) {
    List<iCare_Track_Jobs_Table__mdt> tableComponentMetadata = getTableComponentMetadata(
      request.tableName,
      'Table'
    );

    request.recordLimit = 5000;

    return getJobs(request, tableComponentMetadata) != null
      ? getJobs(request, tableComponentMetadata)?.size()
      : 0;
  }

  @AuraEnabled(cacheable=true)
  public static Integer getNext(Integer v_Offset, Integer v_pagesize) {
    v_Offset += v_pagesize;
    return v_Offset;
  }

  @AuraEnabled(cacheable=true)
  public static Integer getPrevious(Integer v_Offset, Integer v_pagesize) {
    v_Offset -= v_pagesize;
    return v_Offset;
  }

  public static List<DataTableColumns> getTableColumns(
    List<iCare_Track_Jobs_Table__mdt> tableComponentMetadata
  ) {
    List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();

    for (iCare_Track_Jobs_Table__mdt tableComponent : tableComponentMetadata) {
      String label = tableComponent.Column_Field_Tabs__c;
      string location = tableComponent.iCare_Portal_Location__c;
      DataTableColumns dataColumn;
      try {
        label = System.Label.get('', tableComponent.Label__c);
      } catch (Exception e) {
        System.debug(e);
        label = tableComponent.Column_Field_Tabs__c;
      }
      if (
        tableComponent.Column_Field_Tabs__c == 'iCare_Date_Time__c' ||
        tableComponent.Column_Field_Tabs__c == 'iCare_Job_Timestamp__c' ||
        tableComponent.Column_Field_Tabs__c ==
        'iCare_Last_Job_Timestamp_Date__c'
      ) {
        dataColumn = new DataTableColumns(
          label,
          tableComponent.Column_Field_Tabs__c
        );
        dataColumn.type = 'date';
        dataColumn.sortable = 'true';
        String timezone = UserInfo.getTimeZone().getID();
        TypeAttributes ta = new TypeAttributes(
          'numeric',
          'numeric',
          'numeric',
          '2-digit',
          '2-digit',
          timezone
        );
        dataColumn.typeAttributes = ta;
      } else if (
        tableComponent.Column_Field_Tabs__c == 'iCare_Job_Hyperlink__c' ||
        tableComponent.Column_Field_Tabs__c == 'GTS_RFI_Number__c'
      ) {
        dataColumn = new DataTableColumns(label, 'LinkUrl');
        dataColumn.type = 'url';
        Label attributeLabel = new Label('LinkLabel');
        TypeAttributes ta = new TypeAttributes(attributeLabel, '_self');
        dataColumn.typeAttributes = ta;
        if (location.contains('GTS Track Jobs')) {
          dataColumn.sortable = 'true';
        }
      } else if (
        tableComponent.Column_Field_Tabs__c == 'iCare_Testing_Location__r.Name'
      ) {
        dataColumn = new DataTableColumns(label, 'LabName');
      } else if (
        tableComponent.Column_Field_Tabs__c == 'iCare_Job_Outcome__c'
      ) {
        dataColumn = new DataTableColumns(label, 'translatedOutcome');
      } else if (
        tableComponent.Column_Field_Tabs__c == 'iCare_Job_Status_Portal__c'
      ) {
        dataColumn = new DataTableColumns(label, 'translatedStatus');
      } else {
        dataColumn = new DataTableColumns(
          label,
          tableComponent.Column_Field_Tabs__c
        );
        if (location.contains('GTS Track Jobs')) {
          dataColumn.sortable = 'true';
        }
      }

      lstDataColumns.add(datacolumn);
    }
    return lstDataColumns;
  }

  public static List<ContainerTabs> getTabs(
    List<iCare_Track_Jobs_Table__mdt> tableComponentMetadata
  ) {
    List<ContainerTabs> lstContainerTabs = new List<ContainerTabs>();

    for (iCare_Track_Jobs_Table__mdt tableComponent : tableComponentMetadata) {
      String label = tableComponent.Column_Field_Tabs__c;

      ContainerTabs tab;
      try {
        label = System.Label.get('', tableComponent.Label__c);
      } catch (Exception e) {
        System.debug(e);
        label = tableComponent.Label__c;
      }

      tab = new ContainerTabs(
        label,
        tableComponent.Column_Field_Tabs__c,
        tableComponent.Order__c
      );

      lstContainerTabs.add(tab);
    }
    return lstContainerTabs;
  }

  @AuraEnabled(Cacheable=true)
  public static DataTableResponse getTableData(Request request) {
    //Request request = x;

    DataTableResponse finalWrapper = new DataTableResponse();

    List<iCare_Track_Jobs_Table__mdt> tableComponentMetadata = getTableComponentMetadata(
      request.tableName,
      'Table'
    );

    finalWrapper.lstDataTableColumns = getTableColumns(tableComponentMetadata);
    finalWrapper.lstJobRecords = getJobs(request, tableComponentMetadata);
    return finalWrapper;
  }

  @AuraEnabled(Cacheable=true)
  public static DataTableResponse getTabData(String tableName) {
    DataTableResponse finalWrapper = new DataTableResponse();

    List<iCare_Track_Jobs_Table__mdt> tableComponentMetadata = getTableComponentMetadata(
      tableName,
      'Container'
    );

    finalWrapper.lstContainerTabs = getTabs(tableComponentMetadata);

    return finalWrapper;
  }

  public static List<iCare_Track_Jobs_Table__mdt> getTableComponentMetadata(
    String tableName,
    String type
  ) {
    List<iCare_Track_Jobs_Table__mdt> tableComponentMetadata;

    try {
      tableComponentMetadata = [
        SELECT
          Column_Field_Tabs__c,
          Order__c,
          Label__c,
          iCare_Portal_Location__c
        FROM iCare_Track_Jobs_Table__mdt
        WHERE iCare_Portal_Location__c = :tableName AND Type__c = :type
        WITH SECURITY_ENFORCED
        ORDER BY Order__c
      ];
    } catch (System.QueryException qe) {
      System.debug(qe.getMessage());
    }
    return tableComponentMetadata;
  }

  @AuraEnabled
  public static List<String> checkRelatedCertificates(List<String> jobIds) {
    List<String> lstJobIds = new List<String>();

    List<GTS_Certificate__c> lstCertificates = [
      SELECT GTS_Job__c
      FROM GTS_Certificate__c
      WHERE GTS_Job__c IN :jobIds AND GTS_Job__c != NULL
      WITH SECURITY_ENFORCED
    ];

    for (GTS_Certificate__c certRec : lstCertificates) {
      lstJobIds.add(certRec.GTS_Job__c);
    }

    return lstJobIds;
  }

  public class Label {
    @AuraEnabled
    public String fieldName;
    public Label(String fieldName) {
      this.fieldName = fieldName;
    }
  }

  public class TypeAttributes {
    @AuraEnabled
    public String target;
    @AuraEnabled
    public Label label;
    @AuraEnabled
    public String weekday;
    @AuraEnabled
    public String year;
    @AuraEnabled
    public String month;
    @AuraEnabled
    public String day;
    @AuraEnabled
    public String hour;
    @AuraEnabled
    public String minute;
    @AuraEnabled
    public String second;
    @AuraEnabled
    public Boolean hour12;
    @AuraEnabled
    public String timeZone;

    public TypeAttributes(Label label, String target) {
      this.target = target;
      this.label = label;
    }
    public TypeAttributes(
      String day,
      String month,
      String year,
      String hour,
      String minute,
      String timeZone
    ) {
      this.year = year;
      this.month = month;
      this.day = day;
      this.hour = hour;
      this.minute = minute;
      this.second = second;
      this.hour12 = hour12;
      this.timeZone = timeZone;
    }
  }

  public class DataTableColumns {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String fieldName { get; set; }
    @AuraEnabled
    public String type;
    @AuraEnabled
    public String hideDefaultActions = 'false';
    @AuraEnabled
    public boolean wrapText = true;
    @AuraEnabled
    public TypeAttributes typeAttributes;
    @AuraEnabled
    public String sortable;

    public DataTableColumns(String label, String fieldName) {
      this.label = label;
      this.fieldName = fieldName;
    }
  }

  public class ContainerTabs {
    @AuraEnabled
    public String tabLabel { get; set; }
    @AuraEnabled
    public String value { get; set; }
    @AuraEnabled
    public Decimal key { get; set; }

    public ContainerTabs(String tabLabel, String value, Decimal key) {
      this.tabLabel = tabLabel;
      this.value = value;
      this.key = key;
    }
  }

  public class DataTableResponse {
    @AuraEnabled
    public List<DataTableColumns> lstDataTableColumns { get; set; }
    @AuraEnabled
    public List<iCare_Job__c> lstJobRecords { get; set; }
    @AuraEnabled
    public List<ContainerTabs> lstContainerTabs { get; set; }
  }
}