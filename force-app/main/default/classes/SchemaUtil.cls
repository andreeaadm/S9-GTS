public class SchemaUtil {
  /*
    |--------------------------------------------------------------------------
    | Picklist
    |--------------------------------------------------------------------------
    |
    | The inner classes, methods and variables written
    | below offer utility while addressing picklist
    | & multipicklist columns inside Salesforce.
    |
    */

  public class PicklistEntry {
    @AuraEnabled
    public Boolean isDefault;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;

    public PicklistEntry(Boolean isDefault, String label, String value) {
      this.isDefault = isDefault;
      this.label = label;
      this.value = value;
    }
  }

  /**
   * Return a List of SchemaUtil.PicklistEntry objects.
   *
   * @param  String  obj
   * @param  String  fld
   * @return List<PicklistEntry>
   */
  public static List<PicklistEntry> getPicklistEntries(String obj, String fld) {
    List<PicklistEntry> result = new List<PicklistEntry>();

    Schema.DescribeFieldResult field = Schema.getGlobalDescribe()
      .get(obj)
      .getDescribe()
      .fields.getMap()
      .get(fld)
      .getDescribe();

    if (
      field.getType() == Schema.DisplayType.Picklist ||
      field.getType() == Schema.DisplayType.MultiPicklist
    ) {
      for (Schema.PicklistEntry picklistEntry : field.getPicklistValues()) {
        if (picklistEntry.isActive()) {
          result.add(
            new SchemaUtil.PicklistEntry(
              picklistEntry.isDefaultValue(),
              picklistEntry.getLabel(),
              picklistEntry.getValue()
            )
          );
        }
      }
    } else {
      return null;
    }

    return result;
  }

  public static Map<String, String> getPicklistValues(
    String obj,
    String fld,
    Boolean isValueFirst
  ) {
    List<PicklistEntry> ple = getPicklistEntries(obj, fld);
    Map<String, String> pleValues = new Map<String, String>();
    for (PicklistEntry pe : ple) {
      if (isValueFirst) {
        pleValues.put(pe.Value, pe.label);
      } else {
        pleValues.put(pe.label, pe.Value);
      }
    }
    return pleValues;
  }

  public static boolean getPicklistValueExists(
    String obj,
    String fld,
    String checkValueExists
  ) {
    try {
      Map<string, String> values = getPicklistValues(obj, fld, true);
      String v = values.get(checkValueExists);
      return String.isBlank(v);
    } catch (Exception e) {
      return null;
    }
  }

  /*
    |--------------------------------------------------------------------------
    | Field
    |--------------------------------------------------------------------------
    |
    | This inner class and methods written below represent
    | general, reusable and useful utility methods when
    | working with SFDC Schema.SObjectField objects.
    |
    */

  public class Field {
    public Schema.SObjectField field;
    public Schema.DescribeFieldResult fieldDescribe;
    public String label;
    public String name;

    public Field(Schema.SObjectField field) {
      this.field = field;
      this.fieldDescribe = field.getDescribe();
      this.label = this.fieldDescribe.getLabel();
      this.name = this.fieldDescribe.getName();
    }
  }

  /**
   * Return a single SchemaUtil.Field object.
   *
   * @param  String  obj
   * @param  String  fld
   * @return SchemaUtil.Field
   */
  public static SchemaUtil.Field getField(String obj, String fld) {
    return new SchemaUtil.Field(
      Schema.getGlobalDescribe().get(obj).getDescribe().fields.getMap().get(fld)
    );
  }

  /**
   * Return a List of SchemaUtil.Field objects.
   *
   * @param  String  obj
   * @return List<SchemaUtil.Field>
   */
  public static List<SchemaUtil.Field> getFieldList(String obj) {
    List<SchemaUtil.Field> result = new List<SchemaUtil.Field>();

    for (
      Schema.SObjectField field : Schema.getGlobalDescribe()
        .get(obj)
        .getDescribe()
        .fields.getMap()
        .values()
    ) {
      result.add(new SchemaUtil.Field(field));
    }

    return result;
  }

  /**
   * Return a Map of field API name to a SchemaUtil.Field objects.
   *
   * @param  String  obj
   * @return Map<String, SchemaUtil.Field>
   */
  public static Map<String, SchemaUtil.Field> getFieldMap(String obj) {
    Map<String, SchemaUtil.Field> result = new Map<String, SchemaUtil.Field>();

    for (
      Schema.SObjectField field : Schema.getGlobalDescribe()
        .get(obj)
        .getDescribe()
        .fields.getMap()
        .values()
    ) {
      Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

      result.put(fieldDescribe.getName(), new SchemaUtil.Field(field));
    }

    return result;
  }

  /*
    |--------------------------------------------------------------------------
    | RecordType
    |--------------------------------------------------------------------------
    |
    | This inner class and methods written below represent
    | general, reusable and useful utility methods when
    | working with SFDC Schema.RecordTypeInfo class.
    |
    */

  public class RecordType {
    public Id recordId;
    public String recordName;
    public String label;
    public Schema.RecordTypeInfo recordTypeInfo;

    public RecordType(Schema.RecordTypeInfo recordTypeInfo) {
      this.recordId = recordTypeInfo.getRecordTypeId();
      this.recordName = recordTypeInfo.getDeveloperName();
      this.label = recordTypeInfo.getName();
      this.recordTypeInfo = recordTypeInfo;
    }
  }

  /**
   * Return an instance of SchemaUtil.RecordType.
   *
   * @param  String  obj
   * @param  String  name
   * @return SchemaUtil.RecordType
   */
  public static SchemaUtil.RecordType getRecordType(String obj, String name) {
    return new SchemaUtil.RecordType(
      Schema.getGlobalDescribe()
        .get(obj)
        .getDescribe()
        .getRecordTypeInfosByDeveloperName()
        .get(name)
    );
  }

  /*┌───────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * Signature:
   * Use this method to generate the start of a SOQL query for any SObject
   * If updatableOnly is true, only writeable fields for the current user will be returned in the string
   * Once you have the string, add your own second half, e.g. " FROM xxxxxxxx WHERE xxxxxxxx LIMIT xxxxxxxx"
   *└───────────────────────────────────────────────────────────────────────────────────────────────────────┘*/
  public static String generateSOQLFieldsString(
    String sObjApiName,
    Boolean updatableOnly
  ) {
    String soqlStr = 'SELECT Id';

    Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe()
      .get(sObjApiName)
      .getDescribe()
      .fields.getMap();
    fieldsMap = new Map<String, Schema.SObjectField>(fieldsMap);

    fieldsMap.remove('id');
    for (String s : fieldsMap.keyset()) {
      if (updatableOnly) {
        if (fieldsMap.get(s).getDescribe().isUpdateable()) {
          soqlStr += ', ' + s;
        }
      } else {
        soqlStr += ', ' + s;
      }
    }
    return soqlStr;
  }

  /*┌────────────────────────────────────────────────────────────────┐
   * getSObjectType supports 2 signatures to support String or Id
   * to avoid messy conversion handling in the event of bad input data
   *└────────────────────────────────────────────────────────────┄ℌ𝔍┄┘*/
  public static String getSObjectType(String objId) {
    try {
      return getSObjectType((Id) objId);
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Could not convert String to an Id: ' +
        objId +
        ' [' +
        e.getLineNumber() +
        ']'
      );
      return null;
    }
  }
  public static String getSObjectType(Id objId) {
    try {
      return objId.getSObjectType().getDescribe().getName();
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Could not convert Id to SObject name: ' +
        objId +
        ' [' +
        e.getLineNumber() +
        ']'
      );
      return null;
    }
  }

  public static Map<String, String> getQueryableFieldsFromFieldSet(String objectName, String fieldSetName){
    Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
    Schema.SObjectType sObjectType = globalDescribeMap.get(objectName);
    Schema.DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();

    Schema.FieldSet fieldSetObj = DescribeSObjectResult.FieldSets.getMap().get(fieldSetName);
    List<Schema.FieldSetMember> fieldSetMembers = fieldSetObj.getFields();

    Map<String, String> fieldPathVsTypeMap = new Map<String, String>();
    for(Schema.FieldSetMember field :fieldSetMembers){
      fieldPathVsTypeMap.put(field.getFieldPath(), String.valueOf(field.getType()));
    }
    return fieldPathVsTypeMap;
  }
}