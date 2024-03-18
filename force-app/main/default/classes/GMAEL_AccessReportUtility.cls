/*
* @author       Globant
* @created      18-Sep-2023
* @description  Class contains logic to methods for Access Passport Report Generation
*/
public with sharing class GMAEL_AccessReportUtility {

    public class AccessReportInput{
        @AuraEnabled
        public List<String> countries{get;set;}
        @AuraEnabled
        public String accId{get;set;} 
        @AuraEnabled
        public String contactId{get;set;}
        @AuraEnabled
        public String ginNumber{get;set;}
        @AuraEnabled
        public String productCategoryId{get;set;}
        @AuraEnabled
        public String productDescriptionId{get;set;}
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
        public Boolean isRowApplicable{get;set;}

        //Constructor
        public AccessReportCountryLineWrapper(){
            isRowApplicable = false;
            reportLineObj = new GMAEL_Report_Line__c();
        }
    }

    /*
    * Method to generate Access Report Lines based on Countries, Product Category and Product Description selections
    */
    public static AccessReportWrapper generateAccessReport(AccessReportInput inputObj){

        AccessReportWrapper accessReportObj = new AccessReportWrapper();

        List<String> engineeringApplications = new List<String>();
        String productCategory;
        String productDescription;
        Set<String> standardIds = new Set<String>();

        //Retrieving Engineering Applications and sorted alphabetically
        engineeringApplications = retrievePicklist('GMAEL_Legislation_Country__c','GMAEL_Engineering_Application__c',true);
        engineeringApplications.sort();

        //Retrieving Access Report record if exists
        GMAEL_Report__c[] accessReports = [Select Id,GMAEL_Account__c,GAMEL_Contact__c,GMAEL_GIN__c, GMAEL_Report_Status__c,
                                                    GMAEL_Parent_Report__c, GMAEL_System_Id__c, GAMEL_Filter_JSON__c
                                                from GMAEL_Report__c 
                                                where Id=:inputObj.reportId];

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

        //Retrieving Standards from selected Product Category and Product Type
        GMAEL_Standard_Category_Type__c[] standardCategoryTypes = [Select Id, GMAEL_Standard__c, GMAEL_Standard__r.GMAEL_Standard_Title__c,
                                                                            GMAEL_Product_Category__c, GMAEL_Category_Type_Relationship__c,
                                                                            GMAEL_Category_Type_Relationship__r.Category_Name__c, 
                                                                            GMAEL_Category_Type_Relationship__r.GMAEL_Product_Type__c, 
                                                                            GMAEL_Category_Type_Relationship__r.Product_Type_Name__c
                                                                        from GMAEL_Standard_Category_Type__c
                                                                        where GMAEL_Category_Type_Relationship__c=:inputObj.productDescriptionId];

        for(Integer i=0; i<standardCategoryTypes.size(); i++){
            productCategory = standardCategoryTypes[i].GMAEL_Category_Type_Relationship__r.Category_Name__c;
            productDescription = standardCategoryTypes[i].GMAEL_Category_Type_Relationship__r.Product_Type_Name__c;
            standardIds.add(standardCategoryTypes[i].GMAEL_Standard__c);
        }

        //Retrieving Legislation Standards which are related to selected Product Category & Product Description
        GMAEL_Legislation_Standard__c[] legislationStandards = [Select Id, GAMEL_Standard_Title__c, GMAEL_Legislation_Country__c 
                                                                        from GMAEL_Legislation_Standard__c 
                                                                        where GMAEL_Standard__c in: standardIds];
        Set<String> legislationCountryIds = new Set<String>();
        for(Integer i=0; i<legislationStandards.size(); i++){
            legislationCountryIds.add(legislationStandards[i].GMAEL_Legislation_Country__c);
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
                                                                        (Select Id, GAMEL_Standard_Title__c, GMAEL_Legislation_Country__c 
                                                                            from GMAEL_Legislation_Standards__r
                                                                            where GMAEL_Standard__c in: standardIds
                                                                            and GMAEL_Standard__r.GMAEL_Standard_Status__c='Approved'),
                                                                        GMAEL_Legislation__r.GMAEL_Legislation_Status__c
                                                                    FROM GMAEL_Legislation_Country__c
                                                                    where GMAEL_Jurisdiction__c in: inputObj.countries
                                                                    and Id in: legislationCountryIds
                                                                    and GMAEL_Legislation__r.GMAEL_Effective_Date__c <=TODAY
                                                                    and GMAEL_Legislation__r.GMAEL_Legislation_Status__c='Approved'];
        
        Map<String, GMAEL_Legislation_Country__c> countryEngineeringApp_LegisltaionCountryMap = new Map<String, GMAEL_Legislation_Country__c>();
        String mapKey ='';
        for(Integer i=0; i<legislationCountries.size(); i++){
            mapKey = legislationCountries[i].GMAEL_Jurisdiction__c+'-'+legislationCountries[i].GMAEL_Engineering_Application__c;
            countryEngineeringApp_LegisltaionCountryMap.put(mapKey,legislationCountries[i]);
        }

        //Generating Access Report SObject record
        String systemId = '';
        String parentReportId = '';
        Map<String,GMAEL_Report_Country__c> country_ReportCountryMap = new Map<String,GMAEL_Report_Country__c>();//Map to store Country and corresponding Report Country record
        Map<String,GMAEL_Report_Line__c> countryEnggApp_ReportLineMap = new Map<String,GMAEL_Report_Line__c>();//Map to store Country + Engineering App and corresponding Report Line record
        
        if(accessReports.size()>0){//Generating Access Report SObject record from existing data and retrieving related Report Country and Report Country Line records.
            systemId = accessReports[0].GMAEL_System_Id__c;
            parentReportId = accessReports[0].GMAEL_Parent_Report__c;
            
            //Retrieving existing Report Country Records
            GMAEL_Report_Country__c[] reportCountries = [Select GMAEL_Report__c, GMAEL_Report__r.GMAEL_System_Id__c, 
                                                                GMAEL_Country_Name__c, GMAEL_Country_ISO_Code__c,
                                                                GMAEL_Method_of_Conformity__c, GMAEL_National_Deviation_Supply_Voltage__c, 
                                                                GMAEL_National_Deviation_Supply_Freqncy__c,
                                                                GMAEL_Product_Category__c,GMAEL_Product_Description__c,
                                                                GMAEL_Scheme_Document__c,GMAEL_System_Id__c, GMAEL_Flag_URL__c,
                                                                GMAEL_Region_Name__c, GMAEL_Region_Flag_URL__c, GMAEL_Continent__c,
                                                                (Select Id, GMAEL_Report_Country__c, Name, 
                                                                        GMAEL_Logo_File_URL__c, GMAEL_Plug_Type_Description__c,
                                                                        GAMEL_System_Id__c
                                                                    from GMAEL_Report_Country_Plug_Types__r order by Name ASC)
                                                            from GMAEL_Report_Country__c 
                                                            where GMAEL_Report__c=:accessReports[0].Id 
                                                            and GMAEL_Country_ISO_Code__c in: countryISOCodeMap.keySet()];
            //delete reportCountries;
            //Preparing Map to store Country and corresponding Report Country record
            for(Integer i=0; i<reportCountries.size(); i++){
                country_ReportCountryMap.put(countryISOCodeMap.get(reportCountries[i].GMAEL_Country_ISO_Code__c).Id,reportCountries[i]);
            }
            
            //Retrieving Report Line Records
            GMAEL_Report_Line__c[] reportLines = [Select Id, GMAEL_Report_Country__c, 
                                                        GMAEL_Report_Country__r.GMAEL_System_Id__c, GMAEL_Report_Country__r.GMAEL_Country_ISO_Code__c, 
                                                        GMAEL_Engineering_Application__c, GMAEL_Governance_URL__c, 
                                                        GMAEL_Governance_URL_Label__c, GMAEL_Governance_Description__c,
                                                        GMAEL_Governing_Body__c, GMAEL_Standard__c, GMAEL_Scheme__c,
                                                        GMAEL_Country_Mark__c, GMAEL_CAB_Accreditation__c, GMAEL_Conformity_Method__c,
                                                        GMAEL_Pre_Shipment__c, GMAEL_Legislation_Additional_Information__c, GMAEL_System_Id__c,
                                                        GMAEL_Standard_Conga__c,GMAEL_Pre_Shipment_Requirement_Conga__c,
                                                        GMAEL_CAB_Accreditation_Conga__c, GMAEL_Conformity_Method_Conga__c
                                                    from GMAEL_Report_Line__c
                                                    where GMAEL_Report_Country__r.GMAEL_Report__c=:accessReports[0].Id
                                                    and GMAEL_Report_Country__r.GMAEL_Country_ISO_Code__c in: countryISOCodeMap.keySet()];

            //Preparing Map to store Country + Engineering App and corresponding Report Line record
            mapKey='';
            for(Integer i=0; i<reportLines.size(); i++){
                mapKey = countryISOCodeMap.get(reportLines[i].GMAEL_Report_Country__r.GMAEL_Country_ISO_Code__c).Id+'-'+reportLines[i].GMAEL_Engineering_Application__c;
                countryEnggApp_ReportLineMap.put(mapKey,reportLines[i]);
            }
        }
        accessReportObj.reportObj = createAccessReportRecord(inputObj.accId, inputObj.contactId, inputObj.ginNumber,systemId,parentReportId, JSON.serialize(inputObj));

        //Generating Access Report Country and Access Report Line Wrapper Data
        if(countryMap!=null){
            mapKey='';
            for(String countryId : countryMap.keySet()){
                AccessReportCountryWrapper tempCountryWrpObj = createReportCountry(countryMap.get(countryId),productCategory,productDescription,
                                                                                    accessReportObj.reportObj.GMAEL_System_Id__c,country_ReportCountryMap.get(countryId));
                for(String engApp: engineeringApplications){
                    AccessReportCountryLineWrapper tempLineRowObj = new AccessReportCountryLineWrapper();
                    mapKey = countryId+'-'+engApp;
                    tempLineRowObj = createReportLine(engApp,countryEngineeringApp_LegisltaionCountryMap.get(mapKey),
                                                        tempCountryWrpObj.reportCountry.GMAEL_System_Id__c, countryEnggApp_ReportLineMap.get(mapKey));
                    
                    if(tempLineRowObj.isRowApplicable==true){
                        tempCountryWrpObj.reportCountryLines.add(tempLineRowObj);                    
                        tempCountryWrpObj.legislationFound = true;
                    }
                }
                accessReportObj.reportCountries.add(tempCountryWrpObj);
            }
        }

        return accessReportObj;
    }

    /*
    * Method to create Access Report SObject record
    */
    public static GMAEL_Report__c createAccessReportRecord(String accId, String contactId, String ginNumber, String systemId, String parentReportId, String filterJSON){
        GMAEL_Report__c reportObj = new GMAEL_Report__c();
        reportObj.GMAEL_Account__c = accId;
        reportObj.GAMEL_Contact__c = contactId;
        reportObj.GMAEL_GIN__c = ginNumber;
        reportObj.GMAEL_System_Id__c = generateSystemId()[0];
        reportObj.GAMEL_Filter_JSON__c = filterJSON;
        if(systemId!=null && systemId!=''){
            reportObj.GMAEL_System_Id__c = systemId;
        }
        if(parentReportId!=null && parentReportId!=''){
            reportObj.GMAEL_Parent_Report__c = parentReportId;
        }
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
        

        if(reportCountryObj!=null){
            reportCountryWrpObj.reportCountry.GMAEL_System_Id__c = reportCountryObj.GMAEL_System_Id__c;
            reportCountryWrpObj.reportCountry.Id = reportCountryObj.Id;                   
            /*if(reportCountryObj.GMAEL_Report_Country_Plug_Types__r!=null && reportCountryObj.GMAEL_Report_Country_Plug_Types__r.size()>0){
                reportCountryWrpObj.reportCountryPlugTypes.clear();
                for(Integer i=0; i<reportCountryObj.GMAEL_Report_Country_Plug_Types__r.size(); i++){
                    AccessReportCountryPlugWrapper plugWrpObj = new AccessReportCountryPlugWrapper();
                    plugWrpObj.reportCountryPlugObj.GMAEL_Report_Country__r =  new GMAEL_Report_Country__c(GMAEL_System_Id__c=reportCountryWrpObj.reportCountry.GMAEL_System_Id__c);
                    plugWrpObj.reportCountryPlugObj.Name = reportCountryObj.GMAEL_Report_Country_Plug_Types__r[i].Name;
                    plugWrpObj.reportCountryPlugObj.GMAEL_Logo_File_URL__c = reportCountryObj.GMAEL_Report_Country_Plug_Types__r[i].GMAEL_Logo_File_URL__c;
                    plugWrpObj.reportCountryPlugObj.GMAEL_Plug_Type_Description__c = reportCountryObj.GMAEL_Report_Country_Plug_Types__r[i].GMAEL_Plug_Type_Description__c;
                    plugWrpObj.reportCountryPlugObj.GAMEL_System_Id__c = reportCountryObj.GMAEL_Report_Country_Plug_Types__r[i].GAMEL_System_Id__c;
                    reportCountryWrpObj.reportCountryPlugTypes.add(plugWrpObj);
                }
            }*/
        }

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
        return reportCountryWrpObj;
    }

    /*
    *
    */
    public static AccessReportCountryLineWrapper createReportLine(String enggApp, GMAEL_Legislation_Country__c legislationCountryObj, String reportCountrySystemId, GMAEL_Report_Line__c reportLineObj){
        AccessReportCountryLineWrapper lineWrpObj = new AccessReportCountryLineWrapper();
        lineWrpObj.reportLineObj.GMAEL_Report_Country__r = new GMAEL_Report_Country__c(GMAEL_System_Id__c=reportCountrySystemId);
        lineWrpObj.reportLineObj.GMAEL_Engineering_Application__c = enggApp;
        lineWrpObj.reportLineObj.GMAEL_System_Id__c = generateSystemId()[0];
        lineWrpObj.reportLineObj.GMAEL_Governance_URL__c = '';
        lineWrpObj.reportLineObj.GMAEL_Governance_URL_Label__c = '';
        lineWrpObj.reportLineObj.GMAEL_Governance_Description__c = '';
        lineWrpObj.reportLineObj.GMAEL_Scheme__c = '';
        lineWrpObj.reportLineObj.GMAEL_Governing_Body__c='';
        lineWrpObj.reportLineObj.GMAEL_Standard__c = '';
        lineWrpObj.reportLineObj.GMAEL_Standard_Conga__c = '';
        lineWrpObj.reportLineObj.GMAEL_Country_Mark__c ='';
        lineWrpObj.reportLineObj.GMAEL_CAB_Accreditation__c = '';
        lineWrpObj.reportLineObj.GMAEL_CAB_Accreditation_Conga__c = '';
        lineWrpObj.reportLineObj.GMAEL_Conformity_Method__c = '';
        lineWrpObj.reportLineObj.GMAEL_Conformity_Method_Conga__c = '';
        lineWrpObj.reportLineObj.GMAEL_Pre_Shipment__c = '';
        lineWrpObj.reportLineObj.GMAEL_Pre_Shipment_Requirement_Conga__c = '';
        lineWrpObj.reportLineObj.GMAEL_Legislation_Additional_Information__c = '';
        lineWrpObj.reportLineObj.GMAEL_Legislation_Additional_Info_Conga__c = '';

        if(legislationCountryObj!=null){
            lineWrpObj.isRowApplicable = true;
            lineWrpObj.reportLineObj.GMAEL_Engineering_Application__c = legislationCountryObj.GMAEL_Engineering_Application__c;
            lineWrpObj.reportLineObj.GMAEL_Governance_URL__c = legislationCountryObj.GMAEL_Governance_URL__c;
            lineWrpObj.reportLineObj.GMAEL_Governance_URL_Label__c = legislationCountryObj.GMAEL_Legislation__r.Name;
            lineWrpObj.reportLineObj.GMAEL_Governance_Description__c = legislationCountryObj.GMAEL_Governance_Description__c;
            lineWrpObj.reportLineObj.GMAEL_Scheme__c = legislationCountryObj.GMAEL_Scheme__c;
            lineWrpObj.reportLineObj.GMAEL_Governing_Body__c = legislationCountryObj.GMAEL_Governing_Body_Name__c;
            
            //Processing standards to generate HTML
            lineWrpObj.reportLineObj.GMAEL_Standard__c = '';
            lineWrpObj.reportLineObj.GMAEL_Standard_Conga__c = '';
            if(legislationCountryObj.GMAEL_Legislation_Standards__r!=null && legislationCountryObj.GMAEL_Legislation_Standards__r.size()>0){
                List<String> listItems = new List<String>();
                for(Integer i=0; i<legislationCountryObj.GMAEL_Legislation_Standards__r.size(); i++){
                    listItems.add(legislationCountryObj.GMAEL_Legislation_Standards__r[i].GAMEL_Standard_Title__c);
                }
                lineWrpObj.reportLineObj.GMAEL_Standard__c = generateHTMLUL('',listItems);
                lineWrpObj.reportLineObj.GMAEL_Standard_Conga__c = generateTextBullet('',listItems);
            }

            lineWrpObj.reportLineObj.GMAEL_Country_Mark__c = legislationCountryObj.GMAEL_Country_Mark__r.GMAEL_Country_Mark__r.GMAEL_Logo_File_URL__c;

            //Processing CAB Accreditation to generate HTML
            lineWrpObj.reportLineObj.GMAEL_CAB_Accreditation__c = '';
            lineWrpObj.reportLineObj.GMAEL_CAB_Accreditation_Conga__c = '';
            if(legislationCountryObj.GMAEL_CAB_Accreditation__c!=null && legislationCountryObj.GMAEL_CAB_Accreditation__c!=''){
                List<String> listItems = new List<String>();
                listItems.addAll(legislationCountryObj.GMAEL_CAB_Accreditation__c.split(';'));
                lineWrpObj.reportLineObj.GMAEL_CAB_Accreditation__c = generateHTMLUL('',listItems);
                lineWrpObj.reportLineObj.GMAEL_CAB_Accreditation_Conga__c = generateTextBullet('',listItems);
            }

            //Processing Conformity Requirement to generate HTML
            lineWrpObj.reportLineObj.GMAEL_Conformity_Method__c = legislationCountryObj.GMAEL_Country_Conformity_Requirement__c;
            lineWrpObj.reportLineObj.GMAEL_Conformity_Method_Conga__c = legislationCountryObj.GMAEL_Country_Conformity_Requirement__c;
            if(legislationCountryObj.GMAEL_Country_Conformity_Types__c!=null && legislationCountryObj.GMAEL_Country_Conformity_Types__c!=''){
                List<String> listItems = new List<String>();
                listItems.addAll(legislationCountryObj.GMAEL_Country_Conformity_Types__c.split(';'));
                lineWrpObj.reportLineObj.GMAEL_Conformity_Method__c = generateHTMLUL(legislationCountryObj.GMAEL_Country_Conformity_Requirement__c,listItems);
                lineWrpObj.reportLineObj.GMAEL_Conformity_Method_Conga__c = generateTextBullet(legislationCountryObj.GMAEL_Country_Conformity_Requirement__c,listItems);
            }

            //Processing Pre-Shipment Requirement to generate HTML
            lineWrpObj.reportLineObj.GMAEL_Pre_Shipment__c = legislationCountryObj.GMAEL_Pre_Shipment_Requirement__c;
            lineWrpObj.reportLineObj.GMAEL_Pre_Shipment_Requirement_Conga__c = legislationCountryObj.GMAEL_Pre_Shipment_Requirement_Conga__c;
            if(legislationCountryObj.GMAEL_Pre_Shipment_Type__c!=null && legislationCountryObj.GMAEL_Pre_Shipment_Type__c!=''){
                List<String> listItems = new List<String>();
                listItems.addAll(legislationCountryObj.GMAEL_Pre_Shipment_Type__c.split(';'));
                lineWrpObj.reportLineObj.GMAEL_Pre_Shipment__c = generateHTMLUL(legislationCountryObj.GMAEL_Pre_Shipment_Requirement__c,listItems);
                lineWrpObj.reportLineObj.GMAEL_Pre_Shipment_Requirement_Conga__c = legislationCountryObj.GMAEL_Pre_Shipment_Requirement_Conga__c;
            }

            //Processing Additional Information to generate HTML
            lineWrpObj.reportLineObj.GMAEL_Legislation_Additional_Information__c = '';
            lineWrpObj.reportLineObj.GMAEL_Legislation_Additional_Info_Conga__c = '';
            if(legislationCountryObj.GMAEL_Legislation_Additional_Information__c!=null && legislationCountryObj.GMAEL_Legislation_Additional_Information__c!=''){
                List<String> listItems = new List<String>();
                listItems.addAll(legislationCountryObj.GMAEL_Legislation_Additional_Information__c.split(';'));
                lineWrpObj.reportLineObj.GMAEL_Legislation_Additional_Information__c = generateHTMLUL('',listItems);
                lineWrpObj.reportLineObj.GMAEL_Legislation_Additional_Info_Conga__c = generateTextBullet('',listItems);
            }
        }
        
        if(reportLineObj!=null){
            lineWrpObj.reportLineObj.GMAEL_System_Id__c=reportLineObj.GMAEL_System_Id__c;
        }

        return lineWrpObj;
    }
    
    /*
    * Method to save data
    */
    public static AccessReportWrapper saveAccessReportData(AccessReportWrapper accessReportObj){

        if(accessReportObj!=null){
            //upsert accessReportObj.reportObj GMAEL_System_Id__c;
            System.debug('----------accessReportObj='+accessReportObj);
            GMAEL_Report__c[] accessReports = [Select Id,GMAEL_Account__c,GAMEL_Contact__c,GMAEL_GIN__c,GMAEL_Report_Status__c,
                                                    GMAEL_Parent_Report__c, GMAEL_System_Id__c, GAMEL_Filter_JSON__c
                                                from GMAEL_Report__c 
                                                where GMAEL_System_Id__c=:accessReportObj.reportObj.GMAEL_System_Id__c];

            if(accessReports.size()>0 && (accessReports[0].GMAEL_Report_Status__c=='Approved' || accessReports[0].GMAEL_Report_Status__c=='Pending Approval')){
                return accessReportObj;
            }
            
            List<GMAEL_Report_Country__c> reportCountriesList = new List<GMAEL_Report_Country__c>();
            List<GMAEL_Report_Country_Plug_Type__c> reportCountryPlugList = new List<GMAEL_Report_Country_Plug_Type__c>();
            List<GMAEL_Report_Line__c> reportCountryLineList = new List<GMAEL_Report_Line__c>();
            List<GMAEL_Report_Country__c> reportCountriesListForDelete = new List<GMAEL_Report_Country__c>();
            Set<String> reportCountryISOCodes = new Set<String>();

            for(Integer i=0; i<accessReportObj.reportCountries.size(); i++){
                if(accessReportObj.reportCountries[i].legislationFound==true){
                    reportCountriesList.add(accessReportObj.reportCountries[i].reportCountry);
                    reportCountryISOCodes.add(accessReportObj.reportCountries[i].reportCountry.GMAEL_Country_ISO_Code__c);
                    for(Integer j=0; j<accessReportObj.reportCountries[i].reportCountryLines.size(); j++){
                        reportCountryLineList.add(accessReportObj.reportCountries[i].reportCountryLines[j].reportLineObj);
                    }
                    for(Integer j=0; j<accessReportObj.reportCountries[i].reportCountryPlugTypes.size(); j++){
                        reportCountryPlugList.add(accessReportObj.reportCountries[i].reportCountryPlugTypes[j].reportCountryPlugObj);
                    }
                }
                if(accessReportObj.reportCountries[i].legislationFound==false && accessReportObj.reportCountries[i].reportCountry.Id!=null){
                    reportCountriesListForDelete.add(accessReportObj.reportCountries[i].reportCountry);
                }
            }

            //Identifying existing and obselete Report Country Records
            GMAEL_Report_Country__c[] reportCountries = [Select GMAEL_Report__c, GMAEL_Report__r.GMAEL_System_Id__c, 
                                                                GMAEL_Country_Name__c, GMAEL_Country_ISO_Code__c,
                                                                GMAEL_Method_of_Conformity__c, GMAEL_National_Deviation_Supply_Voltage__c, 
                                                                GMAEL_National_Deviation_Supply_Freqncy__c,
                                                                GMAEL_Product_Category__c,GMAEL_Product_Description__c,
                                                                GMAEL_Scheme_Document__c,GMAEL_System_Id__c
                                                            from GMAEL_Report_Country__c 
                                                            where GMAEL_Report__r.GMAEL_System_Id__c=:accessReportObj.reportObj.GMAEL_System_Id__c
                                                            and GMAEL_Country_ISO_Code__c not in: reportCountryISOCodes];
            if(reportCountries.size()>0){
                reportCountriesListForDelete.addAll(reportCountries);
            }
            if(reportCountriesListForDelete.size()>0){
                delete reportCountriesListForDelete;
            }

            //Identifying existing and obselete Report Country Plug Type Records
            GMAEL_Report_Country_Plug_Type__c[] obseletePlugTypes = [Select Id 
                                                                        from GMAEL_Report_Country_Plug_Type__c
                                                                        where GMAEL_Report_Country__r.GMAEL_Report__r.GMAEL_System_Id__c=:accessReportObj.reportObj.GMAEL_System_Id__c];
            System.debug('----------accessReportObj.reportObj.GMAEL_System_Id__c='+accessReportObj.reportObj.GMAEL_System_Id__c);
            System.debug('-----------obseletePlugTypes='+obseletePlugTypes);
            if(obseletePlugTypes.size()>0){
                delete obseletePlugTypes;
            }

            //Upserting Report Data
            if(reportCountriesList.size()>0){
                upsert accessReportObj.reportObj GMAEL_System_Id__c;
                upsert reportCountriesList GMAEL_System_Id__c;
            }
            if(reportCountryLineList.size()>0){
                upsert reportCountryLineList GMAEL_System_Id__c;
            }
            if(reportCountryPlugList.size()>0){
                upsert reportCountryPlugList GAMEL_System_Id__c;
            }
        }
        
        return accessReportObj;
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

    /*
    * Method to genereate HTML Unordered List content with header.
    */
    public static String generateHTMLUL(String header, List<String> listItems){
        String htmlStr='';

        if(header!=null && header!=''){
            htmlStr+='<h4>'+header+'</h4>';
        }

        if(listItems.size()>0){
            listItems.sort();
            htmlStr+='<ul>';
            for(Integer i=0; i<listItems.size(); i++){
                htmlStr+='<li>'+listItems[i]+'</li>';
            }
            htmlStr+='</ul>';
        }
        return htmlStr;
    }

    /*
    * Method to genereate HTML Unordered List content with header.
    */
    public static String generateTextBullet(String header, List<String> listItems){
        String textBulletsStr='';

        if(header!=null && header!=''){
            textBulletsStr+= header+'\n';
        }

        if(listItems.size()>0){
            listItems.sort();
            for(Integer i=0; i<listItems.size(); i++){
                textBulletsStr += '- '+listItems[i]+'\n';
            }
        }
        return textBulletsStr;
    }
}