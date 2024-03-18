global with sharing class NavIconConfiguration_DataSource extends VisualEditor.DynamicPickList {
    VisualEditor.DesignTimePageContext context;
    
	global NavIconConfiguration_DataSource(VisualEditor.DesignTimePageContext context) {
       this.context = context;
    }
    global override VisualEditor.DataRow getDefaultValue(){
        return null;
    }
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows  picklistValues = new VisualEditor.DynamicPickListRows();
        
        for(Community_Nav_Icon_Configuration__mdt config : [SELECT Id, DeveloperName, MasterLabel FROM Community_Nav_Icon_Configuration__mdt]) {
            VisualEditor.DataRow dataRow = new VisualEditor.DataRow(config.DeveloperName, config.MasterLabel);
            picklistValues.addRow(dataRow);
        }

        return picklistValues;
    }
}