/**
 * TC_SynchroniseProducts
 * Given a list of chemicals, checks with the remote ZDHC Gateway service to
 * discover if any of these products have been updated. Implemented as a
 * Schedulable that is Batchable.
 *
 * At the time of implementing, we have to work around limitations of
 * GET /products.
 *
 * Idealy we would collect a list of productGUIDs in a batch then call
 * GET /products with productGUID=guid0,guid1,guid2,guid3...  To request
 * precise results for example 200 productGUIDs, but this is not currently
 * available.
 *
 * We could perform a callout for each product in the batch, one by one.
 *
 * Instead, we hope to get many or most products for one batch using just a
 * few callouts, by searching for products using their formulatorName.
 *
 * formulatorGUID is not currently a searchable field.
 *
 * Searching by formulatorName also has limitations. The response when
 * searching for a name with quotes, combining diacritics, and Chinese glyphs
 * is:
 *   500 Internal Server Error, with errorMessage "No results found."
 *
 * Can be scheduled:
 *   System.schedule(TC_SynchroniseProducts.CRON_NAME, TC_SynchroniseProducts.CRON_EXPRESSION, new TC_SynchroniseProducts('Scheduled'));
 *
 * Can be batched:
 *   Database.executebatch(new TC_SynchroniseProducts(false), 75);
 *
 * Fields to update:
 *  o Chemical Product Name
 *  o Product Trade Name
 *  o Product Code
 *  o ZDHC PID
 *  o Registered
 *  o Product ID
 *  o Last Verified date time
 *  o ZDHC Certification JSON.
 *  o Other Certifications
 *  o ZDHC MRSL v2.0
 *  o Formulator (lookup) – update if its changed
 *
 * @author Alan West (oe:gen)
 */
