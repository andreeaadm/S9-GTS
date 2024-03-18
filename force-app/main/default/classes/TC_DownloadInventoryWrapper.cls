/******************************************************************************
Created Date: May 2022
@description: Support wrapper class of TC_DownloadInventoryController which 
creates mapping of CSV coloumns and rows for invntory line items
@test class: TC_DownloadInventoryWrapper_Test
@author: Intertek
Modification History:
Ver			Date			Author			Modification
1.0         Nov 2023      	Akshay          Added mappings for Inditex classification fields(TBS-59)
2.0  		Jan 2024		Yash			Added Commodity Chemical & Type of Chemical Fields(TBS-61)

******************************************************************************/
public class TC_DownloadInventoryWrapper {
    @AuraEnabled
    public String supplierName;
    @AuraEnabled
    public String facilityName;
    @AuraEnabled
    public String inventoryName;
    @AuraEnabled
    public List<InventoryLine> lineItems;
    
    public TC_DownloadInventoryWrapper(
        List<Inventory_Line_Item__c> rawLineItems
    ) {
        if (rawLineItems.size() > 0) {
            this.supplierName = rawLineItems[0].Inventory__r.Facility__r.Parent.Name;
            this.facilityName = rawLineItems[0].Inventory__r.Facility__r.Name;
            this.inventoryName = rawLineItems[0].Inventory__r.Inventory_Name__c;
        }
        
        this.lineItems = new List<InventoryLine>();
        for (Inventory_Line_Item__c ili : rawLineItems) {
            this.lineItems.add(new InventoryLine(ili));
        }
    }
    
    public class InventoryLine {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String inventoryName;
        @AuraEnabled
        public String inventoryDate;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String chemicalProduct;
        @AuraEnabled
        public String chemicalProductName;
        @AuraEnabled
        public String formulatorName;
        @AuraEnabled
        public String otherName;
        @AuraEnabled
        public String substrate;
        @AuraEnabled
        public String otherCertifications;
        @AuraEnabled
        public String zdhcMRSL;
        @AuraEnabled
        public String zdhcMRSLVersion;
        @AuraEnabled
        public String conformant;
        @AuraEnabled
        public String productId;
        @AuraEnabled
        public String productGUID;
        @AuraEnabled
        public String unit;
        @AuraEnabled
        public String stockTakeMonthBegin;
        @AuraEnabled
        public String deliveredStock;
        @AuraEnabled
        public String stockTakeMonthEnd;
        @AuraEnabled
        public String calculatedUsage;
        @AuraEnabled
        public String calculatedWeight;
        @AuraEnabled
        public String deliveredStockHistory;
        @AuraEnabled
        public String storageLocation;
        @AuraEnabled
        public String lotNumber;
        @AuraEnabled
        public String expiryDate;
        @AuraEnabled
        public String CASNumber;
        @AuraEnabled
        public String SupplierReferenceNumber;
        @AuraEnabled
        public String SupplierReferenceName;
        @AuraEnabled
        public String ProductName_LocalLangauge;
        @AuraEnabled
        public String FormulatorName_LocalLangauge;
        @AuraEnabled
        public String InditexClassificationForBabies;
        @AuraEnabled
        public String InditexClassificationForChildAdult;
        @AuraEnabled
        public String CommodityChemicalStandardName;
        @AuraEnabled
        public String TypeofChemicals;

        
        public InventoryLine(Inventory_Line_Item__c lineItem) {
            this.name = StringUtil.formatForCsv(lineItem.Name);
            this.inventoryName = StringUtil.formatForCsv(
                lineItem.Inventory__r.Inventory_Name__c
            );
            this.inventoryDate = StringUtil.formatForCsv(
                String.valueOf(lineItem.Inventory__r.Inventory_Date__c)
            );
            this.type = StringUtil.formatForCsv(lineItem.Inventory__r.Type__c);
            this.chemicalProduct = StringUtil.formatForCsv(
                lineItem.Chemical_Product__r.Name
            );
            this.chemicalProductName = StringUtil.formatForCsv(
                lineItem.Chemical_Product_Name__c
            );
            this.formulatorName = StringUtil.formatForCsv(
                lineItem.Formulator_Name__c
            );
            this.otherName = StringUtil.formatForCsv(
                lineItem.Product_Trade_Name_Other_Name__c
            );
            this.substrate = StringUtil.formatForCsv(lineItem.Substrate__c);
            this.otherCertifications = StringUtil.formatForCsv(
                lineItem.Other_Certifications__c
            );
            this.zdhcMRSL = StringUtil.formatForCsv(lineItem.ZDHC_MRSL_v2_0__c);
            this.zdhcMRSLVersion = StringUtil.formatForCsv(lineItem.ZDHC_MRSL_Version__c);
            this.conformant = lineItem.Conformant__c ? Label.Yes : Label.No;
            this.productId = StringUtil.formatForCsv(lineItem.ZDHC_Product_Id__c);
            this.productGUID = StringUtil.formatForCsv(lineItem.ZDHC_Product_GUID__c);
            this.unit = StringUtil.formatForCsv(lineItem.Unit__c);
            this.stockTakeMonthBegin = StringUtil.formatForCsv(
                String.valueOf(lineItem.Stock_Take_Month_Begin__c)
            );
            this.deliveredStock = StringUtil.formatForCsv(
                String.valueOf(lineItem.Delivered_Stock_This_Month__c)
            );
            this.stockTakeMonthEnd = StringUtil.formatForCsv(
                String.valueOf(lineItem.Stock_Take_Month_End__c)
            );
            this.calculatedUsage = StringUtil.formatForCsv(
                String.valueOf(lineItem.Calculated_Usage__c)
            );
            this.calculatedWeight = StringUtil.formatForCsv(
                String.valueOf(lineItem.Calculated_Weight_kg__c)
            );
            this.deliveredStockHistory = StringUtil.formatForCsv(
                lineItem.Delivered_Stock_History__c
            );
            this.storageLocation = StringUtil.formatForCsv(
                lineItem.Storage_Location__c
            );
            this.lotNumber = StringUtil.formatForCsv(lineItem.Lot_Number__c);
            this.expiryDate = StringUtil.formatForCsv(
                String.valueOf(lineItem.Expiry_Date__c)
            );
            this.CASNumber = StringUtil.formatForCsv(
                lineItem.Chemical_Product__r.CAS_Number__c
                );
            this.SupplierReferenceName = StringUtil.formatForCsv(
                lineItem.Supplier_Reference_Name__c
                );
            this.SupplierReferenceNumber = StringUtil.formatForCsv(
                lineItem.Supplier_Reference_Number__c
                );
            this.ProductName_LocalLangauge = StringUtil.formatForCsv(
                lineItem.Product_Name_Local_Language__c
                );
            this.FormulatorName_LocalLangauge = StringUtil.formatForCsv(
                lineItem.Formulator_Name_Local_Language__c
                );
            this.InditexClassificationForBabies = StringUtil.formatForCsv(lineItem.Inditex_Classification_for_Babies__c);
            this.InditexClassificationForChildAdult = StringUtil.formatForCsv(lineItem.Inditex_Classification_for_Child_Adult__c);
            this.CommodityChemicalStandardName = StringUtil.formatForCsv(lineItem.Commodity_Chemical_Standard_Name__c);
            this.TypeofChemicals = StringUtil.formatForCsv(lineItem.Type_of_Chemicals__c);
        }
    }
}