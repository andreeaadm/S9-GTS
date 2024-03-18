/*
* @author       Globant
* @created      18-Sep-2023
* @description  Class contains logic to methods for Access Passport Report Generation
*/
public with sharing class GMAEL_AccessReportUtilityLite {

    public class AccessReportInput{
        @AuraEnabled
        public List<String> countries{get;set;}
        @AuraEnabled
        public String reportId{get;set;}

        //Constructor
        public AccessReportInput(){
            countries = new List<String>();
        }
    }
    
    public class AccessReportWrapper{
        @AuraEnabled
        public GMAEL_Report__c reportObj{get;set;}        
        @AuraEnabled
        public List<AccessReportCountryWrapper> reportCountries{get;set;}

        //Constructor
        public AccessReportWrapper(){
            reportObj = new GMAEL_Report__c();
            reportCountries = new List<AccessReportCountryWrapper>();
        }
    }

    public class AccessReportCountryWrapper{
        @AuraEnabled
        public GMAEL_Report_Country__c reportCountry{get;set;}
        @AuraEnabled
        public List<AccessReportCountryLineWrapper> reportCountryLines{get;set;}
        @AuraEnabled
        public List<AccessReportCountryPlugWrapper> reportCountryPlugTypes{get;set;}
        @AuraEnabled
        public Boolean legislationFound{get;set;}
        @AuraEnabled
        public Boolean plugsFound{get;set;}

        //Constructor
        public AccessReportCountryWrapper(){
            reportCountry = new GMAEL_Report_Country__c();
            reportCountryLines = new List<AccessReportCountryLineWrapper>();
            reportCountryPlugTypes = new List<AccessReportCountryPlugWrapper>();
            legislationFound = false;
            plugsFound = false;
        }
    }
    
    public class AccessReportCountryPlugWrapper{
        @AuraEnabled
        public GMAEL_Report_Country_Plug_Type__c reportCountryPlugObj{get;set;}

        //Constructor
        public AccessReportCountryPlugWrapper(){            
            reportCountryPlugObj = new GMAEL_Report_Country_Plug_Type__c();
        }
    }

    public class AccessReportCountryLineWrapper{
        @AuraEnabled
        public GMAEL_Report_Line__c reportLineObj{get;set;}
        @AuraEnabled
        public Set<String> legislationSummaries{get;set;}
        @AuraEnabled
        public Set<String> schemes{get;set;}
        @AuraEnabled
        public Set<String> countryMarks{get;set;}

        @AuraEnabled
        public Boolean isRowApplicable{get;set;}

        //Constructor
        public AccessReportCountryLineWrapper(){
            isRowApplicable = false;
            reportLineObj = new GMAEL_Report_Line__c();
            legislationSummaries = new Set<String>();
            schemes = new Set<String>();
            countryMarks = new Set<String>();
        }
    }

    /*
    * Method to generate Access Report Lines based on Countries, Product Category and Product Description selections
    */
    public static AccessReportWrapper generateAccessReport(AccessReportInput inputObj){       

        List<String> engineeringApplications = new List<String>();
        String productCategory;
        String productDescription;
        Set<String> standardIds = new Set<String>();

        //Retrieving Engineering Applications and sorted alphabetically
        engineeringApplications = retrievePicklist('GMAEL_Legislation_Country__c','GMAEL_Engineering_Application__c',true);
        engineeringApplications.sort();

        //Retrieving Country records and preparing Country Maps
        Map<Id,GMAEL_Country__c> countryMap = new Map<Id,GMAEL_Country__c>([Select Id, Name, GMAEL_ISO_Code__c, GMAEL_Method_of_Conformity__c,
                                                                                GMAEL_National_Deviation_Supply_Freqncy__c, GMAEL_Continent__c,
                                                                                GMAEL_National_Deviation_Supply_Voltage__c, GMAEL_Logo_File_URL__c,
                                                                                GMAEL_Region__c, GMAEL_Region__r.Name, GMAEL_Region__r.GMAEL_Logo_File_URL__c,
                                                                                GMAEL_Scheme_Document__c, GMAEL_General_Information__c,
                                                                                (Select Id, GMAEL_Country__c,
                                                                                        GMAEL_Plug_Type__c, GMAEL_Plug_Type__r.Name,
                                                                                        GMAEL_Plug_Type__r.GMAEL_Plug_Type_Description__c, GMAEL_Plug_Type__r.GMAEL_Logo_File_URL__c
                                                                                    from GMAEL_Country_Plug_Type_Relationships__r 
                                                                                    where GMAEL_CPTR_Status__c='Approved'
                                                                                    order by GMAEL_Plug_Type__r.Name ASC)
                                                                                from GMAEL_Country__c
                                                                                where Id in:inputObj.countries
                                                                                order by Name ASC]);
                                                                                
        Map<String,GMAEL_Country__c> countryISOCodeMap = new Map<String,GMAEL_Country__c>();
        for(Integer i=0; i<countryMap.values().size(); i++){
            countryISOCodeMap.put(countryMap.values()[i].GMAEL_ISO_Code__c,countryMap.values()[i]);
        }


        //Retrieving Legislation Country records for selected Countries & respective Legislation Standards which are related to selected Product Category & Product Description
        GMAEL_Legislation_Country__c[] legislationCountries = [SELECT Id, Name, GMAEL_Engineering_Application__c, GMAEL_Legislation__c, GMAEL_Legislation__r.Name,
                                                                        GMAEL_Jurisdiction__c, GMAEL_Jurisdiction__r.Name, 
                                                                        GMAEL_Governance_Description__c, GMAEL_Scheme__c, 
                                                                        GMAEL_Governing_Body__c, GMAEL_Governing_Body_Name__c, GMAEL_Governance_URL__c,
                                                                        GMAEL_Country_Mark__c, GMAEL_Country_Mark__r.GMAEL_Country_Mark__r.GMAEL_Logo_File_URL__c, 
                                                                        GMAEL_CAB_Accreditation__c, 
                                                                        GMAEL_Country_Conformity_Requirement__c, GMAEL_Country_Conformity_Types__c, 
                                                                        GMAEL_Pre_Shipment_Requirement__c, GMAEL_Pre_Shipment_Type__c, 
                                                                        GMAEL_Legislation_Additional_Information__c, GMAEL_Pre_Shipment_Requirement_Conga__c,
                                                                        GMAEL_Legislation__r.GMAEL_Legislation_Status__c
                                                                    FROM GMAEL_Legislation_Country__c
                                                                    where GMAEL_Jurisdiction__c in: inputObj.countries
                                                                    and GMAEL_Legislation__r.GMAEL_Effective_Date__c <=TODAY
                                                                    and GMAEL_Legislation__r.GMAEL_Legislation_Status__c='Approved'];
        
        Map<String, List<GMAEL_Legislation_Country__c>> countryEngineeringApp_LegisltaionCountryMap = new Map<String, List<GMAEL_Legislation_Country__c>>();
        String mapKey ='';
        for(Integer i=0; i<legislationCountries.size(); i++){
            mapKey = legislationCountries[i].GMAEL_Jurisdiction__c+'-'+legislationCountries[i].GMAEL_Engineering_Application__c;
            if(!countryEngineeringApp_LegisltaionCountryMap.containsKey(mapKey)){
                countryEngineeringApp_LegisltaionCountryMap.put(mapKey,new List<GMAEL_Legislation_Country__c>());
            }
            countryEngineeringApp_LegisltaionCountryMap.get(mapKey).add(legislationCountries[i]);
        }

        System.debug('-------------countryEngineeringApp_LegisltaionCountryMap'+JSON.serialize(countryEngineeringApp_LegisltaionCountryMap));
  
        //Generating Access Report SObject record
        AccessReportWrapper accessReportObj = new AccessReportWrapper();
        accessReportObj.reportObj = createAccessReportRecord('', '', '','','','');
        System.debug('-----------1-------');
        //Generating Access Report Country and Access Report Line Wrapper Data
        if(countryMap!=null){
            mapKey='';
            System.debug('-----------2-------');
            for(String countryId : countryMap.keySet()){
                AccessReportCountryWrapper tempCountryWrpObj = createReportCountry(countryMap.get(countryId),'','',
                                                                                    accessReportObj.reportObj.GMAEL_System_Id__c,null);
                for(String engApp: engineeringApplications){
                    AccessReportCountryLineWrapper tempLineRowObj = new AccessReportCountryLineWrapper();
                    mapKey = countryId+'-'+engApp;
                    tempLineRowObj = createReportLine(engApp,countryEngineeringApp_LegisltaionCountryMap.get(mapKey),
                                                        tempCountryWrpObj.reportCountry.GMAEL_System_Id__c,null);
                    
                    if(tempLineRowObj.isRowApplicable==true){
                        tempCountryWrpObj.reportCountryLines.add(tempLineRowObj);                    
                        tempCountryWrpObj.legislationFound = true;
                    }
                }
                accessReportObj.reportCountries.add(tempCountryWrpObj);
                System.debug('-----------3-------');
            }
        }

        return accessReportObj;
    }

    /*
    * Method to create Access Report SObject record
    */
    public static GMAEL_Report__c createAccessReportRecord(String accId, String contactId, String ginNumber, String systemId, String parentReportId, String filterJSON){
        GMAEL_Report__c reportObj = new GMAEL_Report__c();
        reportObj.GMAEL_System_Id__c = generateSystemId()[0];
        reportObj.GAMEL_Filter_JSON__c = filterJSON;
        if(systemId!=null && systemId!=''){
            reportObj.GMAEL_System_Id__c = systemId;
        }
        if(parentReportId!=null && parentReportId!=''){
            reportObj.GMAEL_Parent_Report__c = parentReportId;
        }
        System.debug('-----------A-------');
        return reportObj;
    }

    /*
    * Method to create Legislation Country Wrapper obj
    */
    public static AccessReportCountryWrapper createReportCountry(GMAEL_Country__c countryObj, String prodCategory, String prodDescription, String reportSystemId, GMAEL_Report_Country__c reportCountryObj){
        
        AccessReportCountryWrapper reportCountryWrpObj = new AccessReportCountryWrapper();
        reportCountryWrpObj.reportCountry.GMAEL_Report__r = new GMAEL_Report__c(GMAEL_System_Id__c=reportSystemId);
        reportCountryWrpObj.reportCountry.GMAEL_Country_Name__c = countryObj.Name;
        reportCountryWrpObj.reportCountry.GMAEL_Country_ISO_Code__c = countryObj.GMAEL_ISO_Code__c;       
        reportCountryWrpObj.reportCountry.GMAEL_Method_of_Conformity__c = countryObj.GMAEL_Method_of_Conformity__c;
        reportCountryWrpObj.reportCountry.GMAEL_National_Deviation_Supply_Voltage__c = countryObj.GMAEL_National_Deviation_Supply_Voltage__c;
        reportCountryWrpObj.reportCountry.GMAEL_National_Deviation_Supply_Freqncy__c = countryObj.GMAEL_National_Deviation_Supply_Freqncy__c;
        reportCountryWrpObj.reportCountry.GMAEL_Product_Category__c = prodCategory;
        reportCountryWrpObj.reportCountry.GMAEL_Product_Description__c =prodDescription;
        reportCountryWrpObj.reportCountry.GMAEL_Scheme_Document__c = countryObj.GMAEL_Scheme_Document__c;
        reportCountryWrpObj.reportCountry.GMAEL_General_Information__c = countryObj.GMAEL_General_Information__c;
        reportCountryWrpObj.reportCountry.GMAEL_Flag_URL__c = countryObj.GMAEL_Logo_File_URL__c;
        reportCountryWrpObj.reportCountry.GMAEL_Continent__c = countryObj.GMAEL_Continent__c;
        reportCountryWrpObj.reportCountry.GMAEL_Region_Name__c = countryObj.GMAEL_Region__r.Name;
        reportCountryWrpObj.reportCountry.GMAEL_Region_Flag_URL__c = countryObj.GMAEL_Region__r.GMAEL_Logo_File_URL__c;
        reportCountryWrpObj.reportCountry.GMAEL_System_Id__c =generateSystemId()[0];

        if(countryObj.GMAEL_Country_Plug_Type_Relationships__r!=null && countryObj.GMAEL_Country_Plug_Type_Relationships__r.size()>0){
            reportCountryWrpObj.reportCountryPlugTypes.clear();
            for(Integer i=0; i<countryObj.GMAEL_Country_Plug_Type_Relationships__r.size(); i++){
                AccessReportCountryPlugWrapper plugWrpObj = new AccessReportCountryPlugWrapper();
                plugWrpObj.reportCountryPlugObj.GMAEL_Report_Country__r =  new GMAEL_Report_Country__c(GMAEL_System_Id__c=reportCountryWrpObj.reportCountry.GMAEL_System_Id__c);
                plugWrpObj.reportCountryPlugObj.Name = countryObj.GMAEL_Country_Plug_Type_Relationships__r[i].GMAEL_Plug_Type__r.Name;
                plugWrpObj.reportCountryPlugObj.GMAEL_Logo_File_URL__c = countryObj.GMAEL_Country_Plug_Type_Relationships__r[i].GMAEL_Plug_Type__r.GMAEL_Logo_File_URL__c;
                plugWrpObj.reportCountryPlugObj.GMAEL_Plug_Type_Description__c = countryObj.GMAEL_Country_Plug_Type_Relationships__r[i].GMAEL_Plug_Type__r.GMAEL_Plug_Type_Description__c;
                plugWrpObj.reportCountryPlugObj.GAMEL_System_Id__c = generateSystemId()[0];
                reportCountryWrpObj.reportCountryPlugTypes.add(plugWrpObj);
            }
        }
        if(reportCountryWrpObj.reportCountryPlugTypes!=null && reportCountryWrpObj.reportCountryPlugTypes.size()>0){
            reportCountryWrpObj.plugsFound = true;
        }
        System.debug('-----------B-------');
        return reportCountryWrpObj;
    }

    /*
    *
    */
    public static AccessReportCountryLineWrapper createReportLine(String enggApp, List<GMAEL_Legislation_Country__c> legislationCountryList, String reportCountrySystemId, GMAEL_Report_Line__c reportLineObj){
        AccessReportCountryLineWrapper lineWrpObj = new AccessReportCountryLineWrapper();
        lineWrpObj.reportLineObj.GMAEL_Report_Country__r = new GMAEL_Report_Country__c(GMAEL_System_Id__c=reportCountrySystemId);
        lineWrpObj.reportLineObj.GMAEL_Engineering_Application__c = enggApp;
        lineWrpObj.reportLineObj.GMAEL_System_Id__c = generateSystemId()[0];



        if(legislationCountryList!=null){
            lineWrpObj.isRowApplicable = true;
            for(Integer i=0; i<legislationCountryList.size(); i++){
                lineWrpObj.reportLineObj.GMAEL_Engineering_Application__c = legislationCountryList[i].GMAEL_Engineering_Application__c;
                //lineWrpObj.legislationSummaries.add(legislationCountryList[i].GMAEL_Governance_Description__c);
                lineWrpObj.legislationSummaries.add(legislationCountryList[i].GMAEL_Legislation__r.Name);
                lineWrpObj.schemes.addAll(legislationCountryList[i].GMAEL_Scheme__c?.split(';'));
                lineWrpObj.countryMarks.add(legislationCountryList[i].GMAEL_Country_Mark__r.GMAEL_Country_Mark__r.GMAEL_Logo_File_URL__c);
            }   
        }
        System.debug('-----------C-------');
        return lineWrpObj;
    }
    
    /*
    * Method to return picklist values or label for Object picklist field.
    */
    public static List<String> retrievePicklist(String objectAPIName, String fieldAPIName, Boolean returnLabels){
        
        List<String> picklist = new List<String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectAPIName) ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldAPIName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        
        String picklistStr = '';
        for( Schema.PicklistEntry pickListVal : ple){
            
            picklistStr = pickListVal.getValue();
            if(returnLabels){
                picklistStr = pickListVal.getLabel();
            }
            picklist.add(picklistStr);
        }

        return picklist;
    }

    /*
    * Method to generate Unique System Id
    */
    @InvocableMethod(label='Generate System Identifier')
    public static List<String> generateSystemId(){
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        List<String> systemIdList = new List<String>();
        systemIdList.add(guid);
        return systemIdList;
    }
}