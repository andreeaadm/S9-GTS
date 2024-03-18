public with sharing class CSVImportController extends VisualEditor.DynamicPickList {
  // Return a default CSV Import Setting to the csvFileImport LWC targetConfigs
  public override VisualEditor.DataRow getDefaultValue() {
    List<CSV_Import_Setting__mdt> settings = new List<CSV_Import_Setting__mdt>(
      [
        SELECT DeveloperName, MasterLabel
        FROM CSV_Import_Setting__mdt
        ORDER BY MasterLabel ASC
        LIMIT 1
      ]
    );
    return settings.isEmpty()
      ? new VisualEditor.DataRow(label.Error, label.Error)
      : new VisualEditor.DataRow(
          settings[0].MasterLabel,
          settings[0].DeveloperName
        );
  }
  // Return the list of available CSV Import Settings to the csvFileImport LWC targetConfigs
  public override VisualEditor.DynamicPickListRows getValues() {
    VisualEditor.DynamicPickListRows picklistRows = new VisualEditor.DynamicPickListRows();
    for (CSV_Import_Setting__mdt setting : [
      SELECT DeveloperName, MasterLabel
      FROM CSV_Import_Setting__mdt
    ]) {
      picklistRows.addRow(
        new VisualEditor.DataRow(setting.MasterLabel, setting.DeveloperName)
      );
    }
    return picklistRows;
  }

  @AuraEnabled
  public static List<String> getTemplateColumns(String settingName) {
    List<String> response = new List<String>();
    CSVFile csv = new CSVFile(settingName, null, null);
    return new List<String>(csv.masterLabelToTemplateColumnsMap.keyset());
  }

  @AuraEnabled
  public static APIResponse doImport(
    String settingName,
    String base64,
    String parentId
  ) {
    CSVFile csv;
    try {
      csv = new CSVFile(settingName, base64, parentId);
    } catch (Exception e) {
      return new APIResponse(
        'Bad Request',
        400,
        new List<String>{
          label.Problem_With_CSV_Import_Setting +
          ' ' +
          settingName
        }
      );
    }
    return csv.import();
  }
}