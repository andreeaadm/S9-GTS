@isTest(SeeAllData=false)
public with sharing class contentVersionTriggerHandlerTest {
    @IsTest
    public static void checkRecallOrRegulationTest(){

        //Regulation data setup
        List<Regulation__c> regList = new List<Regulation__c>();

        Regulation__c reg1 = new Regulation__c();
        reg1.Age_Range__c = 'Adult';
        reg1.Category__c = 'Apparel';
        reg1.Legal_Regulation_Name__c = 'testLegalName';
        reg1.Market__c = 'Australia';
        reg1.Material__c = 'Coated material / Synthetic Sheet (PVC, PU)';
        reg1.Technical_Details__c = 'The scope of this Law applies to products which are intended for direct food contact, as well as other product categories such as Toys.[rtaImage]';
        regList.add(reg1);

        Regulation__c reg2 = new Regulation__c();
        reg2.Age_Range__c = 'Adult;Children 3 Years Or Above;Children Under 3 Years Of Age';
        reg2.Category__c = 'Accessories;Apparel;Art Material;Childcare product;Children’s Drinking equipment;Cookware;Decoration;Food contact article;Food contact material;Foodstuff;Footwear;Furniture (adult);Furniture (child);Hardgoods;Health and Beauty;Homesoft;Office equipment;Personal protective equipment;Playground equipment;Sleepwear;Sport;Stationery;Toy';
        reg2.Legal_Regulation_Name__c = 'China Compulsory Certification Mark Management Rules';
        reg2.Market__c = 'China';
        reg2.Material__c = 'Adhesive;Art material;Ceramic;Coated material / Synthetic Sheet (PVC, PU);Coating;Feather and Down;Foam;Gel;Glass;Lacquer;Leather;Liquid;Metal;Modelling Clay;Paper;Plastic;Polymer;Putty;PVC;Real fur, feathers;Sand Material;Slime;Stone;Synthetic fill material;Textile;Wood';
        reg2.Technical_Details__c = 'The China Compulsory Certification (CCC) applies to certain products both imported to and manufactured in China.[Title]';
        regList.add(reg2);

        insert regList;

        //Recall data setup
        List<Recall__c> recallList = new List<Recall__c>();

        Recall__c recall1 = new Recall__c();
        recall1.CurrencyIsoCode = 'USD';
        recall1.Images__c = '[Title]';
        recall1.Name = 'testRecallName';
        recallList.add(recall1);

        Recall__c recall2 = new Recall__c();
        recall2.CurrencyIsoCode = 'USD';
        recall2.Images__c = '[rtaImage]';
        recall2.Name = 'China Recall';
        recallList.add(recall2);

        insert recallList;

        //Content Version data setup
        List<ContentVersion> conVerList = new List<ContentVersion>();

        ContentVersion con1 = new ContentVersion();
        con1.Title = 'rtaImage';
        con1.VersionData =  EncodingUtil.base64Decode(EncodingUtil.urlEncode('Unit Test Attachment Body','UTF-8'));
        con1.PathOnClient = 'logo.png';
        con1.FirstPublishLocationId = reg1.Id;
        conVerList.add(con1);

        ContentVersion con2 = new ContentVersion();
        con2.Title = 'Title';
        con2.VersionData =  EncodingUtil.base64Decode(EncodingUtil.urlEncode('Unit Test Attachment Body','UTF-8'));
        con2.PathOnClient = 'logo.png';
        con2.FirstPublishLocationId = reg2.Id;
        conVerList.add(con2);

        ContentVersion con3 = new ContentVersion();
        con3.Title = 'rtaImage';
        con3.VersionData =  EncodingUtil.base64Decode(EncodingUtil.urlEncode('Unit Test Attachment Body','UTF-8'));
        con3.PathOnClient = 'logo.png';
        con3.FirstPublishLocationId = recall2.Id;
        conVerList.add(con3);

        ContentVersion con4 = new ContentVersion();
        con4.Title = 'Title';
        con4.VersionData =  EncodingUtil.base64Decode(EncodingUtil.urlEncode('Unit Test Attachment Body','UTF-8'));
        con4.PathOnClient = 'logo.png';
        con4.FirstPublishLocationId = recall1.Id;
        conVerList.add(con4);

        Test.startTest();
        insert conVerList;
        Test.stopTest();
        
    }
   
}