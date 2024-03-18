/**
 *  Custom apex class to create the legislation countries from the legislation (this apex used to call from the Flow).
 * 
 *  @since     Sep 2023
 *  @author    Globant
 */
public with sharing class GMAELLegislationCountriesActionHelper {
    
    private static final String COUNTRY_SEPARATOR = ';';
    private static final String NO_INPUT_PROVIDED = 'No Input Provided, please contact to System Administrator.';

    /**
     *  This method is used to creates GMAEL legislation countries.
     * 
     *  @param  inputs           The variables of the Flow like country mark Id, governing body etc. 
     *  @return                  A fully customized output to response to the Flow.
     */
    @InvocableMethod(label='Create GMAEL Legislation Countries' description='To Create GMAEL Legislation Countries!')
    public static List<Output> createGMAELLegislationCountries(List<Input> inputs) {
        
        List<Output> Outputs = new List<Output>();
        
        try {         
            
            Input input = !inputs.isEmpty() ? inputs.get(0) : null; 
            
            if (input == null) throw new GMAELLegislationCountriesActionHelperException(NO_INPUT_PROVIDED);
            
            String errorMessageForGoverningBody = '';
            String errorMessageForCountryMark = '';
            Boolean isDataNotValid;
            
            Id gmaelCountryBodyRelationshipId;
            Id gmaelCountryMarkRelationshipId;
            Map<String, GMAEL_Country__c> gMAELCountryMapById;
            Map<String, GMAEL_Country_Body_Relationship__c> gMAELCountryBodyRelationshipMapByCountryId;
            Map<String, GMAEL_Country_Mark_Relationship__c> gMAELCountryMarkRelationshipMapByCountryId;

            List<GMAEL_Legislation_Country__c> gMAELLegislationCountriesToInsert = new List<GMAEL_Legislation_Country__c>();
            List<GMAEL_Legislation_Standard__c> gMAELLegislationStandardsToInsert = new List<GMAEL_Legislation_Standard__c>();
            
            List<String> selectedCountries = input?.selectedCountries?.split(COUNTRY_SEPARATOR);
            gMAELCountryMapById = getGMAELCountryMapById(selectedCountries);
            gMAELCountryBodyRelationshipMapByCountryId = getGMAELCountryBodyRelationshipMapByCountryId(input?.governingBodyId, selectedCountries);
            gMAELCountryMarkRelationshipMapByCountryId = getGMAELCountryMarkRelationshipMapByCountryId(input?.countryMarkId, selectedCountries);

            List<GMAEL_Legislation_Standard__c> gMAELLegislationStandardToClone = input?.gMAELLegislationStandards != null ? input?.gMAELLegislationStandards : null;
            String gMAELCountryMarkId = input?.countryMarkId;

            for (String gmaelCountryId : selectedCountries) {
                
                gmaelCountryBodyRelationshipId = gMAELCountryBodyRelationshipMapByCountryId?.get(gmaelCountryId)?.Id;
                gmaelCountryMarkRelationshipId = gMAELCountryMarkRelationshipMapByCountryId?.get(gmaelCountryId)?.Id;
                isDataNotValid = gmaelCountryBodyRelationshipId == null || gmaelCountryMarkRelationshipId == null;

                if (gmaelCountryBodyRelationshipId == null) {
                    
                    errorMessageForGoverningBody += '\n' +gMAELCountryMapById?.get(gmaelCountryId)?.Name;
                }
                
                if (gmaelCountryMarkRelationshipId == null) {
                    
                    errorMessageForCountryMark += '\n' +gMAELCountryMapById?.get(gmaelCountryId)?.Name;
                }

                if (isDataNotValid == true) continue;                

                GMAEL_Legislation_Country__c gMAELLegislationCountry = input?.gMAELLegislationCountry?.clone(false, true, false, false);
                gMAELLegislationCountry.GMAEL_Jurisdiction__c = gmaelCountryId;
                gMAELLegislationCountry.GMAEL_Governing_Body__c = gmaelCountryBodyRelationshipId;
                gMAELLegislationCountry.GMAEL_Country_Mark__c = gmaelCountryMarkRelationshipId;

                gMAELLegislationCountriesToInsert?.add(gMAELLegislationCountry);
            }

            if (!gMAELLegislationCountriesToInsert.isEmpty() && isDataNotValid != true) {
            
                insert gMAELLegislationCountriesToInsert;
                
                if (gMAELLegislationStandardToClone != null) {
                    
                    for (GMAEL_Legislation_Country__c lc : gMAELLegislationCountriesToInsert) {
                        for (GMAEL_Legislation_Standard__c gMAELLegislationStandard : gMAELLegislationStandardToClone) {
                            
                            GMAEL_Legislation_Standard__c legislationStandard = gMAELLegislationStandard?.clone(false, true, false, false);
                            legislationStandard.GMAEL_Legislation_Country__c = lc.Id;
                            gMAELLegislationStandardsToInsert.add(legislationStandard);
                        }
                    }

                    if (!gMAELLegislationStandardsToInsert.isEmpty()) {
                        
                        insert gMAELLegislationStandardsToInsert;
                    }
                }
            }

            String errorMessage = throwErrorMessages(errorMessageForGoverningBody, errorMessageForCountryMark);
            
            if (String.isNotBlank(errorMessage)) {
                
                Outputs.add(new Output(false, errorMessage));   
            } else {
                
                Outputs.add(new Output(true, System.Label.GMAEL_Create_Legislation_For_Region_Found_Success));   
            }
        } catch (Exception ex) {
            
            Outputs.add(new Output(false, ex.getMessage()));   
        }

        return Outputs;
    }

    /**
     *  This method is used to create the customized error message.
     * 
     *  @param  errorMessageForGoverningBody  The variables of the error message for governing body. 
     *  @param  errorMessageForCountryMark    The variables of the error message for country mark 
     *  @return                               A string of the customized error message.
     */
    @TestVisible
    private static String throwErrorMessages(String errorMessageForGoverningBody, String errorMessageForCountryMark) {
        
        String errorMessage = '';

        if (String.isNotBlank(errorMessageForGoverningBody)) {
            
            errorMessage += '\n' + System.Label.GMAEL_No_Governing_Body_Error_Message + errorMessageForGoverningBody;   
        } else if (String.isNotBlank(errorMessageForCountryMark)) {
            
            errorMessage +=  '\n' + System.Label.GMAEL_No_Country_Mark_Error_Message + errorMessageForGoverningBody;   
        }

        return errorMessage;
    }

    /**
     *  This method is used to create the country map whish is used to create the country legislation.
     * 
     *  @param  selectedCountries  The variables is list of the selected countries passed as param in Flow. 
     *  @return                    It returns map of the GMAEL country.
     */
    @TestVisible
    private static Map<String, GMAEL_Country__c> getGMAELCountryMapById(List<String> selectedCountries) {
            
        Map<String, GMAEL_Country__c> gMAELCountryNameMap = new Map<String, GMAEL_Country__c>(
            [SELECT Id, Name FROM GMAEL_Country__c WHERE Id IN: selectedCountries]
        );

        return gMAELCountryNameMap;
    }

    /**
     *  This method is used to create the country body relation map whish is used to create the country legislation.
     * 
     *  @param  governingBodyId  The variables contains governing body Id which is passed as param in Flow. 
     *  @param  countyIds        The variables is list of the selected countries passed as param in Flow. 
     *  @return                  It returns map of the GMAEL country body relationship.
     */
    @TestVisible
    private static Map<String, GMAEL_Country_Body_Relationship__c> getGMAELCountryBodyRelationshipMapByCountryId(String governingBodyId, List<String> countyIds) {
            
        Map<String, GMAEL_Country_Body_Relationship__c> gMAELCountryBodyRelationshipMap = new Map<String, GMAEL_Country_Body_Relationship__c>();

        for (GMAEL_Country_Body_Relationship__c cbr : [SELECT Id, GMAEL_Country__r.Name 
                                                        FROM GMAEL_Country_Body_Relationship__c
                                                        WHERE GMAEL_Country__c IN: countyIds
                                                        AND GMAEL_Issuing_Governing_Body__c =: governingBodyId]) {
            
            gMAELCountryBodyRelationshipMap.put(cbr.GMAEL_Country__c, cbr);
        }

        return gMAELCountryBodyRelationshipMap;
    }

    /**
     *  This method is used to create the country mark relation map whish is used to create the country legislation.
     * 
     *  @param  countryMarkId  The variables contains country mark Id which is passed as param in Flow. 
     *  @param  countyIds      The variables is list of the selected countries passed as param in Flow. 
     *  @return                It returns map of the GMAEL country mark relationship.
     */
    @TestVisible
    private static Map<String, GMAEL_Country_Mark_Relationship__c> getGMAELCountryMarkRelationshipMapByCountryId(String countryMarkId, List<String> countyIds) {
            
        Map<String, GMAEL_Country_Mark_Relationship__c> gmaelCountryMarkRelationshipMap = new Map<String, GMAEL_Country_Mark_Relationship__c>();

        for (GMAEL_Country_Mark_Relationship__c cmr : [SELECT Id, GMAEL_Country__c 
                                                        FROM GMAEL_Country_Mark_Relationship__c
                                                        WHERE GMAEL_Country__c IN: countyIds
                                                        AND GMAEL_Country_Mark__c =: countryMarkId]) {
            
            gmaelCountryMarkRelationshipMap.put(cmr.GMAEL_Country__c, cmr);
        }

        return gmaelCountryMarkRelationshipMap;
    }
    
    /**
     *  Custom wrapper class takes inputs from the Flow.
     */
    public class Input {        
        @InvocableVariable
        public String selectedCountries;
        @InvocableVariable
        public String countryMarkId;
        @InvocableVariable
        public String governingBodyId;
        @InvocableVariable
        public List<GMAEL_Legislation_Standard__c> gMAELLegislationStandards;
        @InvocableVariable
        public GMAEL_Legislation_Country__c gMAELLegislationCountry;
    }
    
    /**
     *  Custom wrapper class return output to the Flow.
     */
    public class Output {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String message;
        
        public Output(Boolean success, String message) {

            this.success = success;
            this.message = message;
        }
    }

    /**
     *  Custom inner class to handling the exception 
     */
    private class GMAELLegislationCountriesActionHelperException extends Exception { }
}