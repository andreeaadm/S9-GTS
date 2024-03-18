/**
* @author Kaspars Rezgalis <kaspars.rezgalis@cloudshiftgroup.com>
* @date 2022-09-06
* @group CloudShiftGroup
* @description Trigger handler class for Regulation__c records.
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 06/09/2022        Kaspars Rezgalis     Created Class
*/

public with sharing class RegulationTrgHandler extends TriggerHandler {
    @testVisible private static final String CONCAT_FIELD_NAME = 'Concatenated_Product__c';
    @testVisible private static final Set<String> MULTIPICKLISTS_TO_CONCAT = new Set<String>{'Product__c', 'Additional_Product__c', 
                                                                                                'Auxiliary_Product__c',
                                                                                                'Ancillary_Product__c',
                                                                                                'Extra_Product__c'
                                                                                            };
    @testVisible private static final String MULTIPICKLIST_SPLIT_CHAR = ';';
    @testVisible private static final Integer MAX_MULTIPICKLIST_VALUES = 100;

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

    /**
     * Concatenate values from given multipicklist fields and store text version into given field; also, sort values and ensure only unique values remain across all picklists
     * This method is primarily needed to address issue that only 100 values can be selected for multi-picklists - to address that values can be added into multiple multi-picklists,
     * and then all valus combined are stored in text field while also ensuring only unique values (and alphabetically) are stored in picklists.
     * This method is used for both Regulation__c and Test_Plan__c records
     *
     * @param  records                  List of sobjects to process (assuming trigger context)
     * @param  multipicklistFieldNames  API names of multi-picklist fields which hold the values to be sorted & concatenated
     * @param  concatFieldName          API name of the field to store concatenated value in
     * 
    */
    public static void concatAndSortPicklistValues(List<Sobject> records, Set<String> multipicklistFieldNames, String concatFieldName) {
        for (Sobject record : records) {
            List<String> multiPicklistValues = new List<String>();
            Map<String, Object> recordPopulatedValues = record.getPopulatedFieldsAsMap();

            for (String fieldApiName : multipicklistFieldNames) {
                if (recordPopulatedValues.containsKey(fieldApiName)) {
                    multiPicklistValues.add((String)recordPopulatedValues.get(fieldApiName));
                }
            }

            String concatValues = concactUniqueValues(multiPicklistValues);
            record.put(concatFieldName, concatValues);

            List<String> sortedValuesForEachPicklist = splitIntoMultiplePicklistValues(concatValues);
            Integer index = 0;
            for (String fieldApiName : multipicklistFieldNames) {
                Boolean valuesExist = (sortedValuesForEachPicklist.size() > index);
                String valueToSet = (valuesExist ? sortedValuesForEachPicklist.get(index) : '');
                record.put(fieldApiName, valueToSet);
                index++;
            }
        }
    }

    /**
     * Method for transforming multiple values from many multi-picklists into one string, with sorted unique values only
     *
     * @param  multipicklistValuesAsLists   List of multipicklist values from various multi-picklists which needs to be unified.
     * 
     * @return String unique, concatenated & sorted values as one string
    */
    private static String concactUniqueValues(List<String> multipicklistValuesAsLists) {
        List<String> allIndividualValues = new List<String>();
        for (String picklistValuesAsString : multipicklistValuesAsLists) {
            if (String.isNotBlank(picklistValuesAsString)) {
                allIndividualValues.addAll(picklistValuesAsString.split(MULTIPICKLIST_SPLIT_CHAR));
            }
        }
        allIndividualValues.sort();
        Set<String> uniqueValues = new Set<String>(allIndividualValues);
        return String.join(new List<String>(uniqueValues), MULTIPICKLIST_SPLIT_CHAR);
    }

    /**
     * Method for splitting string (which contains all values from all multi-picklists concatenated) into multiple strings
     * so that those can be saved into separate multi-picklists which can take 100 values each
     * 
     * @param  allValues    String containing all (sorted) concatenated values from multiple picklists
     *                      that should now be split into separate lists (100 values max each)
     * 
     * @return List<String> picklist values (as concatenated string) 100 values max each
     * 
    */
    private static List<String> splitIntoMultiplePicklistValues(String allValues) {
        List<String> retValues = new List<String>(); //list where each string represents individual separate multipicklist values, e.g. for Product__c, Additional_Product__c
        List<String> tmpList = new List<String>();
        for (String s : allValues.split(MULTIPICKLIST_SPLIT_CHAR)) {
            tmpList.add(s);
            if (tmpList.size()==MAX_MULTIPICKLIST_VALUES) {
                retValues.add(String.join(tmpList, MULTIPICKLIST_SPLIT_CHAR));
                tmpList.clear();
            }
        }
        retValues.add(String.join(tmpList, MULTIPICKLIST_SPLIT_CHAR));

        return retValues;
    }
}