global class TC_SynchroniseProducts implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts/*, Database.Stateful*/ {
  public static final String CRON_EXPRESSION = '0 0 2 * * ?';
  public static final String CRON_NAME = 'TC_SynchroniseProducts Nightly 02:00 Pull From ZDHC Gateway';

  /**
   * count of all the Chemical Products matching the criteria before batching.
   */
  private Integer count;
  /**
   * result Used during synchronisation as a final result.
   */
  private final SynchronisationResult result;
  /**
   * userAccessKey The ZDHC User Access Keys to use for ZDHC Gateway requests.
   */
  private String userAccessKey/* = ZDHC_Access_Key__mdt.getInstance(
      'Sync_Chemical_Products_Key'
    )
    .ZDHC_User_Access_Key__c*/;
  /**
   * sendReportEmail Enable/disable sending the report email.
   */
  private Boolean sendReportEmail;
  

  /**
   * TC_SynchroniseProducts Construct with option for sending report email.
   * @param sendReportEmail (Boolean): true to send the report email.
   * @param syncInditexProducts (Boolean): true to sync inditex products.
   */
  public TC_SynchroniseProducts(Boolean sendReportEmail) {
    this.sendReportEmail = sendReportEmail;
    result = new SynchronisationResult();
  }

  /**
   * execute Implements the Schedulable interace, used to begin executing the
   * batchable task.
   *
   * System.schedule(TC_SynchroniseProducts.CRON_NAME, TC_SynchroniseProducts.CRON_EXPRESSION, new TC_SynchroniseProducts(true));
   *
   */
  global void execute(SchedulableContext sc) {
    // Uses callouts which are limited to 100, worst cases:
    // 100 limit used up because all products have a different formulator.
    // 100 limit used up by paging through 100,000 products for one formulator.
    Database.executebatch(this, 75);
  }

  /**
   * start Implements the start of the batch task, queries for all records
   * which will be processed in batches.
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    List<String> fields = new List<String>{
      'Id',
      'Origin__c',
      'ZDHC_Product_GUID__c',
      'Chemical_Product_Name__c',
      'Product_Trade_Name_Other_Name__c',
      'Product_Status__c',
      'ZDHC_Product_Code__c',
      'ZDHC_PID__c',
      'Registered__c',
      'ZDHC_Product_Id__c',
      'Last_Verified_Date__c',
      'ZDHC_Certification_JSON__c',
      'Other_Certifications__c',
      'ZDHC_MRSL_v2_0__c',
      'ZDHC_MRSL_Version__c',
      'ZDHC_Formulator_GUID__c',
      'Formulator__c',
      'Formulator__r.Name',
      '(SELECT Id,Origin__c, ZDHC_MRSL_v2_0__c,ZDHC_MRSL_Version__c, Other_Certifications__c,ZDHC_Certification_JSON__c, ZDHC_Product_GUID__c, ZDHC_Product_Id__c FROM Inventory_Line_Items__r WHERE Inventory__r.Status__c = \'Pending\' AND (Inventory__r.Inventory_Date__c = LAST_MONTH OR Inventory__r.Inventory_Date__c = THIS_MONTH))'
    };
    String whereClause = ' WHERE ZDHC_Product_GUID__c != NULL';
    count = Database.countQuery(
      'SELECT COUNT() FROM Chemical_Product__c' + whereClause
    );
    return Database.getQueryLocator(
      'SELECT ' +
      String.join(fields, ',') +
      ' FROM Chemical_Product__c' +
      whereClause +
      ' ORDER BY Formulator__r.Name ASC'
    );
  }
  /**
   * execute Processes a batch of records.
   */
  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    try {
       
        TCSynchroniseProductsLogging__c TCSyncLog = TCSynchroniseProductsLogging__c.getOrgDefaults();
        count = scope.size();
        
        SynchronisationResult chunk = synchronise(
            (List<Chemical_Product__c>) scope
        );
        chunk.doUpdates();
        result.addAll(chunk); 
        
        TCSyncLog.count__c += count;
        TCSyncLog.updated__c += result.updated.size();
        TCSyncLog.notChanged__c += result.notChanged.size();
        TCSyncLog.deactivated__c += result.deactivated.size();
        TCSyncLog.notFound__c += result.notFound.size();
        TCSyncLog.Result_Size__c += result.updated.size() + result.notChanged.size() + result.deactivated.size() + result.notFound.size();
        TCSyncLog.formulatorChanged__c += result.formulatorChanged.size();
        TCSyncLog.formulatorNameUpdated__c += result.formulatorNameUpdated.size();
        TCSyncLog.inventoryLineItemUpdates__c += result.inventoryLineItemUpdates;
        TCSyncLog.errors__c += String.join(result.errors, '\n');
        
        update TCSyncLog;
        
    } catch (Exception e) {
      result.errors.add(e.getMessage() + '\n' + e.getStackTraceString());
    }
  }
    
  /**
   * finish When all the batches have been processed, the final steps.
   */
  public void finish(Database.BatchableContext bc) {
    if (sendReportEmail) {
        TCSynchroniseProductsLogging__c TCSyncLog = TCSynchroniseProductsLogging__c.getOrgDefaults();
      AsyncApexJob a = [
        SELECT
          Id,
          Status,
          NumberOfErrors,
          JobItemsProcessed,
          TotalJobItems,
          CreatedBy.Email
        FROM AsyncApexJob
        WHERE Id = :bc.getJobId()
      ];
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      String[] toAddresses = new List<String>{ a.CreatedBy.Email };
      mail.setToAddresses(toAddresses);
      mail.setSubject('TC_SynchroniseProducts ' + a.Status);

      String body =
        'TC_SynchroniseProducts pulls updates from ZDHC Gateway.\n' +
        'The batch Apex job processed ' +
        a.TotalJobItems +
        ' batches with ' +
        a.NumberOfErrors +
        ' failures.\n';

      body += 'Job size: ' + Integer.valueOf(TCSyncLog.count__c) + ' Chemical Products\n';
      body += 'Updated: ' + Integer.valueOf(TCSyncLog.updated__c) + '\n';
      body += 'No changes: ' + Integer.valueOf(TCSyncLog.notChanged__c) + '\n';
      body += 'Not found and deactivated: ' + Integer.valueOf(TCSyncLog.deactivated__c) + '\n';
      body +=
        'Not found, previously deactivated: ' +
        Integer.valueOf(TCSyncLog.notFound__c) +
        '\n';
      body +=
        'Result size: ' + Integer.valueOf(TCSyncLog.Result_Size__c) +
        '\n';
      body +=
        'Chemical Products which changed Formulator: ' +
        Integer.valueOf(TCSyncLog.formulatorChanged__c) +
        '\n';
      body +=
        'Formulator name updates: ' +
        Integer.valueOf(TCSyncLog.formulatorNameUpdated__c) +
        '\n';
      body +=
        'Pending Inventory Line Item updates, this month and last: ' +
        Integer.valueOf(TCSyncLog.inventoryLineItemUpdates__c) +
        '\n';

      if (result.errors.size() > 0) {
        body += '\nError messages:\n';
        body += Integer.valueOf(TCSyncLog.errors__c);
      }
      mail.setCharset('UTF-8');
      mail.setPlainTextBody(body);
      try{
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        TCSyncLog.count__c = 0;
        TCSyncLog.updated__c = 0;
        TCSyncLog.notChanged__c = 0;
        TCSyncLog.deactivated__c = 0;
        TCSyncLog.notFound__c = 0;
        TCSyncLog.Result_Size__c = 0;
        TCSyncLog.formulatorChanged__c = 0;
        TCSyncLog.formulatorNameUpdated__c = 0;
        TCSyncLog.inventoryLineItemUpdates__c = 0;
        TCSyncLog.errors__c = null;
        update TCSyncLog;
      }catch(Exception e){
        //When deploying to environments where deliverability is set to System or off.
        System.debug(LoggingLevel.INFO,e.getMessage()+' : Likely cause is Email Deliverability set to off.');
      }
    }
  }

  /**
   * SynchronisationResult
   * Performs the comparissons with the supplied remote data.
   * Collects/sorts the synchronisation results into separate lists.
   * Used by TC_SynchroniseProductsFromZDHC to collect all processed products.
   * Also used in a loop for chunks of synchronised products processed.
   */
  @TestVisible
  private without sharing class SynchronisationResult {
    public List<ZDHC_Error_Log__c> calloutLogEntries;
    public List<Chemical_Product__c> checkNext;
    public List<Chemical_Product__c> notFound;
    public List<Chemical_Product__c> deactivated;
    public List<Chemical_Product__c> notChanged;
    public List<Chemical_Product__c> updated;
    public List<Chemical_Product__c> formulatorChanged;
    public Map<Id, Formulator__c> formulatorNameUpdated;
    public Integer inventoryLineItemUpdates;
    public List<String> errors;

    public SynchronisationResult() {
      calloutLogEntries = new List<ZDHC_Error_Log__c>();
      checkNext = new List<Chemical_Product__c>();
      notFound = new List<Chemical_Product__c>();
      deactivated = new List<Chemical_Product__c>();
      notChanged = new List<Chemical_Product__c>();
      updated = new List<Chemical_Product__c>();
      formulatorChanged = new List<Chemical_Product__c>();
      formulatorNameUpdated = new Map<Id, Formulator__c>();
      inventoryLineItemUpdates = 0;
      errors = new List<String>();
    }

    /**
     * addAll A chunk of synchronisation has been processed, so add this chunk of
     * synchronisation results to these results.
     * @param other (SynchronisationResult): The chunk of results processed.
     */
    public void addAll(SynchronisationResult other) {
      calloutLogEntries.addAll(other.calloutLogEntries);
      checkNext.addAll(other.checkNext);
      notFound.addAll(other.notFound);
      deactivated.addAll(other.deactivated);
      notChanged.addAll(other.notChanged);
      updated.addAll(other.updated);
      formulatorChanged.addAll(other.formulatorChanged);
      formulatorNameUpdated.putAll(other.formulatorNameUpdated);
      inventoryLineItemUpdates += other.inventoryLineItemUpdates;
      errors.addAll(other.errors);
    }

    /**
     * pull Pulls in any updated fields from the remote data. Organising this
     * result into appropriate lists based on what needs to happen next.
     * @param local (Chemical_Product__c): The updateable record.
     * @param remote (ZDHCGetProductsResponseData): The record in ZDHC Gateway.
     */
    public void pull(
      Chemical_Product__c local,
      ZDHCGetProductsResponseData remote
    ) {
      String certificationJson = remote.ProductCertifications != null
        ? JSON.serialize(remote.ProductCertifications, true)
        : null;
      Integer changes = 0;
      //update the ZDHC status
      local.Last_Verified_Date__c = Datetime.now();
      local.ZDHC_Status__c = 'Success';
      
        if (local.Product_Status__c == 'Deactivated') {
            local.Product_Status__c = 'Active';
            changes++;
        }
      if (local.Chemical_Product_Name__c != remote.productName) {
        local.Chemical_Product_Name__c = remote.productName;
        changes++;
      }
      if (local.Product_Trade_Name_Other_Name__c != remote.OtherName) {
        local.Product_Trade_Name_Other_Name__c = remote.OtherName;
        changes++;
      }
      if (local.ZDHC_Product_Code__c != remote.productCode) {
        local.ZDHC_Product_Code__c = remote.productCode;
        changes++;
      }
      if (local.ZDHC_PID__c != remote.zdhcPID) {
        local.ZDHC_PID__c = remote.zdhcPID;
        changes++;
      }
      if (local.Registered__c != remote.registered) {
        local.Registered__c = remote.registered;
        changes++;
      }
      if (local.ZDHC_Product_Id__c != remote.ProductID) {
        local.ZDHC_Product_Id__c = remote.ProductID;
        changes++;
      }
      if (local.ZDHC_Formulator_GUID__c != remote.formulatorGUID) {
        local.ZDHC_Formulator_GUID__c = remote.formulatorGUID;
        changes++;
      }
      if (local.ZDHC_Certification_JSON__c != certificationJson) {
        local.ZDHC_Certification_JSON__c = certificationJson;
        changes++;
      }
      if (remote.ProductCertifications != null) {
        Map<String, String> parsed = TC_ParseProductCertifications.parse(
          remote.ProductCertifications
        );
          
          if(parsed.get('mrsl2') == 'Level 1' || parsed.get('mrsl2') == 'Level 2' || parsed.get('mrsl2') == 'Level 3'){
              local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
              local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v2.0';
              changes++;
          }
          if(parsed.get('mrsl2') == 'Expired'){
              local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
              local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v2.0';
              changes++;
          }
          if(parsed.get('mrsl2') == 'Registered'){
              local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
              local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v2.0';
              changes++;
          }
          
          if(parsed.get('mrsl3') == 'Level 1' || parsed.get('mrsl3') == 'Level 2' || parsed.get('mrsl3') == 'Level 3'){
              local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl3');
              local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v3.1';
              changes++;
          }
          if(parsed.get('mrsl3') == 'Expired'){
              if(parsed.get('mrsl2') == 'Level 1' || parsed.get('mrsl2') == 'Level 2' || parsed.get('mrsl2') == 'Level 3'){
                  local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
                  local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v2.0';
                  changes++;
              }
              else{
                  local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl3');
                  local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v3.1';
                  changes++;
              }
          }
          if(parsed.get('mrsl3') == 'Registered'){
              if(parsed.get('mrsl2') == 'Level 1' || parsed.get('mrsl2') == 'Level 2' || parsed.get('mrsl2') == 'Level 3'){
                  local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
                  local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v2.0';
                  changes++;
              }
              else{
                  local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl3');
                  local.ZDHC_MRSL_Version__c = 'ZDHC MRSL v3.1';
                  changes++;
              }
          }   
              
          if(parsed.get('mrsl3') == null && parsed.get('mrsl2') == null){
              local.ZDHC_MRSL_v2_0__c = '-';
              local.ZDHC_MRSL_Version__c = '-';
              changes++;
          }
          
           /*if (local.ZDHC_MRSL_v2_0__c != parsed.get('mrsl2')) {
local.ZDHC_MRSL_v2_0__c = parsed.get('mrsl2');
changes++;
} */

          if (
              local.Other_Certifications__c != parsed.get('otherCertifications')
          ) {
              local.Other_Certifications__c = parsed.get('otherCertifications');
              changes++;
          }
          if((parsed.get('mrsl2') == 'Level 1' || parsed.get('mrsl2') == 'Level 2' || parsed.get('mrsl2') == 'Level 3') &&
             (parsed.get('mrsl3') == 'Level 1' || parsed.get('mrsl3') == 'Level 2' || parsed.get('mrsl3') == 'Level 3')
            ){
                local.Other_Certifications__c += '\r\n ZDHC MRSL v2.0 - ' + parsed.get('mrsl2');
            } 
          
      } else {
        // No certifications.
          local.ZDHC_MRSL_v2_0__c = '-';
          local.ZDHC_MRSL_Version__c = '-';
          changes++;
        if (local.Other_Certifications__c != null) {
          local.Other_Certifications__c = null;
          changes++;
        }
      }
      if (local.ZDHC_Formulator_GUID__c != remote.formulatorGUID) {
        // I doubt this ever changes, as it identifies that record.
        // If this does change, a new Formulator__c will need creating.
        local.ZDHC_Formulator_GUID__c = remote.formulatorGUID;
        changes++;
        formulatorChanged.add(local);
      } else if (
        local.Formulator__c != null &&
        local.Formulator__r.Name != remote.formulatorName.trim() &&
        !formulatorNameUpdated.containsKey(local.Formulator__c)
      ) {
        // Same Formulator__c, but the Name updated.
        formulatorNameUpdated.put(
          local.Formulator__c,
          new Formulator__c(
            Id = local.Formulator__c,
            Name = remote.formulatorName.trim()
          )
        );
      }
      if (changes > 0) {
        updated.add(local);
      } else {
        notChanged.add(local);
      }
    }

    /**
     * pull Pulls in any updated fields from the remote data. Organising this
     * result into appropriate lists based on what needs to happen next.
     * @param local (List<Chemical_Product__c>): A list of products to process.
     * @param remote (Map<String, ZDHCGetProductsResponseData>): Find updates
     *        in this remote data.
     */
    public void pull(
      List<Chemical_Product__c> local,
      Map<String, ZDHCGetProductsResponseData> remote
    ) {
      for (Chemical_Product__c product : local) {
        if (remote.containsKey(product.ZDHC_Product_GUID__c)) {
          pull(product, remote.get(product.ZDHC_Product_GUID__c));
        } else {
          checkNext.add(product);
        }
      }
    }

    public void doUpdates() {
      if (!formulatorNameUpdated.isEmpty()) {
        update formulatorNameUpdated.values();
      }
      if (!formulatorChanged.isEmpty()) {
        // Lookup Formulator__c when GUID changed.
        Map<String, Id> formulatorIdByGUID = new Map<String, Id>();
        for (Chemical_Product__c p : formulatorChanged) {
          if (!formulatorIdByGUID.containsKey(p.ZDHC_Formulator_GUID__c)) {
            formulatorIdByGUID.put(p.ZDHC_Formulator_GUID__c, null);
          }
        }
        for (Formulator__c f : [
          SELECT Id, ZDHC_Formulator_GUID__c
          FROM Formulator__c
          WHERE ZDHC_Formulator_GUID__c IN :formulatorIdByGUID.keySet()
        ]) {
          formulatorIdByGUID.put(f.ZDHC_Formulator_GUID__c, f.Id);
        }
        for (Chemical_Product__c p : updated) {
          if (
            formulatorIdByGUID.containsKey(p.ZDHC_Formulator_GUID__c) &&
            p.Formulator__c != formulatorIdByGUID.get(p.ZDHC_Formulator_GUID__c)
          ) {
            p.Formulator__c = formulatorIdByGUID.get(p.ZDHC_Formulator_GUID__c);
          }
        }
      }
        List<Chemical_Product__c> notChangedProducts = new List<Chemical_Product__c>();
        if (!notChanged.isEmpty()) {
            update notChanged;
            
            notChangedProducts.addAll(notChanged);
        }
        if (!notChangedProducts.isEmpty()) {
            // Also update Inventory Line Items recording these Chemical Products.
            inventoryLineItemUpdates = updateRelatedLineItems(notChangedProducts);
        }
      if (!notFound.isEmpty()) {
        update notFound;
      }

      List<Chemical_Product__c> updatedOrDeactivated = new List<Chemical_Product__c>();
      if (!updated.isEmpty()) {
        update updated;
        updatedOrDeactivated.addAll(updated);
      }
      if (!deactivated.isEmpty()) {
        update deactivated;
        updatedOrDeactivated.addAll(deactivated);
      }
      if (!updatedOrDeactivated.isEmpty()) {
        // Also update Inventory Line Items recording these Chemical Products.
        inventoryLineItemUpdates = updateRelatedLineItems(updatedOrDeactivated);
      }
      if (!calloutLogEntries.isEmpty()) {
        // If inserting log entries fails, record it but try to continue.
        try {
          insert calloutLogEntries;
          calloutLogEntries.clear();
        } catch (Exception e) {
          errors.add(e.getMessage() + '\n' + e.getStackTraceString());
        }
      }
    }
    /**
     * updateRelatedLineItems keeps certain fields on Inventory_Line_Item__c in sync with Chemical_Product__c
     * @param products (List<Chemical_Product__c>): items to process.
     */
    @TestVisible
    private Integer updateRelatedLineItems(List<Chemical_Product__c> products) {
      List<Inventory_Line_Item__c> lineItemsToUpdate = new List<Inventory_Line_Item__c>();
      for (Chemical_Product__c cp : products) {
        for (Inventory_Line_Item__c ili : cp.Inventory_Line_Items__r) {
          if (
            ili.ZDHC_Product_GUID__c != cp.ZDHC_Product_GUID__c ||
            ili.ZDHC_Product_Id__c != cp.ZDHC_Product_Id__c ||
            ili.ZDHC_MRSL_v2_0__c != cp.ZDHC_MRSL_v2_0__c ||
            ili.Other_Certifications__c != cp.Other_Certifications__c ||
            ili.ZDHC_MRSL_Version__c != cp.ZDHC_MRSL_Version__c ||
            ili.ZDHC_Certification_JSON__c != cp.ZDHC_Certification_JSON__c ||
            ili.Origin__c != cp.Origin__c  
          ) {
            ili.ZDHC_Product_GUID__c = cp.ZDHC_Product_GUID__c;
            ili.ZDHC_Product_Id__c = cp.ZDHC_Product_Id__c;
            ili.ZDHC_MRSL_v2_0__c = cp.ZDHC_MRSL_v2_0__c;
            ili.Other_Certifications__c = cp.Other_Certifications__c;
            ili.ZDHC_MRSL_Version__c = cp.ZDHC_MRSL_Version__c;
            ili.ZDHC_Certification_JSON__c = cp.ZDHC_Certification_JSON__c;
            ili.Origin__c = cp.Origin__c;
            lineItemsToUpdate.add(ili);
          }
        }
      }
      update lineItemsToUpdate;
      return lineItemsToUpdate.size();
    }
  }

  /**
   * synchronise Synchronises a single product by calling out to ZDHC Gateway
   * in search of a product by productGUID. Expecting only one result if found.
   * @param product (Chemical_Product__c): The product to look for updates for.
   */
  @TestVisible
  private SynchronisationResult synchronise(Chemical_Product__c product) {
    SynchronisationResult chunk = new SynchronisationResult();
    //Fetching ZDHC User Access Key from Custom Metadata based on environment
     if(OrgUtil.isProduction()){
       userAccessKey = ZDHC_Access_Key__mdt.getInstance('Sync_Chemical_Products_Key_PROD').ZDHC_User_Access_Key__c; 
    }
    else if(OrgUtil.isSandbox()){
      userAccessKey = ZDHC_Access_Key__mdt.getInstance('Sync_Chemical_Products_Key_SB').ZDHC_User_Access_Key__c;  
    }
    ZDHCGetProducts zdhcGetProducts = new ZDHCGetProducts(
      chunk.calloutLogEntries,
      userAccessKey,
      new Map<String, Object>{ 'productGUID' => product.ZDHC_Product_GUID__c }
    );
    try {
      if (zdhcGetProducts.call()) {
        chunk.pull(product, zdhcGetProducts.response.data[0]);
      } else {
        //update the ZDHC status
        product.Last_Verified_Date__c = Datetime.now();
        product.ZDHC_Status__c = 'Error';

        if (zdhcGetProducts.errors.size() == 0) {
          chunk.errors.add(Label.TC_Submitting_Product_to_ZDHC_Error);
        } else if (
          zdhcGetProducts.errors.size() > 0 &&
          zdhcGetProducts.errors[0] != 'No results found.'
        ) {
          // ZDHC Gateway API reports server error when product is not found.
          // Only errors other than 'No results found.' are logged.
          chunk.errors.addAll(zdhcGetProducts.errors);
        } else {
          // Not found. Is it already deactivated or needs deactivating?
          if (product.Product_Status__c == 'Deactivated') {
            chunk.notFound.add(product);
          } else {
            product.Product_Status__c = 'Deactivated';
            chunk.deactivated.add(product);
          }
        }
      }
    } catch (Exception e) {
      chunk.errors.add(e.getMessage() + '\n' + e.getStackTraceString());
    }
    return chunk;
  }

  /**
   * synchronise Synchronises a list of products which all have the same
   * Formulator__c therefore Formulator__r.Name.
   * @param formulatorName (String): The Formulator__r.Name of all list items.
   * @param products (List<Chemical_Product__c>): Updateable items to process.
   */
  @TestVisible
  private SynchronisationResult synchronise(
    String formulatorName,
    List<Chemical_Product__c> products
  ) {
    SynchronisationResult chunk = new SynchronisationResult();

   /* ZDHCGetProducts zdhcGetProducts = new ZDHCGetProducts(
      chunk.calloutLogEntries,
      userAccessKey,
      new Map<String, Object>{ 'FormulatorName' => formulatorName },
      1000
    );

    while (!zdhcGetProducts.isEnd() && products.size() > 1) {
      try {
        if (zdhcGetProducts.call()) {
          Map<String, ZDHCGetProductsResponseData> zdhcProducts = zdhcGetProducts.mapByProductGUID();
          chunk.pull(products, zdhcProducts);
          // Prepare for next iteration.
          // Products not found in this page of results are checked on the
          // next page.
          products = chunk.checkNext;
          chunk.checkNext = new List<Chemical_Product__c>();
        } else {
          // ZDHC Gateway API reports server error when products not found.
          if (zdhcGetProducts.errors.size() == 0) {
            chunk.errors.add(Label.TC_Submitting_Product_to_ZDHC_Error);
          } else if (
            zdhcGetProducts.errors.size() > 0 &&
            zdhcGetProducts.errors[0] != 'No results found.'
          ) {
            // Only errors other than 'No results found.' are logged.
            chunk.errors.addAll(zdhcGetProducts.errors);
          }
        }
      } catch (Exception e) {
        chunk.errors.add(e.getMessage() + '\n' + e.getStackTraceString());
      }
      // When the callout fails next resets the index to null.
      // isEnd is therefore then true.
      zdhcGetProducts.next();
    }*/

    // If any products remain they were not found looking by formulatorName.
    for (Chemical_Product__c product : products) {
      // Lookup one by one, using productGUID.
      chunk.addAll(synchronise(product));
    }
    return chunk;
  }

  /**
   * mapByFormulatorName Constructs a map of formulatorNames to lists of
   * products.
   * @param products (List<Chemical_Product__c>): Items to organise.
   * @return Map<String, List<Chemical_Product__c>>: Organised map.
   */
  @TestVisible
  private static Map<String, List<Chemical_Product__c>> mapByFormulatorName(
    List<Chemical_Product__c> products
  ) {
    Map<String, List<Chemical_Product__c>> productsByFormulator = new Map<String, List<Chemical_Product__c>>();
    for (Chemical_Product__c product : products) {
      if (!productsByFormulator.containsKey(product.Formulator__r.Name)) {
        productsByFormulator.put(
          product.Formulator__r.Name,
          new List<Chemical_Product__c>{ product }
        );
      } else {
        productsByFormulator.get(product.Formulator__r.Name).add(product);
      }
    }
    return productsByFormulator;
  }

  /**
   * synchronise Synchronises any list of products.
   * @param products (List<Chemical_Product__c>): Updateable items to process.
   */
  @TestVisible
  private SynchronisationResult synchronise(
    List<Chemical_Product__c> products
  ) {
    Map<String, List<Chemical_Product__c>> organisedByFormulator = mapByFormulatorName(
      products
    );
    SynchronisationResult chunks = new SynchronisationResult();
    for (String key : organisedByFormulator.keySet()) {
      chunks.addAll(synchronise(key, organisedByFormulator.get(key)));
    }
    return chunks;
  }
}