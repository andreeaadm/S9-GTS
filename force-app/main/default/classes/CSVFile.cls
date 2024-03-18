public with sharing class CSVFile {
  private String settingName;
  private Id parentId;
  @TestVisible
  private CSV_Import_Setting__mdt setting;
  @TestVisible
  private Schema.SObjectType sObjType;
  @TestVisible
  private Id recordTypeOverrideId;
  @TestVisible
  private Map<String, CSV_Import_Column__mdt> masterLabelToColumnDefinitionMap = new Map<String, CSV_Import_Column__mdt>();
  public Map<String, CSV_Import_Column__mdt> masterLabelToTemplateColumnsMap = new Map<String, CSV_Import_Column__mdt>();
  private Map<String, Schema.DescribeFieldResult> fieldMap = new Map<String, Schema.DescribeFieldResult>();
  @TestVisible
  private Map<Integer, String> importColumnIndexToLabelMap = new Map<Integer, String>();
  private List<List<String>> importRows = new List<List<String>>();
  private String base64 {
    get {
      return base64;
    }
    set {
      base64 = value;
      this.importRows = this.parseCSV(
        EncodingUtil.base64Decode(value).toString(),
        false
      );
    }
  }
  public CSVFile(String settingName, String base64, Id parentId) {
    this.settingName = settingName;
    this.parentId = parentId;
    List<CSV_Import_Setting__mdt> settings = new List<CSV_Import_Setting__mdt>(
      [
        SELECT
          DeveloperName,
          ObjectName__c,
          RecordTypeOverride__c,
          DMLStatement__c,
          AllowExtraColumns__c,
          ParentField__c,
          (
            SELECT
              MasterLabel,
              FieldName__c,
              Required__c,
              TemplateOnly__c,
              Hidden__c,
              DefaultValue__c,
              SortOrder__c
            FROM CSV_Import_Columns__r
            ORDER BY SortOrder__c ASC
          )
        FROM CSV_Import_Setting__mdt
        WHERE DeveloperName = :this.settingName
        LIMIT 1
      ]
    );
    this.setting = !settings.isEmpty() ? settings[0] : null;
    if (this.setting != null) {
      this.sObjType = Schema.getGlobalDescribe()
        .get(this.setting.ObjectName__c);
      for (
        Schema.SObjectField field : this.sObjType.getDescribe()
          .fields.getMap()
          .values()
      ) {
        Schema.DescribeFieldResult dfr = field.getDescribe();
        this.fieldMap.put(dfr.getName(), dfr);
      }
      if (this.setting.CSV_Import_Columns__r != null) {
        for (
          CSV_Import_Column__mdt column : this.setting.CSV_Import_Columns__r
        ) {
          masterLabelToColumnDefinitionMap.put(column.MasterLabel, column);
          if (!column.Hidden__c) {
            masterLabelToTemplateColumnsMap.put(column.MasterLabel, column);
          }
        }
      }
    }
    if (base64 != null) {
      this.base64 = base64;
    }
  }

  private List<List<String>> parseCSV(String contents, Boolean skipHeaders) {
    List<List<String>> allCsvRows = new List<List<String>>();
    // replace instances where a double quote begins a field containing a comma
    // in this case you get a double quote followed by a doubled double quote
    // do this for beginning and end of a field
    contents = contents.replaceAll(',"""', ',"DBLQT')
      .replaceall('""",', 'DBLQT",');
    // now replace all remaining double quotes - we do this so that we can reconstruct
    // fields with commas inside assuming they begin and end with a double quote
    contents = contents.replaceAll('""', 'DBLQT');
    // we are not attempting to handle fields with a newline inside of them
    // so, split on newline to get the spreadsheet rows
    List<String> lines = new List<String>();
    try {
      lines = contents.split('\n');
    } catch (System.ListException e) {
      System.debug('Limits exceeded? ' + e.getMessage());
    }
    for (String line : lines) {
      // check for blank CSV lines (only commas)
      if (line.replaceAll(',', '').trim().length() == 0)
        break;
      List<String> fields = line.split(',');
      List<String> cleanFields = new List<String>();
      String compositeField;
      Boolean makeCompositeField = false;
      for (String field : fields) {
        if (field.startsWith('"') && field.endsWith('"')) {
          cleanFields.add(
            field.replaceAll('DBLQT', '"').removeStart('"').removeEnd('"')
          );
        } else if (field.startsWith('"')) {
          makeCompositeField = true;
          compositeField = field;
        } else if (field.endsWith('"')) {
          compositeField += ',' + field;
          cleanFields.add(
            compositeField.replaceAll('DBLQT', '"')
              .removeStart('"')
              .removeEnd('"')
          );
          makeCompositeField = false;
        } else if (makeCompositeField) {
          compositeField += ',' + field;
        } else {
          cleanFields.add(
            field.replaceAll('DBLQT', '"').removeStart('"').removeEnd('"')
          );
        }
      }
      allCsvRows.add(cleanFields);
    }
    // Loop through the column headers (first csv row) and build a map from zero-based index to column label
    if (!allCsvRows.isEmpty()) {
      Integer colIndex = 0;
      for (String s : allCsvRows[0]) {
        this.importColumnIndexToLabelMap.put(colIndex, s.removeEnd('\r'));
        colIndex++;
      }
    }
    // Remove the column headers
    allCsvRows.remove(0);
    return allCsvRows;
  }

  public APIResponse import() {
    APIResponse response = new APIResponse('OK', 200, new List<String>());
    // validate sObjType
    if (this.sObjType == null) {
      response.status = 'Bad Request';
      response.statusCode = 400;
      response.messages.add(
        StringUtil.format(
          Label.Problem_With_sObjectType_In_Setting,
          new List<Object>{ this.settingName }
        )
      );
      return response;
    }
    // set up the record type override
    try {
      if (this.setting.RecordTypeOverride__c != null) {
        this.recordTypeOverrideId = this.sObjType.getDescribe()
          .getRecordTypeInfosByDeveloperName()
          .get(this.setting.RecordTypeOverride__c)
          .getRecordTypeId();
      }
    } catch (Exception e) {
      response.status = 'Bad Request';
      response.statusCode = 400;
      response.messages.add(
        StringUtil.format(
          Label.Problem_With_Record_Type_Name_In_Configuration,
          new List<Object>{ this.settingName }
        )
      );
      return response;
    }

    // validate CSV columns
    Integer columnIndex = 0;
    Integer lastColumn = this.importColumnIndexToLabelMap.values().size() - 1;
    for (String columnLabel : this.importColumnIndexToLabelMap.values()) {
      if (this.masterLabelToColumnDefinitionMap.containsKey(columnLabel)) {
        CSV_Import_Column__mdt columnDefinition = this.masterLabelToColumnDefinitionMap.get(
          columnLabel
        );
        // field exists in our map of CSV_Import_Column__mdt's so let's get the API field name from that
        try {
          Schema.DescribeFieldResult field = this.fieldMap.get(
            this.masterLabelToColumnDefinitionMap.get(columnLabel).FieldName__c
          );
          // if it's not a template only column, validate the user has permission to write to the field
          if (
            !columnDefinition.TemplateOnly__c &&
            !this.validateFieldAccess(field)
          ) {
            response.status = 'Bad Request';
            response.statusCode = 400;
            response.messages.add(
              StringUtil.format(
                Label.You_Do_Not_Have_Permision_To_Update_Field,
                new List<Object>{ columnLabel }
              )
            );
          }
        } catch (Exception e) {
          response.status = 'Bad Request';
          response.statusCode = 400;
          response.messages.add(
            StringUtil.format(
              Label.Invalid_Field_API_Name_In_Configuration,
              new List<Object>{ columnLabel }
            )
          );
        }
      } else {
        // the user is trying to import data for an unmapped field. Should we allow this?
        if (this.setting.AllowExtraColumns__c) {
          // for the user to be successful, they need to be using a valid API field name in the CSV column header, else this will fail
          try {
            Schema.DescribeFieldResult field = this.fieldMap.get(columnLabel);
            // validate the user has permission to write to the field
            if (!this.validateFieldAccess(field)) {
              response.status = 'Bad Request';
              response.statusCode = 400;
              response.messages.add(
                StringUtil.format(
                  Label.You_Do_Not_Have_Permision_To_Update_Field,
                  new List<Object>{ columnLabel }
                )
              );
            }
          } catch (Exception e) {
            response.status = 'Bad Request';
            response.statusCode = 400;
            response.messages.add(
              StringUtil.format(
                Label.Invalid_Field_API_Name,
                new List<Object>{ columnLabel }
              )
            );
          }
        } else {
          response.status = 'Bad Request';
          response.statusCode = 400;
          response.messages.add(
            String.isNotBlank(columnLabel)
              ? StringUtil.format(
                  Label.Unexpected_Column,
                  new List<Object>{ columnLabel }
                )
              : columnIndex < lastColumn
                  ? Label.Empty_Column_Label
                  : Label.Labels_Row_Ends_With_Comma
          );
        }
      }
      columnIndex++;
    }

    // if columns were invalid then return without further ado
    if (response.messages.size() > 0) {
      return response;
    }

    // process rows
    if (!this.importRows.isEmpty()) {
      Integer rowIndex = 0;
      for (List<String> row : this.importRows) {
        SObject sObj = this.sObjType.newSObject();
        if (this.recordTypeOverrideId != null) {
          try {
            sObj.put('RecordTypeId', this.recordTypeOverrideId);
          } catch (Exception e) {
            response.status = 'Bad Request';
            response.statusCode = 400;
            response.messages.add(
              StringUtil.format(
                Label.No_Record_Types_Found_For_Object,
                new List<Object>{ this.setting.ObjectName__c }
              )
            );
            return response;
          }
        }
        Integer colIndex = 0;
        for (String cellValue : row) {
          if (this.importColumnIndexToLabelMap.containsKey(colIndex)) {
            // get information about the cell's column
            String columnLabel = this.importColumnIndexToLabelMap.get(colIndex);
            CSV_Import_Column__mdt columnDefinition;
            if (
              this.masterLabelToColumnDefinitionMap.containsKey(columnLabel)
            ) {
              columnDefinition = this.masterLabelToColumnDefinitionMap.get(
                columnLabel
              );
            }
            Schema.DescribeFieldResult field = this.fieldMap.get(
              columnDefinition != null
                ? columnDefinition.FieldName__c
                : columnLabel
            );
            cellValue = cellValue.removeEnd('\r');
            // only bother processing this cell if it's not a template-only column
            if (columnDefinition != null) {
              if (!columnDefinition.TemplateOnly__c) {
                // set a default value if it was configured on the import column metadata and the user hasn't set a value in the import
                if (
                  columnDefinition.DefaultValue__c != null &&
                  String.isBlank(cellValue)
                ) {
                  cellValue = columnDefinition.DefaultValue__c;
                }
                // validate requiredness if it was set on the import column metadata
                if (columnDefinition.Required__c && String.isBlank(cellValue)) {
                  response.status = 'Bad Request';
                  response.statusCode = 400;
                  response.messages.add(
                    StringUtil.format(
                      Label.Missing_Value_Field_Required,
                      new List<Object>{ columnLabel }
                    )
                  );
                } else {
                  // try to set the field value
                  try {
                    String fieldType = String.valueOf(field.getType());
                    sObj.put(
                      field.getName(),
                      String.isBlank(cellValue)
                        ? null
                        : getConvertedCellValue(fieldType, cellValue)
                    );
                  } catch (Exception e) {
                    response.status = 'Bad Request';
                    response.statusCode = 400;
                    String errorMsg = e.getMessage();
                    if (errorMsg.contains('Invalid date')) {
                      errorMsg += ' ' + Label.Date_Format_CSV;
                    }
                    response.messages.add(
                      StringUtil.format(
                        Label.Row_Column_Message,
                        new List<Object>{ rowIndex + 1, columnLabel, errorMsg }
                      )
                    );
                  }
                }
              }
            } else {
              // this is an extra column, try to set the field value
              try {
                String fieldType = String.valueOf(field.getType());
                sObj.put(
                  field.getName(),
                  String.isBlank(cellValue)
                    ? null
                    : getConvertedCellValue(fieldType, cellValue)
                );
              } catch (Exception e) {
                response.status = 'Bad Request';
                response.statusCode = 400;
                String errorMsg = e.getMessage();
                if (errorMsg.contains('Invalid date')) {
                  errorMsg += ' ' + Label.Date_Format_CSV;
                }
                response.messages.add(
                  StringUtil.format(
                    Label.Row_Column_Message,
                    new List<Object>{ rowIndex + 1, columnLabel, errorMsg }
                  )
                );
              }
            }
          } else {
            response.status = 'Bad Request';
            response.statusCode = 400;
            response.messages.add(
              StringUtil.format(
                Label.Row_Message,
                new List<Object>{
                  rowIndex + 1,
                  Label.Trailing_Comma_Or_Column_Not_Defined
                }
              )
            );
          }
          colIndex++;
        }
        // populate any hidden fields with a default value configured on the import column metadata, where the user hasn't set a value in a custom column
        for (
          CSV_Import_Column__mdt columnDefinition : this.masterLabelToColumnDefinitionMap.values()
        ) {
          if (
            columnDefinition.Hidden__c &&
            columnDefinition.DefaultValue__c != null &&
            (!this.setting.AllowExtraColumns__c ||
            sObj.get(columnDefinition.FieldName__c) == null)
          ) {
            sObj.put(
              columnDefinition.FieldName__c,
              columnDefinition.DefaultValue__c
            );
          }
        }
        // populate the parent relationship field
        if (this.setting.ParentField__c != null && parentId != null) {
          sObj.put(this.setting.ParentField__c, parentId);
        }
        // add the new sObj to a list of sObjects to perform DML on
        if (response.objList != null) {
          response.objList.add(sObj);
        } else {
          response.objList = new List<SObject>{ sObj };
        }
        rowIndex++;
      }
    } else {
      response.status = 'Bad Request';
      response.statusCode = 400;
      response.messages.add(label.No_Rows_Were_Found);
    }

    // flag any issues in the pre-DML checks, such as the user not populating a required field
    if (response.messages.size() > 0) {
      return response;
    }

    // perform DML on sObjectsForDML
    if (response.objList != null) {
      try {
        switch on this.setting.DMLStatement__c {
          when 'Insert' {
            insert response.objList;
          }
          when else {
            response.status = 'Bad Request';
            response.statusCode = 400;
            response.messages.add(
              StringUtil.format(
                Label.Invalid_DML_Statement,
                new List<Object>{ this.setting.DMLStatement__c }
              )
            );
          }
        }
        // TODO: batchable DML for large lists of records
      } catch (DmlException e) {
        response.status = 'Bad Request';
        response.statusCode = 400;
        for (Integer i = 0; i < e.getNumDml(); i++) {
          response.messages.add(
            StringUtil.format(
              Label.Row_Message,
              new List<Object>{ e.getDmlIndex(i) + 1, e.getDmlMessage(i) }
            )
          );
        }
      }
    }
    return response;
  }

  private Boolean validateFieldAccess(Schema.DescribeFieldResult field) {
    return field.isAccessible() &&
      (this.setting.DMLStatement__c == 'Insert' && field.isCreateable()) ||
      (this.setting.DMLStatement__c == 'Update' && field.isUpdateable()) ||
      (this.setting.DMLStatement__c != 'Insert' &&
      this.setting.DMLStatement__c != 'Update');
  }

  private Object getConvertedCellValue(String fieldType, String cellValue) {
    switch on fieldType {
      when 'INTEGER' {
        return Integer.valueOf(cellValue);
      }
      when 'DOUBLE' {
        return Double.valueOf(cellValue);
      }
      when 'LONG' {
        return Decimal.valueOf(cellValue);
      }
      when 'CURRENCY' {
        return Decimal.valueOf(cellValue);
      }
      when 'DATE' {
        return Date.valueOf(cellValue);
      }
      when 'DATETIME' {
        return DateTime.valueOf(cellValue);
      }
      when 'TIME' {
        String[] timeSplits = cellValue.split(':');
        return Time.newInstance(
          Integer.valueOf(timeSplits[0]),
          Integer.valueOf(timeSplits[1]),
          0,
          0
        );
      }
      when else {
        return cellValue;
      }
    }
  }
}