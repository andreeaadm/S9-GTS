/**
* @author Kaspars Rezgalis <kaspars.rezgalis@cloudshiftgroup.com>
* @date 2022-09-06
* @group CloudShiftGroup
* @description Trigger handler class for Test_Item__c records.
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 06/09/2022        Kaspars Rezgalis     Created Class
*/

public with sharing class TestItemTrgHandler extends TriggerHandler {
    @testVisible private static final String CONCAT_FIELD_NAME = 'Concatenated_Product__c';
    @testVisible private static final Set<String> MULTIPICKLISTS_TO_CONCAT = new Set<String>{'Product__c', 'Additional_Product__c', 
                                                                                                'Auxiliary_Product__c',
                                                                                                'Ancillary_Product__c',
                                                                                                'Extra_Product__c'
                                                                                            };
    
    /**
     * Before Insert actions
    */
    public override void beforeInsert() {
        RegulationTrgHandler.concatAndSortPicklistValues(Trigger.new, MULTIPICKLISTS_TO_CONCAT, CONCAT_FIELD_NAME);
    }

    /**
     * Before Update actions
    */
    public override void beforeUpdate() {
        RegulationTrgHandler.concatAndSortPicklistValues(Trigger.new, MULTIPICKLISTS_TO_CONCAT, CONCAT_FIELD_NAME);
    }
}