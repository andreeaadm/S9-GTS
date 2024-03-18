public with sharing class AssetTrgHandler extends TriggerHandler {
  public override void beforeInsert() {
    List<Asset> newAssets = (List<Asset>) Trigger.new;
    Map<Id, Asset> oldAssets = (Map<Id, Asset>) Trigger.oldMap;
    //AssetUtil.updateAssetSyncDate(newAssets,oldAssets);
    AssetUtil.updateTokenizedProdCoveredNoDML((List<Asset>) Trigger.new, null);
  }
  public override void beforeUpdate() {
    List<Asset> newAssets = (List<Asset>) Trigger.new;
    Map<Id, Asset> oldAssets = (Map<Id, Asset>) Trigger.oldMap;
   // AssetUtil.updateAssetSyncDate(newAssets,oldAssets);
    AssetUtil.updateTokenizedProdCoveredNoDML(
      (List<Asset>) Trigger.new,
      (Map<Id, Asset>) Trigger.oldMap
    );
  }

  public override void afterInsert() {
    List<Asset> newAssets = (List<Asset>) Trigger.new;
    Map<Id, Asset> oldAssets = (Map<Id, Asset>) Trigger.oldMap;
    AssetUtil.updateAssetSyncDate(newAssets,oldAssets);//prateek
    DefaultGroupUtil.newAssetAddToDefaultGroup(newAssets);
    ReportAccessUtil.newAssets(AssetUtil.filterDeliverables(newAssets));

    AssetUtil.alignContactIdWithParentContactId(
      newAssets,
      new Map<Id, Asset>()
    );
    AccountRelationUtil.updateRoleWhenReportContact(
      newAssets,
      new Map<Id, Asset>()
    );
    
    AssetUtil.updateLastActivityDateWhenNewAsset(newAssets); 
  }

    public override void afterUpdate() {
        List<Asset> newAssets = (List<Asset>) Trigger.new;
        Map<Id, Asset> oldAssets = (Map<Id, Asset>) Trigger.oldMap;
        AssetUtil.updateAssetSyncDate(newAssets,oldAssets); //prateek
        List<Asset> reportsWithAccountChange = AssetUtil.filterReportWithAccountChange(
            newAssets,
            oldAssets
        );
        if (!reportsWithAccountChange.isEmpty()) {
            AssetUtil.cleanupRefsAfterTransfer(reportsWithAccountChange);
            DefaultGroupUtil.newAssetAddToDefaultGroup(reportsWithAccountChange);
        }
        AssetUtil.alignContactIdWithParentContactId(newAssets, oldAssets);
        AccountRelationUtil.updateRoleWhenReportContact(newAssets, oldAssets);
        
        List<Asset> reportsWithDateChanges = AssetUtil.filterReportWithDateChange(
            newAssets,
            oldAssets
        );
        if (!reportsWithDateChanges.isEmpty()) {
            AssetUtil.updateLastActivityDate(reportsWithDateChanges,oldAssets); 
        }
    }
}